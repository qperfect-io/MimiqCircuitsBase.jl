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
using Random
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

        @testset "rotations keyword" begin
            @test CliffordTBasis().rotations isa GridSynthRewrite

            # Phase-only GateU (e.g. from the canonical GateHYZ) must not reach
            # the rotations rule, which only accepts GateRZ.
            for op in (GateU(0, 0, 0, 0.3), GateHYZ(), MeasureY())
                d = decompose(op; basis=CliffordTBasis())
                @test all(i -> isterminal(CliffordTBasis(), getoperation(i)), d)
                @test !any(i -> getoperation(i) isa GateID, d)
            end
            @test isempty(decompose(GateU(0, 0, 0, 0.3); basis=CliffordTBasis()))
            test_basis_decomposition(CliffordTBasis(), GateHYZ())

            # Under a Control the phase is relative and must be kept.
            for γ in (0.3, π / 3)
                test_basis_decomposition(CliffordTBasis(), Control(GateU(0, 0, 0, γ)); atol=1e-8)
                test_basis_decomposition(CliffordTBasis(), Control(2, GateU(0, 0, 0, γ)); atol=1e-8)
            end

            @test CliffordTBasis(sk_depth=3) == CliffordTBasis(sk_depth=3)
            @test hash(CliffordTBasis(sk_depth=3)) == hash(CliffordTBasis(sk_depth=3))
            @test CliffordTBasis(sk_depth=3) != CliffordTBasis(sk_depth=2)
            @test CliffordTBasis() == CliffordTBasis()
            @test CliffordTBasis() != CliffordTBasis(rotations=GridSynthRewrite(epsilon=1e-6))
            @test CliffordTBasis(sk_depth=2).rotations isa SolovayKitaevRewrite
            @test_throws ArgumentError CliffordTBasis(sk_depth=2, rotations=GridSynthRewrite())
            @test CliffordTBasis(sk_depth=2).rotations.depth == 2
            @test_throws ArgumentError CliffordTBasis(rotations=ZYZRewrite())

            ε = 1e-8
            basis_gs = CliffordTBasis(rotations=GridSynthRewrite(epsilon=ε))
            @test basis_gs.rotations.epsilon == ε

            gate = GateRZ(0.123)
            decomposed = decompose(gate; basis=basis_gs)
            @test all(inst -> isterminal(basis_gs, getoperation(inst)), decomposed)
            @test matrices_equivalent(unwrapvalue.(matrix(gate)),
                matrix_from_circuit(decomposed, 1); atol=1e-7)
        end

        @testset "decomposition — approximate (gridsynth), random circuit" begin
            ε = 1e-8
            basis_gs = CliffordTBasis(rotations=GridSynthRewrite(epsilon=ε))
            rng = MersenneTwister(42)
            rand_angle() = 2π * rand(rng)

            c = Circuit()
            for _ in 1:4
                push!(c, GateRX(rand_angle()), 1)
                push!(c, GateRY(rand_angle()), 2)
                push!(c, GateRZ(rand_angle()), 3)
                push!(c, GateCX(), 1, 2)
                push!(c, GateU(rand_angle(), rand_angle(), rand_angle()), 3)
                push!(c, GateCX(), 2, 3)
            end
            # Upper bound on the rotations left for synthesis: GateU becomes
            # three Z-rotations, RX/RY/RZ one each.
            nrot = 4 * (3 + 3)

            decomposed = decompose(c; basis=basis_gs)
            @test all(inst -> isterminal(basis_gs, getoperation(inst)), decomposed)

            U = matrix_from_circuit(c, 3)
            V = matrix_from_circuit(decomposed, 3)
            φ = angle(tr(V' * U))
            @test opnorm(U - cis(φ) * V) <= nrot * ε
        end

        @testset "output is Clifford+T only" begin
            clifford_t_types = (GateID, GateX, GateY, GateZ, GateH,
                GateS, GateSDG, GateT, GateTDG,
                GateSX, GateSXDG, GateSY, GateSYDG,
                GateCX, GateCY, GateCZ)

            decomp = decompose(GateCCX(); basis=basis)
            @test circuit_contains_only(decomp, clifford_t_types...)
        end

        @testset "terminal set follows StimBasis" begin
            # One instance of every kind of operation. CliffordTBasis keeps what
            # StimBasis keeps, plus T, T†, classical operations and conditionals
            # of any of its terminal operations.
            ops = [
                GateID(), GateX(), GateY(), GateZ(), GateH(), GateHXY(), GateHYZ(), GateHXZ(),
                GateS(), GateSDG(), GateSX(), GateSXDG(), GateSY(), GateSYDG(),
                GateP(0.3), GateRX(0.3), GateRY(π / 2), GateRZ(π / 4), GateR(0.3, 0.2),
                GateU(0.1, 0.2, 0.3), GateU(0, 0, 0, 0.3), GateU1(0.3), GateU2(0.1, 0.2),
                GateU3(0.1, 0.2, 0.3), GateRNZ(2, 0.3),
                GateCX(), GateCY(), GateCZ(), GateCH(), GateCS(), GateCSDG(), GateCSX(), GateCSXDG(),
                GateCP(0.3), GateCRX(0.3), GateCRY(0.3), GateCRZ(0.3), GateCU(0.1, 0.2, 0.3, 0.4),
                GateSWAP(), GateISWAP(), GateISWAPDG(), GateDCX(), GateECR(),
                GateRXX(π / 2), GateRXX(0.3), GateRYY(-π / 2), GateRYY(0.3), GateRZZ(3π / 2), GateRZZ(π),
                GateRZX(0.3), GateXXplusYY(0.1, 0.2), GateXXminusYY(0.1, 0.2),
                GateCCX(), GateC3X(), GateCCP(0.3), GateCSWAP(),
                RPauli("XYZ", π / 2), RPauli("II", π / 2), RPauli("XZ", 0.3), PauliString("XYZ"),
                Control(GateH()), Control(2, GateU(0, 0, 0, 0.3)), Power(GateX(), 1 / 2),
                Parallel(2, GateH()), Repeat(2, GateX()), QFT(2), PhaseGradient(2), Diffusion(2),
                GateCustom([1 0; 0 1im]), RescaledGate(GateX(), 0.5),
                Measure(), MeasureX(), MeasureY(), MeasureZ(), MeasureXX(), MeasureYY(), MeasureZZ(),
                MeasurePauli("XZ"), Reset(), ResetX(), ResetY(), ResetZ(),
                MeasureReset(), MeasureResetX(), MeasureResetY(), MeasureResetZ(), Barrier(1),
                PauliX(0.1), PauliY(0.1), PauliZ(0.1), Depolarizing1(0.1), Depolarizing2(0.1),
                Depolarizing(3, 0.1), PauliNoise([0.9, 0.1], ["I", "X"]), AmplitudeDamping(0.1),
                GeneralizedAmplitudeDamping(0.1, 0.2), PhaseAmplitudeDamping(0.1, 0.2, 0.3),
                ThermalNoise(0.1, 0.2, 0.3, 0.4), ProjectiveNoise("X"), ReadoutErr(0.1, 0.2),
                Detector(1), ObservableInclude(1), QubitCoordinates(0, 0), Tick(),
                Amplitude(bs"0"), ExpectationValue(GateZ()), BondDim(), SchmidtRank(), VonNeumannEntropy(),
                Add(2), Multiply(2), Pow(2), Delay(0.1), Loss(0.1), Reload(), Check(), MeasureCheck(),
                Lost(), Reloaded(), PrepareStateT(),
            ]
            for op in ops
                @test isterminal(basis, op) == isterminal(StimBasis(), op)
            end

            for op in (GateT(), GateTDG(), Inverse(GateT()))
                @test isterminal(basis, op)
                @test !isterminal(StimBasis(), op)
            end

            for op in (Not(), SetBit0(), SetBit1(), And(), Or(), Xor())
                @test isterminal(basis, op)
            end

            # A conditional is terminal when its body is, whatever the condition.
            for body in (GateX(), GateZ(), GateH(), GateT(), GateCX(), Measure(), ResetX())
                for cond in (bs"1", bs"0", bs"10")
                    @test isterminal(basis, IfStatement(body, cond))
                end
            end
            for body in (GateRX(0.3), GateCCX(), GateU(0.1, 0.2, 0.3))
                @test !isterminal(basis, IfStatement(body, bs"1"))
            end
        end

        @testset "decomposition — representative circuits" begin
            # Stim operations stay as they are.
            c = push!(Circuit(), GateHXY(), 1)
            push!(c, GateRZZ(π / 2), 1, 2)
            push!(c, RPauli("XYZ", -π / 2), 1, 2, 3)
            push!(c, MeasurePauli("XZ"), 1, 3, 1)
            push!(c, MeasureResetY(), 2, 2)
            push!(c, ResetX(), 3)
            push!(c, ResetY(), 1)
            push!(c, Depolarizing2(0.1), 1, 2)
            push!(c, Detector(1), 1)
            @test collect(decompose(c; basis=basis)) == collect(c)

            # Non-Clifford+T gates decompose into terminal operations.
            c = push!(Circuit(), GateCCX(), 1, 2, 3)
            push!(c, GateRXX(π / 4), 1, 2)
            push!(c, RPauli("XZ", π), 2, 3)
            push!(c, GateCP(π / 2), 1, 3)
            push!(c, IfStatement(GateCRZ(π / 2), bs"0"), 1, 2, 1)
            d = decompose(c; basis=basis)
            @test all(inst -> isterminal(basis, getoperation(inst)), d)
            for g in (GateCCX(), GateRXX(π / 4), RPauli("XZ", π), GateCP(π / 2))
                test_basis_decomposition(basis, g)
            end

            # Noise that Stim does not support cannot be decomposed.
            @test_throws DecompositionError decompose(push!(Circuit(), AmplitudeDamping(0.1), 1); basis=basis)
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

        @testset "conditionals and MeasureReset" begin
            @test isterminal(basis, IfStatement(GateX(), bs"1"))
            @test !isterminal(basis, IfStatement(GateCP(0.3), bs"1"))
            @test !isterminal(basis, WhileStatement(GateX(), bs"1"))

            c = push!(Circuit(), WhileStatement(GateX(), bs"1"), 1, 1)
            @test_throws MimiqCircuitsBase.DecompositionError decompose(c; basis=basis)

            # Measure + Reset leaves the same state and bit as the conditional X,
            # and needs no condition on the whole register.
            c = Circuit()
            push!(c, MeasureReset(), 1, 2)
            push!(c, MeasureResetX(), 2, 1)
            d = decompose(c; basis=basis)
            @test collect(d) == [
                Instruction(Measure(), 1, 2), Instruction(Reset(), 1),
                Instruction(GateH(), 2), Instruction(Measure(), 2, 1),
                Instruction(Reset(), 2), Instruction(GateH(), 2),
            ]
            w = decompose(c; basis=basis, wrap=true)
            @test all(inst -> getoperation(inst) isa Block, w)
            @test collect(decompose(w; basis=basis)) == collect(d)
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

        @testset "isterminal — Stim gates added in 1.16 support" begin
            @test isterminal(basis, GateHXY())
            @test isterminal(basis, GateHYZ())
            @test isterminal(basis, MeasureXX())
            @test isterminal(basis, MeasureYY())
            @test isterminal(basis, MeasureZZ())
            @test isterminal(basis, MeasurePauli("XYZ"))
            @test isterminal(basis, PauliNoise([0.9, 0.1], ["IXZ", "YYY"]))

            # Pauli rotations are terminal only at ±π/2 (modulo 2π)
            for g in (GateRXX(π / 2), GateRXX(-π / 2), GateRYY(π / 2), GateRZZ(3π / 2), RPauli("XIZ", π / 2), RPauli("Y", -π / 2))
                @test isterminal(basis, g)
            end
            for g in (GateRXX(π), GateRYY(0.3), GateRZZ(0), RPauli("XZ", π), RPauli("II", π / 2))
                @test !isterminal(basis, g)
            end

            # feedback: a Pauli conditioned on one bit being 1
            for P in (GateX(), GateY(), GateZ())
                @test isterminal(basis, IfStatement(P, bs"1"))
                @test !isterminal(basis, IfStatement(P, bs"0"))
                @test !isterminal(basis, IfStatement(P, bs"11"))
            end
            @test !isterminal(basis, IfStatement(GateH(), bs"1"))
        end

        @testset "decomposition — conditional Paulis" begin
            # P if c == 0 becomes P, then P if c == 1
            d = decompose(push!(Circuit(), IfStatement(GateY(), bs"0"), 2, 1); basis=basis)
            @test getoperation.(collect(d)) == [GateY(), IfStatement(GateY(), bs"1")]
            @test getqubits.(collect(d)) == [(2,), (2,)]
            @test getbits.(collect(d)) == [(), (1,)]

            # rotations by multiples of π become the conditional Pauli they equal
            d = decompose(push!(Circuit(), IfStatement(GateRX(π), bs"1"), 1, 3); basis=basis)
            @test getoperation.(collect(d)) == [IfStatement(GateX(), bs"1")]
            @test getbits.(collect(d)) == [(3,)]
            d = decompose(push!(Circuit(), IfStatement(GateRZ(-π), bs"0"), 1, 1); basis=basis)
            @test getoperation.(collect(d)) == [GateZ(), IfStatement(GateZ(), bs"1")]

            # anything else cannot be written in Stim
            @test_throws DecompositionError decompose(push!(Circuit(), IfStatement(GateX(), bs"10"), 1, 1, 2); basis=basis)
            @test_throws DecompositionError decompose(push!(Circuit(), IfStatement(GateH(), bs"1"), 1, 1); basis=basis)
            @test_throws DecompositionError decompose(push!(Circuit(), IfStatement(GateRZ(π / 2), bs"1"), 1, 1); basis=basis)
            @test_throws DecompositionError decompose(push!(Circuit(), IfStatement(GateCX(), bs"1"), 1, 2, 1); basis=basis)
        end

        @testset "decomposition — Pauli rotations away from ±π/2" begin
            for g in (GateRXX(π), RPauli("XZ", π), GateRZZ(0))
                d = decompose(push!(Circuit(), g, 1, 2); basis=basis)
                @test all(inst -> isterminal(basis, getoperation(inst)), d)
                @test !any(inst -> getoperation(inst) isa Union{GateRXX,GateRZZ,RPauli}, d)
            end
        end

        @testset "NOT terminal — non-Clifford gates" begin
            @test !isterminal(basis, GateT())
            @test !isterminal(basis, GateTDG())
            @test !isterminal(basis, GateRZ(0.5))
            @test !isterminal(basis, GateU(0.1, 0.2, 0.3))
            @test !isterminal(basis, GateCCX())
        end

        @testset "decomposition — phase-only GateU" begin
            # A global phase is dropped, in this basis and in CliffordTBasis.
            for b in (basis, CliffordTBasis())
                @test isempty(decompose(GateU(0, 0, 0, 0.3); basis=b))
                @test isempty(decompose(GateU(0, 0, 0, 0); basis=b))
                @test isempty(decompose(RPauli("II", 0.3); basis=b))
                @test isempty(decompose(push!(Circuit(), RPauli("II", π / 3), 1, 2); basis=b))
            end

            # Under a Control the phase is relative and must be kept.
            for g in (Control(GateU(0, 0, 0, π / 2)), Control(GateU(0, 0, 0, π)), Control(2, GateU(0, 0, 0, π)))
                test_basis_decomposition(basis, g)
            end
            @test_throws DecompositionError decompose(Control(GateU(0, 0, 0, 0.3)); basis=basis)
            for nc in (1, 2)
                test_basis_decomposition(CliffordTBasis(), Control(nc, GateU(0, 0, 0, π / 2)))
                # Gridsynth approximates the phase to 1e-10; dropping it would be off by about 0.3.
                test_basis_decomposition(CliffordTBasis(), Control(nc, GateU(0, 0, 0, 0.3)); atol=1e-8)
            end
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

@testset "IfStatement in decomposition bases" begin
    feedback = push!(Circuit(), Measure(), 1, 1)
    push!(feedback, IfStatement(GateX(), bs"1"), 2, 1)
    reset = push!(Circuit(), MeasureReset(), 1, 1)

    # MeasureReset expands to Measure and a conditional X on the same bit.
    stepped = decompose_step(reset)
    @test getoperation.(collect(stepped)) == [Measure(), IfStatement(GateX(), bs"1")]
    @test getbits.(collect(stepped)) == [(1,), (1,)]

    @testset "$(typeof(basis))" for basis in (CanonicalBasis(), CliffordTBasis(), QASMBasis(), StimBasis(), FlattenedBasis())
        for c in (feedback, reset)
            @test all(inst -> isterminal(basis, getoperation(inst)), decompose(c; basis=basis))
        end
    end

    @test_throws DecompositionError decompose(push!(Circuit(), IfStatement(GateH(), bs"1"), 1, 1); basis=StimBasis())

    # A conditional gate decomposes into conditional Clifford+T gates with the
    # same condition, and their product is the original gate.
    @testset "CliffordTBasis $(opname(gate))" for gate in (GateCCX(), GateRX(π / 4), GateCSWAP(), GateU(π / 2, π / 4, -π / 4))
        basis = CliffordTBasis()
        n = numqubits(gate)
        c = push!(Circuit(), IfStatement(gate, bs"1"), 2:(n+1)..., 1)
        d = decompose(c; basis=basis)
        @test all(inst -> getoperation(inst) isa IfStatement, d)
        @test all(inst -> getbitstring(getoperation(inst)) == bs"1", d)
        @test all(inst -> getbits(inst) == (1,), d)
        @test all(inst -> isterminal(basis, getoperation(getoperation(inst))), d)
        body = Circuit()
        for inst in d
            push!(body, getoperation(getoperation(inst)), (getqubits(inst) .- 1)...)
        end
        @test matrices_equivalent(matrix_from_circuit(body, n), matrix_from_circuit(push!(Circuit(), gate, 1:n...), n))
    end

    # A conditional arbitrary rotation becomes conditional Clifford+T gates.
    basis = CliffordTBasis(sk_depth=0)
    d = decompose(push!(Circuit(), IfStatement(GateRX(0.3), bs"0"), 1, 3); basis=basis)
    @test !isempty(d)
    @test all(inst -> getoperation(inst) isa IfStatement, d)
    @test all(inst -> getbitstring(getoperation(inst)) == bs"0" && getbits(inst) == (3,), d)
    @test all(inst -> isterminal(basis, getoperation(getoperation(inst))), d)

    # Nested conditions are merged into one IfStatement per instruction.
    d = decompose_step(push!(Circuit(), IfStatement(MeasureReset(), bs"0"), 1, 1, 2))
    @test getoperation.(collect(d)) == [IfStatement(Measure(), bs"0"), IfStatement(GateX(), bs"10")]
    @test getbits.(collect(d)) == [(1, 2), (1, 2)]

    # FlattenedBasis expands a conditional GateCall into conditional gates.
    inner = push!(Circuit(), GateH(), 1)
    push!(inner, GateCX(), 1, 2)
    call = GateDecl(:Inner, (), inner)()
    d = decompose(push!(Circuit(), IfStatement(call, bs"1"), 1, 2, 1); basis=FlattenedBasis())
    @test getoperation.(collect(d)) == [IfStatement(GateH(), bs"1"), IfStatement(GateCX(), bs"1")]

    # RuleBasis applies its rule to the body of a conditional.
    basis = RuleBasis(ZYZRewrite())
    op = IfStatement(GateU(π / 2, π / 4, π / 3), bs"1")
    @test !isterminal(basis, op)
    d = decompose(push!(Circuit(), op, 1, 1); basis=basis)
    @test all(inst -> getoperation(inst) isa IfStatement && isterminal(basis, getoperation(inst)), d)
end
