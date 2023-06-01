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
2-qubit circuit with 1 gates:
└── CRX(θ=π⋅0.5) @ q1, q2
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
