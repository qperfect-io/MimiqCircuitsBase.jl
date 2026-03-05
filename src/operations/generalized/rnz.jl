#
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
    GateRNZ(n, θ)
    GateRNZ() # lazy

Multi-qubit parity-phase rotation gate along the Z-axis.

## Examples

```jldoctests
julia> using Symbolics; @variables θ
1-element Vector{Num}:
 θ

julia> GateRNZ(4, θ)
RNZ(θ)

julia> matrix(GateRNZ(2, θ))
4×4 Matrix{Complex{Symbolics.Num}}:
 cos((1//2)*θ) + im*sin((1//2)*θ)                           0                                   0                        0
               0                   cos((-1//2)*θ) + im*sin((-1//2)*θ)                           0                        0
               0                                            0          cos((-1//2)*θ) + im*sin((-1//2)*θ)                0
               0                                            0                                   0          cos((1//2)*θ) + im*sin((1//2)*θ)

julia> c = push!(Circuit(), GateRNZ(3, θ), 1, 2, 3)
3-qubit circuit with 1 instructions:
└── RNZ(θ) @ q[1:3]

julia> push!(c, inverse(GateRNZ(3, θ)), 1, 2, 3)
3-qubit circuit with 2 instructions:
├── RNZ(θ) @ q[1:3]
└── RNZ(-θ) @ q[1:3]
"""
struct GateRNZ{N} <: AbstractGate{N}
    θ::Num
end

GateRNZ(n::Int, θ::Union{Number,Num}) = GateRNZ{n}(θ)

opname(::Type{<:GateRNZ}) = "RNZ"

inverse(g::GateRNZ{N}) where {N} = GateRNZ{N}(-g.θ)

_power(g::GateRNZ{N}, pwr) where {N} = GateRNZ{N}(g.θ * pwr)

GateRNZ(n) = LazyExpr(GateRNZ, n, LazyArg())

GateRNZ() = LazyExpr(GateRNZ, LazyArg(), LazyArg())

function _matrix(::Type{GateRNZ{N}}, θ) where {N}
    dim = 1 << N
    T = promote_type(typeof(cis(θ / 2)), ComplexF64)
    mat = Matrix{T}(I, dim, dim)
    for i in 1:dim
        parity = count_ones(i - 1)
        mat[i, i] = cis(-(-1)^parity * θ / 2)
    end
    return mat
end

matches(::CanonicalRewrite, ::GateRNZ) = true

function decompose_step!(circ, ::CanonicalRewrite, g::GateRNZ{N}, qtargets, ctrls, zregs) where {N}
    ancilla = last(qtargets)
    data = qtargets[1:end-1]

    for q in data
        push!(circ, GateCX(), q, ancilla)
    end

    push!(circ, GateRZ(g.θ), ancilla)

    for q in reverse(data)
        push!(circ, GateCX(), q, ancilla)
    end
    return circ
end

