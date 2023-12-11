#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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
    Inverse(operation)

Inverse of the wrapped quantum operation.

The inversion is not performed right away, but only when the circuit is cached
or executed.

Some simplifications are already carried out at construction, for example,
`Inverse(Inverse(op))` is simplified as `Inverse(op)`.

!!! warn
    Users should not use directly `Inverse` but the `inverse` method, which
    performs already all the simplifications.

See also [`inverse`](@ref), [`iswrapper`](@ref), [`Control`](@ref),
[`Power`](@ref).

## Examples

```jldoctests
julia> Inverse(GateX())
X†

julia> Inverse(GateH())
H†

julia> Inverse(GateSX())
SX†

julia> Inverse(GateCSX())
(CSX)†

julia> Inverse(QFT(4))
QFT†

```

## Decomposition

Decomposition of the inverse is carring out by inverting the decomposition of
the wrapped operation.

```jldoctests
julia> decompose(Inverse(GateCSX()))
2-qubit circuit with 3 instructions:
├── H @ q[2]
├── CU1(-1π/2) @ q[1], q[2]
└── H @ q[2]
```
"""
struct Inverse{N,T<:AbstractGate{N}} <: AbstractGate{N}
    op::T

    function Inverse(op::T) where {N,T<:AbstractGate{N}}
        new{N,T}(op)
    end

    function Inverse{N,T}(args...; kwargs...) where {N,T<:AbstractGate{N}}
        new{N,T}(T(args...; kwargs...))
    end
end

# avoids to repeat the wrapper uselessly
# the constructor is not supposed to perform simplifications
# this is an exception
Inverse(inv::Inverse) = inv.op

# inverse is supposed to perform the simplification, so ok.
inverse(inv::Inverse) = inv.op

opname(::Type{<:Inverse}) = "Inverse"

iswrapper(::Type{<:Inverse}) = true

getoperation(inv::Inverse) = inv.op

qregsizes(q::Inverse) = qregsizes(getoperation(q))

# numparams is defined by default from parnames
parnames(::Type{Inverse{N,T}}) where {N,T} = parnames(T)

# access directly the parameters of the wrapped gate
getparam(inv::Inverse, name) = getparam(getoperation(inv), name)

@generated _matrix(::Type{Inverse{N,T}}) where {N,T} = adjoint(_matrix(T))

_matrix(::Type{Inverse{N,T}}, args...) where {N,T} = adjoint(_matrix(T, args...))

function decompose!(circuit::Circuit, inv::Inverse, qtargets, _)
    newcirc = decompose!(Circuit(), inv.op, qtargets, nothing)

    for inst in inverse(newcirc)
        push!(circuit, inst)
    end

    return circuit
end

function Base.show(io::IO, inv::Inverse)
    op = getoperation(inv)
    _print_wrapped_parens(io, op)

    # PERF: should not be there, since the operation wrapped should always be
    # unitary.
    if isunitary(getoperation(inv))
        print(io, "†")
    else
        print(io, "⁻¹")
    end
end
