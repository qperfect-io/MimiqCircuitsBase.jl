#
# Copyright © 2025-2026 QPerfect. All Rights Reserved.
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

# ============================================== #
# INSTANTANEOUS QUANTUM POLYNOMIAL (IQP) CIRCUIT #
# ============================================== #

@doc raw"""
    iqp_circuit(n_qubits, edges; angles=nothing, rng=Random.GLOBAL_RNG)

IQP circuit: ``H^{\otimes n}`` - Diagonal gates - ``H^{\otimes n}``

Used in quantum advantage arguments. All gates are diagonal in Z basis.

Key features: Commuting gate structure, diagonal unitaries only.
"""
function iqp_circuit(n_qubits::Int, edges::Vector{Tuple{Int,Int}};
    angles::Union{Nothing,AbstractVector}=nothing,
    rng=Random.GLOBAL_RNG)
    c = Circuit()

    # Default angles
    if angles === nothing
        angles = rand(rng, length(edges)) .* 2π
    end

    # Initial Hadamards
    push!(c, GateH(), 1:n_qubits)

    # Diagonal layer: T gates and CZ gates
    for q in 1:n_qubits
        push!(c, GateT(), q)
    end

    for (idx, (i, j)) in enumerate(edges)
        # Controlled-phase with angle
        angle = idx <= length(angles) ? angles[idx] : π
        push!(c, GateCP(angle), i, j)
    end

    # Final Hadamards
    push!(c, GateH(), 1:n_qubits)

    return c
end

function iqp_random_circuit(n_qubits::Int; rng=Random.GLOBAL_RNG)
    perm = randperm(rng, n_qubits)
    edges = [(perm[i], perm[i+1]) for i in 1:(n_qubits-1)]
    return iqp_circuit(n_qubits, edges, rng=rng)
end
