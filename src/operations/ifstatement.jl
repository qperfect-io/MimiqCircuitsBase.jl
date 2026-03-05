#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""
    IfStatement(op, bs::BitString)

Applies the provided operation only if the classical register matches the specified `BitString`.

`IfStatement` enables conditional operations in a quantum circuit based on the state of a classical register. 
If the classical register's state matches the `BitString`, the operation (`op`) is applied to the target qubits.

## Arguments
- `op`: The quantum operation to apply, such as `GateX()` or another operation.
- `bs`: A `BitString` object representing the target state of the classical register that triggers `op`.

## Examples

### Basic Usage
```julia
julia> using MimiqCircuitsBase

# Define a condition as a BitString
julia> condition = BitString("01011")
5-bits BitString with integer value 26:
  01011

# Apply GateX only if the condition is met
julia> if_statement = IfStatement(GateX(), condition)
IF(c==01011) X

# Add this conditional operation to a circuit
julia> c = Circuit()
empty circuit

julia> push!(c, if_statement, 1, 2, 3, 4, 5, 6)
1-qubit, 6-bit circuit with 1 instructions:
└── IF(c==01011) X @ q[1], condition[2:6]

julia> push!(c, IfStatement(Measure(),BitString("010")),1,1,3,4,5)
1-qubit, 6-bit circuit with 2 instructions:
├── IF(c==01011) X @ q[1], condition[2:6]
└── IF(c==010) M @ q[1], c[1], condition[3:5]

julia> push!(c,IfStatement(Amplitude(BitString("01")),BitString("01")),1,2,1)
1-qubit, 6-bit, 1-vars circuit with 3 instructions:
├── IF(c==01011) X @ q[1], condition[2:6]
├── IF(c==010) M @ q[1], c[1], condition[3:5]
└── IF(c==01) Amplitude(bs"01") @ condition[1:2], z[1]

```
"""
struct IfStatement{N,M,K,T<:Operation} <: Operation{N,M,K}
    op::T
    bs::BitString

    function IfStatement(op::T, bs::BitString) where {T<:Operation}
        N = numqubits(op)
        M = numbits(op) + length(bs)
        K = numzvars(op)
        return new{N,M,K,T}(op, bs)
    end
end

opname(::Type{<:IfStatement}) = "IF"

inverse(::IfStatement) = error("Cannot inverse an IfStatement.")

_power(::IfStatement, n) = error("Cannot elevate an IfStatement to any power.")

getoperation(c::IfStatement) = c.op

getbitstring(c::IfStatement) = c.bs

iswrapper(::Type{<:IfStatement}) = true

matches(strat::CanonicalRewrite, ifs::IfStatement) = matches(strat, getoperation(ifs))

function decompose_step!(builder, rule::CanonicalRewrite, ifs::IfStatement, qtargets, ctargets, ztargets)
    inner = getoperation(ifs)
    condition = getbitstring(ifs)

    target_bits = ctargets[1:numbits(inner)]
    condition_bits = ctargets[numbits(inner)+1:end]

    decomposed = decompose_step!(Circuit(), rule, inner, qtargets, target_bits, ztargets)

    for inst in decomposed
        op = getoperation(inst)
        qt = getqubits(inst)
        bt = getbits(inst)
        zt = getztargets(inst)

        if op isa IfStatement
            # Flatten the if statements, the topmost condition goes to the back.
            inner_inner = getoperation(op)

            inner_condition_bits = bt[numbits(inner_inner)+1:end]
            inner_target_bits = bt[1:numbits(inner_inner)]

            new_bits = (inner_target_bits..., inner_condition_bits..., condition_bits...)
            new_condition = vcat(getbitstring(op), condition)

            push!(builder, Instruction(IfStatement(inner_inner, new_condition), qt, new_bits, zt))
        else
            new_bits = (bt..., condition_bits...)
            push!(builder, Instruction(IfStatement(op, condition), qt, new_bits, zt))
        end
    end

    return builder
end

function Base.show(io::IO, s::IfStatement)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, "IfStatement(", getoperation(s), sep, getbitstring(s), ")")
end

function Base.show(io::IO, m::MIME"text/plain", s::IfStatement{N,M,K,T}) where {N,M,K,T}
    print(io, opname(IfStatement), "(c==", to01(getbitstring(s)), ") ")
    show(io, m, getoperation(s))
end

function Base.:(==)(g1::IfStatement, g2::IfStatement)
    getoperation(g1) == getoperation(g2) || return false
    getbitstring(g1) == getbitstring(g2) || return false
    return true
end
