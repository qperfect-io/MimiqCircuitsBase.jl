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
    0 & \cos(\frac{\theta}{2}) & -i\sin(\frac{\theta}{2})e^{-i\phi} & 0 \\
    0 & -i\sin(\\frac{theta}{2})e^{i\phi} & \cos(\frac{\theta}{2}) & 0 \\
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
2-qubit circuit with 1 gates:
└── XXplusYY(θ=π⋅1.0, β=π⋅1.0) @ q1, q2
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

gatename(::Type{GateXXplusYY}) = "XXplusYY"

parnames(::Type{GateXXplusYY}) = (:θ, :β)
