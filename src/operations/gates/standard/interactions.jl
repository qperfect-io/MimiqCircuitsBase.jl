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
    GateRXX(θ)

Parametric two qubit ``X \otimes X`` interaction `\operatorname{R}_{XX}(\theta)`
gate.

It corresponds to a rotation of ``\theta`` radians along the XX axis of the
two-qubit Bloch sphere.

See also [`GateRYY`](@ref), [`GateRZZ`](@ref), [`GateRZX`](@ref),
[`GateXXplusYY`](@ref), [`GateXXminusYY`](@ref).

## Matrix representation

```math
\operatorname{R}_{XX}(\theta) =
\begin{pmatrix}
    \cos\left(\frac{\theta}{2}\right) & 0 & 0 & -i\sin\left(\frac{\theta}{2}\right) \\
    0 & \cos\left(\frac{\theta}{2}\right) & -i\sin\left(\frac{\theta}{2}\right) & 0 \\
    0 & -i\sin\left(\frac{\theta}{2}\right) & \cos\left(\frac{\theta}{2}\right) & 0 \\
    -i\sin\left(\frac{\theta}{2}\right) & 0 & 0 & \cos\left(\frac{\theta}{2}\right)
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRXX(θ)
RXX(θ)

julia> matrix(GateRXX(θ))
4×4 Matrix{Complex{Symbolics.Num}}:
     cos((1//2)*θ)                  0                  0  -im*sin((1//2)*θ)
                 0      cos((1//2)*θ)  -im*sin((1//2)*θ)                  0
                 0  -im*sin((1//2)*θ)      cos((1//2)*θ)                  0
 -im*sin((1//2)*θ)                  0                  0      cos((1//2)*θ)

julia> c = push!(Circuit(), GateRXX(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── RXX(θ) @ q[1:2]

julia> push!(c, GateRXX(π/2), 1, 2)
2-qubit circuit with 2 instructions:
├── RXX(θ) @ q[1:2]
└── RXX(π/2) @ q[1:2]

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateRXX(θ))
2-qubit circuit with 7 instructions:
├── H @ q[1]
├── H @ q[2]
├── CX @ q[1], q[2]
├── RZ(θ) @ q[2]
├── CX @ q[1], q[2]
├── H @ q[2]
└── H @ q[1]

```
"""
struct GateRXX <: AbstractGate{2}
    θ::Num
end

opname(::Type{GateRXX}) = "RXX"

inverse(g::GateRXX) = GateRXX(-g.θ)

_matrix(::Type{GateRXX}, θ) = [
    cos(θ / 2) 0 0 -im*sin(θ / 2)
    0 cos(θ / 2) -im*sin(θ / 2) 0
    0 -im*sin(θ / 2) cos(θ / 2) 0
    -im*sin(θ / 2) 0 0 cos(θ / 2)
]

_power(g::GateRXX, pwr) = GateRXX(g.θ * pwr)

function decompose!(circ::Circuit, g::GateRXX, qtargets, _, _)
    a, b = qtargets
    θ = g.θ
    push!(circ, GateH(), a)
    push!(circ, GateH(), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRZ(θ), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateH(), b)
    push!(circ, GateH(), a)
    return circ
end

@doc raw"""
    GateRYY(θ)

Parametric two qubit ``Y \otimes Y`` interaction `\operatorname{R}_{YY}(\theta)`
gate.

It corresponds to a rotation of ``\theta`` radians along the YY axis of the
two-qubit Bloch sphere.

See also [`GateRXX`](@ref), [`GateRZZ`](@ref), [`GateRZX`](@ref),
[`GateXXplusYY`](@ref), [`GateXXminusYY`](@ref).

## Matrix representation

