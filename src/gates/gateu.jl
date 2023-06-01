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
1-qubit circuit with 1 gates:
└── U(θ=π⋅0.3333..., ϕ=π⋅0.3333..., λ=π⋅0.3333...) @ q1
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

