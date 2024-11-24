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
    AbstractAnnotation{N, M, L} <: Operation{N, M, L}

An abstract type representing a general annotation operation for use in quantum circuits. 
This type supports annotations that are not strictly quantum operations but may carry metadata or extra circuit information.
"""
abstract type AbstractAnnotation{N,M,L} <: Operation{N,M,L} end

"""
    Detector{N}(N::Integer, notes::AbstractVector)

An annotation class representing a detector in a quantum circuit. 
The `Detector` checks the parity of measurement results over `N` classical bits, where the parity should be deterministic under noiseless execution.

Detector monitors the results of a specific set of measurements and verifies that their combined parity (even or odd) remains consistent. This consistency is expected under ideal, noiseless conditions. 
If noise or errors disrupt the circuit, the Detector can identify this because the parity will change unexpectedly, 
signaling a potential error in the measurement outcomes. This helps in error detection by revealing inconsistencies that arise due to unintended disturbances.

See Also [`QubitCoordinates`](@ref), [`ShiftCoordinates`](@ref), or [`Tick`](@ref)

# Arguments
- `N::Integer`: The number of classical bits.
- `notes::AbstractVector`: A vector of floating-point values that contain measurement notes.

# Throws
- `ArgumentError`: If `N` is zero or negative.

# Examples

```jldoctests
julia> detector = Detector(2, [1.0, 0.5])
Detector(1.0, 0.5)

julia> c = Circuit()
empty circuit

julia> push!(c,detector,1,2)
0-qubit circuit with 1 instructions:
└── Detector(1.0,0.5) @ c[1:2]
```
"""
struct Detector{N} <: AbstractAnnotation{0,N,0}
    notes::Vector{Float64}

    function Detector(N::Integer, notes::AbstractVector)
        if N <= 0
            throw(ArgumentError("Detectors should be applied to at least 1 classical bit"))
        end
        return new{N}(float.(notes))
    end
end

Detector(N::Integer, notes...) = Detector(N, collect(notes))

Detector(args...) = LazyExpr(Detector, LazyArg(), collect(args))

opname(::Type{<:Detector}) = "Detector"

cregsizes(::Detector{N}) where {N} = (N,)

getnotes(a::Detector) = a.notes

function Base.show(io::IO, a::Detector)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, opname(a), "(")
    join(io, getnotes(a), sep)
    print(io, ")")
end

Base.show(io::IO, ::MIME"text/plain", a::Detector) = show(io, a)

"""
    QubitCoordinates(coordinates...)


An annotation class used to specify the spatial location of a qubit in a quantum circuit. 
Coordinates do not affect simulation results but are useful for visualizing and organizing qubit layouts within the circuit.

See Also [`Detector`](@ref), [`ShiftCoordinates`](@ref), or [`Tick`](@ref)

# Arguments
- `coordinates`: A variable number of floating-point values representing the coordinates of the qubit.

# Examples

```jldoctests
julia> coords = QubitCoordinates(0.0, 1.0)
QubitCoordinates(0.0, 1.0)

julia> c = Circuit()
empty circuit

julia> push!(c,coords,1)
1-qubit circuit with 1 instructions:
└── QubitCoordinates(0.0,1.0) @ q[1]
```
"""
struct QubitCoordinates <: AbstractAnnotation{1,0,0}
    coordinates::Vector{Float64}
end

QubitCoordinates(coordinates...) = QubitCoordinates(collect(coordinates))

opname(::Type{<:QubitCoordinates}) = "QubitCoordinates"

getnotes(a::QubitCoordinates) = a.coordinates

function Base.show(io::IO, a::QubitCoordinates)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, opname(a), "(")
    join(io, getnotes(a), sep)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", a::QubitCoordinates)
    show(io, a)
end

"""
    ShiftCoordinates(coordinates...)

An annotation class used to apply a shift to the spatial coordinates of subsequent qubit or detector annotations in a quantum circuit. 
`ShiftCoordinates` accumulates offsets that adjust the position of related circuit components, aiding in visualization without affecting the simulation.

See Also [`QubitCoordinates`](@ref), [`ShiftCoordinates`](@ref), or [`Tick`](@ref)

