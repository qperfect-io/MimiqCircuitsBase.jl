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
    struct GateCX <: Gate{2}

Two qubit Controlled-X gate (or CNOT).

## Matrix Representation

```math
\operatorname{CX} =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 0 & 1 \\
    0 & 0 & 1 & 0
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

## Examples

```jldoctest
julia> matrix(GateCX())
4×4 Matrix{Float64}:
 1.0  0.0  0.0   0.0
 0.0  1.0  0.0   0.0
 0.0  0.0  0.0   1.0
 0.0  0.0  1.0  -0.0


julia> push!(Circuit(), GateCX(), 1, 2)
2-qubit circuit with 1 instructions:
└── CX @ q1, q2
```
"""
struct GateCX <: Gate{2} end

@generated matrix(::GateCX) = ctrl(matrix(GateX()))

inverse(g::GateCX) = g

opname(::Type{GateCX}) = "CX"

@doc raw"""
    struct GateCY <: Gate{2}

Two qubit Controlled-Y gate.

## Matrix Representation

```math
\operatorname{CY} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 0 & -i \\
    0 & 0 & i & 0
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

## Examples

```jldoctest
julia> matrix(GateCY())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im   0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im   0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  -0.0-1.0im
 0.0+0.0im  0.0+0.0im  0.0+1.0im  -0.0+0.0im

julia> push!(Circuit(), GateCY(), 1, 2)
2-qubit circuit with 1 instructions:
└── CY @ q1, q2
```
"""
struct GateCY <: Gate{2} end

@generated matrix(::GateCY) = ctrl(matrix(GateY()))

inverse(g::GateCY) = g

opname(::Type{GateCY}) = "CY"

@doc raw"""
    struct GateCZ <: Gate{2}

Two qubit Controlled-Z gate.

## Matrix Representation

```math
\operatorname{CZ} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & -1
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

## Examples
```jldoctest
julia> matrix(GateCZ())
4×4 Matrix{Float64}:
 1.0  0.0  0.0   0.0
 0.0  1.0  0.0   0.0
 0.0  0.0  1.0   0.0
 0.0  0.0  0.0  -1.0

julia> push!(Circuit(), GateCZ(), 1, 2)
2-qubit circuit with 1 instructions:
└── CZ @ q1, q2
```
"""
struct GateCZ <: Gate{2} end

@generated matrix(::GateCZ) = ctrl(matrix(GateZ()))

inverse(g::GateCZ) = g

opname(::Type{GateCZ}) = "CZ"

@doc raw"""
    struct GateCH <: Gate{2}

Two qubit Controlled-Hadamard gate.

## Matrix Representation

```math
\operatorname{CH} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & \frac{1}{\sqrt{2}} & \frac{1}{\sqrt{2}} \\
    0 & 0 & \frac{1}{\sqrt{2}} & -\frac{1}{\sqrt{2}}
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

## Examples

```jldoctest
julia> matrix(GateCH())
4×4 Matrix{Float64}:
 1.0  0.0  0.0        0.0
 0.0  1.0  0.0        0.0
 0.0  0.0  0.707107   0.707107
 0.0  0.0  0.707107  -0.707107

julia> push!(Circuit(), GateCH(), 1, 2)
2-qubit circuit with 1 instructions:
└── CH @ q1, q2
```
"""
struct GateCH <: Gate{2} end

@generated matrix(::GateCH) = ctrl(matrix(GateH()))

inverse(g::GateCH) = g

opname(::Type{GateCH}) = "CH"

@doc raw"""
    struct GateSWAP <: Gate{2}

Two qubit SWAP gate.

See also [`GateISWAP`](@ref)

## Matrix Representation

```math
\operatorname{SWAP} = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 0 & 1
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateSWAP())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  0.0  1.0

julia> push!(Circuit(), GateSWAP(), 1, 2)
2-qubit circuit with 1 instructions:
└── SWAP @ q1, q2
```
"""
struct GateSWAP <: Gate{2} end

@generated matrix(::GateSWAP) = Float64[1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1]

inverse(g::GateSWAP) = g

opname(::Type{GateSWAP}) = "SWAP"

@doc raw"""
    struct GateISWAP <: Gate{2}

