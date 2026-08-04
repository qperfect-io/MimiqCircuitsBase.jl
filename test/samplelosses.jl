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

using Random
using Symbolics

# any leftover loss operation after lowering is a bug
_has_loss_ops(c) = any(c) do inst
    getoperation(inst) isa Union{Loss,Reload,Check,MeasureCheck}
end

@testset "loss operations" begin
    @testset "constructors" begin
        @test Loss() == Loss(1.0)
        @test_throws ArgumentError Loss(1.5)
        @test_throws ArgumentError Loss(-0.1)
    end

    # ----------------------------------------------------------------- #
    # deprecated aliases: old names map onto the redesigned ops         #
    # ----------------------------------------------------------------- #
    @testset "deprecated loss aliases" begin
        @test (@test_deprecated LossErr(0.2)) == Loss(0.2)
        @test (@test_deprecated QubitLoss()) == Loss(1.0)
        @test (@test_deprecated QubitReload()) == Reload()
        @test (@test_deprecated CheckLoss()) == Check()
        @test (@test_deprecated MeasureCheckLoss()) == MeasureCheck()
    end

    # ----------------------------------------------------------------- #
    # sample_losses: resolve randomness only                            #
    # ----------------------------------------------------------------- #
    @testset "sample_losses" begin
        @testset "certain loss kept, everything else passes through" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            push!(c, Check(), 2, 1)
            push!(c, MeasureCheck(), 2, 1, 2)
            sampled = sample_losses(c)
            @test length(sampled) == 4
            @test getoperation(sampled[1]) == Loss(1.0)
            @test getoperation(sampled[2]) isa GateCX
            @test getoperation(sampled[3]) isa Check
            @test getoperation(sampled[4]) isa MeasureCheck
        end

        @testset "deterministic with p=1 and p=0" begin
            one = sample_losses(push!(Circuit(), Loss(1.0), 1); rng=MersenneTwister(42))
            @test length(one) == 1 && getoperation(one[1]) == Loss(1.0)
            zero = sample_losses(push!(Circuit(), Loss(0.0), 1); rng=MersenneTwister(42))
            @test isempty(zero)
        end

        @testset "Reload/Check/MeasureCheck are not touched" begin
            c = Circuit()
            push!(c, Reload(), 1)
            push!(c, Check(), 1, 1)
            sampled = sample_losses(c)
            @test getoperation(sampled[1]) isa Reload
            @test getoperation(sampled[2]) isa Check
        end
    end

    # ----------------------------------------------------------------- #
    # lower_losses: bookkeeping into primitives                         #
    # ----------------------------------------------------------------- #
    @testset "lower_losses bookkeeping" begin
        @testset "Loss becomes a Lost marker" begin
            lowered = lower_losses(push!(Circuit(), Loss(), 1))
            @test getoperation(lowered[1]) isa Lost
            @test !_has_loss_ops(lowered)
        end

        @testset "lower_losses treats any remaining Loss as certain" begin
            lowered = lower_losses(push!(Circuit(), Loss(0.3), 1))
            @test getoperation(lowered[1]) isa Lost
        end

        @testset "already-lost qubit: second Loss is ignored" begin
            c = Circuit()
            push!(c, Loss(), 1)
            push!(c, Loss(), 1)
            push!(c, GateH(), 2)
            lowered = lower_losses(c)
            @test length(lowered) == 2
            @test getoperation(lowered[1]) isa Lost
            @test getoperation(lowered[2]) isa GateH
        end

        @testset "Reload always resets and restores presence" begin
            # reload of a lost qubit
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, Reload(), 2)
            push!(c, GateCX(), 1, 2)
            lowered = lower_losses(c)
            @test getoperation(lowered[1]) isa Lost
            @test getoperation(lowered[2]) isa Reset
            @test getoperation(lowered[3]) isa Reloaded
            @test getoperation(lowered[4]) isa GateCX   # q2 present again

            # reload of a present qubit still resets (default policy)
            present = lower_losses(push!(Circuit(), Reload(), 1))
            @test getoperation(present[1]) isa Reset
            @test getoperation(present[2]) isa Reloaded
        end

        @testset "Check: 1 when present, 0 when lost" begin
            present = lower_losses(push!(Circuit(), Check(), 1, 1))
            @test getoperation(present[1]) isa SetBit1
            c = Circuit()
            push!(c, Loss(), 1)
            push!(c, Check(), 1, 1)
            @test getoperation(lower_losses(c)[end]) isa SetBit0
        end

        @testset "MeasureCheck: present measures, lost reads 0" begin
            mc = lower_losses(push!(Circuit(), MeasureCheck(), 1, 1, 2))
            @test getoperation(mc[1]) isa Measure
            @test getoperation(mc[2]) isa SetBit1
            c = Circuit()
            push!(c, Loss(), 1)
            push!(c, MeasureCheck(), 1, 1, 2)
            low = lower_losses(c)
            @test getoperation(low[end-1]) isa SetBit0
            @test getoperation(low[end]) isa SetBit0
        end

        @testset "measurement on a lost qubit reads 0" begin
            c = Circuit()
            push!(c, Loss(), 1)
            push!(c, Measure(), 1, 1)
            @test getoperation(lower_losses(c)[end]) isa SetBit0
        end
    end

    # ----------------------------------------------------------------- #
    # gates touching lost qubits                                        #
    # ----------------------------------------------------------------- #
    @testset "gates on lost qubits" begin
        @testset "no lost qubits: passes through" begin
            c = Circuit()
            push!(c, GateCX(), 1, 2)
            push!(c, GateH(), 1)
            lowered = lower_losses(c; lossmodel=LossModel([DropRule()]))
            @test length(lowered) == 2
            @test getoperation(lowered[1]) isa GateCX
            @test getoperation(lowered[2]) isa GateH
        end

        @testset "all qubits lost: always dropped" begin
            c = Circuit()
            push!(c, Loss(), 1)
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.5))])
            lowered = lower_losses(c; lossmodel=lm)
            @test length(lowered) == 2
            @test all(i -> getoperation(lowered[i]) isa Lost, 1:2)
        end

        @testset "some lost, default model drops the gate" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            push!(c, GateH(), 2)
            lowered = lower_losses(c)
            @test length(lowered) == 1
            @test getoperation(lowered[1]) isa Lost
        end

        @testset "1-qubit gate / noise on lost qubit is dropped" begin
            for op in (GateH(), Depolarizing1(0.1))
                c = Circuit()
                push!(c, Loss(), 1)
                push!(c, op, 1)
                lowered = lower_losses(c)
                @test length(lowered) == 1
                @test getoperation(lowered[1]) isa Lost
            end
        end
    end

    # ----------------------------------------------------------------- #
    # LossModel rules                                                   #
    # ----------------------------------------------------------------- #
    @testset "LossModel rules" begin
        @testset "DropRule explicit and catch-all" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            @test length(lower_losses(c; lossmodel=LossModel([DropRule(GateCX())]))) == 1
            @test length(lower_losses(c; lossmodel=LossModel([DropRule()]))) == 1
        end

        @testset "ReplaceRule puts noise on the surviving qubit" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            out = lower_losses(c; lossmodel=LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2))]))
            @test getoperation(out[2]) isa Depolarizing1
            @test getqubits(out[2]) == (1,)
            @test !_has_loss_ops(out)
        end

        @testset "DecorateRule keeps decoration on survivors" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            out = lower_losses(c; lossmodel=LossModel([DecorateRule(GateCX(), Depolarizing1(0.1))]))
            @test getoperation(out[2]) isa Depolarizing1
            @test getqubits(out[2]) == (1,)
            # no lost qubits on the gate → rules not consulted
            c2 = Circuit()
            push!(c2, Loss(), 3)
            push!(c2, GateCX(), 1, 2)
            out2 = lower_losses(c2; lossmodel=LossModel([DecorateRule(GateCX(), Depolarizing1(0.1))]))
            @test getoperation(out2[2]) isa GateCX
        end

        @testset "CustomRule single, multiple, and drop" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            single = LossModel([CustomRule(
                inst -> getoperation(inst) isa GateCX,
                (inst, lost; rng=nothing) -> begin
                    alive = [q for q in getqubits(inst) if !get(lost, q, false)]
                    Instruction(Depolarizing1(0.05), alive[1])
                end)])
            out = lower_losses(c; lossmodel=single)
            @test getoperation(out[2]) isa Depolarizing1
            @test getqubits(out[2]) == (1,)

            cz = Circuit()
            push!(cz, Loss(), 1)
            push!(cz, GateCZ(), 1, 2)
            multi = LossModel([CustomRule(
                inst -> getoperation(inst) isa GateCZ,
                (inst, lost; rng=nothing) -> begin
                    alive = [q for q in getqubits(inst) if !get(lost, q, false)]
                    [Instruction(GateH(), alive[1]), Instruction(Depolarizing1(0.1), alive[1])]
                end)])
            outm = lower_losses(cz; lossmodel=multi)
            @test getoperation(outm[2]) isa GateH
            @test getoperation(outm[3]) isa Depolarizing1
            @test getqubits(outm[2]) == (2,)

            drop = LossModel([CustomRule(inst -> true, (inst, lost; rng=nothing) -> nothing)])
            @test length(lower_losses(c; lossmodel=drop)) == 1
        end

        @testset "first match wins" begin
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateCX(), 1, 2)
            push!(c, GateCZ(), 1, 2)
            lm = LossModel([
                ReplaceRule(GateCX() => Depolarizing1(0.2)),
                ReplaceRule(GateCZ() => Depolarizing1(0.1)),
            ])
            out = lower_losses(c; lossmodel=lm)
            @test getoperation(out[2]).p ≈ 0.2
            @test getoperation(out[3]).p ≈ 0.1
        end

        @testset "DropRule has higher priority than a broad replace" begin
            @variables θ
            c = Circuit()
            push!(c, Loss(), 2)
            push!(c, GateRXX(0.3), 1, 2)
            push!(c, GateRXX(0.2), 1, 2)
            lm = LossModel([ReplaceRule(GateRXX(θ), GateZ()), DropRule(GateRXX(0.2))])
            out = lower_losses(c; lossmodel=lm)
            @test length(out) == 2
            @test getoperation(out[2]) isa GateZ
            @test getqubits(out[2]) == (1,)
        end

        @testset "N-qubit gate replacements" begin
            # 1-qubit replacement broadcasts, lost target filtered
            c = Circuit()
            push!(c, Loss(), 3)
            push!(c, GateCCX(), 1, 2, 3)
            out = lower_losses(c; lossmodel=LossModel([ReplaceRule(GateCCX() => Depolarizing1(0.2))]))
            @test length(out) == 3
            @test getqubits(out[2]) == (1,)
            @test getqubits(out[3]) == (2,)

            # matching qubit-count replacement touches the lost qubit → filtered
            out2 = lower_losses(c; lossmodel=LossModel([ReplaceRule(GateCCX(), Depolarizing(3, 0.1))]))
            @test length(out2) == 1
            @test getoperation(out2[1]) isa Lost

            # explicit vector replacement, lost target filtered
            out3 = lower_losses(c; lossmodel=LossModel([ReplaceRule(GateCCX(), [
                Instruction(Depolarizing1(0.1), 1),
                Instruction(Depolarizing1(0.2), 2),
                Instruction(Depolarizing1(0.3), 3),
            ])]))
            @test length(out3) == 3
            @test getqubits(out3[2]) == (1,)
            @test getqubits(out3[3]) == (2,)
        end
    end

    # ----------------------------------------------------------------- #
    # symbolic probabilities                                            #
    # ----------------------------------------------------------------- #
    @testset "symbolic loss probability" begin
        @variables θ
        @test Symbolics.value(evaluate(Loss(θ), Dict(θ => 0.5)).p) ≈ 0.5
        # sampling needs a numeric probability
        @test_throws ArgumentError sample_losses(push!(Circuit(), Loss(θ), 1))
    end

    # ----------------------------------------------------------------- #
    # resolve_losses: sample then lower                                 #
    # ----------------------------------------------------------------- #
    @testset "resolve_losses" begin
        c = Circuit()
        push!(c, Loss(), 1)
        push!(c, GateX(), 1)
        push!(c, Check(), 1, 1)
        out = resolve_losses(c)
        @test getoperation(out[1]) isa Lost
        @test getoperation(out[end]) isa SetBit0
        @test !_has_loss_ops(out)

        # impossible loss leaves the gate intact
        c0 = Circuit()
        push!(c0, Loss(0.0), 1)
        push!(c0, GateX(), 1)
        out0 = resolve_losses(c0)
        @test length(out0) == 1
        @test getoperation(out0[1]) isa GateX
    end

    # ----------------------------------------------------------------- #
    # sample_loss_scenario                                              #
    # ----------------------------------------------------------------- #
    @testset "sample_loss_scenario" begin
        function scenario_circuit()
            c = Circuit()
            push!(c, Loss(0.2), 1)
            push!(c, GateCX(), 1, 2)
            push!(c, Loss(0.4), 2)
            push!(c, GateH(), 3)
            return c
        end

        @testset "select one site by index" begin
            out = sample_loss_scenario(scenario_circuit(), 1)
            @test length(out) == 2
            @test getoperation(out[1]) isa Lost
            @test getqubits(out[1]) == (1,)
            @test getoperation(out[2]) isa GateH
        end

        @testset "select a later site" begin
            out = sample_loss_scenario(scenario_circuit(), 2)
            @test length(out) == 3
            @test getoperation(out[1]) isa GateCX
            @test getoperation(out[2]) isa Lost
            @test getqubits(out[2]) == (2,)
            @test getoperation(out[3]) isa GateH
        end

        @testset "force multiple sites" begin
            out = sample_loss_scenario(scenario_circuit(), [1, 2])
            @test length(out) == 3
            @test getoperation(out[1]) isa Lost
            @test getoperation(out[2]) isa Lost
            @test getoperation(out[3]) isa GateH
            @test !_has_loss_ops(out)
        end

        @testset "chosen probability p=0 loses nothing" begin
            out = sample_loss_scenario(scenario_circuit(), [1, 2]; p=0.0)
            @test length(out) == 2
            @test getoperation(out[1]) isa GateCX
            @test getoperation(out[2]) isa GateH
        end

        @testset "validation" begin
            c = push!(Circuit(), Loss(0.2), 1)
            @test_throws ArgumentError sample_loss_scenario(c, 0)
            @test_throws ArgumentError sample_loss_scenario(c, 2)
            @test_throws ArgumentError sample_loss_scenario(c, [1, 2])
            @test_throws ArgumentError sample_loss_scenario(c, 1; p=-0.1)
            @test_throws ArgumentError sample_loss_scenario(c, 1; p=1.1)
            @test_throws ArgumentError sample_loss_scenario(Circuit(), [1])
        end
    end

    @testset "LossModel display" begin
        lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2)), DropRule()])
        @test occursin("2 rules", string(lm))
        @test occursin("my_model", string(LossModel(; name="my_model")))
    end
end
