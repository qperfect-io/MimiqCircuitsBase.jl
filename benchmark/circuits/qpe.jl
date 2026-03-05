# ======================================== #
# QUANTUM PHASE ESTIMATION (QPE structure) #
# ======================================== #

"""
    qpe_circuit(n_precision, unitary_qubits, controlled_unitary_adder!)

Quantum Phase Estimation circuit structure.

Uses `n_precision` qubits for phase readout, applies controlled-``U^{2^k}`` gates.

Key features: Inverse QFT structure, controlled powers of unitary.
"""
function qpe_circuit(n_precision::Int; target_qubits::Int=1, rng=Random.GLOBAL_RNG)
    c = Circuit()
    total_qubits = n_precision + target_qubits

    # Initialize precision qubits in |+⟩
    push!(c, GateH(), 1:n_precision)

    # Initialize target in some state (e.g., eigenstate)
    push!(c, GateX(), n_precision + 1)  # Simple |1⟩ state

    # Controlled-``U^{2^k}`` operations
    for k in 0:(n_precision-1)
        control_qubit = n_precision - k  # Reverse order for standard QPE
        power = 2^k

        # Simplified: use controlled rotation as placeholder for U^power
        # In real QPE, this would be the actual controlled unitary
        for _ in 1:power
            push!(c, GateCP(rand(rng) * 2π), control_qubit, n_precision + 1)
        end
    end

    # Inverse QFT on precision qubits
    for j in n_precision:-1:1
        for k in n_precision:-1:(j+1)
            angle = -π / 2^(k - j)
            push!(c, GateCP(angle), k, j)
        end
        push!(c, GateH(), j)
    end

    # Swaps for bit reversal
    for i in 1:(n_precision÷2)
        push!(c, GateSWAP(), i, n_precision - i + 1)
    end

    return c
end
