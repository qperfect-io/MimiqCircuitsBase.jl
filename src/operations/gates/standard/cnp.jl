#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
(GateCCP(λ), 2, 1)

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
3-qubit circuit with 1 instruction:
└── CCP(λ) @ q[1:2], q[3]

julia> push!(c, GateCCP(π/8), 1, 2, 3)
3-qubit circuit with 2 instructions:
├── CCP(λ) @ q[1:2], q[3]
└── CCP(π/8) @ q[1:2], q[3]

julia> power(GateCCP(λ), 2), inverse(GateCCP(λ))
(GateCCP(2λ), GateCCP(-λ))

```

## Decomposition

```jldoctests
julia> @variables λ
1-element Vector{Symbolics.Num}:
 λ

julia> decompose(GateCCP(λ))
3-qubit circuit with 17 instructions:
├── U(0,0,λ / 4) @ q[1]
├── CX @ q[1], q[3]
├── U(0,0,(-1//4)*λ) @ q[3]
├── CX @ q[1], q[3]
├── U(0,0,λ / 4) @ q[3]
├── CX @ q[1], q[2]
├── U(0,0,(-1//4)*λ) @ q[2]
├── CX @ q[2], q[3]
├── U(0,0,(1//4)*λ) @ q[3]
├── CX @ q[2], q[3]
├── U(0,0,(-1//4)*λ) @ q[3]
├── CX @ q[1], q[2]
├── U(0,0,λ / 4) @ q[2]
├── CX @ q[2], q[3]
├── U(0,0,(-1//4)*λ) @ q[3]
├── CX @ q[2], q[3]
└── U(0,0,λ / 4) @ q[3]
```
"""
const GateCCP = typeof(Control(2, GateP(π)))

@definename GateCCP "CCP"

matches(::CanonicalRewrite, ::GateCCP) = true

function decompose_step!(builder, ::CanonicalRewrite, g::GateCCP, qtargets, _, _)
    a, b, c = qtargets
    λ = getparam(g, :λ)
    push!(builder, GateCP(λ / 2), a, c)
    push!(builder, GateCX(), a, b)
    push!(builder, GateCP(-λ / 2), b, c)
    push!(builder, GateCX(), a, b)
    push!(builder, GateCP(λ / 2), b, c)
    return builder
end
