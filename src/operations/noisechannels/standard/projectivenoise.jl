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
    ProjectiveNoiseX()

Single qubit projection noise onto a X Pauli basis.

This channel is defined by the Kraus operators

```math
E_1 = |-\rangle \langle-|, \quad E_2 = |+\rangle \langle+|,
```

Where ``\ket{+}`` and ``\ket{-}`` are the eigenstates of Pauli `X`.

See also [`ProjectiveNoise`](@ref), [`ProjectiveNoiseY`](@ref), or [`ProjectiveNoiseZ`](@ref).
"""
struct ProjectiveNoiseX <: AbstractKrausChannel{1} end

opname(::Type{<:ProjectiveNoiseX}) = "ProjectiveNoiseX"

function krausoperators(::ProjectiveNoiseX)
    return [ProjectorX0(), ProjectorX1()]
end

@doc raw"""
    ProjectiveNoiseY()

Single qubit projection noise onto a Y Pauli basis.

This channel is defined by the Kraus operators

```math
E_1 = |Y0\rangle \langle Y0|, \quad E_2 = |Y1\rangle \langle Y1|,
```

Where ``\ket{Y0}`` and ``\ket{Y1}`` are the eigenstates of Pauli `Y`.

See also [`ProjectiveNoise`](@ref), [`ProjectiveNoiseX`](@ref), or [`ProjectiveNoiseZ`](@ref).
"""
struct ProjectiveNoiseY <: AbstractKrausChannel{1} end

opname(::Type{<:ProjectiveNoiseY}) = "ProjectiveNoiseY"

function krausoperators(::ProjectiveNoiseY)
    return [ProjectorY0(), ProjectorY1()]
end

@doc raw"""
    ProjectiveNoiseZ()

Single qubit projection noise onto a Z Pauli basis.

This channel is defined by the Kraus operators

```math
E_1 = |0\rangle \langle Z0|, \quad E_2 = |1\rangle \langle Z1|,
```

Where ``\ket{0}`` and ``\ket{1}`` are the eigenstates of Pauli `Z`.

See also [`ProjectiveNoise`](@ref), [`ProjectiveNoiseX`](@ref), or [`ProjectiveNoiseY`](@ref).
"""
struct ProjectiveNoiseZ <: AbstractKrausChannel{1} end

opname(::Type{<:ProjectiveNoiseZ}) = "ProjectiveNoiseZ"

function krausoperators(::ProjectiveNoiseZ)
    return [Projector0(), Projector1()]
end

@doc raw"""
    ProjectiveNoise(basis)

Single qubit projection noise onto a Pauli basis.

This channel is defined by the Kraus operators

```math
E_1 = |\alpha\rangle \langle\alpha|, \quad E_2 = |\beta\rangle \langle\beta|,
```

where the states ``|\alpha\rangle`` and ``|\beta\rangle`` are the +1 and -1
eigenstates of a Pauli operator. Specifically, they correspond to
``\{ |0\langle, |1\langle \}`` (``Z`` basis),
``\{ |+\langle, |-\langle \}`` (``X`` basis),
or ``\{ |y+\langle, |y-\langle \}`` (`Y` basis).

This operation is similar to measuring in the corresponding basis (``X``, ``Y``, or ``Z``),
except that the outcome of the measurement is not stored, i.e. there's loss of information.

## Arguments

* `basis`: Symbol, String or Char that selects the Pauli basis, `"X"`, `"Y"`, or `"Z"`.

## Examples

```jldoctests
julia> push!(Circuit(), ProjectiveNoise("Z"), 1)
1-qubit circuit with 1 instructions:
└── ProjectiveNoiseZ @ q[1]
```

The Kraus matrices are given by:

```jldoctests
julia> krausmatrices(ProjectiveNoise("X"))
2-element Vector{Matrix{Float64}}:
 [0.5 0.5; 0.5 0.5]
 [0.5 -0.5; -0.5 0.5]

julia> krausmatrices(ProjectiveNoise("Y"))
2-element Vector{Matrix{ComplexF64}}:
 [0.5 + 0.0im 0.0 - 0.5im; 0.0 + 0.5im 0.5 + 0.0im]
 [0.5 + 0.0im 0.0 + 0.5im; 0.0 - 0.5im 0.5 + 0.0im]

julia> krausmatrices(ProjectiveNoise("Z"))
2-element Vector{Matrix{Int64}}:
 [1 0; 0 0]
 [0 0; 0 1]
```
"""
function ProjectiveNoise end

function ProjectiveNoise(basis::Symbol=:Z)
    if basis == :X
        return ProjectiveNoiseX()
    elseif basis == :Y
        return ProjectiveNoiseY()
    elseif basis == :Z
        return ProjectiveNoiseZ()
    end
    error("Invalid basis for Projective noise. Must be X, Y, or Z.")
end

ProjectiveNoise(basis) = ProjectiveNoise(Symbol(basis))

