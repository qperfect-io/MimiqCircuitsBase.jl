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
    GPhase(λ)
    GPhase(numqubits, λ)

Operations that applies a global phase to the targeted qubits.

Applies ``\mathrm{e}^{\imath \lambda} I_N`` where ``I_N`` is ``2^N \times 2^N``
identity matrix.

## Examples

```jldoctests; setup = :(@variables λ)
julia> GPhase(3, λ)
GPhase(λ)

julia> numqubits(GPhase(3, λ))
3

julia> matrix(GPhase(2, π/2))
4×4 Matrix{ComplexF64}:
 0.0+1.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+1.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im

```
"""
struct GPhase{N} <: AbstractGate{N}
    λ::Num

    function GPhase{N}(λ) where {N}
        if !(N isa Integer)
            throw(OperationError(GPhase, "Number of qubits must be an integer."))
        end
        if N < 1
            throw(OperationError(GPhase, "Number of qubits must be ≥ 1."))
        end
        new{N}(λ)
    end
end

function GPhase(numqubits, λ)
    GPhase{numqubits}(λ)
end

GPhase(λ) = (targets...) -> Instruction(GPhase(length(targets...), λ), Tuple(targets), ())

inverse(s::GPhase{N}) where {N} = GPhase(N, -s.λ)

_power(s::GPhase{N}, pwr) where {N} = GPhase(N, s.λ * pwr)

opname(::Type{GPhase{N}}) where {N} = "GPhase"

qregsizes(::GPhase{N}) where {N} = (N,)

function _matrix(::Type{GPhase{N}}, λ) where {N}
    hdim = 2^N
    return cispi(λ / π) * Matrix{ComplexF64}(I, hdim, hdim)
end
