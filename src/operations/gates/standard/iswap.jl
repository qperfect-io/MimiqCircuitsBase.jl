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
    GateISWAP()

Two qubit ISWAP gate.

See also [`GateSWAP`](@ref).

## Matrix representation

```math
\operatorname{ISWAP} = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & i & 0 \\
    0 & i & 0 & 0 \\
    0 & 0 & 0 & 1
\end{pmatrix}
```

## Examples

```jldoctest
julia> GateISWAP()
ISWAP

julia> matrix(GateISWAP())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+1.0im  0.0+0.0im
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im

julia> c = push!(Circuit(), GateISWAP(), 1, 2)
2-qubit circuit with 1 instructions:
└── ISWAP @ q1, q2

julia> push!(c, GateISWAP, 3, 4)
4-qubit circuit with 2 instructions:
├── ISWAP @ q1, q2
└── ISWAP @ q3, q4

julia> power(GateISWAP(), 2), inverse(GateISWAP())
(ISWAP^2, ISWAP†)

```

## Decomposition

```jldoctest
julia> decompose(GateISWAP())
2-qubit circuit with 6 instructions:
├── S @ q1
├── S @ q2
├── H @ q1
├── CX @ q1, q2
├── CX @ q2, q1
└── H @ q2

```
"""
struct GateISWAP <: AbstractGate{2} end

@generated _matrix(::Type{GateISWAP}) = Complex{Float64}[1 0 0 0; 0 0 im 0; 0 im 0 0; 0 0 0 1]

opname(::Type{GateISWAP}) = "ISWAP"

function decompose!(circ::Circuit, ::GateISWAP, qtargets, _)
    a, b = qtargets
    push!(circ, GateS(), a)
    push!(circ, GateS(), b)
    push!(circ, GateH(), a)
    push!(circ, GateCX(), a, b)
    push!(circ, GateCX(), b, a)
    push!(circ, GateH(), b)
    return circ
end

