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
1-qubit, 1-bit circuit with 1 instruction:
└── M @ q[1], c[1]

julia> push!(c, Measure(), 3, 4)
3-qubit, 4-bit circuit with 2 instructions:
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
1-qubit, 1-bit circuit with 3 instructions:
├── U(π/2,0,π) @ q[1]
├── M @ q[1], c[1]
└── U(π/2,0,π) @ q[1]

julia> c = push!(Circuit(), Measure, 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── M @ q[1], c[1]

julia> push!(c, Measure(), 3, 4)
3-qubit, 4-bit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[3], c[4]
```
"""
struct MeasureX <: AbstractMeasurement{1} end

opname(::Type{<:MeasureX}) = "MeasureX"

inverse(::MeasureX) = error("Cannot invert measurements")

matches(::CanonicalRewrite, ::MeasureX) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureX, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(builder, GateH(), q)
    push!(builder, Measure(), q, c)
    push!(builder, GateH(), q)
    return builder
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
1-qubit, 1-bit circuit with 11 instructions:
├── U(π/2,0,π) @ q[1]
├── U(0,0,π/2) @ q[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,π) @ q[1]
├── U(0,0,0,-1π/4) @ q[1]
├── M @ q[1], c[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,π/2) @ q[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,π) @ q[1]
└── U(0,0,0,-1π/4) @ q[1]

julia> c = push!(Circuit(), MeasureY, 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── MeasureY @ q[1], c[1]

julia> push!(c, MeasureY(), 3, 4)
3-qubit, 4-bit circuit with 2 instructions:
├── MeasureY @ q[1], c[1]
└── MeasureY @ q[3], c[4]
```
"""
struct MeasureY <: AbstractMeasurement{1} end

opname(::Type{<:MeasureY}) = "MeasureY"

inverse(::MeasureY) = error("Cannot invert measurements")

matches(::CanonicalRewrite, ::MeasureY) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureY, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(builder, GateHYZ(), q)
    push!(builder, Measure(), q, c)
    push!(builder, GateHYZ(), q)
    return builder
end

function Base.show(io::IO, ::MeasureY)
    print(io, opname(MeasureY))
end

@doc raw"""
    MeasureZ()

See [`Measure`](@ref).
"""
const MeasureZ = Measure

