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
    GateCCX()

Three-qubit, doubly-controlled ``X`` gate.

!!! details
    Implemented as an alias to ``Control(2, GateX())``.

!!! note
    By convention, the first two qubits are the controls and the third is the
    target.

## Examples

```jldoctests
julia> GateCCX(), numcontrols(GateCCX()), numtargets(GateCCX())
(Control(2, GateX()), 2, 1)

julia> matrix(GateCCX())
8×8 Matrix{Float64}:
 1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0
 0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0

julia> c = push!(Circuit(), GateCCX(), 1, 2, 3)
3-qubit circuit with 1 instruction:
└── C₂X @ q[1:2], q[3]

julia> power(GateCCX(), 2), inverse(GateCCX())
(Control(2, GateID()), Control(2, GateX()))

```

## Decomposition

```jldoctests
julia> decompose(GateCCX())
3-qubit circuit with 15 instructions:
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
└── CX @ q[1], q[2]

```
"""
const GateCCX = typeof(Control(2, GateX()))

matches(::CanonicalRewrite, ::GateCCX) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateCCX, qtargets, _, _)
    a, b, c = qtargets
    push!(builder, GateH(), c)

    push!(builder, GateCX(), b, c)
    push!(builder, GateTDG(), c)

    push!(builder, GateCX(), a, c)
    push!(builder, GateT(), c)

    push!(builder, GateCX(), b, c)
    push!(builder, GateTDG(), c)

    push!(builder, GateCX(), a, c)
    push!(builder, GateT(), b)
    push!(builder, GateT(), c)
    push!(builder, GateH(), c)

    push!(builder, GateCX(), a, b)
    push!(builder, GateT(), a)
    push!(builder, GateTDG(), b)

    push!(builder, GateCX(), a, b)

    return builder
end

"""
    GateC3X()

Four qubit, triply-controlled ``X`` gate.

!!! details
    Implemented as an alias to ``Control(3, GateX())``.

!!! note
    By convention, the first three qubits are the controls and the fourth is
    the target.

## Examples

```jldoctests
julia> GateC3X(), numcontrols(GateC3X()), numtargets(GateC3X())
(Control(3, GateX()), 3, 1)

julia> matrix(GateC3X())
16×16 Matrix{Float64}:
 1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  …  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  …  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     1.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  …  0.0  1.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  1.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  …  0.0  0.0  0.0  0.0  0.0  1.0  0.0

julia> c = push!(Circuit(), GateC3X(), 1, 2, 3, 4)
4-qubit circuit with 1 instruction:
└── C₃X @ q[1:3], q[4]

julia> power(GateC3X(), 2), inverse(GateC3X())
(Control(3, GateID()), Control(3, GateX()))

```

## Decomposition

```jldoctests
julia> decompose(GateC3X())
4-qubit circuit with 31 instructions:
├── U(π/2,0,π) @ q[4]
├── U(0,0,π/8) @ q[1]
├── U(0,0,π/8) @ q[2]
├── U(0,0,π/8) @ q[3]
├── U(0,0,π/8) @ q[4]
├── CX @ q[1], q[2]
├── U(0,0,-1π/8) @ q[2]
├── CX @ q[1], q[2]
├── CX @ q[2], q[3]
⋮   ⋮
├── CX @ q[1], q[4]
├── U(0,0,π/8) @ q[4]
├── CX @ q[3], q[4]
├── U(0,0,-1π/8) @ q[4]
├── CX @ q[2], q[4]
├── U(0,0,π/8) @ q[4]
├── CX @ q[3], q[4]
├── U(0,0,-1π/8) @ q[4]
├── CX @ q[1], q[4]
└── U(π/2,0,π) @ q[4]

```
"""
const GateC3X = typeof(Control(3, GateX()))

function decompose_step!(builder, ::CanonicalRewrite, ::GateC3X, qtargets, _, _)
    a, b, c, d = qtargets

    push!(builder, GateH(), d)
    push!(builder, GateP(π / 8), qtargets)
    push!(builder, GateCX(), a, b)
    push!(builder, GateP(-π / 8), b)
    push!(builder, GateCX(), a, b)
    push!(builder, GateCX(), b, c)
    push!(builder, GateP(-π / 8), c)
    push!(builder, GateCX(), a, c)
    push!(builder, GateP(π / 8), c)
    push!(builder, GateCX(), b, c)
    push!(builder, GateP(-π / 8), c)
    push!(builder, GateCX(), a, c)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(-π / 8), d)
    push!(builder, GateCX(), b, d)
    push!(builder, GateP(π / 8), d)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(-π / 8), d)
    push!(builder, GateCX(), a, d)
    push!(builder, GateP(π / 8), d)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(-π / 8), d)
    push!(builder, GateCX(), b, d)
    push!(builder, GateP(π / 8), d)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(-π / 8), d)
    push!(builder, GateCX(), a, d)
    push!(builder, GateH(), d)

    return builder
end
