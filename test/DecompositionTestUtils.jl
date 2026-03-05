
module DecompositionTestUtils

using Test
using LinearAlgebra
using MimiqCircuitsBase

import MimiqCircuitsBase:
    matches,
    isterminal,
    unwrapvalue,
    RewriteRule,
    DecompositionBasis

export matrices_equivalent, random_gate, special_angle_gate, clifford_angle_gate
export test_rewrite_rule_matrix, test_basis_decomposition, test_basis_terminality, matrix_from_circuit
export test_rewrite_matches, test_basis_terminal
export test_all_gates_with_rule, test_all_gates_with_basis
export count_gate_type, count_gate_types, t_count, cnot_count, circuit_contains_only

# === Matrix Comparison Utilities ===

"""
    matrices_equivalent(A, B; atol=1e-10) -> Bool

Check if two unitary matrices are equivalent up to a global phase.

Two unitaries U and V are equivalent if U = e^{iθ} V for some θ.
"""
function matrices_equivalent(A::AbstractMatrix, B::AbstractMatrix; atol::Real=1e-10)
    size(A) != size(B) && return false

    # Find first non-zero element to extract phase
    for i in eachindex(A)
        if abs(A[i]) > atol && abs(B[i]) > atol
            phase = A[i] / B[i]
            return isapprox(A, phase * B; atol=atol)
        end
    end

    # Both matrices are essentially zero
    return isapprox(A, B; atol=atol)
end

"""
    matrix_from_circuit(circuit, num_qubits) -> Matrix

Compute the unitary matrix of a circuit.
Handles empty circuits by returning Identity of appropriate size.
"""
function matrix_from_circuit(circuit, num_qubits)
    if isempty(circuit)
        dim = 2^num_qubits
        return Matrix{ComplexF64}(I, dim, dim)
    end

    nq_circuit = numqubits(circuit)
    if nq_circuit > num_qubits
        error("num_qubits ($num_qubits) is smaller than circuit's qubit count ($nq_circuit)")
    end

    m = unwrapvalue.(matrix(circuit))

    if nq_circuit < num_qubits
        # Pad the circuit matrix with the identity matrix on the higher qubits
        # TODO: check convention (little-endian vs big-endian)
        dim_diff = 2^(num_qubits - nq_circuit)
        m = kron(Matrix{ComplexF64}(I, dim_diff, dim_diff), m)
    end

    return m
end

# === Gate Generation Utilities ===

"""
    random_gate(GateType) -> gate

Create a gate with random parameters.
"""
function random_gate(GateType)
    nparams = numparams(GateType)
    if nparams == 0
        return GateType()
    else
        # Use random angles in [0, 2π)
        params = 2π .* rand(nparams)
        return GateType(params...)
    end
end

"""
    special_angle_gate(GateType, k::Int) -> gate

Create a rotation gate with angle k·π/4.

Only works for gates with a single angle parameter (RX, RY, RZ, P, etc.).
"""
function special_angle_gate(GateType, k::Int)
    @assert numparams(GateType) == 1 "special_angle_gate only works for single-parameter gates"
    return GateType(k * π / 4)
end

"""
    clifford_angle_gate(GateType, k::Int) -> gate

Create a rotation gate with angle k·π/2 (Clifford angles).
"""
function clifford_angle_gate(GateType, k::Int)
    @assert numparams(GateType) == 1 "clifford_angle_gate only works for single-parameter gates"
    return GateType(k * π / 2)
end

# ===Decomposition Testing Utilities ===

"""
    test_rewrite_rule_matrix(rule::RewriteRule, gate; atol=1e-10)

Test that a rewrite rule produces a matrix-equivalent decomposition.

Verifies that `decompose_step(gate; rule=rule)` produces a circuit
implementing the same unitary as `gate`.
"""
function test_rewrite_rule_matrix(rule::RewriteRule, gate; atol::Real=1e-10)
    if !matches(rule, gate)
        return  # Skip gates not handled by this rule
    end

    nq = numqubits(gate)
    nq > 4 && error("Cannot test matrices for gates with more than 4 qubits")

    original_matrix = unwrapvalue.(matrix(gate))
    decomposed = decompose_step(gate; rule=rule)
    decomposed_matrix = matrix_from_circuit(decomposed, nq)

    @test matrices_equivalent(original_matrix, decomposed_matrix; atol=atol)
end

"""
    test_basis_decomposition(basis::DecompositionBasis, gate; atol=1e-10)

Test that a decomposition basis produces a valid decomposition.

Verifies:
1. The decomposed circuit is matrix-equivalent to the original gate
2. All operations in the result are terminal for the basis
"""
function test_basis_decomposition(basis::DecompositionBasis, gate; atol::Real=1e-10)
    nq = numqubits(gate)
    nq > 4 && error("Cannot test matrices for gates with more than 4 qubits")

    original_matrix = unwrapvalue.(matrix(gate))
    decomposed = decompose(gate; basis=basis)
    decomposed_matrix = matrix_from_circuit(decomposed, nq)

    # Check matrix equivalence
    @test matrices_equivalent(original_matrix, decomposed_matrix; atol=atol)

    # Check all operations are terminal
    for inst in decomposed
        op = getoperation(inst)
        @test isterminal(basis, op)
    end
