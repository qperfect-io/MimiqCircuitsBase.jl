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
    struct GateCP <: ParametricGate{2}

Two qubit Controlled-Phase gate 

# Arguments

- `λ::Float64`: Phase angle in radians

# Matrix Representation

```math
\operatorname{CP}(\lambda) = \begin{pmatrix}
          1 & 0 & 0 & 0 \\
          0 & 1 & 0 & 0 \\
          0 & 0 & 1 & 0 \\
          0 & 0 & 0 & e^{i\lambda}
      \end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCP(pi/4))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im       0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.707107+0.707107im

julia> push!(Circuit(), GateCP(pi/4), 1, 2)
2-qubit circuit with 1 instructions:
└── CP(λ=0.7853981633974483) @ q1, q2
```
"""
struct GateCP <: ParametricGate{2}
    λ::Float64
    U::Matrix{ComplexF64}
    a::Float64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateCP(λ, U)
        if size(U, 1) != 4 && size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end
        new(λ, U, 1, 0, 0, U[16])
    end
end

GateCP(λ) = GateCP(λ, ctrl(pmatrix(λ)))

inverse(g::GateCP) = GateCP(-g.λ)

numparams(::Type{GateCP}) = 1

opname(::Type{GateCP}) = "CP"

parnames(::Type{GateCP}) = (:λ,)

@doc raw"""
    struct GateCRX <: ParametricGate{2}

Two qubit Controlled-RX gate 

# Arguments

- `θ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{CRX}(\theta) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & \cos\frac{\theta}{2} & -i\sin\frac{\theta}{2} \\
    0 & 0 & -i\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{pmatrix}
```
By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCRX(pi/2))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.707107+0.0im           -0.0-0.707107im
 0.0+0.0im  0.0+0.0im       0.0-0.707107im  0.707107+0.0im

julia> push!(Circuit(), GateCRX(pi/2), 1, 2)
2-qubit circuit with 1 instructions:
└── CRX(θ=1.5707963267948966) @ q1, q2
```
"""
struct GateCRX <: ParametricGate{2}
    θ::Float64
    U::Matrix{ComplexF64}
    a::Float64
    b::ComplexF64
    c::ComplexF64
    d::Float64

    function GateCRX(θ, U)
        if size(U, 1) != 4 && size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end

        if !isreal(U[11]) || !isreal(U[16])
            throw(ArgumentError("Gate CRX diagonal should be real."))
        end

        new(θ, U, real(U[11]), U[12], U[15], real(U[16]))
    end
end

GateCRX(θ) = GateCRX(θ, ctrl(rxmatrix(θ)))

inverse(g::GateCRX) = GateCRX(-g.θ)

numparams(::Type{GateCRX}) = 1

opname(::Type{GateCRX}) = "CRX"

parnames(::Type{GateCRX}) = (:θ,)

@doc raw"""
    struct GateCRY <: ParametricGate{2}

Two qubit Controlled-RY gate 

# Arguments

- `θ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{CRY}(\theta) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & \cos\frac{\theta}{2} & -\sin\frac{\theta}{2} \\
    0 & 0 & \sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCRY(pi/2))
4×4 Matrix{Float64}:
 1.0  0.0  0.0        0.0
 0.0  1.0  0.0        0.0
 0.0  0.0  0.707107  -0.707107
 0.0  0.0  0.707107   0.707107

