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
    GateP(λ)

Single qubit Phase gate.

`λ` is the phase angle in radians.

## Matrix representation

```math
\operatorname{P}(\lambda) =
\operatorname{U}(0, 0, g.λ) =
\begin{pmatrix}
    1 & 0 \\
    0 & e^{i\lambda}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables λ
1-element Vector{Symbolics.Num}:
 λ

julia> GateP(λ)
P(λ)

julia> matrix(GateP(1.989))
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  -0.40612+0.91382im

julia> c = push!(Circuit(), GateP(λ), 1)
1-qubit circuit with 1 instructions:
└── P(λ) @ q[1]

julia> push!(c, GateP(π/2), 2)
2-qubit circuit with 2 instructions:
├── P(λ) @ q[1]
└── P(π/2) @ q[2]

```

## Decomposition

```jldoctests; setup = :(@variables λ)
julia> decompose(GateP(λ))
1-qubit circuit with 1 instructions:
└── U(0, 0, λ) @ q[1]

```
"""
struct GateP <: AbstractGate{1}
    λ::Num
end

opname(::Type{GateP}) = "P"

inverse(g::GateP) = GateP(-g.λ)

_power(g::GateP, pwr) = GateP(g.λ * pwr)

_matrix(::Type{GateP}, λ) = pmatrix(λ)

function decompose!(circ::Circuit, g::GateP, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(0, 0, g.λ), q)
    return circ
end
