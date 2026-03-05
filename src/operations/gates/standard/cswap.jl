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
(GateCSWAP(), 1, 2)

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
3-qubit circuit with 1 instruction:
└── CSWAP @ q[1], q[2:3]

julia> power(GateCSWAP(), 2), inverse(GateCSWAP())
(Control(Parallel(2, GateID())), GateCSWAP())

```

## Decomposition

```jldoctests
julia> decompose(GateCSWAP())
3-qubit circuit with 17 instructions:
├── CX @ q[3], q[2]
├── U(π/2,0,π) @ q[3]
├── CX @ q[2], q[3]
├── U(0,0,-1π/4) @ q[3]
├── CX @ q[1], q[3]
├── U(0,0,π/4) @ q[3]
├── CX @ q[2], q[3]
├── U(0,0,-1π/4) @ q[3]
├── CX @ q[1], q[3]
├── U(0,0,π/4) @ q[2]
├── U(0,0,π/4) @ q[3]
├── U(π/2,0,π) @ q[3]
├── CX @ q[1], q[2]
├── U(0,0,π/4) @ q[1]
├── U(0,0,-1π/4) @ q[2]
├── CX @ q[1], q[2]
└── CX @ q[3], q[2]

```
"""
const GateCSWAP = typeof(Control(1, GateSWAP()))

@definename GateCSWAP "CSWAP"

matches(::CanonicalRewrite, ::GateCSWAP) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateCSWAP, qtargets, _, _)
    a, b, c = qtargets
    push!(builder, GateCX(), c, b)
    push!(builder, GateCCX(), a, b, c)
    push!(builder, GateCX(), c, b)
    return builder
end
