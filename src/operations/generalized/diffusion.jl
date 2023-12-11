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
    Diffusion(n)
    Diffusion() # lazy

Grover's diffusion operator.

It implements the unitary transformation.

```math
H^{\otimes n} (1-2\bra{0^n}\ket{0^n}) H^{\otimes n}
```

## Examples

```jldoctests
julia> c = push!(Circuit(), Diffusion(10), 1:10...)
10-qubit circuit with 1 instructions:
└── Diffusion @ q[1:10]

julia> push!(c, inverse(Diffusion(10)), 1:10...)
10-qubit circuit with 2 instructions:
├── Diffusion @ q[1:10]
└── Diffusion† @ q[1:10]
```

```jldoctests
julia> decompose(Diffusion(4))
4-qubit circuit with 9 instructions:
├── RY(π/2) @ q[1]
├── RY(π/2) @ q[2]
├── RY(π/2) @ q[3]
├── RY(π/2) @ q[4]
├── C₃Z @ q[1:3], q[4]
├── RY(π/2) @ q[1]
├── RY(π/2) @ q[2]
├── RY(π/2) @ q[3]
└── RY(π/2) @ q[4]

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

function decompose!(circ::Circuit, ::Diffusion{N}, qubits, _) where {N}
    push!(circ, GateRY(pi / 2), qubits)
    push!(circ, control(N - 1, GateZ()), qubits...)
    push!(circ, GateRY(pi / 2), qubits)
    return circ
end
