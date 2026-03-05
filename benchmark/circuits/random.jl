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

# ============== #
# RANDOM CIRCUIT #
# ============== #

# Cache gates by qubit count to avoid repeated filtering
const _GATES_BY_QUBITS = let
    gates = Dict{Int,Vector{Type}}()
    for G in MimiqCircuitsBase.GATES
        # Skip non-computational/uninvertible gates for random circuits
        (G === Delay || G === Barrier) && continue

        n = numqubits(G)
        push!(get!(gates, n, Type[]), G)
    end
    gates
end

"""
    random_circuit(n_qubits, depth; kwargs...) -> Circuit

Generate a random quantum circuit.

# Arguments
- `n_qubits::Int`: Number of qubits
- `depth::Int`: Number of circuit layers

# Keywords
- `rng::AbstractRNG=Random.GLOBAL_RNG`: Random number generator
- `max_operands::Int=3`: Maximum gate size (1-4)
- `weights::NTuple{4,Float64}=(0.4, 0.4, 0.15, 0.05)`: Probability weights for 1,2,3,4-qubit gates
- `gate_filter=Returns(true)`: Predicate to filter gate types
- `measure::Bool=false`: Include measurement operations
- `reset::Bool=false`: Include reset operations

# Examples
```julia
# Basic random circuit
c = random_circuit(10, 20)

# Clifford-only circuit
c = random_circuit(10, 20; gate_filter=g -> g in CLIFFORD_GATES)

# With measurements
c = random_circuit(10, 20; measure=true)
```
"""
function random_circuit(
    n_qubits::Int,
    depth::Int;
    rng::AbstractRNG=Random.GLOBAL_RNG,
    max_operands::Int=3,
    weights::NTuple{4,Float64}=(0.4, 0.4, 0.15, 0.05),
    gate_filter=Returns(true),
    measure::Bool=false,
    reset::Bool=false
)
    # Validate inputs
    n_qubits > 0 || throw(ArgumentError("n_qubits must be positive"))
    depth > 0 || throw(ArgumentError("depth must be positive"))
    1 <= max_operands <= 4 || throw(ArgumentError("max_operands must be in 1:4"))

    # Clamp max_operands to available qubits
    max_operands = min(max_operands, n_qubits)

    # Build gate pools (filtered and grouped by qubit count)
    gates = _build_gate_pools(gate_filter, max_operands, measure, reset)

    # Normalize weights for available operand sizes
    norm_weights = _normalize_weights(weights, max_operands, gates)

    c = Circuit()

    # Reusable buffer for qubit permutation
    qubit_perm = collect(1:n_qubits)

    for _ in 1:depth
        _add_random_layer!(c, n_qubits, gates, norm_weights, qubit_perm, rng)
    end

    return c
end

# Build filtered gate pools indexed by qubit count
function _build_gate_pools(gate_filter, max_operands::Int, measure::Bool, reset::Bool)
    pools = Dict{Int,Vector{Type}}()

    # Standard gates
    for (n, gate_types) in _GATES_BY_QUBITS
        n > max_operands && continue
        filtered = filter(gate_filter, gate_types)
        isempty(filtered) || (pools[n] = filtered)
    end

    # Add measurement operations
    if measure
        push!(get!(pools, 1, Type[]), MeasureX, MeasureY, MeasureZ)
        if max_operands >= 2
            push!(get!(pools, 2, Type[]), MeasureXX, MeasureYY, MeasureZZ)
        end
    end

    # Add reset operations  
    if reset
        push!(get!(pools, 1, Type[]), ResetX, ResetY, ResetZ)
    end

    return pools
end

# Normalize weights to valid operand sizes only
function _normalize_weights(weights::NTuple{4,Float64}, max_operands::Int, gates::Dict)
    w = zeros(4)
    for i in 1:max_operands
        haskey(gates, i) && (w[i] = weights[i])
    end
    total = sum(w)
    total > 0 || error("No gates available for given constraints")
    return ntuple(i -> w[i] / total, 4)
end

# Add one layer of random gates covering all qubits
function _add_random_layer!(
    c::Circuit,
    n_qubits::Int,
    gates::Dict{Int,Vector{Type}},
    weights::NTuple{4,Float64},
    qubit_perm::Vector{Int},
    rng::AbstractRNG
)
    # Random qubit ordering for this layer
    shuffle!(rng, qubit_perm)

    pos = 1      # Current position in qubit_perm
    bit_idx = 1  # Current classical bit index

    while pos <= n_qubits
        remaining = n_qubits - pos + 1

        # Sample operand size (respecting remaining qubits)
        op_size = _sample_operand_size(rng, weights, remaining, gates)

        # Get random gate of this size
        gate_type = rand(rng, gates[op_size])
        gate = _instantiate_gate(gate_type, rng)

        # Target qubits from permutation
        targets = ntuple(i -> qubit_perm[pos+i-1], op_size)

        # Classical bits for measurements
        n_bits = numbits(gate)
        bits = n_bits > 0 ? ntuple(i -> bit_idx + i - 1, n_bits) : ()

        push!(c, gate, targets..., bits...)

        pos += op_size
        bit_idx += n_bits
    end
end

# Weighted random selection of operand size
function _sample_operand_size(
    rng::AbstractRNG,
    weights::NTuple{4,Float64},
    max_size::Int,
    gates::Dict{Int,Vector{Type}}
)
    # Compute cumulative weights for valid sizes
    cumsum = 0.0
    r = rand(rng)

    for size in 1:min(max_size, 4)
        haskey(gates, size) || continue
        cumsum += weights[size]
        r < cumsum && return size
    end

    # Fallback to largest valid size (numerical edge case)
    for size in min(max_size, 4):-1:1
        haskey(gates, size) && return size
    end

    return 1
end

# Instantiate gate with random parameters
function _instantiate_gate(::Type{G}, rng::AbstractRNG) where {G}
    np = numparams(G)
    np == 0 && return G()

    # Random parameters in [0, 2π)
    params = ntuple(_ -> rand(rng) * 2π, np)
    return G(params...)
end

# Specialization for gates that need specific parameter ranges
function _instantiate_gate(::Type{GateU}, rng::AbstractRNG)
    GateU(rand(rng) * π, rand(rng) * 2π, rand(rng) * 2π)
end

function _instantiate_gate(::Type{GateU2}, rng::AbstractRNG)
    GateU2(rand(rng) * 2π, rand(rng) * 2π)
end

"""
    random_clifford_circuit(n_qubits, depth; rng=Random.default_rng()) -> Circuit

Generate a random Clifford circuit (efficiently classically simulable).

Uses only Clifford gates: H, S, S†, X, Y, Z, CNOT, CY, CZ, SWAP.
"""
function random_clifford_circuit(
    n_qubits::Int,
    depth::Int;
    rng::AbstractRNG=Random.GLOBAL_RNG,
    weights::NTuple{2,Float64}=(0.5, 0.5)
)
    random_circuit(n_qubits, depth, gate_filter=x -> x isa GateH || x isa GateS || x isa GateSX || x isa GateCX, rng=rng, weights=weights)
end
