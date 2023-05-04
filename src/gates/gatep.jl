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
    struct GateP <: ParametricGate{1}

Single qubit Phase gate.

# Arguments

- `λ::Float64`: Phase angle in radians

# Matrix Representation

```math
\operatorname P(\lambda) =
\begin{pmatrix}
    1 & 0 \\
    0 & e^{i\lambda}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateP(pi/4))
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107+0.707107im

julia> push!(Circuit(), GateP(pi/4), 1)
1-qubit circuit with 1 gates:
└── P(λ=π⋅0.25) @ q1
```
"""
struct GateP <: ParametricGate{1}
    λ::Float64
    U::Matrix{ComplexF64}
    a::Float64
    b::Float64
    c::Float64
    d::ComplexF64

    function GateP(λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(λ, U, 1, 0, 0, U[4])
    end
end

GateP(λ::Number) = GateP(λ, pmatrix(λ))

inverse(g::GateP) = GateP(-g.λ)

numparams(::Type{GateP}) = 1

parnames(::Type{GateP}) = (:λ,)

gatename(::Type{GateP}) = "P"

