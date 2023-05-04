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
    struct GateXXminusYY <: ParametricGate{2}

Two qubit XXminusYY gate.

# Arguments

- `θ::Float64`: The angle in radians.
- `β::Float64`: The phase angle in radians.

# Matrix Representation
```math
\operatorname{XXminusYY}(\theta, \beta) =
\begin{pmatrix}
    \cos(\frac{\theta}{2}) & 0 & 0 & -i\sin(\frac{\theta}{2})e^{-i\phi} \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    -i\sin(\frac{\theta}{2})e^{i\phi} & 0 & 0 & \cos(\frac{\theta}{2})
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateXXminusYY(π/2,π/2))
4×4 Matrix{ComplexF64}:
  0.707107+0.0im          0.0+0.0im  0.0+0.0im  -0.707107-4.32978e-17im
       0.0+0.0im          1.0+0.0im  0.0+0.0im        0.0+0.0im
       0.0+0.0im          0.0+0.0im  1.0+0.0im        0.0+0.0im
 -0.707107-4.32978e-17im  0.0+0.0im  0.0+0.0im   0.707107+0.0im

julia> push!(Circuit(), GateXXminusYY(π,π), 1, 2)
2-qubit circuit with 1 gates:
└── XXminusYY(θ=π⋅1.0, β=π⋅1.0) @ q1, q2
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

gatename(::Type{GateXXminusYY}) = "XXminusYY"

parnames(::Type{GateXXminusYY}) = (:θ, :β)
