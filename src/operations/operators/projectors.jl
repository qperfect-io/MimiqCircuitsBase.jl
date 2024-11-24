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
    Projector0(a)

One-qubit operator corresponding to a projection onto ``|0\rangle``.

The corresponding matrix
```math
\begin{pmatrix}
    a & 0\\
    0 & 0
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.
Equivalent to `DiagonalOp(a,0)`.

The parameter ``a`` is optional and is set to 1 by default.

See also [`Projector1`](@ref), [`DiagonalOp`](@ref).

## Examples

```jldoctests
julia> Projector0()
P₀(1)

julia> Projector0(0.5)
P₀(0.5)

julia> push!(Circuit(), ExpectationValue(Projector0()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨P₀(1)⟩ @ q[1], z[1]
```
"""
struct Projector0 <: AbstractOperator{1}
    a::Num
end

Projector0() = Projector0(1)

opname(::Type{<:Projector0}) = "P₀"

_matrix(::Type{Projector0}, a) = [a 0; 0 0]


@doc raw"""
    Projector1(a)

One-qubit operator corresponding to a projection onto ``|1\rangle``.

The corresponding matrix
```math
\begin{pmatrix}
    0 & 0\\
    0 & a
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.
Equivalent to `DiagonalOp(0,a)`.

The parameter ``a`` is optional and is set to 1 by default.

See also [`Projector0`](@ref), [`DiagonalOp`](@ref).

## Examples

```jldoctests
julia> Projector1()
P₁(1)

julia> Projector1(0.5)
P₁(0.5)

julia> push!(Circuit(), ExpectationValue(Projector1()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨P₁(1)⟩ @ q[1], z[1]
```
"""
struct Projector1 <: AbstractOperator{1}
    a::Num
end

Projector1() = Projector1(1)

opname(::Type{<:Projector1}) = "P₁"

_matrix(::Type{Projector1}, a) = [0 0; 0 a]


@doc raw"""
    ProjectorZ0(a)

See [`Projector0`](@ref).
"""
const ProjectorZ0 = Projector0


@doc raw"""
    ProjectorZ1(a)

See [`Projector1`](@ref).
"""
const ProjectorZ1 = Projector1


@doc raw"""
    ProjectorX0(a)

One-qubit operator corresponding to a projection onto ``|+\rangle``.

The corresponding matrix
```math
\frac{a}{2}
\begin{pmatrix}
    1 & 1\\
    1 & 1
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`ProjectorX1`](@ref).

## Examples

```jldoctests
julia> ProjectorX0()
PX₀(1)

julia> ProjectorX0(0.5)
PX₀(0.5)

julia> push!(Circuit(), ExpectationValue(ProjectorX0()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨PX₀(1)⟩ @ q[1], z[1]
```
"""
struct ProjectorX0 <: AbstractOperator{1}
    a::Num
end

ProjectorX0() = ProjectorX0(1)

opname(::Type{<:ProjectorX0}) = "PX₀"

_matrix(::Type{ProjectorX0}, a) = a / 2 .* [1 1; 1 1]


@doc raw"""
    ProjectorX1(a)

One-qubit operator corresponding to a projection onto ``|-\rangle``.

The corresponding matrix
```math
\frac{a}{2}
\begin{pmatrix}
    1 & -1\\
    -1 & 1
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`ProjectorX0`](@ref).

## Examples

```jldoctests
julia> ProjectorX1()
PX₁(1)

julia> ProjectorX1(0.5)
PX₁(0.5)

julia> push!(Circuit(), ExpectationValue(ProjectorX1()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨PX₁(1)⟩ @ q[1], z[1]
```
"""
struct ProjectorX1 <: AbstractOperator{1}
    a::Num
end

ProjectorX1() = ProjectorX1(1)

opname(::Type{<:ProjectorX1}) = "PX₁"

_matrix(::Type{ProjectorX1}, a) = a / 2 .* [1 -1; -1 1]

@doc raw"""
    ProjectorY0(a)

One-qubit operator corresponding to a projection onto ``|y+\rangle``.

The corresponding matrix
```math
\frac{a}{2}
\begin{pmatrix}
    1 & -i\\
    i & 1
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`ProjectorY1`](@ref).

## Examples

```jldoctests
julia> ProjectorY0()
PY₀(1)

julia> ProjectorY0(0.5)
PY₀(0.5)

julia> push!(Circuit(), ExpectationValue(ProjectorY0()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨PY₀(1)⟩ @ q[1], z[1]
```
"""
struct ProjectorY0 <: AbstractOperator{1}
    a::Num
end

ProjectorY0() = ProjectorY0(1)

opname(::Type{<:ProjectorY0}) = "PY₀"

_matrix(::Type{ProjectorY0}, a) = a / 2 .* [1 -im; im 1]

@doc raw"""
    ProjectorY1(a)

One-qubit operator corresponding to a projection onto ``|y-\rangle``.

The corresponding matrix
```math
\frac{a}{2}
\begin{pmatrix}
    1 & i\\
    -i & 1
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`ProjectorY0`](@ref).

## Examples

```jldoctests
julia> ProjectorY1()
PY₁(1)

julia> ProjectorY1(0.5)
PY₁(0.5)

julia> push!(Circuit(), ExpectationValue(ProjectorY1()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨PY₁(1)⟩ @ q[1], z[1]
```
"""
struct ProjectorY1 <: AbstractOperator{1}
    a::Num
end

ProjectorY1() = ProjectorY1(1)

opname(::Type{<:ProjectorY1}) = "PY₁"

_matrix(::Type{ProjectorY1}, a) = a / 2 .* [1 im; -im 1]


@doc raw"""
    Projector00(a)

Two-qubit operator corresponding to a projection onto ``|00\rangle``.

The corresponding matrix
```math
\begin{pmatrix}
    a & 0 & 0 & 0\\
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`Projector01`](@ref), [`Projector10`](@ref), [`Projector11`](@ref).

## Examples

```jldoctests
julia> Projector00()
P₀₀(1)

julia> Projector00(0.5)
P₀₀(0.5)

julia> push!(Circuit(), ExpectationValue(Projector00()), 1, 2, 1)
2-qubit circuit with 1 instructions:
└── ⟨P₀₀(1)⟩ @ q[1:2], z[1]

```
"""
struct Projector00 <: AbstractOperator{2}
    a::Num
end

Projector00() = Projector00(1)

opname(::Type{<:Projector00}) = "P₀₀"

_matrix(::Type{Projector00}, a) = [a 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0]


@doc raw"""
    Projector01(a)

Two-qubit operator corresponding to a projection onto ``|01\rangle``.

The corresponding matrix
```math
\begin{pmatrix}
    0 & 0 & 0 & 0\\
    0 & a & 0 & 0\\
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`Projector00`](@ref), [`Projector10`](@ref), [`Projector11`](@ref).

## Examples

```jldoctests
julia> Projector01()
P₀₁(1)

julia> Projector01(0.5)
P₀₁(0.5)

julia> push!(Circuit(), ExpectationValue(Projector01()), 1, 2, 1)
2-qubit circuit with 1 instructions:
└── ⟨P₀₁(1)⟩ @ q[1:2], z[1]

```
"""
struct Projector01 <: AbstractOperator{2}
    a::Num
end

Projector01() = Projector01(1)

opname(::Type{<:Projector01}) = "P₀₁"

_matrix(::Type{Projector01}, a) = [0 0 0 0; 0 a 0 0; 0 0 0 0; 0 0 0 0]


@doc raw"""
    Projector10(a)

Two-qubit operator corresponding to a projection onto ``|10\rangle``.

The corresponding matrix
```math
\begin{pmatrix}
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0\\
    0 & 0 & a & 0\\
    0 & 0 & 0 & 0
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`Projector00`](@ref), [`Projector01`](@ref), [`Projector11`](@ref).

## Examples

```jldoctests
julia> Projector10()
P₁₀(1)

julia> Projector10(0.5)
P₁₀(0.5)

julia> push!(Circuit(), ExpectationValue(Projector10()), 1, 2, 1)
2-qubit circuit with 1 instructions:
└── ⟨P₁₀(1)⟩ @ q[1:2], z[1]

```
"""
struct Projector10 <: AbstractOperator{2}
    a::Num
end

Projector10() = Projector10(1)

opname(::Type{<:Projector10}) = "P₁₀"

_matrix(::Type{Projector10}, a) = [0 0 0 0; 0 0 0 0; 0 0 a 0; 0 0 0 0]


@doc raw"""
    Projector11(a)

Two-qubit operator corresponding to a projection onto ``|11\rangle``.

The corresponding matrix is
```math
\begin{pmatrix}
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0\\
    0 & 0 & 0 & a
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`Projector00`](@ref), [`Projector01`](@ref), [`Projector10`](@ref).

## Examples

```jldoctests
julia> Projector11()
P₁₁(1)

julia> Projector11(0.5)
P₁₁(0.5)

julia> push!(Circuit(), ExpectationValue(Projector11()), 1, 2, 1)
2-qubit circuit with 1 instructions:
└── ⟨P₁₁(1)⟩ @ q[1:2], z[1]

```
"""
struct Projector11 <: AbstractOperator{2}
    a::Num
end

Projector11() = Projector11(1)

opname(::Type{<:Projector11}) = "P₁₁"

_matrix(::Type{Projector11}, a) = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 a]

for PROJ in [
    Projector0, Projector1, ProjectorX0, ProjectorX1, ProjectorY0, ProjectorY1,
    Projector00, Projector01, Projector10, Projector11
]
    eval(quote
        opsquared(op::$(PROJ)) = $(PROJ)(abs2(op.a))

        rescale(op::$(PROJ), scale) = $(PROJ)(op.a * scale)

        function rescale!(op::$(PROJ), scale)
            op.a *= scale
            return op
        end
    end)
end
