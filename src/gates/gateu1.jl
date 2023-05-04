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
    struct GateU1 <: ParametricGate{1}

One qubit generic unitary gate `u1`, as defined in OpenQASM 3.0

Equivalent to [`GateP`](@ref)

# Arguments

- `λ::Float64`: Rotation angle in radians

# Matrix Representation

```math
\operatorname{U1}(\lambda) =
\begin{pmatrix}
    1 & 0 \\
    0 & e^{i\lambda}
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateU1(pi/4))
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107+0.707107im

julia> push!(Circuit(), GateU1(pi/4), 1)
1-qubit circuit with 1 gates:
└── U1(λ=π⋅0.25) @ q1
```
"""
struct GateU1 <: ParametricGate{1}
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU1(λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(λ, U)
    end
end

GateU1(λ::Number) = GateU1(λ, pmatrix(λ))

inverse(g::GateU1) = GateU1(-g.λ)

numparams(::Type{GateU1}) = 1

gatename(::Type{GateU1}) = "U1"

parnames(::Type{GateU1}) = (:λ,)