```math
\operatorname{R}_{YY}(\theta) =
\begin{pmatrix}
    \cos\left(\frac{\theta}{2}\right) & 0 & 0 & i\sin\left(\frac{\theta}{2}\right) \\
    0 & \cos\left(\frac{\theta}{2}\right) & -i\sin\left(\frac{\theta}{2}\right) & 0 \\
    0 & -i\sin\left(\frac{\theta}{2}\right) & \cos\left(\frac{\theta}{2}\right) & 0 \\
    i\sin\left(\frac{\theta}{2}\right) & 0 & 0 & \cos\left(\frac{\theta}{2}\right)
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRYY(θ)
RYY(θ)

julia> matrix(GateRYY(θ))
4×4 Matrix{Complex{Symbolics.Num}}:
    cos((1//2)*θ)                  0                  0  im*sin((1//2)*θ)
                0      cos((1//2)*θ)  -im*sin((1//2)*θ)                 0
                0  -im*sin((1//2)*θ)      cos((1//2)*θ)                 0
 im*sin((1//2)*θ)                  0                  0     cos((1//2)*θ)

julia> c = push!(Circuit(), GateRYY(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── RYY(θ) @ q[1:2]

julia> push!(c, GateRYY(π/2), 1, 2)
2-qubit circuit with 2 instructions:
├── RYY(θ) @ q[1:2]
└── RYY(π/2) @ q[1:2]

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateRYY(θ))
2-qubit circuit with 7 instructions:
├── RX(π/2) @ q[1]
├── RX(π/2) @ q[2]
├── CX @ q[1], q[2]
├── RZ(θ) @ q[2]
├── CX @ q[1], q[2]
├── RX(-1π/2) @ q[1]
└── RX(-1π/2) @ q[2]

```
"""
struct GateRYY <: AbstractGate{2}
    θ::Num
end

opname(::Type{GateRYY}) = "RYY"

inverse(g::GateRYY) = GateRYY(-g.θ)

_power(g::GateRYY, pwr) = GateRYY(g.θ * pwr)

_matrix(::Type{GateRYY}, θ) = [
    cos(θ / 2) 0 0 im*sin(θ / 2)
    0 cos(θ / 2) -im*sin(θ / 2) 0
    0 -im*sin(θ / 2) cos(θ / 2) 0
    im*sin(θ / 2) 0 0 cos(θ / 2)
]

function decompose!(circ::Circuit, g::GateRYY, qtargets, _, _)
    a, b = qtargets
    push!(circ, GateRX(π / 2), a)
    push!(circ, GateRX(π / 2), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRZ(g.θ), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRX(-π / 2), a)
    push!(circ, GateRX(-π / 2), b)
    return circ
end

@doc raw"""
    GateRZZ(θ)

Parametric two qubit ``Z \otimes Z`` interaction `\operatorname{R}_{ZZ}(\theta)`
gate.

It corresponds to a rotation of ``\theta`` radians along the ZZ axis of the
two-qubit Bloch sphere.

See also [`GateRXX`](@ref), [`GateRYY`](@ref), [`GateRZX`](@ref),
[`GateXXplusYY`](@ref), [`GateXXminusYY`](@ref).

## Matrix representation

