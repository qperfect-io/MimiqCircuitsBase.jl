#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    GateCP(θ)

Controlled-``\operatorname{P}(\lambda)`` gate.

!!! details
    Implemented as an alias to `Control(GateP(θ))`.

See also [`Control`](@ref), [`GateRZ`](@ref).

## Examples

```jldoctests
julia> @variables λ
1-element Vector{Symbolics.Num}:
 λ

julia> GateCP(λ), numcontrols(GateCP(λ)), numtargets(GateCP(λ))
(CP(λ), 1, 1)

julia> matrix(GateCP(1.989))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im       0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  -0.40612+0.91382im

julia> c = push!(Circuit(), GateCP(λ), 1, 2)
2-qubit circuit with 1 instructions:
└── CP(λ) @ q[1], q[2]

julia> push!(c, GateCP(π/8), 1, 2)
2-qubit circuit with 2 instructions:
├── CP(λ) @ q[1], q[2]
└── CP(π/8) @ q[1], q[2]

julia> power(GateCP(λ), 2), inverse(GateCP(λ))
(CP(2λ), CP(-λ))

```

## Decomposition

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> decompose(GateCP(θ))
2-qubit circuit with 5 instructions:
├── P((1//2)*θ) @ q[1]
├── CX @ q[1], q[2]
├── P((-1//2)*θ) @ q[2]
├── CX @ q[1], q[2]
└── P((1//2)*θ) @ q[2]
```
"""
const GateCP = typeof(Control(GateP(π)))

function decompose!(circ::Circuit, g::GateCP, qtargets, _)
    c, t = qtargets
    op = getoperation(g)

    λ2 = op.λ / 2

    push!(circ, GateP(λ2), c)
    push!(circ, GateCX(), c, t)
    push!(circ, GateP(-λ2), t)
    push!(circ, GateCX(), c, t)
    push!(circ, GateP(λ2), t)
    return circ
end