julia> push!(Circuit(), GateCRY(pi/2), 1, 2)
2-qubit circuit with 1 instructions:
└── CRY(θ=1.5707963267948966) @ q1, q2
```
"""
struct GateCRY <: ParametricGate{2}
    θ::Float64
    U::Matrix{Float64}
    a::Float64
    b::Float64
    c::Float64
    d::Float64

    function GateCRY(θ, U)
        if size(U, 1) != 4 && size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end
        new(θ, U, U[11], U[12], U[15], U[16])
    end
end

GateCRY(θ) = GateCRY(θ, ctrl(rymatrix(θ)))

inverse(g::GateCRY) = GateCRY(-g.θ)

numparams(::Type{GateCRY}) = 1

opname(::Type{GateCRY}) = "CRY"

parnames(::Type{GateCRY}) = (:θ,)

@doc raw"""
    struct GateCRZ <: ParametricGate{2}

Two qubit Controlled-RZ gate 

# Arguments

- `λ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{CRZ}(\lambda) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & e^{-i\frac{\lambda}{2}} & 0 \\
    0 & 0 & 0 & e^{i\frac{\lambda}{2}}
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCRZ(pi/2))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.707107-0.707107im      -0.0+0.0im
 0.0+0.0im  0.0+0.0im       0.0+0.0im       0.707107+0.707107im

julia> push!(Circuit(), GateCRZ(pi/2), 1, 2)
2-qubit circuit with 1 instructions:
└── CRZ(λ=1.5707963267948966) @ q1, q2
```
"""
struct GateCRZ <: ParametricGate{2}
    λ::Float64
    U::Matrix{ComplexF64}
    a::ComplexF64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateCRZ(λ, U)
        if size(U, 1) != 4 && size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end
        new(λ, U, U[11], 0, 0, U[16])
    end
end

GateCRZ(λ) = GateCRZ(λ, ctrl(rzmatrix(λ)))

inverse(g::GateCRZ) = GateCRZ(-g.λ)

numparams(::Type{GateCRZ}) = 1

opname(::Type{GateCRZ}) = "CRZ"

parnames(::Type{GateCRZ}) = (:λ,)

@doc raw"""
    struct GateCU <: ParametricGate{2}

Two qubit generic unitary gate, equivalent to the qiskit CUGate
`https://qiskit.org/documentation/stubs/qiskit.circuit.library.CUGate.html`

# Arguments

- `θ::Float64`: Euler angle 1 in radians
- `ϕ::Float64`: Euler angle 2 in radians
- `λ::Float64`: Euler angle 3 in radians
- `γ::Float64`: Global phase of the U gate

# Matrix Representation

```math
\operatorname{CU}(\theta,\phi,\lambda,\gamma) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & e^{i\gamma}\cos\frac{\theta}{2} & -e^{i(\gamma+\lambda)}\sin\frac{\theta}{2} \\
    0 & 0 & e^{i(\gamma+\phi)}\sin\frac{\theta}{2} & e^{i(\gamma+\phi+\lambda)}\cos\frac{\theta}{2}
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCU(pi/3, pi/3, pi/3, 0))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im             0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im             0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.866025+0.0im           -0.25-0.433013im
 0.0+0.0im  0.0+0.0im      0.25+0.433013im  -0.433013+0.75im

julia> push!(Circuit(), GateCU(pi/3, pi/3, pi/3, 0), 1, 2)
2-qubit circuit with 1 instructions:
└── CU(θ=1.0471975511965976, ϕ=1.0471975511965976, λ=1.0471975511965976, γ=0.0) @ q1, q2
```
"""
struct GateCU <: ParametricGate{2}
    θ::Float64
    ϕ::Float64
    λ::Float64
    γ::Float64
    U::Matrix{ComplexF64}
    a::ComplexF64
    b::ComplexF64
    c::ComplexF64
    d::ComplexF64

    function GateCU(θ, ϕ, λ, γ, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end
        new(θ, ϕ, λ, γ, U, U[11], U[12], U[15], U[16])
    end
end

GateCU(θ, ϕ, λ, γ) = GateCU(θ, ϕ, λ, γ, ctrl(umatrix(θ, ϕ, λ, γ)))

inverse(g::GateCU) = GateCU(-g.θ, -g.λ, -g.ϕ, -g.γ)

numparams(::Type{GateCU}) = 4

opname(::Type{GateCU}) = "CU"

parnames(::Type{GateCU}) = (:θ, :ϕ, :λ, :γ)

@doc raw"""
    struct GateCR <: ParametricGate{2}

    Two qubit Controlled-R gate.

# Arguments