end

"""
    test_basis_terminality(basis::DecompositionBasis, gate)

Test that decomposition produces only terminal operations (no matrix check).

Useful for operations without well-defined matrices (noise, measurements, etc.).
"""
function test_basis_terminality(basis::DecompositionBasis, gate)
    decomposed = decompose(gate; basis=basis)

    for inst in decomposed
        op = getoperation(inst)
        @test isterminal(basis, op)
    end
end

"""
    test_rewrite_matches(rule::RewriteRule, gates_should_match, gates_should_not_match)

Test that a rewrite rule correctly identifies which gates it handles.
"""
function test_rewrite_matches(rule::RewriteRule, gates_should_match, gates_should_not_match)
    for gate in gates_should_match
        @test matches(rule, gate)
    end
    for gate in gates_should_not_match
        @test !matches(rule, gate)
    end
end

"""
    test_basis_terminal(basis::DecompositionBasis, ops_should_be_terminal, ops_should_not_be_terminal)

Test that a basis correctly identifies terminal operations.
"""
function test_basis_terminal(basis::DecompositionBasis, ops_should_be_terminal, ops_should_not_be_terminal)
    for op in ops_should_be_terminal
        @test isterminal(basis, op)
    end
    for op in ops_should_not_be_terminal
        @test !isterminal(basis, op)
    end
end

# === Batch Testing Utilities ===

"""
    test_all_gates_with_rule(rule::RewriteRule; gate_types=MimiqCircuitsBase.GATES, atol=1e-10)

Test a rewrite rule against all gate types it matches.
"""
function test_all_gates_with_rule(rule::RewriteRule; gate_types=MimiqCircuitsBase.GATES, atol::Real=1e-10)
    @testset "$(opname(GateType))" for GateType in gate_types
        gate = random_gate(GateType)

        if !matches(rule, gate)
            @test_skip "Not matched by rule"
            continue
        end

        if numqubits(gate) > 4
            @test_skip "Too many qubits for matrix test"
            continue
        end

        test_rewrite_rule_matrix(rule, gate; atol=atol)
    end
end

"""
    test_all_gates_with_basis(basis::DecompositionBasis; gate_types=MimiqCircuitsBase.GATES, atol=1e-10)

Test a decomposition basis against all gate types.
"""
function test_all_gates_with_basis(basis::DecompositionBasis; gate_types=MimiqCircuitsBase.GATES, atol::Real=1e-10)
    @testset "$(opname(GateType))" for GateType in gate_types
        gate = random_gate(GateType)

        if numqubits(gate) > 4
            @test_skip "Too many qubits for matrix test"
            continue
        end

        # Some gates may not be decomposable (expected to fail)
        try
            test_basis_decomposition(basis, gate; atol=atol)
        catch e
            if e isa MimiqCircuitsBase.DecompositionError
                @test_skip "Cannot decompose $(opname(GateType))"
            else
                rethrow(e)
            end
        end
    end
end

# === Specific Test Helpers ===

"""
    count_gate_type(circuit::Circuit, GateType) -> Int

Count occurrences of a specific gate type in a circuit.
"""
function count_gate_type(circuit::Circuit, GateType)
    count = 0
    for inst in circuit
        if getoperation(inst) isa GateType
            count += 1
        end
    end
    return count
end

"""
    count_gate_types(circuit::Circuit, GateTypes...) -> Int

Count occurrences of any of the specified gate types in a circuit.
"""
function count_gate_types(circuit::Circuit, GateTypes...)
    count = 0
    for inst in circuit
        op = getoperation(inst)
        if any(op isa GT for GT in GateTypes)
            count += 1
        end
    end
    return count
end

"""
    t_count(circuit::Circuit) -> Int

Count the number of T and T† gates in a circuit.
"""
t_count(circuit::Circuit) = count_gate_types(circuit, GateT, GateTDG)

"""
    cnot_count(circuit::Circuit) -> Int

Count the number of CNOT gates in a circuit.
"""
cnot_count(circuit::Circuit) = count_gate_type(circuit, GateCX)

"""
    circuit_contains_only(circuit::Circuit, allowed_types...) -> Bool

Check if a circuit contains only gates from the allowed types.
"""
function circuit_contains_only(circuit::Circuit, allowed_types...)
    for inst in circuit
        op = getoperation(inst)
        if !any(op isa AT for AT in allowed_types)
            return false
        end
    end
    return true
end

end # module
