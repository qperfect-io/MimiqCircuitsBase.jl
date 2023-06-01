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
    struct GateX <: Gate{1}

Single qubit Pauli-X gate.

# Matrix Representation

```math
\operatorname X =
\begin{pmatrix}
    0 & 1 \\
    1 & 0
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateX())
2×2 Matrix{Float64}:
 0.0   1.0
 1.0  -0.0

julia> push!(Circuit(), GateX(), 1)
1-qubit circuit with 1 gates:
└── X @ q1
```
"""
struct GateX <: Gate{1} end

@generated matrix(::GateX) = umatrixpi(1, 0, 1) |> _decomplex

inverse(g::GateX) = g

opname(::Type{GateX}) = "X"

@doc raw"""
    struct GateY <: Gate{1}

Single qubit Pauli-Y gate.

# Matrix Representation

```math
\operatorname Y =
\begin{pmatrix}
    0 & -i \\
    i & 0
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateY())
2×2 Matrix{ComplexF64}:
 0.0+0.0im  -0.0-1.0im
 0.0+1.0im  -0.0+0.0im

julia> push!(Circuit(), GateY(), 1)
1-qubit circuit with 1 gates:
└── Y @ q1
```
"""
struct GateY <: Gate{1} end

@generated matrix(::GateY) = umatrixpi(1, 1 / 2, 1 / 2) |> _decomplex

inverse(g::GateY) = g

opname(::Type{GateY}) = "Y"

@doc raw"""    
    struct GateZ <: Gate{1}

Single qubit Pauli-Z gate.

# Matrix Representation

```math
\operatorname Z =
\begin{pmatrix}
    1 & 0 \\
    0 & -1
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateZ())
2×2 Matrix{Float64}:
 1.0   0.0
 0.0  -1.0

julia> push!(Circuit(), GateZ(), 1)
1-qubit circuit with 1 gates:
└── Z @ q1
```
"""
struct GateZ <: Gate{1} end

@generated matrix(::GateZ) = pmatrixpi(1) |> _decomplex

inverse(g::GateZ) = g

opname(::Type{GateZ}) = "Z"

@doc raw"""
    struct GateH <: Gate{1}

Single qubit Hadamard gate.

# Matrix Representation

```math
\operatorname H = \frac{1}{\sqrt{2}}
\begin{pmatrix}
    1 & 1 \\
    1 & -1
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateH())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107

julia> push!(Circuit(), GateH(), 1)
1-qubit circuit with 1 gates:
└── H @ q1
```
"""
struct GateH <: Gate{1} end

@generated matrix(::GateH) = umatrixpi(1 / 2, 0, 1) |> _decomplex

inverse(g::GateH) = g

opname(::Type{GateH}) = "H"

@doc raw"""
    struct GateS <: Gate{1}

Single qubit S gate (or Phase gate).

See also [`GateSDG`](@ref)

# Matrix Representation

```math
\operatorname S =
\begin{pmatrix}
    1 & 0 \\
    0 & i
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateS())
2×2 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+1.0im

julia> push!(Circuit(), GateS(), 1)
1-qubit circuit with 1 gates:
└── S @ q1
```
"""
struct GateS <: Gate{1} end

@generated matrix(::GateS) = pmatrixpi(1 / 2) |> _decomplex

inverse(::GateS) = GateSDG()

opname(::Type{GateS}) = "S"

@doc raw"""
    struct GateSDG <: Gate{1}

Single qubit S-dagger gate (conjugate transpose of the S gate).

See also [`GateS`](@ref)

# Matrix Representation

```math
\operatorname S^\dagger =
\begin{pmatrix}
    1 & 0 \\
    0 & -i
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateSDG())
2×2 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0-1.0im

julia> push!(Circuit(), GateSDG(), 1)
1-qubit circuit with 1 gates:
└── SDG @ q1
```
"""
struct GateSDG <: Gate{1} end

@generated matrix(::GateSDG) = pmatrixpi(-1 / 2) |> _decomplex

inverse(::GateSDG) = GateS()

opname(::Type{GateSDG}) = "SDG"

@doc raw"""
    struct GateT <: Gate{1}

