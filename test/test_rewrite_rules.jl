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
using MimiqCircuitsBase
using LinearAlgebra
import MimiqCircuitsBase: unwrapvalue

# Ensure we can load DecompositionTestUtils (it's in test/ but we are in test/decompositions/)
if !isdefined(@__MODULE__, :DecompositionTestUtils)
    include("DecompositionTestUtils.jl")
end
using .DecompositionTestUtils

@testset "RewriteRules" begin

    # === CanonicalRewrite ===

    @testset "CanonicalRewrite" begin
        rule = CanonicalRewrite()

        @testset "matches" begin
            # Should match most gates
            @test matches(rule, GateH())
            @test matches(rule, GateX())
            @test matches(rule, GateCCX())
            @test matches(rule, GateSWAP())

            # Should not match terminal gates (U, CX)
            @test !matches(rule, GateU(0, 0, 0))
            @test !matches(rule, GateCX())
        end

        @testset "matrix equivalence" begin
            test_all_gates_with_rule(rule)
        end

        @testset "specific decompositions" begin
            # H → U(π/2, 0, π)
            h_decomp = decompose_step(GateH(); rule=rule)
            @test circuit_contains_only(h_decomp, GateU)

            # SWAP → 3 CNOTs
            swap_decomp = decompose_step(GateSWAP(); rule=rule)
            @test cnot_count(swap_decomp) == 3
        end
    end

    # === SpecialAngleRewrite ===

    @testset "SpecialAngleRewrite" begin
        rule = SpecialAngleRewrite()

        @testset "matches — π/4 multiples only" begin
            # Should match rotations at k·π/4
            @test matches(rule, GateRZ(π / 4))
            @test matches(rule, GateRZ(π / 2))
            @test matches(rule, GateRZ(π))
            @test matches(rule, GateRX(3π / 4))
            @test matches(rule, GateRY(π / 4))

            # Should not match arbitrary angles
            @test !matches(rule, GateRZ(0.123))
            @test !matches(rule, GateRX(1.0))
            @test !matches(rule, GateRY(π / 3))

            # Should not match non-rotation gates
            @test !matches(rule, GateH())
            @test !matches(rule, GateCX())
        end

        @testset "matrix equivalence — all k values" begin
            for k in 0:7
                @testset "k = $k" begin
                    test_rewrite_rule_matrix(rule, GateRZ(k * π / 4))
                    test_rewrite_rule_matrix(rule, GateRX(k * π / 4))
                    test_rewrite_rule_matrix(rule, GateRY(k * π / 4))
                end
            end
        end

        @testset "specific decompositions" begin
            # RZ(π/4) → T
            rz_t = decompose_step(GateRZ(π / 4); rule=rule)
            @test count_gate_type(rz_t, GateT) == 1

            # RZ(π/2) → S
            rz_s = decompose_step(GateRZ(π / 2); rule=rule)
            @test count_gate_type(rz_s, GateS) == 1

            # RZ(π) → Z
            rz_z = decompose_step(GateRZ(π); rule=rule)
            @test count_gate_type(rz_z, GateZ) == 1

            # RZ(0) → identity (empty)
            rz_id = decompose_step(GateRZ(0.0); rule=rule)
            @test length(rz_id) == 0
        end

        @testset "output is Clifford+T only" begin
            clifford_t_gates = (GateH, GateS, GateSDG, GateT, GateTDG,
                GateX, GateY, GateZ, GateSX, GateSXDG,
                GateSY, GateSYDG)

            for k in 0:7
                decomp = decompose_step(GateRZ(k * π / 4); rule=rule)
                @test circuit_contains_only(decomp, clifford_t_gates...)

                decomp = decompose_step(GateRX(k * π / 4); rule=rule)
                @test circuit_contains_only(decomp, clifford_t_gates...)

                decomp = decompose_step(GateRY(k * π / 4); rule=rule)
                @test circuit_contains_only(decomp, clifford_t_gates...)
            end
        end

        @testset "only_cliffords = true" begin
            rule_clifford = SpecialAngleRewrite(only_cliffords=true)

            @testset "matches — π/2 multiples only" begin
                # Should NOT match odd multiples of π/4 (T-gates)
                @test !matches(rule_clifford, GateRZ(π / 4))
                @test !matches(rule_clifford, GateRX(3π / 4))
                @test !matches(rule_clifford, GateRY(5π / 4))

                # Should match multiples of π/2
                @test matches(rule_clifford, GateRZ(π / 2))
                @test matches(rule_clifford, GateRX(π))
                @test matches(rule_clifford, GateRY(0.0))
            end

            @testset "decomposition is Clifford only" begin
                # RZ(π/2) → S
                rz_s = decompose_step(GateRZ(π / 2); rule=rule_clifford)
                @test count_gate_type(rz_s, GateS) == 1

                clifford_gates = (GateH, GateS, GateSDG, GateX, GateY, GateZ, GateSX, GateSXDG, GateSY, GateSYDG)

                # Verify no T gates are produced for allowed inputs
                for k in [0, 2, 4, 6] # Even k only
                    decomp = decompose_step(GateRZ(k * π / 4); rule=rule_clifford)
                    @test circuit_contains_only(decomp, clifford_gates...)
                    @test count_gate_type(decomp, GateT) == 0
                    @test count_gate_type(decomp, GateTDG) == 0
                end
            end
        end
    end

    # === ToZRotationRewrite ===

    @testset "ToZRotationRewrite" begin
        rule = ToZRotationRewrite()

        @testset "matches" begin
            @test matches(rule, GateRX(0.5))
            @test matches(rule, GateRY(1.0))

            @test !matches(rule, GateRZ(0.5))  # Already Z
            @test !matches(rule, GateH())
            @test !matches(rule, GateCX())
        end

        @testset "matrix equivalence" begin
            for θ in [0.0, π / 4, π / 2, π, 1.234, 2.0]
                test_rewrite_rule_matrix(rule, GateRX(θ))
                test_rewrite_rule_matrix(rule, GateRY(θ))
            end
        end

        @testset "output contains RZ" begin
            # RX(θ) → H·RZ(θ)·H
            rx_decomp = decompose_step(GateRX(0.5); rule=rule)
            @test count_gate_type(rx_decomp, GateRZ) == 1
            @test count_gate_type(rx_decomp, GateH) == 2

            # RY(θ) → S·H·RZ(θ)·H·Sdg
            ry_decomp = decompose_step(GateRY(0.5); rule=rule)
            @test count_gate_type(ry_decomp, GateRZ) == 1
        end
    end

    # === ZYZRewrite ===

    @testset "ZYZRewrite" begin
        rule = ZYZRewrite()

        @testset "matches" begin
            # GateU with non-zero angles
            @test matches(rule, GateU(π / 2, π / 4, π / 3))
            @test matches(rule, GateU(0.1, 0, 0))

            # Identity U should not match
            @test !matches(rule, GateU(0, 0, 0))

            # RX matches (converted via S conjugation)
            @test matches(rule, GateRX(0.5))

            # Other gates don't match
            @test !matches(rule, GateH())
            @test !matches(rule, GateRZ(0.5))
        end

        @testset "matrix equivalence — GateU" begin
            for _ in 1:10
                θ, ϕ, λ = 2π .* rand(3)
                test_rewrite_rule_matrix(rule, GateU(θ, ϕ, λ))
            end
        end

        @testset "matrix equivalence — GateRX" begin
            for θ in [0.0, π / 4, π / 2, π, 1.234]
                test_rewrite_rule_matrix(rule, GateRX(θ))
            end
        end

        @testset "output contains RZ, RY" begin
            u_decomp = decompose_step(GateU(π / 2, π / 4, π / 3); rule=rule)
            @test count_gate_type(u_decomp, GateRZ) >= 1
            @test count_gate_type(u_decomp, GateRY) == 1
        end
    end

    # === ToffoliToCliffordTRewrite ===

    @testset "ToffoliToCliffordTRewrite" begin
        rule = ToffoliToCliffordTRewrite()

        @testset "matches" begin
            @test matches(rule, GateCCX())

            @test !matches(rule, GateCX())
            @test !matches(rule, GateH())
            @test !matches(rule, GateT())
        end

        @testset "matrix equivalence" begin
            test_rewrite_rule_matrix(rule, GateCCX())
        end

        @testset "T-count is 7" begin
            ccx_decomp = decompose_step(GateCCX(); rule=rule)
            @test t_count(ccx_decomp) == 7
        end

        @testset "CNOT count is 6" begin
            ccx_decomp = decompose_step(GateCCX(); rule=rule)
            @test cnot_count(ccx_decomp) == 6
        end

        @testset "output is Clifford+T only" begin
            ccx_decomp = decompose_step(GateCCX(); rule=rule)
            clifford_t_gates = (GateH, GateS, GateSDG, GateT, GateTDG,
                GateCX, GateX, GateY, GateZ)
            @test circuit_contains_only(ccx_decomp, clifford_t_gates...)
        end
    end

    # === SolovayKitaevRewrite ===

    @testset "SolovayKitaevRewrite" begin
        @testset "matches" begin
            rule = SolovayKitaevRewrite()

            # Matches rotations with concrete angles
            @test matches(rule, GateRZ(0.123))
            @test matches(rule, GateRY(0.456))
            @test matches(rule, GateRX(0.789))
            @test matches(rule, GateU(0.1, 0.2, 0.3))

            # Doesn't match other gates
            @test !matches(rule, GateH())
            @test !matches(rule, GateCX())
            @test !matches(rule, GateT())
        end

        @testset "approximation quality — depth 0" begin
            rule = SolovayKitaevRewrite(0)

            for θ in [0.1, 0.5, 1.0, 2.0]
                gate = GateRZ(θ)
                original = unwrapvalue.(matrix(gate))
                decomposed = decompose_step(gate; rule=rule)
                decomposed_matrix = matrix_from_circuit(decomposed, 1)

                # Depth 0 has ~0.1 error
                # Depth 0 has ~0.1 error
                # Ignore global phase differences
                @test matrices_equivalent(original, decomposed_matrix; atol=0.3)
            end
        end

        @testset "approximation quality — depth 3" begin
            rule = SolovayKitaevRewrite(3)

            for θ in [0.1, 0.5, 1.0, 2.0]
                gate = GateRZ(θ)
                original = unwrapvalue.(matrix(gate))
                decomposed = decompose_step(gate; rule=rule)
                decomposed_matrix = matrix_from_circuit(decomposed, 1)

                # Depth 3 should have ~0.01 error
                @test matrices_equivalent(original, decomposed_matrix; atol=0.03)
            end
        end

        @testset "output is Clifford+T only" begin
            rule = SolovayKitaevRewrite(2)

            decomp = decompose_step(GateRZ(0.123); rule=rule)
            clifford_t_gates = (GateH, GateS, GateSDG, GateT, GateTDG,
                GateX, GateY, GateZ)
            @test circuit_contains_only(decomp, clifford_t_gates...)
        end

        @testset "higher depth → more gates" begin
            gate = GateRZ(0.5)

            decomp_0 = decompose_step(gate; rule=SolovayKitaevRewrite(0))
            decomp_1 = decompose_step(gate; rule=SolovayKitaevRewrite(1))
            decomp_2 = decompose_step(gate; rule=SolovayKitaevRewrite(2))

            @test length(decomp_0) < length(decomp_1) < length(decomp_2)
        end
    end

    # === FlattenContainers ===

    @testset "FlattenContainers" begin
        rule = FlattenContainers()

        @testset "matches" begin
            @test matches(rule, Block(1, 0, 0))
            @test !matches(rule, GateH())
            @test !matches(rule, GateCX())
        end

        @testset "flattens block" begin
            c = Circuit()
            push!(c, GateH(), 1)
            push!(c, GateCX(), 1, 2)
            b = Block(c)

            # verify block structure
            @test length(b) == 2

            # flatten one level
            decomp = decompose_step(b; rule=rule)
            @test length(decomp) == 2
            @test getoperation(decomp[1]) isa GateH
            @test getoperation(decomp[2]) isa GateCX
        end

        @testset "flattens nested block (one level)" begin
            inner_c = Circuit()
            push!(inner_c, GateX(), 1)
            inner_b = Block(inner_c)

            outer_c = Circuit()
            push!(outer_c, inner_b, 1)
            outer_b = Block(outer_c)

            # flatten outer block
            decomp = decompose_step(outer_b; rule=rule)

            # Should have 1 instruction which is the inner block
            @test length(decomp) == 1
            @test getoperation(decomp[1]) isa Block
        end
    end

end  # @testset "RewriteRules"
