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
    GateCH()

Two qubit controlled-Hadamard gate.

!!! details
    Implemented as an alias to `Control(1, GateH())`.

!!! note
    By convention, the first qubit is the control and the second is the target.

## Matrix representation

```math
\operatorname{CH} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & \frac{1}{\sqrt{2}} & \frac{1}{\sqrt{2}} \\
    0 & 0 & \frac{1}{\sqrt{2}} & -\frac{1}{\sqrt{2}}
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCH(), numcontrols(GateCH), numtargets(GateCH)
(CH, 1, 1)

julia> matrix(GateCH())
4×4 Matrix{Float64}:
 1.0  0.0  0.0        0.0
 0.0  1.0  0.0        0.0
 0.0  0.0  0.707107   0.707107
 0.0  0.0  0.707107  -0.707107

julia> c = push!(Circuit(), GateCH(), 1, 2)
2-qubit circuit with 1 instructions:
└── CH @ q[1], q[2]

julia> power(GateCH(), 2), inverse(GateCH())
(C(H^2), CH)

```

## Decomposition

```jldoctests
julia> decompose(GateCH())
2-qubit circuit with 7 instructions:
├── S @ q[2]
├── H @ q[2]
├── T @ q[2]
├── CX @ q[1], q[2]
├── T† @ q[2]
├── H @ q[2]
└── S† @ q[2]

```
"""
const GateCH = Control{1,1,2,GateH}

function decompose!(circ::Circuit, ::GateCH, qtargets, _)
    a, b = qtargets

    push!(circ, GateS(), b)
    push!(circ, GateH(), b)
    push!(circ, GateT(), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateTDG(), b)
    push!(circ, GateH(), b)
    push!(circ, GateSDG(), b)

    return circ
end
