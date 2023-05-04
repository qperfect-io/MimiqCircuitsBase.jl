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
2-qubit circuit with 1 gates:
└── CRY(θ=π⋅0.5) @ q1, q2
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

gatename(::Type{GateCRY}) = "CRY"

parnames(::Type{GateCRY}) = (:θ,)

