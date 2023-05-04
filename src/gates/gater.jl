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
1-qubit circuit with 1 gates:
└── R(θ=π⋅0.5, ϕ=π⋅0.25) @ q1
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

gatename(::Type{GateR}) = "R"

parnames(::Type{GateR}) = (:θ, :ϕ)

