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

abstract type AbstractMeasurement{N} <: Operation{N,1,0} end

@doc raw"""
    Measure()

Single qubit measurement operation in the computational basis

The operation projects the quantum state and stores the result of such
measurement in a classical register.

!!! warn
    `Measure` is non-reversible.

See also [`Operation`](@ref), [`Reset`](@ref).

## Examples

```jldoctests
julia> Measure()
M

julia> c = push!(Circuit(), Measure, 1, 1)
1-qubit circuit with 1 instructions:
└── M @ q[1], c[1]

julia> push!(c, Measure(), 3, 4)
3-qubit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[3], c[4]
```
"""
struct Measure <: AbstractMeasurement{1} end

opname(::Type{<:Measure}) = "M"

inverse(::Measure) = error("Cannot invert measurements")

@doc raw"""
    MeasureX()

Single qubit measurement operation in the X basis.

The operation projects the quantum state and stores the result of such
measurement in a classical register.

This operation is equivalent to the sequence `GateH`, `Measure`, `GateH`. 

!!! warn
    `Measure` is non-reversible.

See also [`Measure`](@ref), [`Operation`](@ref), [`Reset`](@ref).

## Examples

```jldoctests
julia> Measure()
M

julia> decompose(MeasureX())
1-qubit circuit with 3 instructions:
├── H @ q[1]
├── M @ q[1], c[1]
└── H @ q[1]

julia> c = push!(Circuit(), Measure, 1, 1)
1-qubit circuit with 1 instructions:
└── M @ q[1], c[1]

julia> push!(c, Measure(), 3, 4)
3-qubit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[3], c[4]
```
"""
struct MeasureX <: AbstractMeasurement{1} end

opname(::Type{<:MeasureX}) = "MeasureX"

inverse(::MeasureX) = error("Cannot invert measurements")

function decompose!(circ::Circuit, ::MeasureX, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(circ, GateH(), q)
    push!(circ, Measure(), q, c)
    push!(circ, GateH(), q)
    return circ
end

function Base.show(io::IO, ::MeasureX)
    print(io, opname(MeasureX))
end

@doc raw"""
    MeasureY()

Single qubit measurement operation in the Y basis.

The operation projects the quantum state and stores the result of such
measurement in a classical register.

This operation is equivalent to the sequence `GateSDG`, `GateH`, `Measure`,
`GateH`, `GateS`. 

!!! warn
    `Measure` is non-reversible.

See also [`Measure`](@ref), [`Operation`](@ref), [`Reset`](@ref).

## Examples

```jldoctests
julia> MeasureY()
MeasureY

julia> decompose(MeasureY())
1-qubit circuit with 3 instructions:
├── HYZ @ q[1]
├── M @ q[1], c[1]
└── HYZ @ q[1]

julia> c = push!(Circuit(), MeasureY, 1, 1)
1-qubit circuit with 1 instructions:
└── MeasureY @ q[1], c[1]

julia> push!(c, MeasureY(), 3, 4)
3-qubit circuit with 2 instructions:
├── MeasureY @ q[1], c[1]
└── MeasureY @ q[3], c[4]
```
"""
struct MeasureY <: AbstractMeasurement{1} end

opname(::Type{<:MeasureY}) = "MeasureY"

inverse(::MeasureY) = error("Cannot invert measurements")

function decompose!(circ::Circuit, ::MeasureY, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(circ, GateHYZ(), q)
    push!(circ, Measure(), q, c)
    push!(circ, GateHYZ(), q)
    return circ
end

function Base.show(io::IO, ::MeasureY)
    print(io, opname(MeasureY))
end

@doc raw"""
    MeasureZ()

See [`Measure`](@ref).
"""
const MeasureZ = Measure