- `θ::Float64`: Rotation angle in radians
- `ϕ::Float64`: The phase angle in radians.

# Matrix Representation

```math
\operatorname{CR}(\theta, \phi) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & \cos\frac{\theta}{2} & -ie^{-i\phi}\sin\\frac{\theta}{2} \\
    0 & 0 & -ie^{i\phi}\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateCR(pi,-pi))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im           0.0+0.0im          0.0+0.0im
 0.0+0.0im  1.0+0.0im           0.0+0.0im          0.0+0.0im
 0.0+0.0im  0.0+0.0im   6.12323e-17+0.0im  1.22465e-16+1.0im
 0.0+0.0im  0.0+0.0im  -1.22465e-16+1.0im  6.12323e-17+0.0im

julia> push!(Circuit(), GateCR(pi,-pi), 1, 2)
2-qubit circuit with 1 instructions:
└── CR(θ=3.141592653589793, ϕ=-3.141592653589793) @ q1, q2
```
"""
struct GateCR <: ParametricGate{2}
    θ::Float64
    ϕ::Float64
    U::Matrix{ComplexF64}

    function GateCR(θ, ϕ, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, ϕ, U)
    end
end

GateCR(θ::Number, ϕ::Number) = GateCR(θ, ϕ, ctrl(rmatrix(θ, ϕ)))

inverse(g::GateCR) = GateCR(-g.θ, g.ϕ)

numparams(::Type{GateCR}) = 2

opname(::Type{GateCR}) = "CR"

parnames(::Type{GateCR}) = (:θ, :ϕ)

@doc raw"""
    struct GateRXX <: ParametricGate{2}

Two qubit RXX gate.

# Arguments

- `θ::Float64`: The angle in radians

# Matrix Representation

```math
\operatorname{RXX}(\theta) =
\begin{pmatrix}
    \cos(\\frac{\theta}{2}) & 0 & 0 & -i\sin(\\frac{\theta}{2}) \\
    0 & \cos(\frac{\theta}{2}) & -i\sin(\frac{\theta}{2}) & 0 \\
    0 & -i\sin(\frac{\theta}{2}) & \cos(\frac{\theta}{2}) & 0 \\
    -i\sin(\frac{\theta}{2}) & 0 & 0 & \cos(\frac{\theta}{2})
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRXX(π/4))
4×4 Matrix{ComplexF64}:
 0.92388+0.0im           0.0+0.0im       …      0.0-0.382683im
     0.0+0.0im       0.92388+0.0im              0.0+0.0im
     0.0+0.0im           0.0-0.382683im         0.0+0.0im
     0.0-0.382683im      0.0+0.0im          0.92388+0.0im

julia> push!(Circuit(), GateRXX(π), 1, 2)
2-qubit circuit with 1 instructions:
└── RXX(θ=3.141592653589793) @ q1, q2
```
"""
struct GateRXX <: ParametricGate{2}
    θ::Float64
    U::Matrix{ComplexF64}

    function GateRXX(θ, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, U)
    end
end

GateRXX(θ::Number) = GateRXX(
    θ,
    ComplexF64[
        cos(θ / 2) 0 0 -im*sin(θ / 2)
        0 cos(θ / 2) -im*sin(θ / 2) 0
        0 -im*sin(θ / 2) cos(θ / 2) 0
        -im*sin(θ / 2) 0 0 cos(θ / 2)
    ],
)

inverse(g::GateRXX) = GateRXX(-g.θ)

numparams(::Type{GateRXX}) = 1

opname(::Type{GateRXX}) = "RXX"

parnames(::Type{GateRXX}) = (:θ,)

@doc raw"""
    struct GateRYY <: ParametricGate{2}

Two qubit RYY gate.

# Arguments

- `θ::Float64`: The angle in radians

# Matrix Representation