# Arguments
- `coordinates`: A variable number of floating-point values representing the shift offsets for each coordinate.

# Examples

```jldoctests
julia> shift = ShiftCoordinates(1.0, 2.0)
ShiftCoordinates(1.0, 2.0)

julia> c = Circuit()
empty circuit

julia> push!(c, shift)
0-qubit circuit with 1 instructions:
└── ShiftCoordinates(1.0,2.0)
```
"""
struct ShiftCoordinates <: AbstractAnnotation{0,0,0}
    coordinates::Vector{Float64}
end

ShiftCoordinates(coordinates...) = ShiftCoordinates(collect(coordinates))

opname(::Type{<:ShiftCoordinates}) = "ShiftCoordinates"

getnotes(a::ShiftCoordinates) = a.coordinates

function Base.show(io::IO, a::ShiftCoordinates)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, opname(a), "(")
    join(io, getnotes(a), sep)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", a::ShiftCoordinates)
    show(io, a)
end

"""
    ObservableInclude{N}(N::Integer, notes::AbstractVector)

An annotation class for adding measurement records to a specified logical observable within a quantum circuit. 
Observables are sets of measurements expected to produce a deterministic result, used to track specific logical qubit states across operations.

The ObservableInclude class tags a group of measurement records as a logical observable, representing a consistent, predictable result under noiseless conditions. 
This grouping allows for tracking the state of logical qubits across circuit operations, which is crucial for error correction. 
Logical observables monitor encoded qubit states by combining multiple measurements, providing robustness against noise and helping to identify any deviations that indicate potential errors.

See Also [`QubitCoordinates`](@ref), [`Detector`](@ref), or [`Tick`](@ref)

# Arguments
- `N::Integer`: The number of classical bits observed in this logical observable.
- `notes::AbstractVector`: A vector of integers identifying measurement records.

# Throws
- `ArgumentError`: If `N` is zero or negative.

# Examples

```jldoctests
julia> obs_include = ObservableInclude(2, [1, 2])
ObservableInclude(1, 2)

julia> c = Circuit()
empty circuit

julia> push!(c, obs_include,1,2)
0-qubit circuit with 1 instructions:
└── ObservableInclude(1,2) @ c[1:2]
```
"""
struct ObservableInclude{N} <: AbstractAnnotation{0,N,0}
    notes::Vector{Int64}

    function ObservableInclude(N::Integer, notes::AbstractVector)
        if N <= 0
            throw(ArgumentError("ObservableIncludes should be applied to at least 1 classical bit"))
        end
        return new{N}(Int64.(notes))
    end
end

ObservableInclude(N::Integer, notes...) = ObservableInclude(N, collect(notes))

ObservableInclude(args...) = LazyExpr(ObservableInclude, LazyArg(), collect(args))

opname(::Type{<:ObservableInclude}) = "ObservableInclude"

cregsizes(::ObservableInclude{N}) where {N} = (N,)

getnotes(a::ObservableInclude) = a.notes

function Base.show(io::IO, a::ObservableInclude)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, opname(a), "(")
    join(io, getnotes(a), sep)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", a::ObservableInclude)
    show(io, a)
end

"""
    Tick()

An annotation class representing a timing marker or layer boundary in a quantum circuit. 
`Tick` does not affect simulation but provides structure by separating operations into distinct time steps, which is useful for visualization and analysis.

See Also [`QubitCoordinates`](@ref), [`ShiftCoordinates`](@ref), or [`Detector`](@ref)

# Examples

```jldoctests
julia> tick = Tick()
Tick()

julia> c = Circuit()
empty circuit

julia> push!(c, tick)
0-qubit circuit with 1 instructions:
└── Tick()
```
"""
struct Tick <: AbstractAnnotation{0,0,0}
end

opname(::Type{<:Tick}) = "Tick"

getnotes(a::Tick) = []

function Base.show(io::IO, a::Tick)
    sep = get(io, :compact, false) ? "," : ", "
    print(io, opname(a), "(")
    join(io, getnotes(a), sep)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", a::Tick)
    show(io, a)
end
