#
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

@doc raw"""
    Loss(p)
    Loss()

A qubit-loss event: the qubit is lost with probability `p`.

`Loss()` is `Loss(1.0)`, a certain loss. Loss is a kind of noise, so it
sits alongside the other noise channels.

The probability is resolved by [`sample_losses`](@ref), which turns each
`Loss(p)` into a `Loss(1.0)` (the qubit is lost here) or removes it. A circuit
is turned into a runnable, loss-free form by [`lower_losses`](@ref).

See also [`Reload`](@ref), [`Check`](@ref), [`MeasureCheck`](@ref).

## Examples

```jldoctests
julia> push!(Circuit(), Loss(0.1), 1)
1-qubit circuit with 1 instruction:
└── Loss(0.1) @ q[1]

julia> push!(Circuit(), Loss(), 1)
1-qubit circuit with 1 instruction:
└── Loss(1.0) @ q[1]
```
"""
struct Loss <: Operation{1,0,0}
    p::Num
    function Loss(p::Number)
        if !(p isa Symbolics.Num)
            if p < 0 || p > 1
                throw(ArgumentError("Loss probability p must be between 0 and 1."))
            end
        end
        new(p)
    end
end

Loss() = Loss(1.0)

function evaluate(op::Loss, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(op.p, d)
    p = Symbolics.value(evaluated_p)

    if p isa Real
        if p < 0 || p > 1
            throw(ArgumentError("Loss probability p must be between 0 and 1 after evaluation."))
        end
        return Loss(p)
    else
        return Loss(evaluated_p)
    end
end

opname(::Type{<:Loss}) = "Loss"

Base.show(io::IO, op::Loss) = print(io, opname(Loss), "(", op.p, ")")
Base.show(io::IO, ::MIME"text/plain", op::Loss) = print(io, opname(Loss), "(", op.p, ")")

inverse(::Loss) = error("Loss is not invertible")

@doc raw"""
    Reload()

Reload a qubit: re-initialise it to ``|0\rangle`` and mark it present.

`Reload` always resets the qubit, whether or not it was lost.
[`lower_losses`](@ref) turns it into a [`Reset`](@ref) plus a
[`Reloaded`](@ref) marker.

See also [`Loss`](@ref), [`Reset`](@ref).

## Examples

```jldoctests
julia> push!(Circuit(), Reload(), 1)
1-qubit circuit with 1 instruction:
└── Reload @ q[1]
```
"""
struct Reload <: Operation{1,0,0} end

opname(::Type{<:Reload}) = "Reload"

Base.show(io::IO, ::Reload) = print(io, opname(Reload))
Base.show(io::IO, ::MIME"text/plain", ::Reload) = print(io, opname(Reload))

inverse(::Reload) = error("Reload is not invertible")

@doc raw"""
    Check()

Record whether a qubit is present into a classical bit.

- bit = 1 → the qubit is present
- bit = 0 → the qubit is lost

Like [`Measure`](@ref) records a qubit's value, `Check` records its presence.
It does not touch the quantum state.

See also [`MeasureCheck`](@ref), [`Loss`](@ref), [`Reload`](@ref).

## Examples

```jldoctests
julia> push!(Circuit(), Check(), 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── Check @ q[1], c[1]
```
"""
struct Check <: Operation{1,1,0} end

opname(::Type{<:Check}) = "Check"

Base.show(io::IO, ::Check) = print(io, opname(Check))
Base.show(io::IO, ::MIME"text/plain", ::Check) = print(io, opname(Check))

inverse(::Check) = error("Check is not invertible")

@doc raw"""
    MeasureCheck()

Measure a qubit if it is present, and record its presence.

- first bit  = measurement result (0 or 1); forced to 0 if the qubit is lost
- second bit = presence (1 present, 0 lost)

The state is collapsed only when the qubit is present.

See also [`Check`](@ref), [`Measure`](@ref), [`Loss`](@ref).

## Examples

```jldoctests
julia> push!(Circuit(), MeasureCheck(), 1, 1, 2)
1-qubit, 2-bit circuit with 1 instruction:
└── MeasureCheck @ q[1], c[1:2]
```
"""
struct MeasureCheck <: Operation{1,2,0} end

opname(::Type{<:MeasureCheck}) = "MeasureCheck"

Base.show(io::IO, ::MeasureCheck) = print(io, opname(MeasureCheck))
Base.show(io::IO, ::MIME"text/plain", ::MeasureCheck) = print(io, opname(MeasureCheck))

inverse(::MeasureCheck) = error("MeasureCheck is not invertible")
