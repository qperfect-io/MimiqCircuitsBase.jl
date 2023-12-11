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
    GateID()

Single qubit identity gate

## Matrix representation

```math
\operatorname{I} =
\begin{pmatrix}
    1 & 0 \\
    0 & 1
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateID()
ID

julia> matrix(GateID())
2×2 Matrix{Float64}:
 1.0  0.0
 0.0  1.0

julia> c = push!(Circuit(), GateID(), 1)
1-qubit circuit with 1 instructions:
└── ID @ q[1]

julia> power(GateID(), 2), inverse(GateID())
(ID, ID)

```

## Decomposition

```jldoctests
julia> decompose(GateID())
1-qubit circuit with 1 instructions:
└── U(0, 0, 0) @ q[1]

```
"""
struct GateID <: AbstractGate{1} end

opname(::Type{GateID}) = "ID"

@generated _matrix(::Type{GateID}) = _decomplex(umatrixpi(0, 0, 0))

@generated inverse(::GateID) = GateID()

_power(::GateID, _) = GateID()

function decompose!(circ::Circuit, ::GateID, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(0, 0, 0), q)
    return circ
end


@doc raw"""
    GateID2()

Two-qubit identity gate

See also [`GateID`](@ref), [`Parallel`](@ref)

The gate is implemented as a parallel application of a GateID.

## Matrix representation

```math
\operatorname{I} =
\begin{pmatrix}
    1 & 0 & 0 & 0\\
    0 & 1 & 0 & 0\\
    0 & 0 & 1 & 0\\
    0 & 0 & 0 & 1\\
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateID2()
CID

julia> matrix(GateID2())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  1.0  0.0
 0.0  0.0  0.0  1.0

julia> c = push!(Circuit(), GateID2(), 1, 2)
2-qubit circuit with 1 instructions:
└── CID @ q[1], q[2]

julia> power(GateID2(), 2), inverse(GateID2())
(CID, CID)

```

## Decomposition

```jldoctests
julia> decompose(GateID2())
2-qubit circuit with 1 instructions:
└── CU(0, 0, 0) @ q[1], q[2]

```
"""
const GateID2 = typeof(Control(1, GateID()))

@generated inverse(::GateID2) = GateID2()

_power(::GateID2, _) = GateID2()