```math
\operatorname{RYY}(\theta) =
\begin{pmatrix}
    \cos(\frac{\theta}{2}) & 0 & 0 & i\sin(\frac{\theta}{2}) \\
    0 & \cos(\frac{\theta}{2}) & -i\sin(\frac{\theta}{2}) & 0 \\
    0 & -i\sin(\\frac{\theta}{2}) & \cos(\frac{\theta}{2}) & 0 \\
    i\sin(\frac{\theta}{2}) & 0 & 0 & \cos(\frac{\theta}{2})
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRYY(π/4))
4×4 Matrix{ComplexF64}:
 0.92388+0.0im           0.0+0.0im       …      0.0+0.382683im
     0.0+0.0im       0.92388+0.0im              0.0+0.0im
     0.0+0.0im           0.0-0.382683im         0.0+0.0im
     0.0+0.382683im      0.0+0.0im          0.92388+0.0im

julia> push!(Circuit(), GateRYY(π), 1, 2)
2-qubit circuit with 1 instructions:
└── RYY(θ=3.141592653589793) @ q1, q2
```
"""
struct GateRYY <: ParametricGate{2}
    θ::Float64
    U::Matrix{ComplexF64}

    function GateRYY(θ, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, U)
    end
end

GateRYY(θ::Number) = GateRYY(
    θ,
    ComplexF64[
        cos(θ / 2) 0 0 im*sin(θ / 2)
        0 cos(θ / 2) -im*sin(θ / 2) 0
        0 -im*sin(θ / 2) cos(θ / 2) 0
        im*sin(θ / 2) 0 0 cos(θ / 2)
    ],
)

inverse(g::GateRYY) = GateRYY(-g.θ)

numparams(::Type{GateRYY}) = 1

opname(::Type{GateRYY}) = "RYY"

parnames(::Type{GateRYY}) = (:θ,)

@doc raw"""
    struct GateRZZ <: ParametricGate{2}

Two qubit RZZ gate.

# Arguments

- `θ::Float64`: The angle in radians

# Matrix Representation

```math
\operatorname{RZZ}(\theta) =
\begin{pmatrix}
    e^{-i\frac{\theta}{2}} & 0 & 0 & 0 \\
    0 & e^{i\frac{\theta}{2}} & 0 & 0 \\
    0 & 0 & e^{i\frac{\theta}{2}} & 0 \\
    0 & 0 & 0 & e^{-i\frac{\theta}{2}}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRZZ(π/4))
4×4 Matrix{ComplexF64}:
 0.92388-0.382683im      0.0+0.0im       …      0.0+0.0im
     0.0+0.0im       0.92388+0.382683im         0.0+0.0im
     0.0+0.0im           0.0+0.0im              0.0+0.0im
     0.0+0.0im           0.0+0.0im          0.92388-0.382683im

julia> push!(Circuit(), GateRZZ(π), 1, 2)
2-qubit circuit with 1 instructions:
└── RZZ(θ=3.141592653589793) @ q1, q2
```
"""
struct GateRZZ <: ParametricGate{2}
    θ::Float64
    U::Matrix{ComplexF64}

    function GateRZZ(θ, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, U)
    end
end

GateRZZ(θ::Number) = GateRZZ(θ, ComplexF64[exp(-im * (θ / 2)) 0 0 0; 0 exp(im * (θ / 2)) 0 0; 0 0 exp(im * (θ / 2)) 0; 0 0 0 exp(-im * (θ / 2))])

inverse(g::GateRZZ) = GateRZZ(-g.θ)

numparams(::Type{GateRZZ}) = 1

opname(::Type{GateRZZ}) = "RZZ"

parnames(::Type{GateRZZ}) = (:θ,)

@doc raw"""
    struct GateXXplusYY <: ParametricGate{2}

Two qubit XXplusYY gate.

# Arguments
- `θ::Float64`: The angle in radians.
- `β::Float64`: The phase angle in radians.

# Matrix Representation
```math
\operatorname{XXplusYY}(\theta, \beta) =
    \begin{pmatrix}
        1 & 0 & 0 & 0 \\
        0 & \cos(\frac{\theta}{2}) & -i\sin(\frac{\theta}{2})e^{-i\beta} & 0 \\
        0 & -i\sin(\\frac{theta}{2})e^{i\beta} & \cos(\frac{\theta}{2}) & 0 \\
        0 & 0 & 0 & 1
    \end{pmatrix}
```

