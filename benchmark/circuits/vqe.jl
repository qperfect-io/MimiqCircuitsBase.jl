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

# ================== #
# VARIATIONAL ANSATZ #
# ================== #

"""
    variational_ansatz(n_qubits, n_layers; kwargs...) -> Circuit

Hardware-efficient variational ansatz with rotation and entangling layers.

# Arguments
- `n_qubits::Int`: Number of qubits
- `n_layers::Int`: Number of ansatz layers

# Keywords
- `rng::AbstractRNG=Random.GLOBAL_RNG`: RNG for parameter initialization
- `rotation_gates::Vector=[GateRY, GateRZ]`: Single-qubit rotations per layer
- `entangling_gate::Type=GateCX`: Two-qubit entangling gate
- `entanglement::Symbol=:linear`: Connectivity pattern (:linear, :circular, :full, :pairwise)
- `final_rotation::Bool=true`: Add rotation layer after last entangling layer
- `parameter_values::Union{Nothing,Vector{<:Real}}=nothing`: Fixed parameters (length must match)
"""
function variational_ansatz(
    n_qubits::Int,
    n_layers::Int;
    rng::AbstractRNG=Random.GLOBAL_RNG,
    rotation_gates::Vector{<:Type}=[GateRY, GateRZ],
    entangling_gate::Type=GateCX,
    entanglement::Symbol=:linear,
    final_rotation::Bool=true,
    parameter_values::Union{Nothing,AbstractVector}=nothing
)
    n_qubits > 0 || throw(ArgumentError("n_qubits must be positive"))
    n_layers >= 0 || throw(ArgumentError("n_layers must be non-negative"))
    
    c = Circuit()
    n_rotations = length(rotation_gates)
    param_idx = 1
    
    for layer in 1:n_layers
        # Rotation layer
        param_idx = _add_rotation_layer!(c, n_qubits, rotation_gates, 
                                         parameter_values, param_idx, rng)
        
        # Entangling layer
        _add_entangling_layer!(c, n_qubits, entangling_gate, entanglement)
    end
    
    # Optional final rotation layer
    if final_rotation && n_layers > 0
        _add_rotation_layer!(c, n_qubits, rotation_gates, 
                            parameter_values, param_idx, rng)
    end
    
    return c
end

function _add_rotation_layer!(c, n_qubits, rotation_gates, params, param_idx, rng)
    for q in 1:n_qubits
        for G in rotation_gates
            θ = isnothing(params) ? rand(rng) * 2π : params[param_idx]
            push!(c, G(θ), q)
            param_idx += 1
        end
    end
    return param_idx
end

function _add_entangling_layer!(c, n_qubits, gate, pattern)
    n_qubits < 2 && return
    
    pairs = if pattern == :linear
        [(i, i + 1) for i in 1:(n_qubits - 1)]
    elseif pattern == :circular
        vcat([(i, i + 1) for i in 1:(n_qubits - 1)], [(n_qubits, 1)])
    elseif pattern == :full
        [(i, j) for i in 1:n_qubits for j in (i + 1):n_qubits]
    elseif pattern == :pairwise
        [(2i - 1, 2i) for i in 1:(n_qubits ÷ 2)]
    else
        throw(ArgumentError("Unknown entanglement pattern: $pattern"))
    end
    
    for (q1, q2) in pairs
        push!(c, gate(), q1, q2)
    end
end
