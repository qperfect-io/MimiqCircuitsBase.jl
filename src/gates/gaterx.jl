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
1-qubit circuit with 1 gates:
└── RX(θ=π⋅0.5) @ q1
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

gatename(::Type{GateRX}) = "RX"

parnames(::Type{GateRX}) = (:θ,)

