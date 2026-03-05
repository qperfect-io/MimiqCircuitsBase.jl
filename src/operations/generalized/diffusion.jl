#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    Diffusion(n)
    Diffusion() # lazy

Grover's diffusion operator.

It implements the unitary transformation.

```math
H^{\otimes n} (1-2\ket{0^n}\bra{0^n}) H^{\otimes n}
```

## Examples

```jldoctests
julia> c = push!(Circuit(), Diffusion(10), 1:10...)
10-qubit circuit with 1 instruction:
└── Diffusion @ q[1:10]

julia> push!(c, inverse(Diffusion(10)), 1:10...)
10-qubit circuit with 2 instructions:
├── Diffusion @ q[1:10]
└── Diffusion† @ q[1:10]
```

```jldoctests
julia> decompose(Diffusion(4))
4-qubit circuit with 71 instructions:
├── U(π/2,0,0) @ q[1]
├── U(π/2,0,0) @ q[2]
├── U(π/2,0,0) @ q[3]
├── U(π/2,0,0) @ q[4]
├── U(0,0,π/4) @ q[3]
├── CX @ q[3], q[4]
├── U(0,0,-1π/4) @ q[4]
├── CX @ q[3], q[4]
├── U(0,0,π/4) @ q[4]
⋮   ⋮
├── U(0,0,π/8) @ q[1]
├── U(0,0,π/8) @ q[4]
├── CX @ q[1], q[4]
├── U(0,0,-1π/8) @ q[4]
├── CX @ q[1], q[4]
├── U(0,0,0) @ q[4]
├── U(-1π/2,0,0) @ q[1]
├── U(-1π/2,0,0) @ q[2]
├── U(-1π/2,0,0) @ q[3]
└── U(-1π/2,0,0) @ q[4]

```
"""
struct Diffusion{N} <: AbstractGate{N}
    function Diffusion{N}() where {N}
        if !(N isa Integer)
            throw(OperationError(Diffusion, "Number of qubits must be an integer."))
        end

        if N < 1
            throw(OperationError(Diffusion, "Number of qubits must be ≥ 1."))
        end

        new{N}()
    end
end

function Diffusion(numqubits::Int)
    Diffusion{numqubits}()
end

function Diffusion()
    LazyExpr(Diffusion, LazyArg())
end

opname(::Type{<:Diffusion}) = "Diffusion"

qregsizes(::Diffusion{N}) where {N} = (N,)

matches(::CanonicalRewrite, ::Diffusion) = true

function decompose_step!(circ, ::CanonicalRewrite, ::Diffusion{N}, qubits, _, _) where {N}
    push!(circ, GateRY(π / 2), qubits)
    push!(circ, control(N - 1, GateZ()), qubits...)
    push!(circ, GateRY(-π / 2), qubits)
    return circ
end
