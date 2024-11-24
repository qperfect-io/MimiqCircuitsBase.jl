#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
- `op`: The quantum operation to apply, such as `GateX()` or another gate.
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
julia> push!(c, if_statement, 1, 2, 3, 4, 5, 6)
1-qubit circuit with 1 instructions:
└── IF(c==01011) X @ q[1], c[2:6]

```
"""
struct IfStatement{N,M,T<:Operation{N,0,0}} <: Operation{N,M,0}
    op::T
    bs::BitString

    function IfStatement(op::T, bs::BitString) where {T<:AbstractGate}
        new{numqubits(op),length(bs),T}(op, bs)
    end
end

opname(::Type{<:IfStatement}) = "IF"

inverse(::IfStatement) = error("Cannot inverse an IfStatement.")

_power(::IfStatement, n) = error("Cannot elevate an IfStatement to any power.")

getoperation(c::IfStatement) = c.op

getbitstring(c::IfStatement) = c.bs

iswrapper(::Type{<:IfStatement}) = true

function decompose!(circuit::Circuit, ifs::IfStatement{N,M,T}, qtargets, ctargets, _) where {N,M,T}
    decomposed = decompose(getoperation(ifs))

    bs = getbitstring(ifs)

    for inst in decomposed
        push!(
            circuit,
            IfStatement(getoperation(inst), bs),
            qtargets[collect(getqubits(inst))]...,
            ctargets...
        )
    end

    return circuit
end

function Base.show(io::IO, s::IfStatement)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, "IfStatement(", getoperation(s), sep, getbitstring(s), ")")
end

function Base.show(io::IO, m::MIME"text/plain", s::IfStatement{N,M,T}) where {N,M,T}
    print(io, opname(IfStatement), "(c==", to01(getbitstring(s)), ") ")
    show(io, m, getoperation(s))
end
