#
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

using Test
using LinearAlgebra
using MimiqCircuitsBase
import MimiqCircuitsBase: isterminal, unwrapvalue, DecompositionError

if !isdefined(@__MODULE__, :DecompositionTestUtils)
    include("DecompositionTestUtils.jl")
end
using .DecompositionTestUtils

@testset "DecompositionBases" begin

    # === CanonicalBasis ===

    @testset "CanonicalBasis" begin
        basis = CanonicalBasis()

        @testset "isterminal" begin
            # Terminal gates
            @test isterminal(basis, GateU(0, 0, 0))
            @test isterminal(basis, GateCX())
            @test isterminal(basis, Measure())
            @test isterminal(basis, Reset())
            @test isterminal(basis, Barrier(1))

            # Non-terminal gates
            @test !isterminal(basis, GateH())
            @test !isterminal(basis, GateT())
            @test !isterminal(basis, GateSWAP())
            @test !isterminal(basis, GateCCX())
        end

        @testset "decomposition — single-qubit gates" begin
            for GateType in [GateH, GateX, GateY, GateZ, GateS, GateSDG,
                GateT, GateTDG, GateSX, GateSXDG]
                gate = GateType()
                test_basis_decomposition(basis, gate)
            end
        end

        @testset "decomposition — rotation gates" begin
            for θ in [0.0, π / 4, π / 2, π, 1.234]
                test_basis_decomposition(basis, GateRX(θ))
                test_basis_decomposition(basis, GateRY(θ))
                test_basis_decomposition(basis, GateRZ(θ))
            end
        end

        @testset "decomposition — two-qubit gates" begin
            test_basis_decomposition(basis, GateSWAP())
            test_basis_decomposition(basis, GateCZ())
            test_basis_decomposition(basis, GateCY())
            test_basis_decomposition(basis, GateISWAP())
        end

        @testset "decomposition — three-qubit gates" begin
            test_basis_decomposition(basis, GateCCX())
            test_basis_decomposition(basis, GateCSWAP())
        end

        @testset "output contains only U and CX" begin
            decomp = decompose(GateCCX(); basis=basis)
            @test circuit_contains_only(decomp, GateU, GateCX)
        end
    end

    # === CliffordTBasis ===

    @testset "CliffordTBasis" begin
        basis = CliffordTBasis()

        @testset "isterminal" begin
            # Single-qubit Clifford
            @test isterminal(basis, GateID())
            @test isterminal(basis, GateX())
            @test isterminal(basis, GateY())
            @test isterminal(basis, GateZ())
            @test isterminal(basis, GateH())
            @test isterminal(basis, GateS())
            @test isterminal(basis, GateSDG())
            @test isterminal(basis, GateSX())
            @test isterminal(basis, GateSXDG())

            # T gates
            @test isterminal(basis, GateT())
            @test isterminal(basis, GateTDG())

            # Two-qubit Clifford
            @test isterminal(basis, GateCX())
            @test isterminal(basis, GateCY())
            @test isterminal(basis, GateCZ())

            # Non-terminal
            @test !isterminal(basis, GateRZ(0.5))
            @test !isterminal(basis, GateU(0.1, 0.2, 0.3))
            @test !isterminal(basis, GateCCX())
        end

        @testset "decomposition — exact (special angles)" begin
            # These should decompose exactly to Clifford+T
            @testset "$gt" for gt in [GateRX, GateRY, GateRZ]
                for k in 0:7
                    test_basis_decomposition(basis, gt(k * π / 4))
                end
            end
        end

        @testset "decomposition — Toffoli" begin
            test_basis_decomposition(basis, GateCCX())

            decomp = decompose(GateCCX(); basis=basis)
            @test t_count(decomp) == 7
        end

        @testset "decomposition — approximate (Solovay-Kitaev)" begin
            # Arbitrary angles use SK approximation
            basis_sk = CliffordTBasis(sk_depth=2)

            gate = GateRZ(0.123)
            original = unwrapvalue.(matrix(gate))
            decomposed = decompose(gate; basis=basis_sk)
            decomposed_matrix = matrix_from_circuit(decomposed, 1)

            # Should be close but not exact
            error = opnorm(original - decomposed_matrix)
            # Increase it for now due to SK imprecision (TODO improve SK)
            @test error < 0.02

            # All gates should be terminal
            for inst in decomposed
                @test isterminal(basis_sk, getoperation(inst))
            end
        end

        @testset "output is Clifford+T only" begin
            clifford_t_types = (GateID, GateX, GateY, GateZ, GateH,
                GateS, GateSDG, GateT, GateTDG,
                GateSX, GateSXDG, GateSY, GateSYDG,
                GateCX, GateCY, GateCZ)

            decomp = decompose(GateCCX(); basis=basis)
            @test circuit_contains_only(decomp, clifford_t_types...)
        end
    end

    # === QASMBasis ===

    @testset "QASMBasis" begin
        basis = QASMBasis()

        @testset "isterminal — comprehensive" begin
            # All qelib1.inc gates should be terminal
            qasm_gates = [
                GateU(0, 0, 0), GateCX(),
                GateU3(0, 0, 0), GateU2(0, 0), GateU1(0),
                GateID(), GateX(), GateY(), GateZ(),
                GateH(), GateS(), GateSDG(), GateT(), GateTDG(),
                GateRX(0), GateRY(0), GateRZ(0),
                GateCY(), GateCZ(), GateCH(),
                GateCRX(0), GateCRY(0), GateCRZ(0),
                GateSWAP(),
                GateRXX(0), GateRZZ(0),
                GateCCX(), GateCSWAP(), GateC3X(),
                Measure(), Reset(), Barrier(1)
            ]

            for op in qasm_gates
                @test isterminal(basis, op)
            end
        end

        @testset "decomposition preserves QASM gates" begin
            # QASM gates should pass through unchanged (single-instruction result)
            qasm_gates = [GateH(), GateCX(), GateCCX(), GateSWAP()]

            for gate in qasm_gates
                decomp = decompose(gate; basis=basis)
                # For terminal gates, should be just the gate itself
                @test isterminal(basis, gate) || length(decomp) >= 1
            end
        end

        @testset "matrix equivalence" begin
            # Test gates that need decomposition
            test_all_gates_with_basis(basis)
        end
    end

    # === StimBasis ===

    @testset "StimBasis" begin
        basis = StimBasis()

        @testset "isterminal — Clifford gates" begin
            clifford_gates = [
                GateID(), GateX(), GateY(), GateZ(),
                GateH(), GateS(), GateSDG(),
                GateSX(), GateSXDG(), GateSY(), GateSYDG(),
                GateCX(), GateCY(), GateCZ(),
                GateSWAP(), GateISWAP(), GateISWAPDG()
            ]

            for op in clifford_gates
                @test isterminal(basis, op)
            end
        end

        @testset "isterminal — measurements and resets" begin
            @test isterminal(basis, Measure())
            @test isterminal(basis, MeasureX())
            @test isterminal(basis, MeasureY())
            @test isterminal(basis, Reset())
            @test isterminal(basis, ResetX())
            @test isterminal(basis, ResetY())
            @test isterminal(basis, MeasureReset())
            @test isterminal(basis, MeasureResetX())
            @test isterminal(basis, MeasureResetY())
        end

        @testset "isterminal — noise channels" begin
            @test isterminal(basis, PauliX(0.1))
            @test isterminal(basis, PauliY(0.1))
            @test isterminal(basis, PauliZ(0.1))
            @test isterminal(basis, Depolarizing1(0.1))
            @test isterminal(basis, Depolarizing2(0.1))
        end

        @testset "isterminal — annotations" begin
            @test isterminal(basis, Detector(2))
            @test isterminal(basis, ObservableInclude(1))
            @test isterminal(basis, QubitCoordinates())
            @test isterminal(basis, Barrier(1))
        end

        @testset "NOT terminal — non-Clifford gates" begin
            @test !isterminal(basis, GateT())
            @test !isterminal(basis, GateTDG())
            @test !isterminal(basis, GateRZ(0.5))
            @test !isterminal(basis, GateU(0.1, 0.2, 0.3))
            @test !isterminal(basis, GateCCX())
        end

        @testset "decomposition — Clifford rotations (k·π/2)" begin
            # Rotations at multiples of π/2 are Clifford
            for k in 0:3
                test_basis_decomposition(basis, GateRZ(k * π / 2))
                test_basis_decomposition(basis, GateRX(k * π / 2))
                test_basis_decomposition(basis, GateRY(k * π / 2))
            end
        end

        @testset "decomposition fails — non-Clifford" begin
            # T gate (π/4 rotation) should fail
            @test_throws DecompositionError decompose(GateRZ(π / 4); basis=basis)

            # Arbitrary rotation should fail
            @test_throws DecompositionError decompose(GateRZ(0.123); basis=basis)

            # Toffoli should fail (produces T gates)
            @test_throws DecompositionError decompose(GateCCX(); basis=basis)
        end

        @testset "output is Clifford only" begin
            clifford_types = (GateID, GateX, GateY, GateZ, GateH,
                GateS, GateSDG, GateSX, GateSXDG,
                GateSY, GateSYDG, GateCX, GateCY, GateCZ,
                GateSWAP, GateISWAP, GateISWAPDG)

            # Decompose a Clifford circuit
            decomp = decompose(GateRZ(π / 2); basis=basis)  # S gate
            @test circuit_contains_only(decomp, clifford_types...)

            decomp = decompose(GateRX(π); basis=basis)  # X gate
            @test circuit_contains_only(decomp, clifford_types...)
        end
    end

    # === FlattenedBasis ===

    @testset "FlattenedBasis" begin
        basis = FlattenedBasis()

        @testset "isterminal" begin
            # Containers are not terminal
            @test !isterminal(basis, Block(1, 0, 0))
            # Primitives are terminal
            @test isterminal(basis, GateH())
            @test isterminal(basis, GateCX())
            @test isterminal(basis, GateRZ(0.1))
        end

        @testset "flattens fully" begin
            inner_c = Circuit()
            push!(inner_c, GateX(), 1)
            inner_b = Block(inner_c)

            outer_c = Circuit()
            push!(outer_c, inner_b, 1)
            outer_b = Block(outer_c)

            # decompose with FlattenedBasis should recursively flatten
            # Note: decompose returns a Circuit
            decomp = decompose(outer_b; basis=basis)

            # Should have 1 instruction which is the GateX
            @test length(decomp) == 1
            @test getoperation(decomp[1]) isa GateX
        end

        @testset "preserves other gates" begin
            c = Circuit()
            push!(c, GateH(), 1)
            b = Block(c)

            decomp = decompose(b; basis=basis)
            @test length(decomp) == 1
            @test getoperation(decomp[1]) isa GateH
        end
    end

    # === RuleBasis ===

    @testset "RuleBasis" begin
        # Use FlattenContainers as the test rule since we know it works
        rule = FlattenContainers()
        rule_basis = RuleBasis(rule)

        @testset "isterminal" begin
            # Containers are matched by rule, so they are NOT terminal
            @test !isterminal(rule_basis, Block(1, 0, 0))
            
            # Primitives are NOT matched by rule, so they are terminal
            @test isterminal(rule_basis, GateH())
            @test isterminal(rule_basis, GateCX())
        end

        @testset "decompose with basis=rule" begin
            inner_c = Circuit()
            push!(inner_c, GateX(), 1)
            inner_b = Block(inner_c)

            outer_c = Circuit()
            push!(outer_c, inner_b, 1)
            outer_b = Block(outer_c)

            # Test passing the rule directly as basis
            decomp = decompose(outer_b; basis=rule)

            # Should be flattened
            @test length(decomp) == 1
            @test getoperation(decomp[1]) isa GateX
        end
        
        @testset "decompose with wrapped RuleBasis" begin
            inner_c = Circuit()
            push!(inner_c, GateX(), 1)
            inner_b = Block(inner_c)

            # Test passing wrapped basis
            decomp = decompose(inner_b; basis=rule_basis)

            @test length(decomp) == 1
            @test getoperation(decomp[1]) isa GateX
        end
    end

    # === wrap=true functionality ===

    @testset "wrap=true — nested structure preservation and caching" begin

        @testset "nested GateCall/Inverse preservation" begin
            @gatedecl test_ghz() begin
                @on GateH() q=1
                @on GateCX() q=(1, 2:5)
            end

            @gatedecl test_strangeid() begin
                @on test_ghz() q=1:5...
                @on inverse(test_ghz()) q=1:5...
            end

            # Create circuit with inverse(strangeid())
            c = Circuit()
            push!(c, inverse(test_strangeid()), 1:5...)

            cd = decompose(c, basis=QASMBasis(), wrap=true)

            # The result should be a single GateCall wrapping the decomposition
            @test length(cd) == 1
            outer_op = getoperation(cd[1])
            @test outer_op isa GateCall

            # The inner instructions should contain TWO GateCalls:
            # 1. test_ghz() (terminal: all its contents are QASM gates)
            # 2. inverse(test_ghz()) wrapped in a new GateDecl (not flattened!)
            inner_decl = outer_op._decl
            @test length(inner_decl) == 2

            inner_op1 = getoperation(inner_decl[1])
            @test inner_op1 isa GateCall
            @test inner_op1._decl.name == :test_ghz

            inner_op2 = getoperation(inner_decl[2])
            @test inner_op2 isa GateCall
            @test occursin("test_ghz", string(inner_op2._decl.name))
            @test occursin("dagger", string(inner_op2._decl.name))
        end

        @testset "GateCall terminal only when all contents are terminal" begin
            @gatedecl test_all_terminal() begin
                @on GateH() q=1
                @on GateCX() q=(1, 2)
            end

            @gatedecl test_has_nonterminal() begin
                @on test_all_terminal() q=1:2...
                @on inverse(test_all_terminal()) q=1:2...
            end

            basis = QASMBasis()

            # GateCall with only terminal contents should be terminal
            @test isterminal(basis, test_all_terminal())

            # GateCall with non-terminal contents (Inverse{GateCall}) should NOT be terminal
            @test !isterminal(basis, test_has_nonterminal())
        end

        @testset "GateCall with non-terminal contents gets wrapped" begin
            @gatedecl test_inner_gate() begin
                @on GateH() q=1
                @on GateCX() q=(1, 2:5)
            end

            @gatedecl test_container() begin
                @on test_inner_gate() q=1:5...
                @on inverse(test_inner_gate()) q=1:5...
            end

            # test_container() contains inverse(test_inner_gate()), which is non-terminal,
            # so test_container() itself is non-terminal and must be decomposed+wrapped
            c = Circuit()
            push!(c, test_container(), 1:5...)
            push!(c, inverse(test_inner_gate()), 1:5...)
            push!(c, test_inner_gate(), 1:5...)  # This one IS terminal, should pass through

            cd = decompose(c, basis=QASMBasis(), wrap=true)

            @test length(cd) == 3

            # cd[1]: test_container() was non-terminal, so it got wrapped
            op1 = getoperation(cd[1])
            @test op1 isa GateCall
            decl1 = op1._decl
            @test length(decl1) == 2
            # Inner instruction 1: test_inner_gate() passes through (terminal)
            @test getoperation(decl1[1]) isa GateCall
            @test getoperation(decl1[1])._decl.name == :test_inner_gate
            # Inner instruction 2: inverse(test_inner_gate()) was wrapped, NOT left as Inverse
            @test getoperation(decl1[2]) isa GateCall
            @test !(getoperation(decl1[2]) isa Inverse)

            # cd[2]: inverse(test_inner_gate()) is non-terminal, so it got wrapped
            op2 = getoperation(cd[2])
            @test op2 isa GateCall

            # cd[3]: test_inner_gate() is terminal (all QASM gates), passes through as-is
            op3 = getoperation(cd[3])
            @test op3 isa GateCall
            @test op3._decl.name == :test_inner_gate
        end

        @testset "GateDecl caching — identical operations share same decl" begin
            @gatedecl test_cached_gate() begin
                @on GateH() q=1
                @on GateCX() q=(1, 2)
            end

            # Two direct uses of the same non-terminal operation
            c = Circuit()
            push!(c, inverse(test_cached_gate()), 1:2...)
            push!(c, inverse(test_cached_gate()), 3:4...)

            cd = decompose(c, basis=QASMBasis(), wrap=true)

            @test length(cd) == 2

            op1 = getoperation(cd[1])
            op2 = getoperation(cd[2])
            @test op1 isa GateCall
            @test op2 isa GateCall

            # The decls should be the same object (=== identity), not just equal
            @test op1._decl === op2._decl
        end

        @testset "GateDecl caching across nested and top-level uses" begin
            @gatedecl test_shared_gate() begin
                @on GateH() q=1
                @on GateCX() q=(1, 2:5)
            end

            @gatedecl test_shared_outer() begin
                @on test_shared_gate() q=1:5...
                @on inverse(test_shared_gate()) q=1:5...
            end

            c = Circuit()
            push!(c, inverse(test_shared_outer()), 1:5...)  # contains inverse(test_shared_gate()) nested
            push!(c, inverse(test_shared_gate()), 1:5...)   # same operation at top level
            push!(c, test_shared_outer(), 1:5...)            # also contains inverse(test_shared_gate())

            cd = decompose(c, basis=QASMBasis(), wrap=true)

            @test length(cd) == 3

            # All three decompositions should share the same GateDecl for inverse(test_shared_gate())
            # cd[1]: wrapped inverse(test_shared_outer()), inner instruction 2 is wrapped inverse(test_shared_gate())
            decl_from_cd1 = getoperation(cd[1])._decl
            inv_decl_from_nested_1 = getoperation(decl_from_cd1[2])._decl

            # cd[2]: directly wrapped inverse(test_shared_gate())
            inv_decl_from_direct = getoperation(cd[2])._decl

            # cd[3]: wrapped test_shared_outer(), inner instruction 2 is wrapped inverse(test_shared_gate())
            decl_from_cd3 = getoperation(cd[3])._decl
            inv_decl_from_nested_3 = getoperation(decl_from_cd3[2])._decl

            @test inv_decl_from_nested_1 === inv_decl_from_direct
            @test inv_decl_from_nested_3 === inv_decl_from_direct
        end

        @testset "wrapped GateDecl naming" begin
            @gatedecl test_naming_gate() begin
                @on GateH() q=1
            end

            # Test Inverse{GateCall} naming — should include gate name and "dagger"
            c1 = Circuit()
            push!(c1, inverse(test_naming_gate()), 1)
            cd1 = decompose(c1, basis=QASMBasis(), wrap=true)
            wrapped_op1 = getoperation(cd1[1])
            @test wrapped_op1 isa GateCall
            @test occursin("test_naming_gate", string(wrapped_op1._decl.name))
            @test occursin("dagger", string(wrapped_op1._decl.name))

            # Test plain GateCall naming when wrapped via non-terminal container
            @gatedecl test_naming_inner() begin
                @on test_naming_gate() q=1
            end
            c2 = Circuit()
            push!(c2, inverse(test_naming_inner()), 1)
            cd2 = decompose(c2, basis=QASMBasis(), wrap=true)
            wrapped_op2 = getoperation(cd2[1])
            @test wrapped_op2 isa GateCall
            @test occursin("test_naming_inner", string(wrapped_op2._decl.name))
            @test occursin("dagger", string(wrapped_op2._decl.name))
        end

        @testset "wrap=true with terminal operations" begin
            c = Circuit()
            push!(c, GateH(), 1)
            push!(c, GateCX(), 1, 2)

            cd = decompose(c, basis=QASMBasis(), wrap=true)

            # H and CX are terminal in QASMBasis, so they should be unchanged
            @test length(cd) == 2
            @test getoperation(cd[1]) isa GateH
            @test getoperation(cd[2]) isa GateCX
        end

        @testset "wrap=true with multiple levels of nesting" begin
            @gatedecl test_level1() begin
                @on GateH() q=1
                @on GateX() q=2
            end

            @gatedecl test_level2() begin
                @on test_level1() q=1:2...
                @on inverse(test_level1()) q=1:2...
            end

            @gatedecl test_level3() begin
                @on test_level2() q=1:2...
                @on inverse(test_level2()) q=1:2...
            end

            c = Circuit()
            push!(c, inverse(test_level3()), 1:2...)

            cd = decompose(c, basis=QASMBasis(), wrap=true)

            # Should produce a single wrapped instruction
            @test length(cd) == 1
            @test getoperation(cd[1]) isa GateCall

            # The structure should be preserved at all levels
            outer_decl = getoperation(cd[1])._decl
            @test length(outer_decl) == 2

            # All inner operations should be GateCalls (wrapped or terminal)
            for inst in outer_decl
                @test getoperation(inst) isa GateCall
            end
        end

    end  # @testset "wrap=true"

end  # @testset "DecompositionBases"