```math
\operatorname{R}_{ZZ}(\theta) =
\begin{pmatrix}
    e^{-i\frac{\theta}{2}} & 0 & 0 & 0 \\
    0 & e^{i\frac{\theta}{2}} & 0 & 0 \\
    0 & 0 & e^{i\frac{\theta}{2}} & 0 \\
    0 & 0 & 0 & e^{-i\frac{\theta}{2}}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRZZ(θ)
RZZ(θ)

julia> matrix(GateRZZ(θ))
4×4 Matrix{Complex{Symbolics.Num}}:
 cos((-1//2)*θ) + im*sin((-1//2)*θ)  …                           0
                          0                                      0
                          0                                      0
                          0             cos((-1//2)*θ) + im*sin((-1//2)*θ)

julia> c = push!(Circuit(), GateRZZ(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── RZZ(θ) @ q[1:2]

julia> push!(c, GateRZZ(π/2), 1, 2)
2-qubit circuit with 2 instructions:
├── RZZ(θ) @ q[1:2]
└── RZZ(π/2) @ q[1:2]

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateRZZ(θ))
2-qubit circuit with 3 instructions:
├── CX @ q[1], q[2]
├── RZ(θ) @ q[2]
└── CX @ q[1], q[2]

```
"""
struct GateRZZ <: AbstractGate{2}
    θ::Num
end

opname(::Type{GateRZZ}) = "RZZ"

inverse(g::GateRZZ) = GateRZZ(-g.θ)

_matrix(::Type{GateRZZ}, θ) = [
    cis(-θ / 2) 0 0 0
    0 cis(θ / 2) 0 0
    0 0 cis(θ / 2) 0
    0 0 0 cis(-θ / 2)
]

_power(g::GateRZZ, pwr) = GateRZZ(g.θ * pwr)

function decompose!(circ::Circuit, g::GateRZZ, qtargets, _, _)
    a, b = qtargets
    push!(circ, GateCX(), a, b)
    push!(circ, GateRZ(g.θ), b)
    push!(circ, GateCX(), a, b)
    return circ
end

@doc raw"""
    GateRZX(θ)

Parametric two qubit ``Z \otimes X`` interaction `\operatorname{R}_{ZX}(\theta)`
gate.

It corresponds to a rotation of ``\theta`` radians about ZX.

See also [`GateRXX`](@ref), [`GateRYY`](@ref), [`GateRZZ`](@ref),
[`GateXXplusYY`](@ref), [`GateXXminusYY`](@ref).

## Matrix representation

```math
\operatorname{RZX}(\theta) =\begin{pmatrix}
            \cos(\frac{\theta}{2}) & -i\sin(\frac{\theta}{2}) & 0 & 0 \\
            -i\sin(\frac{\theta}{2}) & \cos(\frac{\theta}{2}) & 0 & 0 \\
            0 & 0 & \cos(\frac{\theta}{2}) & i\sin(\frac{\theta}{2}) \\
            0 & 0 & i\sin(\frac{\theta}{2}) & \cos(\frac{\theta}{2})
        \end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRZX(θ)
RZX(θ)

julia> matrix(GateRZX(θ))
4×4 Matrix{Complex{Symbolics.Num}}:
     cos((1//2)*θ)  -im*sin((1//2)*θ)                 0                 0
 -im*sin((1//2)*θ)      cos((1//2)*θ)                 0                 0
                 0                  0     cos((1//2)*θ)  im*sin((1//2)*θ)
                 0                  0  im*sin((1//2)*θ)     cos((1//2)*θ)

julia> c = push!(Circuit(), GateRZX(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── RZX(θ) @ q[1:2]

julia> push!(c, GateRZX(π/2), 1, 2)
2-qubit circuit with 2 instructions:
├── RZX(θ) @ q[1:2]
└── RZX(π/2) @ q[1:2]

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateRZX(θ))
2-qubit circuit with 5 instructions:
├── H @ q[2]
├── CX @ q[1], q[2]
├── RZ(θ) @ q[2]
├── CX @ q[1], q[2]
└── H @ q[2]

```
"""
struct GateRZX <: AbstractGate{2}
    θ::Num
end

opname(::Type{GateRZX}) = "RZX"

inverse(g::GateRZX) = GateRZX(-g.θ)

_power(g::GateRZX, pwr) = GateRZX(g.θ * pwr)

_matrix(::Type{GateRZX}, θ) = [
    cos(θ / 2) -im*sin(θ / 2) 0 0
    -im*sin(θ / 2) cos(θ / 2) 0 0
    0 0 cos(θ / 2) im*sin(θ / 2)
    0 0 im*sin(θ / 2) cos(θ / 2)
]

function decompose!(circ::Circuit, g::GateRZX, qtargets, _, _)
    a, b = qtargets
    push!(circ, GateH(), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRZ(g.θ), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateH(), b)
    return circ
end

@doc raw"""
    GateXXplusYY(θ, β)

