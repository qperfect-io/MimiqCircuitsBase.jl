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
    WhileStatement(op, bs::BitString)

Repeatedly applies the provided operation while the classical register matches
the specified `BitString`.

`WhileStatement` is the loop counterpart of [`IfStatement`](@ref). The body
operation `op` is executed once for every iteration in which the classical
register's state equals the `BitString`. For the loop to terminate, `op` must
mutate at least one of the bits used in the condition (see
[`allow_bit_aliasing`](@ref) — `WhileStatement` allows body bits to alias
condition bits, which is the only way to make progress).

There is no built-in iteration cap: a non-terminating circuit is the user's
responsibility, mirroring how every classical language treats `while`.

## Arguments
- `op`: The operation to apply each iteration.
- `bs`: A `BitString` representing the condition. The loop runs as long as the
  selected condition bits match this pattern.

## Examples

```julia
julia> using MimiqCircuitsBase

# Decrement c[1] until it reaches zero (assuming c[1] starts at 1)
julia> while_statement = WhileStatement(Not(), BitString("1"))
WHILE(c==1) X̲

julia> c = Circuit()
empty circuit

julia> push!(c, while_statement, 1, 1)
1-bit circuit with 1 instruction:
└── WHILE(c==1) X̲ @ c[1], condition[1]
```

See also [`IfStatement`](@ref).
"""
struct WhileStatement{N,M,K,T<:Operation} <: Operation{N,M,K}
    op::T
    bs::BitString

    function WhileStatement(op::T, bs::BitString) where {T<:Operation}
        N = numqubits(op)
        M = numbits(op) + length(bs)
        K = numzvars(op)
        return new{N,M,K,T}(op, bs)
    end
end

opname(::Type{<:WhileStatement}) = "WHILE"

inverse(::WhileStatement) = error("Cannot inverse a WhileStatement.")

_power(::WhileStatement, n) = error("Cannot elevate a WhileStatement to any power.")

getoperation(c::WhileStatement) = c.op

getbitstring(c::WhileStatement) = c.bs

# Wrapper recursion for `reorder_qubits`: the inner op may carry
# qubit-indexed payload (e.g. `Amplitude.bs`). The classical-bit
# condition is qubit-independent and stays unchanged.
function _reorder_op_internals(op::WhileStatement, perm::AbstractVector{<:Integer})
    new_inner = _reorder_op_internals(getoperation(op), perm)
    return WhileStatement(new_inner, getbitstring(op))
end

iswrapper(::Type{<:WhileStatement}) = true

isunitary(::Type{<:WhileStatement{N,M,K,T}}) where {N,M,K,T<:Operation} = isunitary(T)

# WhileStatement's classical-target layout is [op_bits..., condition_bits...].
# Termination requires the body to mutate a condition bit, so aliasing between
# body and condition is essential, not optional.
allow_bit_aliasing(::Type{<:WhileStatement}) = true
allow_zvar_aliasing(::Type{<:WhileStatement}) = true

# A WhileStatement is an opaque control-flow boundary — do NOT rewrite past it.
# The body itself can still be rewritten (see decompose_step! below).
matches(::CanonicalRewrite, ::WhileStatement) = false

function decompose_step!(builder, rule::CanonicalRewrite, ws::WhileStatement, qtargets, ctargets, ztargets)
    inner = getoperation(ws)
    condition = getbitstring(ws)

    target_bits = ctargets[1:numbits(inner)]
    condition_bits = ctargets[numbits(inner)+1:end]

    decomposed = decompose_step!(Circuit(), rule, inner, qtargets, target_bits, ztargets)

    # Wrap the rewritten body in a single Block instruction, preserving the loop
    # boundary as one WhileStatement. Unlike IfStatement we cannot flatten
    # iteration into per-instruction conditionals — the body must execute as a
    # contiguous unit each iteration.
    if length(decomposed) == 1
        only_inst = decomposed[1]
        new_inner_op = getoperation(only_inst)
        qt = getqubits(only_inst)
        bt = getbits(only_inst)
        zt = getztargets(only_inst)
        new_bits = (bt..., condition_bits...)
        push!(builder, Instruction(WhileStatement(new_inner_op, condition), qt, new_bits, zt))
    else
        block = Block(decomposed)
        new_bits = (target_bits..., condition_bits...)
        push!(builder, Instruction(WhileStatement(block, condition), qtargets, new_bits, ztargets))
    end

    return builder
end

function Base.show(io::IO, s::WhileStatement)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, "WhileStatement(", getoperation(s), sep, getbitstring(s), ")")
end

function Base.show(io::IO, m::MIME"text/plain", s::WhileStatement{N,M,K,T}) where {N,M,K,T}
    print(io, opname(WhileStatement), "(c==", to01(getbitstring(s)), ") ")
    show(io, m, getoperation(s))
end

function Base.:(==)(g1::WhileStatement, g2::WhileStatement)
    getoperation(g1) == getoperation(g2) || return false
    getbitstring(g1) == getbitstring(g2) || return false
    return true
end
