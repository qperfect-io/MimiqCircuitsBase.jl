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
1-qubit circuit with 1 gates:
└── RY(θ=π⋅0.5) @ q1
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

gatename(::Type{GateRY}) = "RY"

parnames(::Type{GateRY}) = (:θ,)

