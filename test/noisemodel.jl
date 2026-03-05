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
using Symbolics

@testset "AbstractNoiseRule Interface" begin
    # Test that priority and before have default implementations
    struct DummyRule <: AbstractNoiseRule end

    dummy = DummyRule()
    @test priority(dummy) == 100
    @test before(dummy) == false

    # Test that matches and apply_rule throw errors for unimplemented rules
    inst = Instruction(GateH(), 1)

    @test_throws ErrorException matches(dummy, inst)
    @test_throws ErrorException apply_rule(dummy, inst)
end

@testset "GlobalReadoutNoise" begin
    @testset "Construction" begin
        @test GlobalReadoutNoise(ReadoutErr(0.01, 0.02)) isa GlobalReadoutNoise
    end

    @testset "One-qubit" begin
        rule = GlobalReadoutNoise(ReadoutErr(0.01, 0.02))

        @test matches(rule, Instruction(Measure(), 1, 1))
        @test matches(rule, Instruction(Measure(), 2, 1))
        @test matches(rule, Instruction(Measure(), 3, 1))
        @test matches(rule, Instruction(Measure(), 4, 1))
        @test matches(rule, Instruction(Measure(), 5, 1))
        @test matches(rule, Instruction(Measure(), 6, 1))

        @test apply_rule(rule, Instruction(Measure(), 1, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
        @test apply_rule(rule, Instruction(Measure(), 2, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
    end

    @testset "Two-qubit" begin
        rule = GlobalReadoutNoise(ReadoutErr(0.01, 0.02))

        @test matches(rule, Instruction(MeasureZZ(), 1, 2, 1))
        @test matches(rule, Instruction(MeasureZZ(), 2, 3, 1))
        @test matches(rule, Instruction(MeasureZZ(), 3, 4, 2))
        @test matches(rule, Instruction(MeasureZZ(), 4, 5, 2))
        @test matches(rule, Instruction(MeasureZZ(), 5, 6, 1))
        @test matches(rule, Instruction(MeasureZZ(), 6, 7, 1))

        @test apply_rule(rule, Instruction(MeasureZZ(), 1, 2, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
        @test apply_rule(rule, Instruction(MeasureZZ(), 2, 3, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
    end
end

@testset "ExactQubitReadoutNoise" begin
    @testset "Construction" begin
        # repeated qubits
        @test_throws ArgumentError ExactQubitReadoutNoise([1, 1], ReadoutErr(0.01, 0.02))

        # wrong number of qubits
        @test_throws ArgumentError ExactQubitReadoutNoise([], ReadoutErr(0.01, 0.02))

        # ok
        @test ExactQubitReadoutNoise([1], ReadoutErr(0.01, 0.02)) isa ExactQubitReadoutNoise
        @test ExactQubitReadoutNoise([2], ReadoutErr(0.01, 0.02)) isa ExactQubitReadoutNoise
        @test ExactQubitReadoutNoise([2, 3], ReadoutErr(0.01, 0.02)) isa ExactQubitReadoutNoise
        @test ExactQubitReadoutNoise([3, 2], ReadoutErr(0.01, 0.02)) isa ExactQubitReadoutNoise
    end

    @testset "One-qubit" begin
        rule = ExactQubitReadoutNoise([1], ReadoutErr(0.01, 0.02))

        @test matches(rule, Instruction(Measure(), 1, 1))
        @test !matches(rule, Instruction(Measure(), 2, 1))
        @test !matches(rule, Instruction(Measure(), 3, 1))
        @test !matches(rule, Instruction(Measure(), 4, 1))

        @test apply_rule(rule, Instruction(Measure(), 1, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
    end

    @testset "Two-qubit" begin
        rule = ExactQubitReadoutNoise([1, 2], ReadoutErr(0.01, 0.02))

        @test matches(rule, Instruction(MeasureZZ(), 1, 2, 1))
        @test !matches(rule, Instruction(MeasureZZ(), 2, 3, 1))
        @test !matches(rule, Instruction(MeasureZZ(), 3, 4, 2))
        @test !matches(rule, Instruction(MeasureZZ(), 4, 5, 2))

        @test apply_rule(rule, Instruction(MeasureZZ(), 1, 2, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
    end
end

@testset "SetQubitReadoutNoise" begin
    @testset "Construction" begin
        # repeated qubits
        @test_throws ArgumentError SetQubitReadoutNoise([1, 1], ReadoutErr(0.01, 0.02))

        # ok
        @test SetQubitReadoutNoise([1], ReadoutErr(0.01, 0.02)) isa SetQubitReadoutNoise
        @test SetQubitReadoutNoise([2, 3, 4], ReadoutErr(0.01, 0.02)) isa SetQubitReadoutNoise
    end

    @testset "One-qubit" begin
        rule = SetQubitReadoutNoise([1, 3, 5], ReadoutErr(0.01, 0.02))

        @test matches(rule, Instruction(Measure(), 1, 1))
        @test !matches(rule, Instruction(Measure(), 2, 1))
        @test matches(rule, Instruction(Measure(), 3, 1))
        @test !matches(rule, Instruction(Measure(), 4, 1))
        @test matches(rule, Instruction(Measure(), 5, 1))
        @test !matches(rule, Instruction(Measure(), 6, 1))

        @test apply_rule(rule, Instruction(Measure(), 1, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
        @test apply_rule(rule, Instruction(Measure(), 3, 4)) == Instruction(ReadoutErr(0.01, 0.02), 4)
    end

    @testset "Two-qubit" begin
        rule = SetQubitReadoutNoise([1, 3, 5], ReadoutErr(0.01, 0.02))

        @test matches(rule, Instruction(MeasureZZ(), 1, 3, 1))
        @test !matches(rule, Instruction(MeasureZZ(), 2, 3, 1))
        @test matches(rule, Instruction(MeasureZZ(), 3, 5, 2))
        @test !matches(rule, Instruction(MeasureZZ(), 4, 5, 2))
        @test matches(rule, Instruction(MeasureZZ(), 5, 3, 1))
        @test !matches(rule, Instruction(MeasureZZ(), 6, 7, 1))

        @test apply_rule(rule, Instruction(MeasureZZ(), 1, 3, 1)) == Instruction(ReadoutErr(0.01, 0.02), 1)
        @test apply_rule(rule, Instruction(MeasureZZ(), 5, 3, 2)) == Instruction(ReadoutErr(0.01, 0.02), 2)
    end
end

@testset "OperationInstanceNoise" begin
    @testset "Construction" begin
        # one-qubit wrong number of qubit for the noise
        @test_throws ArgumentError OperationInstanceNoise(GateH(), Depolarizing2(0.01))

        # two-qubits wrong number of qubit for the noise
        @test_throws ArgumentError OperationInstanceNoise(GateCX(), Depolarizing1(0.01))

        # invalid operation target kinds
        @test_throws ArgumentError OperationInstanceNoise(AmplitudeDamping(0.1), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(Projector0(), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(Not(), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(Add(2), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(Multiply(2), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(Pow(2.0), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(ExpectationValue(GateX()), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(BondDim(), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(SchmidtRank(), PauliX(0.01))
        @test_throws ArgumentError OperationInstanceNoise(VonNeumannEntropy(), PauliX(0.01))

        # incompatible flags
        @test_throws ArgumentError OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), before=true, replace=true)

        @test OperationInstanceNoise(GateH(), AmplitudeDamping(0.01)) isa OperationInstanceNoise
        @test OperationInstanceNoise(GateRX(0.038), AmplitudeDamping(0.01)) isa OperationInstanceNoise
        @test OperationInstanceNoise(GateCX(), Depolarizing2(0.01)) isa OperationInstanceNoise
        @test OperationInstanceNoise(ResetZ(), PauliX(0.01)) isa OperationInstanceNoise
        @test OperationInstanceNoise(
            Block(1, 0, 0, [Instruction(GateH(), (1,), (), ())]),
            AmplitudeDamping(0.01)
        ) isa OperationInstanceNoise
        @test OperationInstanceNoise(Repeat(2, GateH()), AmplitudeDamping(0.01)) isa OperationInstanceNoise
        @test OperationInstanceNoise(IfStatement(GateH(), BitString("1")), AmplitudeDamping(0.01)) isa OperationInstanceNoise
        @test OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), replace=true) isa OperationInstanceNoise
    end

    @testset "One-qubit" begin
        rule = OperationInstanceNoise(GateH(), AmplitudeDamping(0.01))
        @test matches(rule, Instruction(GateH(), 1))
        @test matches(rule, Instruction(GateH(), 2))
        @test matches(rule, Instruction(GateH(), 3))
        @test !matches(rule, Instruction(GateRX(π / 2), 1))

        @test apply_rule(rule, Instruction(GateH(), 1)) == Instruction(AmplitudeDamping(0.01), 1)
        @test apply_rule(rule, Instruction(GateH(), 2)) == Instruction(AmplitudeDamping(0.01), 2)
        @test apply_rule(rule, Instruction(GateH(), 3)) == Instruction(AmplitudeDamping(0.01), 3)
    end

    @testset "Two-qubit" begin
        rule = OperationInstanceNoise(GateCX(), Depolarizing2(0.01))
        @test matches(rule, Instruction(GateCX(), 1, 2))
        @test matches(rule, Instruction(GateCX(), 2, 1))
        @test matches(rule, Instruction(GateCX(), 1, 3))
        @test matches(rule, Instruction(GateCX(), 3, 2))
        @test !matches(rule, Instruction(GateH(), 1))
        @test !matches(rule, Instruction(GateH(), 2))

        @test apply_rule(rule, Instruction(GateCX(), 1, 2)) == Instruction(Depolarizing2(0.01), 1, 2)
        @test apply_rule(rule, Instruction(GateCX(), 2, 1)) == Instruction(Depolarizing2(0.01), 2, 1)
        @test apply_rule(rule, Instruction(GateCX(), 1, 3)) == Instruction(Depolarizing2(0.01), 1, 3)
    end

    @testset "Symbolic" begin
        @variables p q

        @test_throws ArgumentError OperationInstanceNoise(GateRX(p + 3.0), AmplitudeDamping(p))

        rule = OperationInstanceNoise(GateRX(p), AmplitudeDamping(0.01 * p / π))

        @test matches(rule, Instruction(GateRX(0.5), 1))
        @test matches(rule, Instruction(GateRX(1.0), 2))
        @test matches(rule, Instruction(GateRX(q), 3))
        @test !matches(rule, Instruction(GateRY(0.5), 1))

        @test apply_rule(rule, Instruction(GateRX(0.5), 1)) == Instruction(AmplitudeDamping(0.01 * 0.5 / π), 1)
        @test apply_rule(rule, Instruction(GateRX(1.0), 2)) == Instruction(AmplitudeDamping(0.01 * 1.0 / π), 2)
        @test_throws ArgumentError apply_rule(rule, Instruction(GateRX(q), 3))
    end
end

@testset "ExactOperationInstanceQubitNoise" begin
    @testset "Construction" begin
        # one-qubit wrong number of qubit for the noise
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateH(), [1], Depolarizing2(0.01))

        # two-qubits wrong number of qubit for the noise
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing1(0.01))

        # invalid operation target kind
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(AmplitudeDamping(0.1), [1], PauliX(0.01))

        # one-qubit wrong number of qubits
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateH(), [], AmplitudeDamping(0.01))
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateH(), [1, 2], AmplitudeDamping(0.01))

        # two-qubits wrong number of qubits
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateCX(), [], Depolarizing2(0.01))
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateCX(), [1], Depolarizing2(0.01))
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateCX(), [1, 2, 3], Depolarizing2(0.01))

        # two-qubits repeated qubits
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateCX(), [1, 1], Depolarizing2(0.01))
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateCX(), [2, 2], Depolarizing2(0.01))

        # incompatible flags
        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateH(), [1], AmplitudeDamping(0.01), before=true, replace=true)
    end

    @testset "One-qubit" begin
        rule = ExactOperationInstanceQubitNoise(GateH(), [1], AmplitudeDamping(0.01))
        @test matches(rule, Instruction(GateH(), 1))
        @test !matches(rule, Instruction(GateH(), 2))
        @test !matches(rule, Instruction(GateH(), 3))
        @test !matches(rule, Instruction(GateRX(π / 2), 1))

        @test ExactOperationInstanceQubitNoise(GateH(), [1], AmplitudeDamping(0.01)) isa ExactOperationInstanceQubitNoise
        @test ExactOperationInstanceQubitNoise(GateH(), [2], AmplitudeDamping(0.01)) isa ExactOperationInstanceQubitNoise
    end

    @testset "Two-qubit" begin
        rule = ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.01))
        @test matches(rule, Instruction(GateCX(), 1, 2))
        @test !matches(rule, Instruction(GateCX(), 2, 1))
        @test !matches(rule, Instruction(GateCX(), 1, 3))
        @test !matches(rule, Instruction(GateCX(), 3, 2))
        @test !matches(rule, Instruction(GateH(), 1))
        @test !matches(rule, Instruction(GateH(), 2))
        @test !matches(rule, Instruction(GateRX(π / 2), 1))

        @test ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.01)) isa ExactOperationInstanceQubitNoise
        @test ExactOperationInstanceQubitNoise(GateCX(), [2, 3], Depolarizing2(0.01)) isa ExactOperationInstanceQubitNoise
    end

    @testset "Symbolic" begin
        @variables p q

        @test_throws ArgumentError ExactOperationInstanceQubitNoise(GateRX(p + 3.0), [1], AmplitudeDamping(p))

        rule = ExactOperationInstanceQubitNoise(GateRX(p), [2], AmplitudeDamping(0.01 * p / π))

        @test matches(rule, Instruction(GateRX(0.5), 2))
        @test matches(rule, Instruction(GateRX(q), 2))
        @test !matches(rule, Instruction(GateRY(0.5), 2))
        @test !matches(rule, Instruction(GateRX(0.5), 1))

        @test apply_rule(rule, Instruction(GateRX(0.5), 2)) == Instruction(AmplitudeDamping(0.01 * 0.5 / π), 2)
        @test_throws ArgumentError apply_rule(rule, Instruction(GateRX(q), 2))
    end
end

@testset "SetOperationInstanceQubitNoise" begin
    @testset "Construction" begin
        # one-qubit wrong number of qubit for the noise
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateH(), [1], Depolarizing2(0.01))
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateH(), [1, 2], Depolarizing2(0.01))

        # two-qubits wrong number of qubit for the noise
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateCX(), [1], Depolarizing1(0.01))
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing1(0.01))
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateCX(), [1, 2, 3], Depolarizing1(0.01))

        # invalid operation target kind
        @test_throws ArgumentError SetOperationInstanceQubitNoise(AmplitudeDamping(0.1), [1], PauliX(0.01))

        # one-qubit too few qubits
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateH(), [], AmplitudeDamping(0.01))

        # two-qubits too few qubits
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateCX(), [1], Depolarizing2(0.01))

        # incompatible flags
        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateH(), [1], AmplitudeDamping(0.01), before=true, replace=true)

        # ok
        @test SetOperationInstanceQubitNoise(GateH(), [1], AmplitudeDamping(0.01)) isa SetOperationInstanceQubitNoise
        @test SetOperationInstanceQubitNoise(GateH(), [1, 2, 3], AmplitudeDamping(0.01)) isa SetOperationInstanceQubitNoise
        @test SetOperationInstanceQubitNoise(GateRX(0.038), [1], AmplitudeDamping(0.01)) isa SetOperationInstanceQubitNoise
        @test SetOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.01)) isa SetOperationInstanceQubitNoise
        @test SetOperationInstanceQubitNoise(GateCX(), [1, 2, 3], Depolarizing2(0.01)) isa SetOperationInstanceQubitNoise
        @test SetOperationInstanceQubitNoise(GateCX(), [1, 2, 3, 4], Depolarizing2(0.01)) isa SetOperationInstanceQubitNoise
        @test SetOperationInstanceQubitNoise(GateCP(0.05), [1, 2], Depolarizing2(0.01)) isa SetOperationInstanceQubitNoise
    end

    @testset "Single-qubit" begin
        rule = SetOperationInstanceQubitNoise(GateRY(0.038), [1, 3, 5], AmplitudeDamping(0.01))
        @test matches(rule, Instruction(GateRY(0.038), 1))
        @test matches(rule, Instruction(GateRY(0.038), 3))
        @test matches(rule, Instruction(GateRY(0.038), 5))
        @test !matches(rule, Instruction(GateRY(0.038), 2))
        @test !matches(rule, Instruction(GateRY(0.038), 4))
        @test !matches(rule, Instruction(GateRY(0.038), 6))
        @test !matches(rule, Instruction(GateRY(0.04), 1))
        @test !matches(rule, Instruction(GateRY(0.04), 3))
        @test !matches(rule, Instruction(GateRY(0.04), 5))
        @test !matches(rule, Instruction(GateH(), 1))
        @test !matches(rule, Instruction(GateH(), 3))
        @test !matches(rule, Instruction(GateH(), 5))

        @test apply_rule(rule, Instruction(GateRY(0.038), 1)) == Instruction(AmplitudeDamping(0.01), 1)
        @test apply_rule(rule, Instruction(GateRY(0.038), 3)) == Instruction(AmplitudeDamping(0.01), 3)
        @test apply_rule(rule, Instruction(GateRY(0.038), 5)) == Instruction(AmplitudeDamping(0.01), 5)
    end

    @testset "Two-qubit" begin
        rule = SetOperationInstanceQubitNoise(GateCP(0.05), [2, 4], Depolarizing2(0.01))
        @test matches(rule, Instruction(GateCP(0.05), 2, 4))
        @test matches(rule, Instruction(GateCP(0.05), 4, 2))
        @test !matches(rule, Instruction(GateCP(0.05), 1, 2))
        @test !matches(rule, Instruction(GateCP(0.05), 3, 4))
        @test !matches(rule, Instruction(GateCP(0.04), 2, 4))
        @test !matches(rule, Instruction(GateH(), 2))
        @test !matches(rule, Instruction(GateH(), 4))
        @test !matches(rule, Instruction(GateRX(π / 2), 2))
        @test !matches(rule, Instruction(GateP(0.05), 4))

        @test apply_rule(rule, Instruction(GateCP(0.05), 2, 4)) == Instruction(Depolarizing2(0.01), 2, 4)
        @test apply_rule(rule, Instruction(GateCP(0.05), 4, 2)) == Instruction(Depolarizing2(0.01), 4, 2)
    end

    @testset "Symbolic" begin
        @variables p q

        @test_throws ArgumentError SetOperationInstanceQubitNoise(GateRX(p + 3.0), [1, 2], AmplitudeDamping(p))

        rule = SetOperationInstanceQubitNoise(GateRX(p), [2, 4, 6], AmplitudeDamping(0.01 * p / π))

        @test matches(rule, Instruction(GateRX(0.5), 2))
        @test matches(rule, Instruction(GateRX(0.5), 4))
        @test matches(rule, Instruction(GateRX(0.5), 6))
        @test matches(rule, Instruction(GateRX(q), 4))
        @test !matches(rule, Instruction(GateRX(1.0), 3))
        @test !matches(rule, Instruction(GateRY(0.5), 2))
        @test !matches(rule, Instruction(GateRX(0.5), 1))

        @test apply_rule(rule, Instruction(GateRX(0.5), 2)) == Instruction(AmplitudeDamping(0.01 * 0.5 / π), 2)
        @test apply_rule(rule, Instruction(GateRX(0.5), 4)) == Instruction(AmplitudeDamping(0.01 * 0.5 / π), 4)
        @test apply_rule(rule, Instruction(GateRX(0.5), 6)) == Instruction(AmplitudeDamping(0.01 * 0.5 / π), 6)
        @test_throws ArgumentError apply_rule(rule, Instruction(GateRX(q), 4))
    end
