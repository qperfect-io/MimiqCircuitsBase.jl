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
    GateCCP(λ)

Three-qubit, doubly-controlled phase gate.

!!! details
    Implemented as an alias to ``Control(2, GateP(λ))``.

!!! note
    By convention, the first two qubits are the controls and the third is the
    target.

## Examples

```jldoctests
julia> @variables λ
1-element Vector{Symbolics.Num}:
 λ

julia> GateCCP(λ), numcontrols(GateCCP(λ)), numtargets(GateCCP(λ))
(C₂P(λ), 2, 1)

julia> matrix(GateCCP(1.989))
8×8 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  …  0.0+0.0im       0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im     0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im     0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  …  0.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im  -0.40612+0.91382im

julia> c = push!(Circuit(), GateCCP(λ), 1, 2, 3)
3-qubit circuit with 1 instructions:
└── C₂P(λ) @ q1, q2, q3

julia> push!(c, GateCCP(π/8), 1, 2, 3)
3-qubit circuit with 2 instructions:
├── C₂P(λ) @ q1, q2, q3
└── C₂P(π/8) @ q1, q2, q3

julia> power(GateCCP(λ), 2), inverse(GateCCP(λ))
(C₂P(2λ), C₂P(-λ))

```

## Decomposition

```jldoctests
julia> @variables λ
1-element Vector{Symbolics.Num}:
 λ

julia> decompose(GateCCP(λ))
3-qubit circuit with 5 instructions:
├── CP((1//2)*λ) @ q2, q3
├── CX @ q1, q2
├── CP((-1//2)*λ) @ q2, q3
├── CX @ q1, q2
└── CP((1//2)*λ) @ q1, q3
```
"""
const GateCCP = typeof(Control(2, GateP(π)))

function decompose!(circ::Circuit, g::GateCCP, qtargets, _)
    a, b, c = qtargets
    λ = getparam(g, :λ)
    push!(circ, GateCP(λ / 2), b, c)
    push!(circ, GateCX(), a, b)
    push!(circ, GateCP(-λ / 2), b, c)
    push!(circ, GateCX(), a, b)
    push!(circ, GateCP(λ / 2), a, c)
    return circ
end
