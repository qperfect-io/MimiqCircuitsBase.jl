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

@testset "CircuitRules" begin
    @testset "DropRule construction" begin
        @test DropRule().operation === nothing
        @test DropRule(GateCX()).operation isa GateCX
        @test_throws ArgumentError DropRule(Depolarizing1(0.1))
    end

    @testset "DropRule matching" begin
        dr = DropRule(GateCX())
        @test matches(dr, Instruction(GateCX(), 1, 2))
        @test !matches(dr, Instruction(GateCZ(), 1, 2))

        # catch-all
        dr_all = DropRule()
        @test matches(dr_all, Instruction(GateCX(), 1, 2))
        @test matches(dr_all, Instruction(GateH(), 1))
    end

    @testset "ReplaceRule construction" begin
        rr = ReplaceRule(GateCX(), Depolarizing1(0.2))
        @test rr.operation isa GateCX
        @test rr.replacement isa Depolarizing1

        # Pair constructor
        rr2 = ReplaceRule(GateCX() => Depolarizing1(0.2))
        @test rr2.operation isa GateCX
        @test rr2.replacement isa Depolarizing1
    end

    @testset "ReplaceRule matching" begin
        rr = ReplaceRule(GateCX() => Depolarizing1(0.2))
        @test matches(rr, Instruction(GateCX(), 1, 2))
        @test !matches(rr, Instruction(GateCZ(), 1, 2))
    end

    @testset "DecorateRule construction" begin
        dr = DecorateRule(GateCX(), Depolarizing1(0.1))
        @test dr.before == false

        dr2 = DecorateRule(GateCX(), Depolarizing1(0.1); before=true)
        @test dr2.before == true

        # Pair constructor
        dr3 = DecorateRule(GateCX() => Depolarizing1(0.1))
        @test dr3.operation isa GateCX
    end

    @testset "CustomRule matching" begin
        cr = CustomRule(
            inst -> getoperation(inst) isa GateCX,
            (inst, lost; rng=nothing) -> nothing,
        )
        @test matches(cr, Instruction(GateCX(), 1, 2))
        @test !matches(cr, Instruction(GateH(), 1))
    end

    @testset "LossModel construction" begin
        lm = LossModel()
        @test isempty(lm.rules)
        @test lm.name == ""

        lm2 = LossModel([DropRule()]; name="test")
        @test length(lm2.rules) == 1
        @test lm2.name == "test"

        @variables θ
        lm3 = LossModel([
            ReplaceRule(GateRXX(θ), GateZ()),
            DropRule(GateRXX(0.2)),
        ])
        @test lm3.rules[1] isa DropRule
        @test lm3.rules[2] isa ReplaceRule
    end

    @testset "show methods" begin
        @test occursin("DropRule(*)", string(DropRule()))
        @test occursin("DropRule(", string(DropRule(GateCX())))
        @test occursin("ReplaceRule(", string(ReplaceRule(GateCX() => Depolarizing1(0.2))))
        @test occursin("DecorateRule(", string(DecorateRule(GateCX(), Depolarizing1(0.1))))
        @test occursin("CustomRule(<callable>)", string(CustomRule(x -> true, (x, l; rng=nothing) -> nothing)))
        @test occursin("LossModel", string(LossModel()))
    end

    @testset "AbstractCircuitRule hierarchy" begin
        @test DropRule <: AbstractCircuitRule
        @test ReplaceRule <: AbstractCircuitRule
        @test DecorateRule <: AbstractCircuitRule
        @test CustomRule <: AbstractCircuitRule
        @test AbstractNoiseRule <: AbstractCircuitRule
    end

    @testset "unified interface: before, replaces" begin
        # DropRule always replaces, never before
        @test replaces(DropRule()) == true
        @test before(DropRule()) == false
        @test priority(DropRule()) < priority(ReplaceRule(GateCX() => Depolarizing1(0.2)))

        # ReplaceRule always replaces, never before
        rr = ReplaceRule(GateCX() => Depolarizing1(0.2))
        @test replaces(rr) == true
        @test before(rr) == false

        # DecorateRule never replaces, before is configurable
        dr_after = DecorateRule(GateCX(), Depolarizing1(0.1))
        @test replaces(dr_after) == false
        @test before(dr_after) == false

        dr_before = DecorateRule(GateCX(), Depolarizing1(0.1); before=true)
        @test replaces(dr_before) == false
        @test before(dr_before) == true

        # CustomRule replaces by default
        cr = CustomRule(x -> true, (x, l; rng=nothing) -> nothing)
        @test replaces(cr) == true
        @test before(cr) == false
    end

    @testset "add_rule! keeps priority order" begin
        @variables θ
        model = LossModel([ReplaceRule(GateRXX(θ), GateZ())])
        add_drop!(model, GateRXX(0.2))

        @test model.rules[1] isa DropRule
        @test model.rules[2] isa ReplaceRule
    end

    @testset "matches is the same for noise and circuit rules" begin
        # Both noise rules and circuit rules use matches()
        dr = DropRule(GateCX())
        @test matches(dr, Instruction(GateCX(), 1, 2))
        @test !matches(dr, Instruction(GateH(), 1))

        # NoiseModel rules also use matches() (same function)
        nr = OperationInstanceNoise(GateH(), Depolarizing1(0.01))
        @test matches(nr, Instruction(GateH(), 1))
        @test !matches(nr, Instruction(GateCX(), 1, 2))
    end

    @testset "apply_rule returns Vector{Instruction}" begin
        inst = Instruction(GateCX(), 3, 5)

        # DropRule: empty vector (drop)
        dr = DropRule(GateCX())
        @test apply_rule(dr, inst) == Instruction[]

        # DropRule: nothing if no match
        @test apply_rule(dr, Instruction(GateH(), 1)) === nothing

        # ReplaceRule with matching qubit count (Form 2)
        rr = ReplaceRule(GateCX(), Depolarizing2(0.1))
        result = apply_rule(rr, inst)
        @test length(result) == 1
        @test getoperation(result[1]) isa Depolarizing2
        @test getqubits(result[1]) == (3, 5)

        # ReplaceRule with 1-qubit broadcast (Form 3)
        rr3 = ReplaceRule(GateCX(), Depolarizing1(0.2))
        result3 = apply_rule(rr3, inst)
        @test length(result3) == 2
        @test getoperation(result3[1]) isa Depolarizing1
        @test getqubits(result3[1]) == (3,)
        @test getqubits(result3[2]) == (5,)

        # DecorateRule: keeps original + adds after
        dec = DecorateRule(GateCX(), Depolarizing1(0.1))
        result_dec = apply_rule(dec, inst)
        @test length(result_dec) == 3  # inst + 2 broadcast decorations
        @test result_dec[1] === inst
        @test getoperation(result_dec[2]) isa Depolarizing1
        @test getqubits(result_dec[2]) == (3,)
        @test getqubits(result_dec[3]) == (5,)

        # DecorateRule with before=true
        dec_before = DecorateRule(GateCX(), Depolarizing1(0.1); before=true)
        result_before = apply_rule(dec_before, inst)
        @test length(result_before) == 3
        @test result_before[3] === inst  # original is last
        @test getoperation(result_before[1]) isa Depolarizing1
    end

    @testset "ReplaceRule with Vector{Instruction} (Form 1)" begin
        # Canonical qubits: 1=control, 2=target
        rr = ReplaceRule(GateCX(), [
            Instruction(Depolarizing1(0.2), 1),
            Instruction(GateH(), 2),
        ])
        inst = Instruction(GateCX(), 5, 7)
        result = apply_rule(rr, inst)
        @test length(result) == 2
        @test getoperation(result[1]) isa Depolarizing1
        @test getqubits(result[1]) == (5,)  # canonical 1 → actual 5
        @test getoperation(result[2]) isa GateH
        @test getqubits(result[2]) == (7,)  # canonical 2 → actual 7
    end

    @testset "replacement qubit validation" begin
        # 3-qubit gate with 2-qubit replacement → error
        @test_throws ArgumentError ReplaceRule(GateCCX(), Depolarizing2(0.1))
        @test_throws ArgumentError DecorateRule(GateCCX(), Depolarizing2(0.1))
    end
end