end

@testset "IdleNoise" begin
    @variables t
    rule = IdleNoise(t => AmplitudeDamping(0.0001 * t))

    @test before(rule) == false
    @test matches(rule, Instruction(Delay(0.1), 1))
    @test matches(rule, Instruction(Delay(0.1), 2))
    @test matches(rule, Instruction(Delay(0.1), 3))
    @test matches(rule, Instruction(Delay(0.1), 12))
    @test matches(rule, Instruction(Delay(0.1), 34783))
    @test !matches(rule, Instruction(GateH(), 1))
    @test !matches(rule, Instruction(GateCX(), 1, 2))
    @test !matches(rule, Instruction(Measure(), 1, 1))
    @test !matches(rule, Instruction(MeasureZZ(), 1, 2, 1))

    # test the apply_rule
    @test apply_rule(rule, Instruction(Delay(0.1), 1)) == Instruction(AmplitudeDamping(0.0001 * 0.1), 1)
    @test apply_rule(rule, Instruction(Delay(0.2), 1)) == Instruction(AmplitudeDamping(0.0001 * 0.2), 1)
    @test apply_rule(rule, Instruction(Delay(0.3), 2)) == Instruction(AmplitudeDamping(0.0001 * 0.3), 2)
    @test apply_rule(rule, Instruction(Delay(0.4), 34783)) == Instruction(AmplitudeDamping(0.0001 * 0.4), 34783)

    # Constant symbolic expressions should be concretized after substitution.
    dep_rule = IdleNoise(t => Depolarizing1(1 - exp(-t / 20e6)))
    dep_inst = apply_rule(dep_rule, Instruction(Delay(1), 1))
    dep_p = getparam(getoperation(dep_inst), :p)
    @test dep_p isa Symbolics.Num
    @test !issymbolic(dep_p)
    @test Symbolics.value(dep_p) isa Real
