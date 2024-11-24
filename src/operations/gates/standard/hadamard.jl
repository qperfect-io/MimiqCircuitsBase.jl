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
    GateH()

Single qubit Hadamard gate.

## Matrix representation

```math
\operatorname{H} =
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
└── H @ q[1]

julia> push!(c, GateH, 1)
1-qubit circuit with 2 instructions:
├── H @ q[1]
└── H @ q[1]

julia> power(GateH(), 2), inverse(GateH())
(GateH()^2, GateH())

```

## Decomposition

```jldoctests
julia> decompose(GateH())
1-qubit circuit with 1 instructions:
└── U(π/2,0,π) @ q[1]

```
"""
struct GateH <: AbstractGate{1} end

opname(::Type{GateH}) = "H"

@generated _matrix(::Type{GateH}) = [1 1; 1 -1] / sqrt(2)

@generated inverse(::GateH) = GateH()

function decompose!(circ::Circuit, ::GateH, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateU(π / 2, 0, π), q)
    return circ
end


@doc raw"""
    GateHXY()

Single qubit HXY gate.

## Matrix representation

```math
\operatorname{HXY} = \frac{1}{\sqrt{2}} \begin{pmatrix}
            0 & 1 - i \\
            1 + i & 0
        \end{pmatrix}
```

## Examples

```jldoctests
julia> GateHXY()
HXY

julia> matrix(GateHXY())
2×2 Matrix{ComplexF64}:
      0.0+0.0im       0.707107-0.707107im
 0.707107+0.707107im       0.0+0.0im

julia> c = push!(Circuit(), GateHXY(), 1)
1-qubit circuit with 1 instructions:
└── HXY @ q[1]

julia> power(GateHXY(), 2), inverse(GateHXY())
(GateHXY()^2, GateHXY())

```

## Decomposition

```jldoctests
julia> decompose(GateHXY())
1-qubit circuit with 5 instructions:
├── H @ q[1]
├── Z @ q[1]
├── H @ q[1]
├── S @ q[1]
└── U(0,0,0,-1π/4) @ q[1]
```
"""
struct GateHXY <: AbstractGate{1} end

opname(::Type{GateHXY}) = "HXY"

@generated _matrix(::Type{GateHXY}) = [0 1-1im; 1+1im 0] / sqrt(2)

@generated inverse(::GateHXY) = GateHXY()

function decompose!(circ::Circuit, ::GateHXY, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateH(), q)
    push!(circ, GateZ(), q)
    push!(circ, GateH(), q)
    push!(circ, GateS(), q)
    push!(circ, GateU(0, 0, 0, -π / 4), q)
    return circ
end

@doc raw"""
    GateHYZ()

 Single qubit HYZ gate.

## Matrix representation

```math
\operatorname{HYZ} = \frac{1}{\sqrt{2}} \begin{pmatrix}
            1 & -i \\
            i & -1
        \end{pmatrix}
```

## Examples

```jldoctests
julia> GateHYZ()
HYZ

julia> matrix(GateHYZ())
2×2 Matrix{ComplexF64}:
 0.707107+0.0im             0.0-0.707107im
      0.0+0.707107im  -0.707107+0.0im

julia> c = push!(Circuit(), GateHYZ(), 1)
1-qubit circuit with 1 instructions:
└── HYZ @ q[1]

julia> power(GateHYZ(), 2), inverse(GateHYZ())
(GateHYZ()^2, GateHYZ())

```

## Decomposition

```jldoctests
julia> decompose(GateHYZ())
1-qubit circuit with 5 instructions:
├── H @ q[1]
├── S @ q[1]
├── H @ q[1]
├── Z @ q[1]
└── U(0,0,0,-1π/4) @ q[1]
```
"""
struct GateHYZ <: AbstractGate{1} end

opname(::Type{GateHYZ}) = "HYZ"

@generated _matrix(::Type{GateHYZ}) = [1 -1im; 1im -1] / sqrt(2)

@generated inverse(::GateHYZ) = GateHYZ()

function decompose!(circ::Circuit, ::GateHYZ, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateH(), q)
    push!(circ, GateS(), q)
    push!(circ, GateH(), q)
    push!(circ, GateZ(), q)
    push!(circ, GateU(0, 0, 0, -π / 4), q)
    return circ
end

@doc raw"""
    GateHXZ()

The `HXZ` gate is an alias for the Hadamard gate. 
It applies a transformation that puts the qubit in an equal superposition of `|0⟩` and `|1⟩`.

## Matrix representation

```math
\operatorname{HXZ} = \frac{1}{\sqrt{2}} \begin{pmatrix}
            1 & 1 \\
            1 & -1
        \end{pmatrix}
```

## Examples

```jldoctests
julia> GateHXZ()
H

julia> matrix(GateHXZ())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107

julia> c = push!(Circuit(), GateHXZ(), 1)
1-qubit circuit with 1 instructions:
└── H @ q[1]

julia> power(GateHXZ(), 2), inverse(GateHXZ())
(GateH()^2, GateH())

```

## Decomposition

```jldoctests
julia> decompose(GateHXZ())
1-qubit circuit with 1 instructions:
└── U(π/2,0,π) @ q[1]
```
"""
const GateHXZ = GateH
