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
    struct GateCU <: ParametricGate{2}

Two qubit generic unitary gate, equivalent to the qiskit CUGate
`https://qiskit.org/documentation/stubs/qiskit.circuit.library.CUGate.html`

# Arguments

- `θ::Float64`: Euler angle 1 in radians
- `ϕ::Float64`: Euler angle 2 in radians
- `λ::Float64`: Euler angle 3 in radians
- `γ::Float64`: Global phase of the U gate

# Matrix Representation

```math
\operatorname{CU}(\theta,\phi,\lambda,\gamma) =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & e^{i\gamma}\cos\frac{\theta}{2} & -e^{i(\gamma+\lambda)}\sin\frac{\theta}{2} \\
    0 & 0 & e^{i(\gamma+\phi)}\sin\frac{\theta}{2} & e^{i(\gamma+\phi+\lambda)}\cos\frac{\theta}{2}
\end{pmatrix}
```

By convention we refer to the first qubit as the control qubit and the second qubit as the target.

# Examples

```jldoctest
julia> matrix(GateCU(pi/3, pi/3, pi/3, 0))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im             0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im             0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.866025+0.0im           -0.25-0.433013im
 0.0+0.0im  0.0+0.0im      0.25+0.433013im  -0.433013+0.75im

julia> push!(Circuit(), GateCU(pi/3, pi/3, pi/3, 0), 1, 2)
2-qubit circuit with 1 gates:
└── CU(θ=π⋅0.3333..., ϕ=π⋅0.3333..., λ=π⋅0.3333..., γ=π⋅0.0) @ q1, q2
```
"""
struct GateCU <: ParametricGate{2}
    θ::Float64
    ϕ::Float64
    λ::Float64
    γ::Float64
    U::Matrix{ComplexF64}
    a::ComplexF64
    b::ComplexF64
    c::ComplexF64
    d::ComplexF64

    function GateCU(θ, ϕ, λ, γ, U)
        if size(U, 1) != 4 || size(U, 2) != 4
            throw(ArgumentError("Wrong matrix dimension for parametric gate"))
        end
        new(θ, ϕ, λ, γ, U, U[11], U[12], U[15], U[16])
    end
end

GateCU(θ, ϕ, λ, γ) = GateCU(θ, ϕ, λ, γ, ctrl(umatrix(θ, ϕ, λ, γ)))

inverse(g::GateCU) = GateCU(-g.θ, -g.λ, -g.ϕ, -g.γ)

numparams(::Type{GateCU}) = 4

opname(::Type{GateCU}) = "CU"

parnames(::Type{GateCU}) = (:θ, :ϕ, :λ, :γ)