end

@testset "CustomNoiseRule" begin
    @testset "Construction" begin
        @test CustomNoiseRule((inst,) -> getoperation(inst) isa GateH, (inst,) -> Instruction(AmplitudeDamping(0.01), getqubits(inst)...)) isa CustomNoiseRule
        @test CustomNoiseRule((inst,) -> getoperation(inst) isa GateCX, (inst,) -> Instruction(Depolarizing2(0.01), getqubits(inst)...)) isa CustomNoiseRule
    end

    @testset "One-qubit" begin
        rule = CustomNoiseRule((inst,) -> getoperation(inst) isa GateH, (inst,) -> Instruction(AmplitudeDamping(0.01), getqubits(inst)...))
        @test matches(rule, Instruction(GateH(), 1))
        @test matches(rule, Instruction(GateH(), 2))
        @test matches(rule, Instruction(GateH(), 3))
        @test !matches(rule, Instruction(GateRX(π / 2), 1))

        @test apply_rule(rule, Instruction(GateH(), 1)) == Instruction(AmplitudeDamping(0.01), 1)
        @test apply_rule(rule, Instruction(GateH(), 2)) == Instruction(AmplitudeDamping(0.01), 2)
        @test apply_rule(rule, Instruction(GateH(), 3)) == Instruction(AmplitudeDamping(0.01), 3)
    end

    @testset "Two-qubit" begin
        rule = CustomNoiseRule((inst,) -> getoperation(inst) isa GateCX, (inst,) -> Instruction(Depolarizing2(0.01), getqubits(inst)...))

        @test matches(rule, Instruction(GateCX(), 1, 2))
        @test matches(rule, Instruction(GateCX(), 2, 1))
        @test matches(rule, Instruction(GateCX(), 1, 3))
        @test matches(rule, Instruction(GateCX(), 3, 2))
        @test !matches(rule, Instruction(GateH(), 1))
        @test !matches(rule, Instruction(GateH(), 2))

        @test apply_rule(rule, Instruction(GateCX(), 1, 2)) == Instruction(Depolarizing2(0.01), 1, 2)
        @test apply_rule(rule, Instruction(GateCX(), 2, 1)) == Instruction(Depolarizing2(0.01), 2, 1)
        @test apply_rule(rule, Instruction(GateCX(), 1, 3)) == Instruction(Depolarizing2(0.01), 1, 3)
    end
