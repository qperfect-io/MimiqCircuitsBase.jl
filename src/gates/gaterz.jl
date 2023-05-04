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
    struct GateRZ <: ParametricGate{1}

Single qubit Rotation-Z gate (RZ gate)

# Arguments

- `λ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{RZ}(\lambda) =
\begin{pmatrix}
    e^{-i\frac{\lambda}{2}} & 0 \\
    0 & e^{i\frac{\lambda}{2}}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateRZ(pi/2))
2×2 Matrix{ComplexF64}:
 0.707107-0.707107im      -0.0+0.0im
      0.0+0.0im       0.707107+0.707107im

julia> push!(Circuit(), GateRZ(pi/2), 1)
1-qubit circuit with 1 gates:
└── RZ(λ=π⋅0.5) @ q1
```
"""
struct GateRZ <: ParametricGate{1}
    λ::Float64
    U::Matrix{ComplexF64}
    a::ComplexF64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateRZ(λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(λ, U, U[1], 0, 0, U[4])
    end
end

GateRZ(λ::Number) = GateRZ(λ, rzmatrix(λ))

inverse(g::GateRZ) = GateRZ(-g.λ)

numparams(::Type{GateRZ}) = 1

gatename(::Type{GateRZ}) = "RZ"

parnames(::Type{GateRZ}) = (:λ,)

