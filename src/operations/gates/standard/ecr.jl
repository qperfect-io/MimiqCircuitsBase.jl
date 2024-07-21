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
    GateECR()

Two qubit ECR echo gate.

## Matrix representation

```math
\operatorname{ECR} = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    0 & 1 & 0 & i \\
    1 & 0 & -i & 0 \\
    0 & i & 0 & 1 \\
    -i & 0 & 1 & 0
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateECR()
ECR

julia> matrix(GateECR())
4×4 Matrix{ComplexF64}:
      0.0+0.0im            0.0+0.0im       …       0.0+0.707107im
      0.0+0.0im            0.0+0.0im          0.707107+0.0im
 0.707107+0.0im            0.0-0.707107im          0.0+0.0im
      0.0-0.707107im  0.707107+0.0im               0.0+0.0im

julia> c = push!(Circuit(), GateECR(), 1, 2)
2-qubit circuit with 1 instructions:
└── ECR @ q[1:2]

julia> power(GateECR(), 2), inverse(GateECR())
(Parallel(2, ID), ECR)

```

## Decomposition

```jldoctests
julia> decompose(GateECR())
2-qubit circuit with 3 instructions:
├── RZX(π/4) @ q[1:2]
├── X @ q[1]
└── RZX(-1π/4) @ q[1:2]

```
"""
struct GateECR <: AbstractGate{2} end

opname(::Type{GateECR}) = "ECR"

@generated _matrix(::Type{GateECR}) = ComplexF64[0 0 1 im; 0 0 im 1; 1 -im 0 0; -im 1 0 0] ./ sqrt(2)

@generated inverse(::GateECR) = GateECR()

_power(::GateECR, pwr) = _power_idempotent(GateECR(), parallel(2, GateID()), pwr)

function decompose!(circ::Circuit, ::GateECR, qtargets, _)
    a, b = qtargets
    push!(circ, GateRZX(π / 4), a, b)
    push!(circ, GateX(), a)
    push!(circ, GateRZX(-π / 4), a, b)
    return circ
end

