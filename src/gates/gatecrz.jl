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
    struct GateCRZ <: ParametricGate{2}

Two qubit Controlled-RZ gate 

# Arguments

- `λ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{CRZ}(\lambda) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & e^{-i\frac{\lambda}{2}} & 0 \\
    0 & 0 & 0 & e^{i\frac{\lambda}{2}}
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCRZ(pi/2))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.707107-0.707107im      -0.0+0.0im
 0.0+0.0im  0.0+0.0im       0.0+0.0im       0.707107+0.707107im

julia> push!(Circuit(), GateCRZ(pi/2), 1, 2)
2-qubit circuit with 1 gates:
└── CRZ(λ=π⋅0.5) @ q1, q2
```
"""
struct GateCRZ <: ParametricGate{2}
    λ::Float64
    U::Matrix{ComplexF64}
    a::ComplexF64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateCRZ(λ, U)
        if size(U, 1) != 4 && size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end
        new(λ, U, U[11], 0, 0, U[16])
    end
end

GateCRZ(λ) = GateCRZ(λ, ctrl(rzmatrix(λ)))

inverse(g::GateCRZ) = GateCRZ(-g.λ)

numparams(::Type{GateCRZ}) = 1

gatename(::Type{GateCRZ}) = "CRZ"

parnames(::Type{GateCRZ}) = (:λ,)