Single qubit T gate.

See also [`GateTDG`](@ref)

# Matrix Representation

```math
\operatorname T =
\begin{pmatrix}
    1 & 0 \\
    0 & \exp(\frac{i\pi}{4})
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateT())
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107+0.707107im

julia> push!(Circuit(), GateT(), 1)
1-qubit circuit with 1 gates:
└── T @ q1
```
"""
struct GateT <: Gate{1} end

@generated matrix(::GateT) = pmatrixpi(1 / 4) |> _decomplex

inverse(::GateT) = GateTDG()

opname(::Type{GateT}) = "T"

@doc raw"""
    struct GateTDG <: Gate{1}

Single qubit T-dagger gate (conjugate transpose of the T gate).

See also [`GateT`](@ref)

# Matrix Representation

```math
\operatorname T^\dagger =
\begin{pmatrix}
    1 & 0 \\
    0 & \exp(\frac{-i\pi}{4})
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateTDG())
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107-0.707107im

julia> push!(Circuit(), GateTDG(), 1)
1-qubit circuit with 1 gates:
└── TDG @ q1
```
"""
struct GateTDG <: Gate{1} end

@generated matrix(::GateTDG) = pmatrixpi(-1 / 4) |> _decomplex

inverse(::GateTDG) = GateT()

opname(::Type{GateTDG}) = "TDG"

@doc raw"""
    struct GateSX <: Gate{1}

Single qubit √X gate.

See also [`GateSXDG`](@ref), [`GateX`](@ref)

# Matrix Representation

```math
\sqrt{\operatorname{X}} = \frac{1}{2}
\begin{pmatrix}
    1+i & 1-i \\
    1-i & 1+i
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateSX())
2×2 Matrix{ComplexF64}:
 0.5+0.5im  0.5-0.5im
 0.5-0.5im  0.5+0.5im

julia> push!(Circuit(), GateSX(), 1)
1-qubit circuit with 1 gates:
└── SX @ q1
```
"""
struct GateSX <: Gate{1} end

@generated matrix(::GateSX) = gphase(π / 4) * rxmatrix(π / 2) |> _decomplex

inverse(::GateSX) = GateSXDG()

opname(::Type{GateSX}) = "SX"

@doc raw"""
    struct GateSXDG <: Gate{1}

Single qubit √X-dagger gate (conjugate transpose of the √X gate)

See also [`GateSX`](@ref), [`GateX`](@ref)

# Matrix Representation

```math
\sqrt{\operatorname{X}}^\dagger = \frac{1}{2}
\begin{pmatrix}
    1-i & 1+i \\
    1+i & 1-i
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateSXDG())
2×2 Matrix{ComplexF64}:
 0.5-0.5im  0.5+0.5im
 0.5+0.5im  0.5-0.5im

julia> push!(Circuit(), GateSXDG(), 1)
1-qubit circuit with 1 gates:
└── SXDG @ q1
```
"""
struct GateSXDG <: Gate{1} end

@generated matrix(::GateSXDG) = gphase(-π / 4) * rxmatrix(-π / 2) |> _decomplex

inverse(::GateSXDG) = GateSX()

opname(::Type{GateSXDG}) = "SXDG"

@doc raw"""
    struct GateID <: Gate{1}

Single qubit Identity gate

# Matrix Representation

```math
\operatorname{I} =
\begin{pmatrix}
    1 & 0 \\
    0 & 1
\end{pmatrix}
```

# Examples

```jldoctest
julia> matrix(GateID())
2×2 Matrix{Float64}:
 1.0  -0.0
 0.0   1.0

julia> push!(Circuit(), GateID(), 1)
1-qubit circuit with 1 gates:
└── ID @ q1
```
"""
struct GateID <: Gate{1} end

@generated matrix(::GateID) = umatrixpi(0, 0, 0) |> _decomplex

opname(::Type{GateID}) = "ID"

inverse(g::GateID) = g
