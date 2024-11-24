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
    Reset()

Quantum operation that resets the status of one qubit to the ``\ket{0}``
state.

See also [`Operation`](@ref), [`Measure`](@ref).

## Examples

```jldoctests
julia> Reset()
Reset

julia> c = push!(Circuit(), Reset, 1)
1-qubit circuit with 1 instructions:
└── Reset @ q[1]

julia> push!(c, Reset(), 3)
3-qubit circuit with 2 instructions:
├── Reset @ q[1]
└── Reset @ q[3]
```
"""
struct Reset <: AbstractKrausChannel{1} end

inverse(::Reset) = error("Cannot invert reset operations")

opname(::Type{<:Reset}) = "Reset"

krausmatrices(res::Reset) = [matrix(kraus) for kraus in krausoperators(res)]

function krausoperators(::Reset)
    return [Projector0(), SigmaMinus()]
end

function Base.show(io::IO, ::Reset)
    print(io, opname(Reset))
end

@doc raw"""
    ResetX

Quantum operation that resets the status of one qubit to ``\ket{+} = (\ket{0}+\ket{1})/\sqrt{2}``,
the +1 eigenstate of the X gate.

This operation is equivalent to the sequence `Reset`, `GateH`.

See also [`Reset`](@ref), [`Operation`](@ref), [`Measure`](@ref).

## Examples

```jldoctests
julia> ResetX()
ResetX

julia> decompose(ResetX())
1-qubit circuit with 3 instructions:
├── H @ q[1]
├── Reset @ q[1]
└── H @ q[1]

julia> c = push!(Circuit(), ResetX, 1)
1-qubit circuit with 1 instructions:
└── ResetX @ q[1]

julia> push!(c, ResetX(), 3)
3-qubit circuit with 2 instructions:
├── ResetX @ q[1]
└── ResetX @ q[3]
```
"""
struct ResetX <: AbstractKrausChannel{1} end

inverse(::ResetX) = error("Cannot invert ResetX operations")

opname(::Type{<:ResetX}) = "ResetX"

krausmatrices(res::ResetX) = [matrix(kraus) for kraus in krausoperators(res)]

function krausoperators(::ResetX)
    return [Operator(1 / sqrt(2) .* [1 0; 1 0]),
        Operator(1 / sqrt(2) .* [0 1; 0 1])]
end

function decompose!(circ::Circuit, ::ResetX, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateH(), q)
    push!(circ, Reset(), q)
    push!(circ, GateH(), q)
    return circ
end

function Base.show(io::IO, ::ResetX)
    print(io, opname(ResetX))
end

@doc raw"""
    ResetY

Quantum operation that resets the status of one qubit to ``\ket{y+} = (\ket{0}+i\ket{1})/\sqrt{2}``,
the +1 eigenstate of the Y gate.

This operation is equivalent to the sequence `Reset`, `GateH`, `GateS`.

See also [`Reset`](@ref), [`Operation`](@ref), [`Measure`](@ref).

## Examples

```jldoctests
julia> ResetY()
ResetY

julia> decompose(ResetY())
1-qubit circuit with 3 instructions:
├── HYZ @ q[1]
├── Reset @ q[1]
└── HYZ @ q[1]

julia> c = push!(Circuit(), ResetY, 1)
1-qubit circuit with 1 instructions:
└── ResetY @ q[1]

julia> push!(c, ResetY(), 3)
3-qubit circuit with 2 instructions:
├── ResetY @ q[1]
└── ResetY @ q[3]
```
"""
struct ResetY <: AbstractKrausChannel{1} end

inverse(::ResetY) = error("Cannot invert ResetY operations")

opname(::Type{<:ResetY}) = "ResetY"

krausmatrices(res::ResetY) = [matrix(kraus) for kraus in krausoperators(res)]

function krausoperators(::ResetY)
    return [Operator(1 / sqrt(2) .* [1 0; im 0]),
        Operator(1 / sqrt(2) .* [0 1; 0 im])]
end

function decompose!(circ::Circuit, ::ResetY, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateHYZ(), q)
    push!(circ, Reset(), q)
    push!(circ, GateHYZ(), q)
    return circ
end

function Base.show(io::IO, ::ResetY)
    print(io, opname(ResetY))
end

@doc raw"""
    ResetZ()

See [`Reset`](@ref).
"""
const ResetZ = Reset
