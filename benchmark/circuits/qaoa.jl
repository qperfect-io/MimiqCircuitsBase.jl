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

# ===================================================== #
# QAOA CIRCUIT (Alternating problem/mixer Hamiltonians) #
# ===================================================== #

@doc raw"""
    qaoa_maxcut_circuit(n_qubits, edges, p; gammas=nothing, betas=nothing)

QAOA circuit for MaxCut on a graph defined by `edges`.

Structure:

```math
    \ket{+}^n \rightarrow \left[\mathrm{e}^{-iγ_k H_C} \mathrm{e}^{-iβ_k H_M}\right]^p
```

Where 

- ``H_C = \sum_{(i,j)\in E} \frac{1 - Z_i Z_j}{2}`` (cost)
- ``H_M = \sum_i X_i`` (mixer)

Key features: Problem-dependent structure, ZZ interactions, X rotations.
"""
function qaoa_maxcut_circuit(n_qubits::Int, edges::Vector{Tuple{Int,Int}}, p::Int;
    gammas::Union{Nothing,AbstractVector}=nothing,
    betas::Union{Nothing,AbstractVector}=nothing,
    rng=Random.GLOBAL_RNG)
    c = Circuit()

    # Default random parameters
    if gammas === nothing
        gammas = rand(rng, p) .* π
    end
    if betas === nothing
        betas = rand(rng, p) .* π
    end

    # Initial state: |+⟩^n
    push!(c, GateH(), 1:n_qubits)

    # p layers of QAOA
    for k in 1:p
        γ = gammas[k]
        β = betas[k]

        # Cost unitary: exp(-iγ H_C)
        # For MaxCut: exp(-iγ(1-ZZ)/2) = exp(-iγ/2) exp(iγ ZZ/2)
        # ZZ interaction via: CX - RZ(2γ) - CX
        for (i, j) in edges
            push!(c, GateCX(), i, j)
            push!(c, GateRZ(γ), j)
            push!(c, GateCX(), i, j)
        end

        # Mixer unitary: exp(-iβ H_M) = Π_i exp(-iβ X_i) = Π_i RX(2β)
        for q in 1:n_qubits
            push!(c, GateRX(2β), q)
        end
    end

    return c
end

# Convenience for complete/random graphs
function qaoa_complete_graph(n_qubits::Int, p::Int; kwargs...)
    edges = [(i, j) for i in 1:n_qubits for j in (i+1):n_qubits]
    qaoa_maxcut_circuit(n_qubits, edges, p; kwargs...)
end

function qaoa_random_graph(n_qubits::Int, edge_prob::Float64, p::Int;
    rng=Random.GLOBAL_RNG, kwargs...)
    edges = [(i, j) for i in 1:n_qubits for j in (i+1):n_qubits if rand(rng) < edge_prob]
    qaoa_maxcut_circuit(n_qubits, edges, p; rng=rng, kwargs...)
end
