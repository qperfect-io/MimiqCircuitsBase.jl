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
    GateCSWAP()

Three-qubit, controlled-``\operatorname{SWAP}`` gate.

!!! details
    Implemented as an alias to `Control{1,2,3,GateSWAP}`.

See also [`Control`](@ref), [`GateU`](@ref).

!!! note
    By convention, the first qubit is the control and the last two are
    targets.

## Examples

```jldoctests
julia> GateCSWAP(), numcontrols(GateCSWAP()), numtargets(GateCSWAP())
(CSWAP, 1, 2)

julia> matrix(GateCSWAP())
8×8 Matrix{Float64}:
 1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0
 0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0

julia> c = push!(Circuit(), GateCSWAP(), 1, 2, 3)
3-qubit circuit with 1 instructions:
└── CSWAP @ q[1], q[2:3]

julia> power(GateCSWAP(), 2), inverse(GateCSWAP())
(C(Parallel(2, ID)), CSWAP)

```

## Decomposition

```jldoctests
julia> decompose(GateCSWAP())
3-qubit circuit with 3 instructions:
├── CX @ q[3], q[2]
├── C₂X @ q[1:2], q[3]
└── CX @ q[3], q[2]

```
"""
const GateCSWAP = typeof(Control(1, GateSWAP()))

function decompose!(circ::Circuit, ::GateCSWAP, qtargets, _)
    a, b, c = qtargets
    push!(circ, GateCX(), c, b)
    push!(circ, GateCCX(), a, b, c)
    push!(circ, GateCX(), c, b)
    return circ
end
