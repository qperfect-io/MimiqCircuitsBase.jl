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
    0 & 0 & \cos\frac{\theta}{2} & -i\sin\\frac{\theta}{2} \\
    0 & 0 & -i\sin\frac{\theta}{2} & \cos\frac{\theta}{2}e^{i\phi}
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
2-qubit circuit with 1 gates:
└── CR(θ=π⋅1.0, ϕ=-π⋅1.0) @ q1, q2
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

gatename(::Type{GateCR}) = "CR"

parnames(::Type{GateCR}) = (:θ, :ϕ)