end

@testset "NoiseModel Construction and Sorting" begin
    # Create rules with different priorities
    rule1 = OperationInstanceNoise(GateH(), AmplitudeDamping(0.01))
    rule2 = IdleNoise(AmplitudeDamping(0.0001))
    rule3 = ExactOperationInstanceQubitNoise(GateRX(π / 2), [1], AmplitudeDamping(0.01))

    model = NoiseModel([rule1, rule2, rule3], name="Test Model")

    # Check that rules are sorted by priority
    @test issorted(priority.(model.rules))

    # Test single rule constructor
    model_single = NoiseModel(rule1, name="Single Rule")
    @test length(model_single.rules) == 1

    # Test empty constructor
    model_empty = NoiseModel(name="Empty")
    @test length(model_empty.rules) == 0
end

@testset "add_rule! Function" begin
    model = NoiseModel()

    rule1 = OperationInstanceNoise(GateH(), AmplitudeDamping(0.01))
    rule2 = ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.01))

    add_rule!(model, rule1)
    @test length(model.rules) == 1

    add_rule!(model, rule2)
    @test length(model.rules) == 2

    # Check that rules are sorted
    @test issorted(priority.(model.rules))
end

@testset "apply_noise_model" begin
    @testset "Basic Functionality" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateCX(), 1, 2)
        push!(c, Measure(), 1, 1)

        # Create a simple model
        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01)),
            OperationInstanceNoise(GateCX(), Depolarizing2(0.01)),
            GlobalReadoutNoise(ReadoutErr(0.01, 0.02))
        ])

        noisy_circuit = apply_noise_model(c, model)

        # Original circuit has 3 instructions
        # Noisy circuit should have 6 (3 original + 3 noise)
        @test length(noisy_circuit) == 6

        # Check structure: original gate, then noise
        @test getoperation(noisy_circuit[1]) isa GateH
        @test getoperation(noisy_circuit[2]) isa AmplitudeDamping

        @test getoperation(noisy_circuit[3]) isa GateCX
        @test getoperation(noisy_circuit[4]) isa Depolarizing2

        @test getoperation(noisy_circuit[5]) isa Measure
        @test getoperation(noisy_circuit[6]) isa ReadoutErr
    end

    @testset "Before Flag" begin
        c = Circuit()
        push!(c, GateH(), 1)

        # Model with before=true
        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), before=true)
        ])

        noisy_circuit = apply_noise_model(c, model)

        @test length(noisy_circuit) == 2

        # Noise should come before the gate
        @test getoperation(noisy_circuit[1]) isa AmplitudeDamping
        @test getoperation(noisy_circuit[2]) isa GateH
    end

    @testset "Replace Flag" begin
        c = Circuit()
        push!(c, GateH(), 1)

        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), replace=true)
        ])

        noisy_circuit = apply_noise_model(c, model)

        @test length(noisy_circuit) == 1
        @test getoperation(noisy_circuit[1]) isa AmplitudeDamping
    end

    @testset "Priority Ordering" begin
        c = Circuit()
        push!(c, GateCX(), 1, 2)

        # Create model with overlapping rules
        model = NoiseModel([
            OperationInstanceNoise(GateCX(), Depolarizing2(0.01)),  # priority 100
            ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.02)),  # priority 60
        ])

        noisy_circuit = apply_noise_model(c, model)

        @test length(noisy_circuit) == 2

        # Higher priority rule (lower number) should be applied
        noise_op = getoperation(noisy_circuit[2])
        @test noise_op isa Depolarizing2
        @test getparam(noise_op, :p) == 0.02  # From ExactOperationInstanceQubitNoise
    end

    @testset "No Matching Rules" begin
        c = Circuit()
        push!(c, GateH(), 1)

        # Model with rules that don't match
        model = NoiseModel([
            OperationInstanceNoise(GateCX(), Depolarizing2(0.01))
        ])

        noisy_circuit = apply_noise_model(c, model)

        # Circuit should be unchanged
        @test length(noisy_circuit) == 1
        @test getoperation(noisy_circuit[1]) isa GateH
    end

    @testset "Recursive Wrappers" begin
        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01))
        ])

        @testset "Block" begin
            b = Block(1, 0, 0, [Instruction(GateH(), (1,), (), ())])
            c = Circuit()
            push!(c, b, 1)

            noisy = apply_noise_model(c, model)
            @test length(noisy) == 1
            @test getoperation(noisy[1]) isa Block
            inner = getoperation(noisy[1])
            @test length(inner) == 2
            @test getoperation(inner[1]) isa GateH
            @test getoperation(inner[2]) isa AmplitudeDamping
        end

        @testset "Nested Block" begin
            inner = Block(1, 0, 0, [Instruction(GateH(), (1,), (), ())])
            outer = Block(1, 0, 0, [Instruction(inner, (1,), (), ())])
            c = Circuit()
            push!(c, outer, 1)

            noisy = apply_noise_model(c, model)
            @test length(noisy) == 1

            outer_noisy = getoperation(noisy[1])
            @test outer_noisy isa Block
            @test length(outer_noisy) == 1

            inner_noisy = getoperation(outer_noisy[1])
            @test inner_noisy isa Block
            @test length(inner_noisy) == 2
            @test getoperation(inner_noisy[1]) isa GateH
            @test getoperation(inner_noisy[2]) isa AmplitudeDamping
            @test getqubits(inner_noisy[1]) == (1,)
            @test getqubits(inner_noisy[2]) == (1,)
        end

        @testset "IfStatement" begin
            c = Circuit()
            push!(c, IfStatement(GateH(), BitString("1")), 1, 1)

            noisy = apply_noise_model(c, model)
            @test length(noisy) == 1
            @test getoperation(noisy[1]) isa IfStatement
            inner = getoperation(getoperation(noisy[1]))
            @test inner isa Block
            @test length(inner) == 2
            @test getoperation(inner[1]) isa GateH
            @test getoperation(inner[2]) isa AmplitudeDamping
        end

        @testset "IfStatement Target Rule" begin
            c = Circuit()
            push!(c, IfStatement(GateH(), BitString("1")), 1, 1)

            model_if = NoiseModel([
                OperationInstanceNoise(IfStatement(GateH(), BitString("1")), AmplitudeDamping(0.01))
            ])

            noisy = apply_noise_model(c, model_if)
            @test length(noisy) == 2
            @test getoperation(noisy[1]) isa IfStatement
            @test getoperation(noisy[2]) isa AmplitudeDamping
            @test getqubits(noisy[2]) == (1,)
        end

        @testset "Parallel" begin
            c = Circuit()
            push!(c, Parallel(2, GateH()), 1, 2)

            noisy = apply_noise_model(c, model)
            @test length(noisy) == 1
            @test getoperation(noisy[1]) isa Block
            inner = getoperation(noisy[1])
            @test length(inner) == 4
            @test getoperation(inner[1]) isa GateH
            @test getoperation(inner[2]) isa AmplitudeDamping
            @test getoperation(inner[3]) isa GateH
            @test getoperation(inner[4]) isa AmplitudeDamping
            @test getqubits(inner[1]) == (1,)
            @test getqubits(inner[2]) == (1,)
            @test getqubits(inner[3]) == (2,)
            @test getqubits(inner[4]) == (2,)
        end

        @testset "Repeat" begin
            c = Circuit()
            push!(c, Repeat(2, GateH()), 1)

            noisy = apply_noise_model(c, model)
            @test length(noisy) == 1
            @test getoperation(noisy[1]) isa Block
            inner = getoperation(noisy[1])
            @test length(inner) == 4
            @test getoperation(inner[1]) isa GateH
            @test getoperation(inner[2]) isa AmplitudeDamping
            @test getoperation(inner[3]) isa GateH
            @test getoperation(inner[4]) isa AmplitudeDamping
            @test getqubits(inner[1]) == (1,)
            @test getqubits(inner[2]) == (1,)
            @test getqubits(inner[3]) == (1,)
            @test getqubits(inner[4]) == (1,)
        end

        @testset "GateCall" begin
            decl = GateDecl(:local_h, (), [Instruction(GateH(), (1,), (), ())])
            c = Circuit()
            push!(c, GateCall(decl), 1)

            noisy = apply_noise_model(c, model)
            @test length(noisy) == 1
            @test getoperation(noisy[1]) isa Block
            inner = getoperation(noisy[1])
            @test length(inner) == 2
            @test getoperation(inner[1]) isa GateH
            @test getoperation(inner[2]) isa AmplitudeDamping
        end
    end
