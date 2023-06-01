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
2-qubit circuit with 1 gates:
└── RXX(θ=π⋅1.0) @ q1, q2
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
