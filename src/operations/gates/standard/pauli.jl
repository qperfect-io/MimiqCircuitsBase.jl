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
    GateX()

Single qubit Pauli-X gate.

## Matrix representation

```math
\operatorname{X} =
\begin{pmatrix}
    0 & 1 \\
    1 & 0
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateX()
X

julia> matrix(GateX())
2×2 Matrix{Float64}:
 0.0  1.0
 1.0  0.0

julia> c = push!(Circuit(), GateX(), 1)
1-qubit circuit with 1 instructions:
└── X @ q1

julia> push!(c, GateX, 2)
2-qubit circuit with 2 instructions:
├── X @ q1
└── X @ q2

```

## Decomposition

```jldoctests
julia> decompose(GateX())
1-qubit circuit with 2 instructions:
├── U(π, 0, π) @ q1
└── GPhase(-1π/2) @ q1

```
"""
struct GateX <: AbstractGate{1} end

opname(::Type{GateX}) = "X"

@generated _matrix(::Type{GateX}) = _decomplex(umatrixpi(1, 0, 1) * gphasepi(-1 / 2))

@generated inverse(::GateX) = GateX()

_power(::GateX, pwr) = _power_nilpotent(GateX(), GateID(), pwr)

function decompose!(circ::Circuit, ::GateX, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(π, 0, π), q)
    push!(circ, GPhase(-π / 2), q)
    return circ
end

@doc raw"""
    GateY()

Single qubit Pauli-Y gate.

## Matrix representation

```math
\operatorname{Y} =
\begin{pmatrix}
    0 & -i \\
    i & 0
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateY()
Y

julia> matrix(GateY())
2×2 Matrix{ComplexF64}:
 0.0+0.0im  0.0-1.0im
 0.0+1.0im  0.0+0.0im

julia> c = push!(Circuit(), GateY(), 1)
1-qubit circuit with 1 instructions:
└── Y @ q1

julia> push!(c, GateY, 2)
2-qubit circuit with 2 instructions:
├── Y @ q1
└── Y @ q2

```

## Decomposition

```jldoctests
julia> decompose(GateY())
1-qubit circuit with 2 instructions:
├── U(π, π/2, π/2) @ q1
└── GPhase(-1π/2) @ q1

```
"""
struct GateY <: AbstractGate{1} end

opname(::Type{GateY}) = "Y"

@generated _matrix(::Type{GateY}) = _decomplex(umatrixpi(1, 1 / 2, 1 / 2) * gphasepi(-1 / 2))

@generated inverse(::GateY) = GateY()

_power(::GateY, pwr) = _power_nilpotent(GateY(), GateID(), pwr)

function decompose!(circ::Circuit, ::GateY, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(π, π / 2, π / 2), q)
    push!(circ, GPhase(-π / 2), q)
    return circ
end

@doc raw"""
    GateZ()

Single qubit Pauli-Z gate.

## Matrix representation

```math
\operatorname{Z} =
\begin{pmatrix}
    1 & 0 \\
    0 & -1
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateZ()
Z

julia> matrix(GateZ())
2×2 Matrix{Float64}:
 1.0   0.0
 0.0  -1.0

julia> c = push!(Circuit(), GateZ(), 1)
1-qubit circuit with 1 instructions:
└── Z @ q1

julia> push!(c, GateZ, 2)
2-qubit circuit with 2 instructions:
├── Z @ q1
└── Z @ q2

```

## Decomposition

```jldoctests
julia> decompose(GateZ())
1-qubit circuit with 1 instructions:
└── P(π) @ q1

```
"""
struct GateZ <: AbstractGate{1} end

opname(::Type{GateZ}) = "Z"

@generated _matrix(::Type{GateZ}) = _decomplex(pmatrixpi(1))

@generated inverse(::GateZ) = GateZ()

_power(::GateZ, pwr) = _power_nilpotent(GateZ(), GateID(), pwr)

function decompose!(circ::Circuit, ::GateZ, qtargets, _)
    q = qtargets[1]
    push!(circ, GateP(π), q)
    return circ
end
