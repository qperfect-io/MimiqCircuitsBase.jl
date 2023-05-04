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
    struct GateU3 <: ParametricGate{1}

One qubit generic unitary gate `u3`, as defined in OpenQASM 3.0 for backwards compatibility.

# Arguments

- `θ:Float64`: Rotation angle 1 in radians
- `ϕ:Float64`: Rotation angle 2 in radians
- `λ::Float64`: Rotation angle 3 in radians

# Examples

```jldoctest
julia> matrix(GateU3(pi/2,pi/4,pi/2))
2×2 Matrix{ComplexF64}:
 0.270598-0.653281im  -0.653281-0.270598im
 0.653281-0.270598im   0.270598+0.653281im

julia> push!(Circuit(), GateU3(pi/2, pi/4, pi/2), 1)
1-qubit circuit with 1 gates:
└── U3(θ=π⋅0.5, ϕ=π⋅0.25, λ=π⋅0.5) @ q1
```
"""
struct GateU3 <: ParametricGate{1}
    θ::Float64
    ϕ::Float64
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU3(θ, ϕ, λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(θ, ϕ, λ, U)
    end
end

GateU3(θ::Number, ϕ::Number, λ::Number) =
    GateU3(θ, ϕ, λ, gphase(-(ϕ + λ) / 2) .* umatrix(θ, ϕ, λ))

inverse(g::GateU3) = GateU3(-g.θ, -g.λ, -g.ϕ)

numparams(::Type{GateU3}) = 3

gatename(::Type{GateU3}) = "U3"

parnames(::Type{GateU3}) = (:θ, :ϕ, :λ)