Two qubit ISWAP gate.

See also [`GateISWAPDG`](@ref), [`GateSWAP`](@ref).

## Matrix Representation

```math
\operatorname{ISWAP} = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & i & 0 \\
    0 & i & 0 & 0 \\
    0 & 0 & 0 & 1
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateISWAP())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+1.0im  0.0+0.0im
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im

julia> push!(Circuit(), GateISWAP(), 1, 2)
2-qubit circuit with 1 instructions:
└── ISWAP @ q1, q2
```
"""
struct GateISWAP <: Gate{2} end

@generated matrix(::GateISWAP) = Complex{Float64}[1 0 0 0; 0 0 im 0; 0 im 0 0; 0 0 0 1]

inverse(::GateISWAP) = GateISWAPDG()

opname(::Type{GateISWAP}) = "ISWAP"

@doc raw"""
    struct GateISWAPDG <: Gate{2}

Two qubit ISWAP-dagger gate (conjugate transpose of ISWAP)

See also [`GateISWAP`](@ref), [`GateSWAP`](@ref)

## Matrix Representation

```math
\operatorname{ISWAP}^\dagger = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & -i & 0 \\
    0 & -i & 0 & 0 \\
    0 & 0 & 0 & 1
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateISWAPDG())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0-1.0im  0.0+0.0im
 0.0+0.0im  0.0-1.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im

julia> push!(Circuit(), GateISWAPDG(), 1, 2)
2-qubit circuit with 1 instructions:
└── ISWAPDG @ q1, q2
```
"""
struct GateISWAPDG <: Gate{2} end

@generated matrix(::GateISWAPDG) = Complex{Float64}[1 0 0 0; 0 0 -im 0; 0 -im 0 0; 0 0 0 1]

inverse(::GateISWAPDG) = GateISWAP()

opname(::Type{GateISWAPDG}) = "ISWAPDG"


@doc raw"""
    struct GateCS <: Gate{2}

Two qubit Controlled-S gate.

## Matrix Representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & i
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateCS())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im

julia> push!(Circuit(), GateCS(), 1, 2)
2-qubit circuit with 1 instructions:
└── CS @ q1, q2
```
"""
struct GateCS <: Gate{2} end

@generated matrix(::GateCS) = ctrl(matrix(GateS()))

inverse(::GateCS) = GateCSDG()

opname(::Type{GateCS}) = "CS"

@doc raw"""
    struct GateCSDG <: Gate{2}

Two qubit CS-dagger gate.

## Matrix Representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & i
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateCSDG())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0-1.0im

julia> push!(Circuit(), GateCSDG(), 1, 2)
2-qubit circuit with 1 instructions:
└── CSDG @ q1, q2
```
"""
struct GateCSDG <: Gate{2} end

@generated matrix(::GateCSDG) = ctrl(matrix(GateSDG()))

inverse(::GateCSDG) = GateCS()

opname(::Type{GateCSDG}) = "CSDG"

@doc raw"""
    struct GateCSX <: Gate{2}

Two qubit Controlled-SX gate. (Control on second qubit)

## Matrix Representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & \frac{1+i}{\sqrt{2}} & 0 & \frac{1-i}{\sqrt{2}} \\
    0 & 0 & 1 & 0 \\
    0 & \frac{1-i}{\sqrt{2}} & 0 & \frac{1+i}{\sqrt{2}}
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateCSX())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.5+0.5im  0.0+0.0im  0.5-0.5im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.5-0.5im  0.0+0.0im  0.5+0.5im