end

@testset "apply_noise_model!" begin
    @testset "In-Place Modification" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateCX(), 1, 2)

        original_length = length(c)

        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01)),
            OperationInstanceNoise(GateCX(), Depolarizing2(0.01))
        ])

        result = apply_noise_model!(c, model)

        # Check that the function returns the circuit
        @test result === c

        # Check that circuit was modified in place
        @test length(c) == original_length + 2

        # Check structure
        @test getoperation(c[1]) isa GateH
        @test getoperation(c[2]) isa AmplitudeDamping
        @test getoperation(c[3]) isa GateCX
        @test getoperation(c[4]) isa Depolarizing2
    end

    @testset "Before Flag" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateCX(), 1, 2)

        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), before=true),
            OperationInstanceNoise(GateCX(), Depolarizing2(0.01), before=false)
        ])

        apply_noise_model!(c, model)

        # Check that H has noise before, CX has noise after
        @test getoperation(c[1]) isa AmplitudeDamping  # before H
        @test getoperation(c[2]) isa GateH
        @test getoperation(c[3]) isa GateCX
        @test getoperation(c[4]) isa Depolarizing2  # after CX
    end

    @testset "Replace Flag" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateCX(), 1, 2)

        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), replace=true),
            OperationInstanceNoise(GateCX(), Depolarizing2(0.01))
        ])

        apply_noise_model!(c, model)

        @test getoperation(c[1]) isa AmplitudeDamping
        @test getoperation(c[2]) isa GateCX
        @test getoperation(c[3]) isa Depolarizing2
        @test length(c) == 3
    end