# Examples
```jldoctest
julia> matrix(GateXXplusYY(π/2,π/2))
4×4 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im                0.0+0.0im          0.0+0.0im
 0.0+0.0im  0.707107+0.0im          -0.707107-4.32978e-17im  0.0+0.0im
 0.0+0.0im  0.707107-4.32978e-17im   0.707107+0.0im          0.0+0.0im
 0.0+0.0im       0.0+0.0im                0.0+0.0im          1.0+0.0im

julia> push!(Circuit(), GateXXplusYY(π,π), 1, 2)
2-qubit circuit with 1 instructions:
└── XXplusYY(θ=3.141592653589793, β=3.141592653589793) @ q1, q2
```
"""
struct GateXXplusYY <: ParametricGate{2}
    θ::Float64
    β::Float64
    U::Matrix{ComplexF64}

    function GateXXplusYY(θ, β, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, β, U)
    end
end

GateXXplusYY(θ::Number, β::Number) = GateXXplusYY(
    θ,
    β,
    ComplexF64[
        1 0 0 0
        0 cos(θ / 2) -im*sin(θ / 2)*exp(-im * β) 0
        0 -im*sin(θ / 2)*exp(im * β) cos(θ / 2) 0
        0 0 0 1
    ],
)


inverse(g::GateXXplusYY) = GateXXplusYY(-g.θ, g.β)

numparams(::Type{GateXXplusYY}) = 2

opname(::Type{GateXXplusYY}) = "XXplusYY"

parnames(::Type{GateXXplusYY}) = (:θ, :β)

@doc raw"""
    struct GateXXminusYY <: ParametricGate{2}

Two qubit XXminusYY gate.

# Arguments

- `θ::Float64`: The angle in radians.
- `β::Float64`: The phase angle in radians.

# Matrix Representation
```math
\operatorname{XXminusYY}(\theta, \beta) =
    \begin{pmatrix}
        \cos(\frac{\theta}{2}) & 0 & 0 & -i\sin(\frac{\theta}{2})e^{-i\beta} \\
        0 & 1 & 0 & 0 \\
        0 & 0 & 1 & 0 \\
        -i\sin(\frac{\theta}{2})e^{i\beta} & 0 & 0 & \cos(\frac{\theta}{2})
    \end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateXXminusYY(π/2,π/2))
4×4 Matrix{ComplexF64}:
 0.707107+0.0im          0.0+0.0im  0.0+0.0im  -0.707107-4.32978e-17im
      0.0+0.0im          1.0+0.0im  0.0+0.0im        0.0+0.0im
      0.0+0.0im          0.0+0.0im  1.0+0.0im        0.0+0.0im
 0.707107-4.32978e-17im  0.0+0.0im  0.0+0.0im   0.707107+0.0im

julia> push!(Circuit(), GateXXminusYY(π,π), 1, 2)
2-qubit circuit with 1 instructions:
└── XXminusYY(θ=3.141592653589793, β=3.141592653589793) @ q1, q2
```
"""
struct GateXXminusYY <: ParametricGate{2}
    θ::Float64
    β::Float64
    U::Matrix{ComplexF64}

    function GateXXminusYY(θ, β, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, β, U)
    end
end

GateXXminusYY(θ::Number, β::Number) = GateXXminusYY(
    θ,
    β,
    ComplexF64[
        cos(θ / 2) 0 0 -im*sin(θ / 2)*cis(-β)
        0 1 0 0
        0 0 1 0
        -im*sin(θ / 2)*cis(β) 0 0 cos(θ / 2)
    ],
)

inverse(g::GateXXminusYY) = GateXXminusYY(-g.θ, g.β)

numparams(::Type{GateXXminusYY}) = 2

opname(::Type{GateXXminusYY}) = "XXminusYY"

parnames(::Type{GateXXminusYY}) = (:θ, :β)