Parametric two qubit ``X \otimes X + Y \otimes Y`` interaction
``\operatorname{(XX+YY)}(\theta, \beta)`` gate, where ``\theta`` and ``\beta``
are the rotation and phase angles.

See also [`GateRXX`](@ref), [`GateRYY`](@ref), [`GateRZZ`](@ref),
[`GateRZX`](@ref), [`GateXXminusYY`](@ref).

## Matrix representation

```math
\operatorname{(XX+YY)}(\theta, \beta) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & \cos(\frac{\theta}{2}) & -i\sin(\frac{\theta}{2})e^{i\beta} & 0 \\
    0 & -i\sin(\frac{\theta}{2})e^{-i\beta} & \cos(\frac{\theta}{2}) & 0 \\
    0 & 0 & 0 & 1
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ β
2-element Vector{Symbolics.Num}:
 θ
 β

julia> GateXXplusYY(θ, β)
XXplusYY(θ, β)

julia> matrix(GateXXplusYY(θ, β))
4×4 Matrix{Complex{Symbolics.Num}}:
 1                                 0                  …  0
 0                     cos((1//2)*θ)                     0
 0  sin(-β)*sin((1//2)*θ) - im*cos(-β)*sin((1//2)*θ)     0
 0                                 0                     1

julia> c = push!(Circuit(), GateXXplusYY(θ, β), 1, 2)
2-qubit circuit with 1 instructions:
└── XXplusYY(θ,β) @ q[1:2]

julia> push!(c, GateXXplusYY(π/2, 0), 1, 2)
2-qubit circuit with 2 instructions:
├── XXplusYY(θ,β) @ q[1:2]
└── XXplusYY(π/2,0) @ q[1:2]

```

## Decomposition

```jldoctests; stup = :(@variables θ β)
julia> decompose(GateXXplusYY(θ, β))
2-qubit circuit with 14 instructions:
├── RZ(β) @ q[1]
├── RZ(-1π/2) @ q[2]
├── SX @ q[2]
├── RZ(π/2) @ q[2]
├── S @ q[1]
├── CX @ q[2], q[1]
├── RY((-1//2)*θ) @ q[2]
├── RY((-1//2)*θ) @ q[1]
├── CX @ q[2], q[1]
├── S† @ q[1]
├── RZ(-1π/2) @ q[2]
├── SX† @ q[2]
├── RZ(π/2) @ q[2]
└── RZ(-β) @ q[1]

```
"""
struct GateXXplusYY <: AbstractGate{2}
    θ::Num
    β::Num
end

opname(::Type{GateXXplusYY}) = "XXplusYY"

inverse(g::GateXXplusYY) = GateXXplusYY(-g.θ, g.β)

_matrix(::Type{GateXXplusYY}, θ, β) = [
    1 0 0 0
    0 cos(θ / 2) -im*sin(θ / 2)*cis(β) 0
    0 -im*sin(θ / 2)*cis(-β) cos(θ / 2) 0
    0 0 0 1
]

function decompose!(circ::Circuit, g::GateXXplusYY, qperfect, _, _)
    a, b = qperfect
    push!(circ, GateRZ(g.β), a)
    push!(circ, GateRZ(-π / 2), b)
    push!(circ, GateSX(), b)
    push!(circ, GateRZ(π / 2), b)
    push!(circ, GateS(), a)
    push!(circ, GateCX(), b, a)
    push!(circ, GateRY(-g.θ / 2), b)
    push!(circ, GateRY(-g.θ / 2), a)
    push!(circ, GateCX(), b, a)
    push!(circ, GateSDG(), a)
    push!(circ, GateRZ(-π / 2), b)
    push!(circ, GateSXDG(), b)
    push!(circ, GateRZ(π / 2), b)
    push!(circ, GateRZ(-g.β), a)
    return circ
end

@doc raw"""
    GateXXminusYY(θ, β)

