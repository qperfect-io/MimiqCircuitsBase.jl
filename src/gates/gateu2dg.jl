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
    struct GateU2DG <: ParametricGate{1}

One qubit generic unitary gate `u2`-dagger, as defined in OpenQASM 3.0 for backwards compatibility

See also [`GateU2`](@ref)

# Arguments
- `ϕ:Float64`: Rotation angle in radians
- `λ::Float64`: Rotation angle in radians

# Examples
```jldoctest
julia> matrix(GateU2DG(pi/2,pi/4))
2×2 Matrix{ComplexF64}:
  0.270598+0.653281im  0.653281-0.270598im
 -0.653281-0.270598im  0.270598-0.653281im

julia> push!(Circuit(), GateU2DG(pi/2,pi/4), 1)
1-qubit circuit with 1 gates:
└── U2DG(ϕ=-π⋅0.5, λ=-π⋅0.25) @ q1
```
"""
struct GateU2DG <: ParametricGate{1}
    ϕ::Float64
    λ::Float64
    U::Matrix{ComplexF64}

    function GateU2DG(ϕ, λ, U)
        if size(U, 1) != 2 || size(U, 2) != 2
            throw(ArgumentError("Error in constructing parametric gate"))
        end
        new(ϕ, λ, U)
    end
end

GateU2DG(ϕ::Number, λ::Number) =
    GateU2DG(ϕ, λ, gphase((ϕ + λ) / 2) .* umatrixpi(-1 / 2, -λ / π, -ϕ / π))

inverse(g::GateU2DG) = GateU2(g.ϕ, g.λ)

numparams(::Type{GateU2DG}) = 2

gatename(::Type{GateU2DG}) = "U2DG"

parnames(::Type{GateU2DG}) = (:ϕ, :λ)

