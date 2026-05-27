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

@testset "sample_losses" begin
    @testset "default LossModel: drops everything" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)
        push!(c, GateH(), 1)

        sampled = sample_losses(c)

        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa GateH
    end

    @testset "DropRule: explicit drop" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([DropRule(GateCX())])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "DropRule: catch-all" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)
        push!(c, GateCZ(), 1, 2)

        lm = LossModel([DropRule()])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "ReplaceRule: CX → Depolarizing1" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2))])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa Depolarizing1
        @test getqubits(sampled[2]) == (1,)
    end

    @testset "ReplaceRule: surviving qubit selection" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)  # qubit 1 is lost (not qubit 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2))])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2
        @test getoperation(sampled[2]) isa Depolarizing1
        @test getqubits(sampled[2]) == (2,)  # surviving qubit is 2
    end

    @testset "DecorateRule: original filtered, decoration on surviving qubits kept" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        # CX touches lost q2 → filtered. Broadcast decoration: q1 survives, q2 filtered.
        lm = LossModel([DecorateRule(GateCX(), Depolarizing1(0.1))])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa Depolarizing1
        @test getqubits(sampled[2]) == (1,)
    end

    @testset "DecorateRule: no lost qubits, keeps everything" begin
        c = Circuit()
        push!(c, QubitLoss(), 3)
        push!(c, GateCX(), 1, 2)  # neither q1 nor q2 is lost

        lm = LossModel([DecorateRule(GateCX(), Depolarizing1(0.1))])
        sampled = sample_losses(c; lossmodel=lm)

        # No lost qubits on CX → passes through unchanged (rules not consulted)
        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa GateCX
    end

    @testset "DecorateRule: before=true, original filtered" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([DecorateRule(GateCX(), Depolarizing1(0.1); before=true)])
        sampled = sample_losses(c; lossmodel=lm)

        # CX on (1,2) filtered (q2 lost). Only decoration on q1 survives.
        @test length(sampled) == 2
        @test getoperation(sampled[2]) isa Depolarizing1
        @test getqubits(sampled[2]) == (1,)
    end

    @testset "CustomRule" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([
            CustomRule(
                inst -> getoperation(inst) isa GateCX,
                (inst, lost; rng=nothing) -> begin
                    qs = collect(getqubits(inst))
                    alive = [q for q in qs if !get(lost, q, false)]
                    return Instruction(Depolarizing1(0.05), alive[1])
                end,
            ),
        ])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2
        @test getoperation(sampled[2]) isa Depolarizing1
        @test getqubits(sampled[2]) == (1,)
    end

    @testset "CustomRule: emit multiple instructions" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)
        push!(c, GateCZ(), 1, 2)

        lm = LossModel([
            CustomRule(
                inst -> getoperation(inst) isa GateCZ,
                (inst, lost; rng=nothing) -> begin
                    qs = collect(getqubits(inst))
                    alive = [q for q in qs if !get(lost, q, false)]
                    return [
                        Instruction(GateH(), alive[1]),
                        Instruction(Depolarizing1(0.1), alive[1]),
                    ]
                end,
            ),
        ])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 3
        @test getoperation(sampled[2]) isa GateH
        @test getoperation(sampled[3]) isa Depolarizing1
        @test getqubits(sampled[2]) == (2,)
    end

    @testset "CustomRule: return nothing (drop)" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([
            CustomRule(
                inst -> true,
                (inst, lost; rng=nothing) -> nothing,
            ),
        ])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "multiple rules: first match wins" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)
        push!(c, GateCZ(), 1, 2)

        lm = LossModel([
            ReplaceRule(GateCX() => Depolarizing1(0.2)),
            ReplaceRule(GateCZ() => Depolarizing1(0.1)),
        ])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 3
        @test getoperation(sampled[2]) isa Depolarizing1
        dep_cx = getoperation(sampled[2])
        @test dep_cx.p ≈ 0.2  # CX rule matched
        dep_cz = getoperation(sampled[3])
        @test dep_cz.p ≈ 0.1  # CZ rule matched
    end

    @testset "DropRule has higher priority than broad replace rule" begin
        @variables θ

        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, GateRXX(0.3), 1, 2)
        push!(c, GateRXX(0.2), 1, 2)

        lm = LossModel([
            ReplaceRule(GateRXX(θ), GateZ()),
            DropRule(GateRXX(0.2)),
        ])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa GateZ
        @test getqubits(sampled[2]) == (1,)
    end

    @testset "all qubits lost: always dropped" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)
        push!(c, QubitLoss(), 2)
        push!(c, GateCX(), 1, 2)

        lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.5))])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2  # only the two QubitLoss
        @test all(i -> getoperation(sampled[i]) isa QubitLoss, 1:2)
    end

    @testset "broadcast 1-qubit replacement on N-qubit gate" begin
        c = Circuit()
        push!(c, QubitLoss(), 3)
        push!(c, GateCCX(), 1, 2, 3)  # 3-qubit, q3 lost → 2 surviving

        # 1-qubit replacement broadcasts to all 3 qubits, lost one filtered out
        lm = LossModel([ReplaceRule(GateCCX() => Depolarizing1(0.2))])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 3  # QubitLoss + 2 surviving depolarizing
        @test getoperation(sampled[2]) isa Depolarizing1
        @test getqubits(sampled[2]) == (1,)
        @test getoperation(sampled[3]) isa Depolarizing1
        @test getqubits(sampled[3]) == (2,)
    end

    @testset "N-qubit gates: matching qubit count replacement filtered" begin
        c = Circuit()
        push!(c, QubitLoss(), 3)
        push!(c, GateCCX(), 1, 2, 3)  # 3-qubit, q3 lost

        # Matching qubit count replacement: Depolarizing(3,...) replaces CCX
        # But the 3-qubit instruction touches q3 (lost) → filtered out
        lm = LossModel([ReplaceRule(GateCCX(), Depolarizing(3, 0.1))])
        sampled = sample_losses(c; lossmodel=lm)
        @test length(sampled) == 1  # only QubitLoss, replacement was filtered
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "N-qubit gates: vector replacement" begin
        c = Circuit()
        push!(c, QubitLoss(), 3)
        push!(c, GateCCX(), 1, 2, 3)  # q3 lost

        # Form 1: vector of canonical instructions, q3's instruction filtered
        lm = LossModel([ReplaceRule(GateCCX(), [
            Instruction(Depolarizing1(0.1), 1),
            Instruction(Depolarizing1(0.2), 2),
            Instruction(Depolarizing1(0.3), 3),
        ])])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 3  # QubitLoss + 2 surviving
        @test getqubits(sampled[2]) == (1,)
        @test getqubits(sampled[3]) == (2,)
    end

    @testset "no lost qubits: passes through" begin
        c = Circuit()
        push!(c, GateCX(), 1, 2)
        push!(c, GateH(), 1)

        lm = LossModel([DropRule()])
        sampled = sample_losses(c; lossmodel=lm)

        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa GateCX
        @test getoperation(sampled[2]) isa GateH
    end

    @testset "CheckLoss and MeasureCheckLoss always kept" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)
        push!(c, CheckLoss(), 1, 1)
        push!(c, MeasureCheckLoss(), 1, 1, 2)

        sampled = sample_losses(c)

        @test length(sampled) == 3
        @test getoperation(sampled[2]) isa CheckLoss
        @test getoperation(sampled[3]) isa MeasureCheckLoss
    end

    @testset "QubitReload resets loss status" begin
        c = Circuit()
        push!(c, QubitLoss(), 2)
        push!(c, QubitReload(), 2)
        push!(c, GateCX(), 1, 2)

        sampled = sample_losses(c)

        @test length(sampled) == 3
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa QubitReload
        @test getoperation(sampled[3]) isa GateCX
    end

    @testset "LossErr: deterministic with p=1" begin
        c = Circuit()
        push!(c, LossErr(1.0), 1)
        push!(c, GateCX(), 1, 2)

        sampled = sample_losses(c; rng=MersenneTwister(42))

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "LossErr: deterministic with p=0" begin
        c = Circuit()
        push!(c, LossErr(0.0), 1)
        push!(c, GateCX(), 1, 2)

        sampled = sample_losses(c; rng=MersenneTwister(42))

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa GateCX
    end

    @testset "LossErr: already-lost qubit ignored" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)
        push!(c, LossErr(1.0), 1)  # should be ignored, q1 already lost
        push!(c, GateH(), 2)

        sampled = sample_losses(c; rng=MersenneTwister(42))

        @test length(sampled) == 2
        @test getoperation(sampled[1]) isa QubitLoss
        @test getoperation(sampled[2]) isa GateH
    end

    @testset "QubitReload on non-lost qubit is a no-op" begin
        c = Circuit()
        push!(c, QubitReload(), 1)  # qubit 1 was never lost
        push!(c, GateH(), 1)

        sampled = sample_losses(c)

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa GateH
    end

    @testset "1-qubit gate on lost qubit is dropped" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)
        push!(c, GateH(), 1)

        sampled = sample_losses(c)

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "1-qubit noise on lost qubit is dropped" begin
        c = Circuit()
        push!(c, QubitLoss(), 1)
        push!(c, Depolarizing1(0.1), 1)

        sampled = sample_losses(c)

        @test length(sampled) == 1
        @test getoperation(sampled[1]) isa QubitLoss
    end

    @testset "LossModel display" begin
        lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2)), DropRule()])
        @test occursin("2 rules", string(lm))

        lm2 = LossModel(; name="my_model")
        @test occursin("my_model", string(lm2))
    end
end