end

@testset "Helpers" begin
    @testset "add_readout_noise!" begin
        model = NoiseModel()

        # Global readout noise
        add_readout_noise!(model, ReadoutErr(0.01, 0.02))
        @test length(model.rules) == 1
        @test model.rules[1] isa GlobalReadoutNoise

        # Set-based readout noise
        add_readout_noise!(model, ReadoutErr(0.03, 0.04), qubits=[1, 3])
        @test length(model.rules) == 2
        @test model.rules[1] isa SetQubitReadoutNoise  # Lower priority than global

        # Exact readout noise
        add_readout_noise!(model, ReadoutErr(0.05, 0.06), qubits=[2, 1], exact=true)
        @test length(model.rules) == 3
        @test model.rules[1] isa ExactQubitReadoutNoise  # Highest priority
    end

    @testset "add_operation_noise!" begin
        @testset "Instance-Based" begin
            model = NoiseModel()

            # Global gate instance noise
            add_operation_noise!(model, GateRX(π / 2), AmplitudeDamping(0.01))
            @test length(model.rules) == 1
            @test model.rules[1] isa OperationInstanceNoise

            # Set-based gate instance noise
            add_operation_noise!(model, GateRY(π / 4), AmplitudeDamping(0.01), qubits=[1, 3, 5])
            @test length(model.rules) == 2
            @test model.rules[1] isa SetOperationInstanceQubitNoise

            # Exact gate instance noise
            add_operation_noise!(model, GateRX(π / 2), AmplitudeDamping(0.02), qubits=[1], exact=true)
            @test length(model.rules) == 3
            @test model.rules[1] isa ExactOperationInstanceQubitNoise

            # Replace mode
            add_operation_noise!(model, GateH(), AmplitudeDamping(0.03), replace=true)
            @test any(r -> r isa OperationInstanceNoise && r.replace, model.rules)

            @test_throws ArgumentError add_operation_noise!(model, GateH(), AmplitudeDamping(0.03), before=true, replace=true)
            @test_throws ArgumentError add_operation_noise!(model, AmplitudeDamping(0.1), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, Projector0(), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, Not(), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, Add(2), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, Multiply(2), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, Pow(2.0), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, ExpectationValue(GateX()), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, BondDim(), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, SchmidtRank(), PauliX(0.01))
            @test_throws ArgumentError add_operation_noise!(model, VonNeumannEntropy(), PauliX(0.01))

            blk = Block(1, 0, 0, [Instruction(GateH(), (1,), (), ())])
            add_operation_noise!(model, blk, AmplitudeDamping(0.01))
            @test any(r -> r isa OperationInstanceNoise && r.operation == blk, model.rules)

            rep = Repeat(2, GateH())
            add_operation_noise!(model, rep, AmplitudeDamping(0.01))
            @test any(r -> r isa OperationInstanceNoise && r.operation == rep, model.rules)

            ifop = IfStatement(GateH(), BitString("1"))
            add_operation_noise!(model, ifop, AmplitudeDamping(0.01))
            @test any(r -> r isa OperationInstanceNoise && r.operation == ifop, model.rules)
        end
    end
