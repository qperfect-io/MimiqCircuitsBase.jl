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

@doc raw"""
    struct GateP <: ParametricGate{1}

Single qubit Phase gate.

# Arguments

- `λ::Float64`: Phase angle in radians

# Matrix Representation

```math
\operatorname P(\lambda) =
\begin{pmatrix}
    1 & 0 \\
    0 & e^{i\lambda}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateP(pi/4))
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107+0.707107im

julia> push!(Circuit(), GateP(pi/4), 1)
1-qubit circuit with 1 instructions:
└── P(λ=0.7853981633974483) @ q1
```
"""
struct GateP <: ParametricGate{1}
    λ::Float64
    U::Matrix{ComplexF64}
    a::Float64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateP(λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(λ, U, 1, 0, 0, U[4])
    end
end

GateP(λ::Number) = GateP(λ, pmatrix(λ))

inverse(g::GateP) = GateP(-g.λ)

numparams(::Type{GateP}) = 1

parnames(::Type{GateP}) = (:λ,)

opname(::Type{GateP}) = "P"

@doc raw"""
    struct GateRX <: ParametricGate{1}

Single qubit Rotation-X gate (RX gate)

# Arguments

- `θ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{RX}(\theta) = \begin{pmatrix}
          \cos\frac{\theta}{2} & -i\sin\frac{\theta}{2} \\
          -i\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
      \end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRX(pi/2))
2×2 Matrix{ComplexF64}:
 0.707107+0.0im           -0.0-0.707107im
      0.0-0.707107im  0.707107+0.0im

julia> push!(Circuit(), GateRX(pi/2), 1)
1-qubit circuit with 1 instructions:
└── RX(θ=1.5707963267948966) @ q1
```
"""
struct GateRX <: ParametricGate{1}
    θ::Float64
    U::Matrix{ComplexF64}
    a::Float64
    b::ComplexF64
    c::ComplexF64
    d::Float64

    function GateRX(θ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end

        if !isreal(U[1, 1]) || !isreal(U[2, 2])
            throw(ArgumentError("Gate RX diagonal should be real."))

        end
        new(θ, U, _decomplex.(U)...)
    end
end

GateRX(θ::Number) = GateRX(θ, rxmatrix(θ))

inverse(g::GateRX) = GateRX(-g.θ)

numparams(::Type{GateRX}) = 1

opname(::Type{GateRX}) = "RX"

parnames(::Type{GateRX}) = (:θ,)

@doc raw"""
    struct GateRY <: ParametricGate{1}

Single qubit Rotation-Y gate (RY gate)

# Arguments

- `θ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{RY}(\theta) = \begin{pmatrix}
          \cos\frac{\theta}{2} & -\sin\frac{\theta}{2} \\
          \sin\frac{\theta}{2} & \cos\frac{\theta}{2}
      \end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRY(pi/2))
2×2 Matrix{Float64}:
 0.707107  -0.707107
 0.707107   0.707107

julia> push!(Circuit(), GateRY(pi/2), 1)
1-qubit circuit with 1 instructions:
└── RY(θ=1.5707963267948966) @ q1
```
"""
struct GateRY <: ParametricGate{1}
    θ::Float64
    U::Matrix{Float64}
    a::Float64
    b::Float64
    c::Float64
    d::Float64

    function GateRY(θ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, U, U...)
    end
end

GateRY(θ::Number) = GateRY(θ, rymatrix(θ))

inverse(g::GateRY) = GateRY(-g.θ)

numparams(::Type{GateRY}) = 1

opname(::Type{GateRY}) = "RY"

parnames(::Type{GateRY}) = (:θ,)

@doc raw"""
    struct GateRZ <: ParametricGate{1}

Single qubit Rotation-Z gate (RZ gate)

# Arguments

- `λ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{RZ}(\lambda) =
\begin{pmatrix}
    e^{-i\frac{\lambda}{2}} & 0 \\
    0 & e^{i\frac{\lambda}{2}}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRZ(pi/2))
2×2 Matrix{ComplexF64}:
 0.707107-0.707107im      -0.0+0.0im
      0.0+0.0im       0.707107+0.707107im

julia> push!(Circuit(), GateRZ(pi/2), 1)
1-qubit circuit with 1 instructions:
└── RZ(λ=1.5707963267948966) @ q1
```
"""
struct GateRZ <: ParametricGate{1}
    λ::Float64
    U::Matrix{ComplexF64}
    a::ComplexF64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateRZ(λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(λ, U, U[1], 0, 0, U[4])
    end
end

GateRZ(λ::Number) = GateRZ(λ, rzmatrix(λ))

inverse(g::GateRZ) = GateRZ(-g.λ)

numparams(::Type{GateRZ}) = 1

opname(::Type{GateRZ}) = "RZ"

parnames(::Type{GateRZ}) = (:λ,)

@doc raw"""
    struct GateR <: ParametricGate{1}

Single qubit Rotation gate around the axis cos(ϕ)x + sin(ϕ)y.

# Arguments

- `θ::Float64`: Rotation angle in radians
- `ϕ::Float64`: Axis of rotation in radians

# Matrix Representation

```math
\operatorname R(\theta,\phi) = \begin{pmatrix}
          \cos\frac{\theta}{2} & -ie^{-i\phi}\sin\frac{\theta}{2} \\
          -ie^{-i\phi}\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
      \end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateR(pi/2,pi/4))
2×2 Matrix{ComplexF64}:
 0.707107+0.0im      -0.5-0.5im
      0.5-0.5im  0.707107+0.0im

julia> push!(Circuit(), GateR(pi/2,pi/4), 1)
1-qubit circuit with 1 instructions:
└── R(θ=1.5707963267948966, ϕ=0.7853981633974483) @ q1
```
"""
struct GateR <: ParametricGate{1}
    θ::Float64
    ϕ::Float64
    U::Matrix{ComplexF64}

    function GateR(θ, ϕ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, ϕ, U)
    end
end

GateR(θ::Number, ϕ::Number) = GateR(θ, ϕ, rmatrix(θ, ϕ))

inverse(g::GateR) = GateR(-g.θ, g.ϕ)

numparams(::Type{GateR}) = 1

opname(::Type{GateR}) = "R"

parnames(::Type{GateR}) = (:θ, :ϕ)

@doc raw"""
    struct GateU1 <: ParametricGate{1}

One qubit generic unitary gate `u1`, as defined in OpenQASM 3.0

Equivalent to [`GateP`](@ref)

# Arguments

- `λ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{U1}(\lambda) =
\begin{pmatrix}
    1 & 0 \\
    0 & e^{i\lambda}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateU1(pi/4))
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107+0.707107im

julia> push!(Circuit(), GateU1(pi/4), 1)
1-qubit circuit with 1 instructions:
└── U1(λ=0.7853981633974483) @ q1
```
"""
struct GateU1 <: ParametricGate{1}
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU1(λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(λ, U)
    end
end

GateU1(λ::Number) = GateU1(λ, pmatrix(λ))

inverse(g::GateU1) = GateU1(-g.λ)

numparams(::Type{GateU1}) = 1

opname(::Type{GateU1}) = "U1"

parnames(::Type{GateU1}) = (:λ,)

@doc raw"""
    struct GateU2 <: ParametricGate{1}

One qubit generic unitary gate `u2`, as defined in OpenQASM 3.0

See also [`GateU2DG`](@ref).

# Arguments

- `ϕ:Float64`: Rotation angle in radians
- `λ::Float64`: Rotation angle in radians

# Examples

```jldoctest
julia> matrix(GateU2(pi/2,pi/4))
2×2 Matrix{ComplexF64}:
 0.270598-0.653281im  -0.653281+0.270598im
 0.653281+0.270598im   0.270598+0.653281im

julia> push!(Circuit(), GateU2(pi/4,pi/4), 1)
1-qubit circuit with 1 instructions:
└── U2(ϕ=0.7853981633974483, λ=0.7853981633974483) @ q1
```
"""
struct GateU2 <: ParametricGate{1}
    ϕ::Float64
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU2(ϕ, λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(ϕ, λ, U)
    end
end

GateU2(ϕ::Number, λ::Number) =
    GateU2(ϕ, λ, gphase(-(ϕ + λ) / 2) .* umatrixpi(1 / 2, ϕ / π, λ / π))

inverse(g::GateU2) = GateU2DG(g.ϕ, g.λ)

numparams(::Type{GateU2}) = 2

opname(::Type{GateU2}) = "U2"

parnames(::Type{GateU2}) = (:ϕ, :λ)

@doc raw"""
    struct GateU2DG <: ParametricGate{1}

One qubit generic unitary gate `u2`-dagger, as defined in OpenQASM 3.0 for backwards compatibility

See also [`GateU2`](@ref)

# Arguments
- `ϕ:Float64`: Rotation angle in radians
- `λ::Float64`: Rotation angle in radians

# Examples
```jldoctest
julia> matrix(GateU2DG(pi/2,pi/4))
2×2 Matrix{ComplexF64}:
  0.270598+0.653281im  0.653281-0.270598im
 -0.653281-0.270598im  0.270598-0.653281im

julia> push!(Circuit(), GateU2DG(pi/2,pi/4), 1)
1-qubit circuit with 1 instructions:
└── U2DG(ϕ=1.5707963267948966, λ=0.7853981633974483) @ q1
```
"""
struct GateU2DG <: ParametricGate{1}
    ϕ::Float64
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU2DG(ϕ, λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(ϕ, λ, U)
    end
end

GateU2DG(ϕ::Number, λ::Number) =
    GateU2DG(ϕ, λ, gphase((ϕ + λ) / 2) .* umatrixpi(-1 / 2, -λ / π, -ϕ / π))

inverse(g::GateU2DG) = GateU2(g.ϕ, g.λ)

numparams(::Type{GateU2DG}) = 2

opname(::Type{GateU2DG}) = "U2DG"

parnames(::Type{GateU2DG}) = (:ϕ, :λ)

@doc raw"""
    struct GateU3 <: ParametricGate{1}

One qubit generic unitary gate `u3`, as defined in OpenQASM 3.0 for backwards compatibility.

# Arguments

- `θ:Float64`: Rotation angle 1 in radians
- `ϕ:Float64`: Rotation angle 2 in radians
- `λ::Float64`: Rotation angle 3 in radians

# Examples

```jldoctest
julia> matrix(GateU3(pi/2,pi/4,pi/2))
2×2 Matrix{ComplexF64}:
 0.270598-0.653281im  -0.653281-0.270598im
 0.653281-0.270598im   0.270598+0.653281im

julia> push!(Circuit(), GateU3(pi/2, pi/4, pi/2), 1)
1-qubit circuit with 1 instructions:
└── U3(θ=1.5707963267948966, ϕ=0.7853981633974483, λ=1.5707963267948966) @ q1
```
"""
struct GateU3 <: ParametricGate{1}
    θ::Float64
    ϕ::Float64
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU3(θ, ϕ, λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, ϕ, λ, U)
    end
end

GateU3(θ::Number, ϕ::Number, λ::Number) =
    GateU3(θ, ϕ, λ, gphase(-(ϕ + λ) / 2) .* umatrix(θ, ϕ, λ))

inverse(g::GateU3) = GateU3(-g.θ, -g.λ, -g.ϕ)

numparams(::Type{GateU3}) = 3

opname(::Type{GateU3}) = "U3"

parnames(::Type{GateU3}) = (:θ, :ϕ, :λ)

@doc raw"""
    struct GateU <: ParametricGate{1}

One qubit generic unitary gate, as defined in OpenQASM 3.0.

# Arguments

- `θ::Float64`: Euler angle 1 in radians
- `ϕ::Float64`: Euler angle 2 in radians
- `λ::Float64`: Euler angle 3 in radians

# Matrix Representation

```math
\operatorname{U}(\theta,\phi,\lambda) = \begin{pmatrix}
          \cos\frac{\theta}{2} & -e^{i\lambda}\sin\frac{\theta}{2} \\
          e^{i\phi}\sin\frac{\theta}{2} & e^{i(\phi+\lambda)}\cos\frac{\theta}{2}
      \end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateU(pi/3, pi/3, pi/3))
2×2 Matrix{ComplexF64}:
 0.866025+0.0im           -0.25-0.433013im
     0.25+0.433013im  -0.433013+0.75im

julia> push!(Circuit(), GateU(pi/3, pi/3, pi/3), 1)
1-qubit circuit with 1 instructions:
└── U(θ=1.0471975511965976, ϕ=1.0471975511965976, λ=1.0471975511965976) @ q1
```
"""
struct GateU <: ParametricGate{1}
    θ::Float64
    ϕ::Float64
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU(θ, ϕ, λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, ϕ, λ, U)
    end
end

GateU(θ::Number, ϕ::Number, λ::Number) = GateU(θ, ϕ, λ, umatrix(θ, ϕ, λ))

inverse(g::GateU) = GateU(-g.θ, -g.λ, -g.ϕ)

numparams(::Type{GateU}) = 3

parnames(::Type{GateU}) = (:θ, :ϕ, :λ)

opname(::Type{GateU}) = "U"

