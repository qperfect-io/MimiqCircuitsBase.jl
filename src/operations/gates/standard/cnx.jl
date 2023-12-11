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
(C₂X, 2, 1)

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
3-qubit circuit with 1 instructions:
└── C₂X @ q[1:2], q[3]

julia> power(GateCCX(), 2), inverse(GateCCX())
(C₂ID, C₂X)

```

## Decomposition

```jldoctests
julia> decompose(GateCCX())
3-qubit circuit with 15 instructions:
├── H @ q[3]
├── CX @ q[2], q[3]
├── T† @ q[3]
├── CX @ q[1], q[3]
├── T @ q[3]
├── CX @ q[2], q[3]
├── T† @ q[3]
├── CX @ q[1], q[3]
├── T @ q[2]
├── T @ q[3]
├── H @ q[3]
├── CX @ q[1], q[2]
├── T @ q[1]
├── T† @ q[2]
└── CX @ q[1], q[2]

```
"""
const GateCCX = typeof(Control(2, GateX()))

function decompose!(circ::Circuit, ::GateCCX, qtargets, _)
    a, b, c = qtargets
    push!(circ, GateH(), c)

    push!(circ, GateCX(), b, c)
    push!(circ, GateTDG(), c)

    push!(circ, GateCX(), a, c)
    push!(circ, GateT(), c)

    push!(circ, GateCX(), b, c)
    push!(circ, GateTDG(), c)

    push!(circ, GateCX(), a, c)
    push!(circ, GateT(), b)
    push!(circ, GateT(), c)
    push!(circ, GateH(), c)

    push!(circ, GateCX(), a, b)
    push!(circ, GateT(), a)
    push!(circ, GateTDG(), b)

    push!(circ, GateCX(), a, b)

    return circ
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
(C₃X, 3, 1)

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
4-qubit circuit with 1 instructions:
└── C₃X @ q[1:3], q[4]

julia> power(GateC3X(), 2), inverse(GateC3X())
(C₃ID, C₃X)

```

## Decomposition

```jldoctests
julia> decompose(GateC3X())
4-qubit circuit with 31 instructions:
├── H @ q[4]
├── P(π/8) @ q[1]
├── P(π/8) @ q[2]
├── P(π/8) @ q[3]
├── P(π/8) @ q[4]
├── CX @ q[1], q[2]
├── P(-1π/8) @ q[2]
├── CX @ q[1], q[2]
├── CX @ q[2], q[3]
⋮   ⋮
├── CX @ q[1], q[4]
├── P(π/8) @ q[4]
├── CX @ q[3], q[4]
├── P(-1π/8) @ q[4]
├── CX @ q[2], q[4]
├── P(π/8) @ q[4]
├── CX @ q[3], q[4]
├── P(-1π/8) @ q[4]
├── CX @ q[1], q[4]
└── H @ q[4]

```
"""
const GateC3X = typeof(Control(3, GateX()))

function decompose!(circ::Circuit, ::GateC3X, qtargets, _)
    a, b, c, d = qtargets

    push!(circ, GateH(), d)
    push!(circ, GateP(π / 8), qtargets)
    push!(circ, GateCX(), a, b)
    push!(circ, GateP(-π / 8), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateCX(), b, c)
    push!(circ, GateP(-π / 8), c)
    push!(circ, GateCX(), a, c)
    push!(circ, GateP(π / 8), c)
    push!(circ, GateCX(), b, c)
    push!(circ, GateP(-π / 8), c)
    push!(circ, GateCX(), a, c)
    push!(circ, GateCX(), c, d)
    push!(circ, GateP(-π / 8), d)
    push!(circ, GateCX(), b, d)
    push!(circ, GateP(π / 8), d)
    push!(circ, GateCX(), c, d)
    push!(circ, GateP(-π / 8), d)
    push!(circ, GateCX(), a, d)
    push!(circ, GateP(π / 8), d)
    push!(circ, GateCX(), c, d)
    push!(circ, GateP(-π / 8), d)
    push!(circ, GateCX(), b, d)
    push!(circ, GateP(π / 8), d)
    push!(circ, GateCX(), c, d)
    push!(circ, GateP(-π / 8), d)
    push!(circ, GateCX(), a, d)
    push!(circ, GateH(), d)

    return circ
end