julia> push!(Circuit(), GateCSX(), 1, 2)
2-qubit circuit with 1 instructions:
└── CSX @ q1, q2
```
"""
struct GateCSX <: Gate{2} end

@generated matrix(::GateCSX) = ctrl2(matrix(GateSX()))

inverse(::GateCSX) = GateCSXDG()

opname(::Type{GateCSX}) = "CSX"

@doc raw"""
    struct GateCSXDG <: Gate{2}

Two qubit CSX-dagger gate. (Control on second qubit)

## Matrix Representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & \frac{1-i}{\sqrt{2}} & 0 & \frac{1+i}{\sqrt{2}} \\
    0 & 0 & 1 & 0 \\
    0 & \frac{1+i}{\sqrt{2}} & 0 & \frac{1-i}{\sqrt{2}}
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateCSXDG())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.5-0.5im  0.0+0.0im  0.5+0.5im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.5+0.5im  0.0+0.0im  0.5-0.5im

julia> push!(Circuit(), GateCSXDG(), 1, 2)
2-qubit circuit with 1 instructions:
└── CSXDG @ q1, q2
```
"""
struct GateCSXDG <: Gate{2} end

@generated matrix(::GateCSXDG) = ctrl2(matrix(GateSXDG()))

inverse(::GateCSXDG) = GateCSX()

opname(::Type{GateCSXDG}) = "CSXDG"

@doc raw"""
    struct GateECR <: Gate{2}

Two qubit ECR echo gate.

## Matrix Representation

```math
\begin{pmatrix}
    0 & \frac{1}{\sqrt{2}} \ & 0 & \frac{i}{\sqrt{2}} \\ 
    \frac{1}{\sqrt{2}} & 0 & \frac{-i}{\\sqrt{2}} & 0 \\
    0 & \frac{i}{\\sqrt{2}} & 0 & \frac{i}{\sqrt{2}} \\ 
    \frac{-i}{\sqrt{2}} & 0 & \frac{1}{\sqrt{2}}  & 0 
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateCSX())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.5+0.5im  0.0+0.0im  0.5-0.5im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.5-0.5im  0.0+0.0im  0.5+0.5im

julia> push!(Circuit(), GateCSX(), 1, 2)
2-qubit circuit with 1 instructions:
└── CSX @ q1, q2
```
"""
struct GateECR <: Gate{2} end

@generated matrix(::GateECR) = ComplexF64[0 1 0 im; 1 0 -im 0; 0 im 0 1; -im 0 1 0] ./ sqrt(2)

inverse(::GateECR) = GateECR()

opname(::Type{GateECR}) = "ECR"


@doc raw"""
    struct GateDCX <: Gate{2}

Two qubit double-CNOT (Control on first qubit and then second) OR DCX gate.

## Matrix Representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & 0 & 1 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateDCX())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0
 0.0  1.0  0.0  0.0
 0.0  0.0  1.0  0.0

julia> push!(Circuit(), GateDCX(), 1, 2)
2-qubit circuit with 1 instructions:
└── DCX @ q1, q2
```
"""
struct GateDCX <: Gate{2} end

@generated matrix(::GateDCX) = ctrlfs(matrix(GateX()))

inverse(::GateDCX) = GateDCXDG()

opname(::Type{GateDCX}) = "DCX"

@doc raw"""
    struct GateDCXDG <: Gate{2}

Two qubit DCX-dagger gate.


## Matrix Representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & 1 \\
    0 & 1 & 0 & 0
\end{pmatrix}
```

## Examples

```jldoctest
julia> matrix(GateDCXDG())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0
 0.0  0.0  0.0  1.0
 0.0  1.0  0.0  0.0

julia> push!(Circuit(), GateDCXDG(), 1, 2)
2-qubit circuit with 1 instructions:
└── DCXDG @ q1, q2
```
"""
struct GateDCXDG <: Gate{2} end

@generated matrix(::GateDCXDG) = ctrlsf(matrix(GateX()))

inverse(::GateDCXDG) = GateDCX()

opname(::Type{GateDCXDG}) = "DCXDG"
