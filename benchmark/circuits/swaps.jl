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

# ============ #
# SWAP NETWORK #
# ============ #

"""
    swap_network_circuit(n_qubits, interaction_gate=GateCZ())

SWAP network that enables all-to-all connectivity on linear nearest-neighbor.
After `n-1` layers, every pair of qubits has interacted once.

Structure: Odd-even transposition sort pattern.

Key features: SWAP-heavy, used for connectivity mapping.
"""
function swap_network_circuit(n_qubits::Int; interaction_gate=GateCZ(), rng=Random.GLOBAL_RNG)
    c = Circuit()
    
    for layer in 1:(n_qubits-1)
        # Determine which pairs interact this layer
        if layer % 2 == 1
            # Odd layer: pairs (1,2), (3,4), (5,6), ...
            pairs = [(i, i+1) for i in 1:2:(n_qubits-1)]
        else
            # Even layer: pairs (2,3), (4,5), (6,7), ...
            pairs = [(i, i+1) for i in 2:2:(n_qubits-1)]
        end
        
        for (i, j) in pairs
            # Single-qubit gates before interaction
            push!(c, GateRY(rand(rng) * 2π), i)
            push!(c, GateRY(rand(rng) * 2π), j)
            
            # Interaction
            push!(c, interaction_gate, i, j)
            
            # SWAP to permute
            push!(c, GateSWAP(), i, j)
        end
    end
    
    return c
end

# ====================== #
# FERMIONIC SWAP NETWORK #
# ====================== #

"""
    fermionic_swap_circuit(n_qubits, n_layers; rng=Random.GLOBAL_RNG)

Fermionic simulation circuit using Givens rotations.
Models particle-conserving operations common in quantum chemistry.

Key features: Particle-number conserving gates (fSWAP-like).
"""
function fermionic_swap_circuit(n_qubits::Int, n_layers::Int; rng=Random.GLOBAL_RNG)
    c = Circuit()
    
    for layer in 1:n_layers
        # Givens rotations on neighboring pairs
        for parity in 0:1
            for i in (1+parity):2:(n_qubits-1)
                θ = rand(rng) * π
                ϕ = rand(rng) * 2π
                
                # Particle-conserving gate: 
                # Preserves |00⟩ and |11⟩, rotates in |01⟩, |10⟩ subspace
                # Implemented as: 
                # RZ(ϕ) ⊗ I, then fSWAP-like structure
                push!(c, GateRZ(ϕ), i)

                # Givens rotation in 01/10 subspace
                # |01⟩ → cos(θ)|01⟩ + sin(θ)|10⟩
                # |10⟩ → -sin(θ)|01⟩ + cos(θ)|10⟩
                push!(c, GateCX(), i+1, i)
                push!(c, GateCRY(2θ), i, i+1)
                push!(c, GateCX(), i+1, i)
            end
        end
    end
    
    return c
end
