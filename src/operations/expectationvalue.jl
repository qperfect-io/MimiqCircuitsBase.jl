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

@doc raw"""
    ExpectationValue(op)

Operation to compute and store expectation value of an Operator in a z-register.

An expectation value for a pure state ``| \psi \rangle`` is defined as
```math
\langle O \rangle = \langle \psi | O | \psi \rangle
```
where ``O`` is an operator. With respect to a density matrix ``\rho`` it's given by
```math
\langle O \rangle = \mathrm{Tr}(\rho O).
```
However, when using quantum trajectories to solve noisy circuits, the expectation
value is computed with respect to the pure state of each trajectory.

The argument `op` can be any gate or non-unitary operator.

!!! note
    ExpectationValue is currently restricted to one and two qubit operators.

See also [`AbstractOperator`](@ref), [`AbstractGate`](@ref).

## Examples

In `push!` the first argument corresponds to the qubit, and the second to the z-register

```jldoctests
julia> ExpectationValue(GateX())
⟨X⟩

julia> c = push!(Circuit(), ExpectationValue(GateX()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨X⟩ @ q[1], z[1]

julia> c = push!(Circuit(), ExpectationValue(SigmaPlus()), 1, 2)
1-qubit circuit with 1 instructions:
└── ⟨SigmaPlus(1)⟩ @ q[1], z[2]

```
"""
struct ExpectationValue{N,T<:AbstractOperator{N}} <: Operation{N,0,1}
    op::T

    function ExpectationValue(op::T) where {N,T<:AbstractOperator{N}}
        if !(op isa PauliString) && !(1 <= N <= 2)
            throw(ArgumentError("ExpectationValue only supports 1- or 2-qubit operators unless the operator is a PauliString."))
        end
        new{N,T}(op)
    end
end

iswrapper(::Type{<:ExpectationValue}) = true

# numparams is defined by default from parnames
parnames(::Type{ExpectationValue{N,T}}) where {N,T} = parnames(T)

# access directly the parameters of the wrapped gate
getparam(c::ExpectationValue, name::Symbol) = getparam(getoperation(c), name)

opname(::Type{<:ExpectationValue}) = "ExpectationValue"

qregsizes(::ExpectationValue{N,T}) where {N,T} = (N,)

getoperation(c::ExpectationValue{N,T}) where {N,T} = c.op

cregsizes(::ExpectationValue{N,T}) where {N,T} = ()

zregsizes(::ExpectationValue{N,T}) where {N,T} = (1,)

inverse(::ExpectationValue{N,T}) where {N,T} = error("Cannot inverse an ExpectationValue operation.")

power(::ExpectationValue{N,T}, _) where {N,T} = error("Cannot elevate an ExpectationValue operation to any power.")

# NOTE: check execute in AbstractQCSs if this is changed to false
isunitary(::Type{<:ExpectationValue{N,T}}) where {N,T} = true

function Base.show(io::IO, m::MIME"text/plain", op::ExpectationValue{N,T}) where {N,T}
    print(io, "⟨")
    _show_wrapped_parens(io, m, getoperation(op))
    print(io, "⟩")
end

