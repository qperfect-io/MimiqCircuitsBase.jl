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
    GateH()

Single qubit Hadamard gate.

## Matrix representation

```math
\operatorname H =
\frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 1 \\
    1 & -1
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateH()
H

julia> matrix(GateH())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107

julia> c = push!(Circuit(), GateH(), 1)
1-qubit circuit with 1 instructions:
└── H @ q1

julia> push!(c, GateH, 1)
1-qubit circuit with 2 instructions:
├── H @ q1
└── H @ q1

julia> power(GateH(), 2), inverse(GateH())
(H^2, H)

```

## Decomposition

```jldoctests
julia> decompose(GateH())
1-qubit circuit with 2 instructions:
├── U(π/2, 0, π) @ q1
└── GPhase(-1π/4) @ q1

```
"""
struct GateH <: AbstractGate{1} end

opname(::Type{GateH}) = "H"

@generated _matrix(::Type{GateH}) = _decomplex(gphasepi(-1 / 4) * umatrixpi(1 / 2, 0, 1))

@generated inverse(::GateH) = GateH()

function decompose!(circ::Circuit, ::GateH, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(π / 2, 0, π), q)
    push!(circ, GPhase(-π / 4), q)
    return circ
end
