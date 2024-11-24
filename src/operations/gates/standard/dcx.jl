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
    GateDCX()

Two qubit double-CNOT (control on first qubit and then second) OR DCX gate.

## Matrix representation

```math
\operatorname{DCX}= \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & 1 \\
    0 & 1 & 0 & 0
\end{pmatrix}
```

## Examples

```jldoctest
julia> GateDCX()
DCX

julia> matrix(GateDCX())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0
 0.0  0.0  0.0  1.0
 0.0  1.0  0.0  0.0

julia> c = push!(Circuit(), GateDCX(), 1, 2)
2-qubit circuit with 1 instructions:
└── DCX @ q[1:2]

julia> power(GateDCX(), 2), inverse(GateDCX())
(Inverse(GateDCX()), Inverse(GateDCX()))

```

## Decomposition

```jldoctest
julia> decompose(GateDCX())
2-qubit circuit with 2 instructions:
├── CX @ q[1], q[2]
└── CX @ q[2], q[1]

```
"""
struct GateDCX <: AbstractGate{2} end

opname(::Type{GateDCX}) = "DCX"

@generated _matrix(::Type{GateDCX}) = _matrix(GateSWAP) * _matrix(GateCX) * _matrix(GateSWAP) * _matrix(GateCX)

_power(::GateDCX, pwr) = _power_three_idempotent(GateDCX(), inverse(GateDCX()), GateID(), pwr)

function decompose!(circ::Circuit, ::GateDCX, qtargets, _, _)
    a, b = qtargets
    push!(circ, GateCX(), a, b)
    push!(circ, GateCX(), b, a)
    return circ
end