end

@testset "Complex Circuit Example" begin
    # Build a more complex circuit
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, GateH(), 2)
    push!(c, GateCX(), 1, 2)
    push!(c, GateCX(), 2, 1)  # Reversed direction
    push!(c, GateRX(π / 2), 1)
    push!(c, Measure(), 1, 1)

    # Create a comprehensive noise model
    model = NoiseModel([
            # Specific direction-dependent CNOT noise
            ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.01)),
            ExactOperationInstanceQubitNoise(GateCX(), [2, 1], Depolarizing2(0.02)),

            # General Hadamard noise
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.001)),

            # Specific RX noise
            OperationInstanceNoise(GateRX(π / 2), AmplitudeDamping(0.002)),

            # Readout noise
            ExactQubitReadoutNoise([1], ReadoutErr(0.01, 0.02))
        ], name="Complex Test Model")

    noisy_circuit = apply_noise_model(c, model)

    # Original: 6 instructions
    # Expected: 6 original + 6 noise = 12
    @test length(noisy_circuit) == 12

    # Verify noise was applied correctly
    # H on qubit 1
    @test getoperation(noisy_circuit[1]) isa GateH
    @test getoperation(noisy_circuit[2]) isa AmplitudeDamping

    # H on qubit 2
    @test getoperation(noisy_circuit[3]) isa GateH
    @test getoperation(noisy_circuit[4]) isa AmplitudeDamping

    # CX(1,2) with specific noise
    @test getoperation(noisy_circuit[5]) isa GateCX
    @test getqubits(noisy_circuit[5]) == (1, 2)
    @test getoperation(noisy_circuit[6]) isa Depolarizing2
    @test getparam(getoperation(noisy_circuit[6]), :p) == 0.01

    # CX(2,1) with different noise
    @test getoperation(noisy_circuit[7]) isa GateCX
    @test getqubits(noisy_circuit[7]) == (2, 1)
    @test getoperation(noisy_circuit[8]) isa Depolarizing2
    @test getparam(getoperation(noisy_circuit[8]), :p) == 0.02

    # RX(π/2) with specific noise
    @test getoperation(noisy_circuit[9]) isa GateRX
    @test getoperation(noisy_circuit[10]) isa AmplitudeDamping

    # Measure with readout noise
    @test getoperation(noisy_circuit[11]) isa Measure
    @test getoperation(noisy_circuit[12]) isa ReadoutErr
end
