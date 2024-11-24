#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
    GateSWAP()

Two qubit SWAP gate.

See also [`GateISWAP`](@ref), [`GateCSWAP`](@ref)

## Matrix representation

```math
\operatorname{SWAP} = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 0 & 1
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateSWAP()
SWAP

julia> matrix(GateSWAP())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  0.0  1.0

julia> c = push!(Circuit(), GateSWAP(), 1, 2)
2-qubit circuit with 1 instructions:
└── SWAP @ q[1:2]

julia> push!(c, GateSWAP, 3, 4)
4-qubit circuit with 2 instructions:
├── SWAP @ q[1:2]
└── SWAP @ q[3:4]

julia> power(GateSWAP(), 2), inverse(GateSWAP())
(Parallel(2, GateID()), GateSWAP())

```

## Decomposition

```jldoctests
julia> decompose(GateSWAP())
2-qubit circuit with 3 instructions:
├── CX @ q[1], q[2]
├── CX @ q[2], q[1]
└── CX @ q[1], q[2]

```
"""
struct GateSWAP <: AbstractGate{2} end

opname(::Type{GateSWAP}) = "SWAP"

@generated _matrix(::Type{GateSWAP}) = Float64[1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1]

@generated inverse(::GateSWAP) = GateSWAP()

_power(::GateSWAP, pwr) = _power_idempotent(GateSWAP(), parallel(2, GateID()), pwr)

function decompose!(circ::Circuit, ::GateSWAP, qtargets, _, _)
    a, b = qtargets
    push!(circ, GateCX(), a, b)
    push!(circ, GateCX(), b, a)
    push!(circ, GateCX(), a, b)
end