Parametric two qubit ``X \otimes X - Y \otimes Y`` interaction
``\operatorname{(XX-YY)}(\theta, \beta)`` gate, where ``\theta`` and ``\beta``
are the rotation and phase angles.

See also [`GateRXX`](@ref), [`GateRYY`](@ref), [`GateRZZ`](@ref),
[`GateRZX`](@ref), [`GateXXplusYY`](@ref).

## Matrix Representation

```math
\operatorname{(XX-YY)}(\theta, \beta) =
\begin{pmatrix}
    \cos(\frac{\theta}{2}) & 0 & 0 & -i\sin(\frac{\theta}{2})e^{-i\beta} \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    -i\sin(\frac{\theta}{2})e^{i\beta} & 0 & 0 & \cos(\frac{\theta}{2})
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ β
2-element Vector{Symbolics.Num}:
 θ
 β

julia> GateXXminusYY(θ, β)
XXminusYY(θ, β)

julia> matrix(GateXXminusYY(θ, β))
4×4 Matrix{Complex{Symbolics.Num}}:
          cos((1//2)*θ)                          …  sin(-β)*sin((1//2)*θ) - im*cos(-β)*sin((1//2)*θ)
                      0                                                            0
                      0                                                            0
 sin(β)*sin((1//2)*θ) - im*cos(β)*sin((1//2)*θ)                        cos((1//2)*θ)

julia> c = push!(Circuit(), GateXXminusYY(θ, β), 1, 2)
2-qubit circuit with 1 instructions:
└── XXminusYY(θ,β) @ q[1:2]

julia> push!(c, GateXXminusYY(π/2, 0.0), 1, 2)
2-qubit circuit with 2 instructions:
├── XXminusYY(θ,β) @ q[1:2]
└── XXminusYY(π/2,0π) @ q[1:2]

```

## Decomposition

```jldoctests; setup = :(@variables θ β)
julia> decompose(GateXXminusYY(θ, β))
2-qubit circuit with 14 instructions:
├── RZ(-β) @ q[2]
├── RZ(-1π/2) @ q[1]
├── SX @ q[1]
├── RZ(π/2) @ q[1]
├── S @ q[2]
├── CX @ q[1], q[2]
├── RY((1//2)*θ) @ q[1]
├── RY((-1//2)*θ) @ q[2]
├── CX @ q[1], q[2]
├── S† @ q[2]
├── RZ(-1π/2) @ q[1]
├── SX† @ q[1]
├── RZ(π/2) @ q[1]
└── RZ(β) @ q[2]

```
"""
struct GateXXminusYY <: AbstractGate{2}
    θ::Num
    β::Num
end

inverse(g::GateXXminusYY) = GateXXminusYY(-g.θ, g.β)

opname(::Type{GateXXminusYY}) = "XXminusYY"

_matrix(::Type{GateXXminusYY}, θ, β) = [
    cos(θ / 2) 0 0 -im*sin(θ / 2)*cis(-β)
    0 1 0 0
    0 0 1 0
    -im*sin(θ / 2)*cis(β) 0 0 cos(θ / 2)
]

function decompose!(circ::Circuit, g::GateXXminusYY, qtargets, _, _)
    a, b = qtargets
    push!(circ, GateRZ(-g.β), b)
    push!(circ, GateRZ(-π / 2), a)
    push!(circ, GateSX(), a)
    push!(circ, GateRZ(π / 2), a)
    push!(circ, GateS(), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRY(g.θ / 2), a)
    push!(circ, GateRY(-g.θ / 2), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateSDG(), b)
    push!(circ, GateRZ(-π / 2), a)
    push!(circ, GateSXDG(), a)
    push!(circ, GateRZ(π / 2), a)
    push!(circ, GateRZ(g.β), b)
end
