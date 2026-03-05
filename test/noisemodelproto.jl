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


function noisemodel_roundtrip(model::NoiseModel)
    fname, _ = mktemp()
    saveproto(fname, model)
    loaded = loadproto(fname, NoiseModel)

    @test loaded isa NoiseModel
    @test loaded.name == model.name
    @test length(loaded.rules) == length(model.rules)

    for (r1, r2) in zip(model.rules, loaded.rules)
        @test typeof(r1) == typeof(r2)
        if hasproperty(r1, :noise)
            @test typeof(r1.noise) == typeof(r2.noise)
        end
    end
    return loaded
end



function base_rule_test(rule::AbstractNoiseRule)
    model = NoiseModel([rule]; name="testmodel")
    noisemodel_roundtrip(model)
end


# Test all NoiseRule variants
@testset "NoiseModel ProtoBuf Tests" begin
    mktempdir() do tmpdir
        tempfile = joinpath(tmpdir, "nm.pb")

        # GlobalReadoutNoise
        @testset "GlobalReadoutNoise" begin
            rule = GlobalReadoutNoise(ReadoutErr(0.01, 0.02))
            base_rule_test(rule)
        end

        # ExactQubitReadoutNoise
        @testset "ExactQubitReadoutNoise" begin
            rule = ExactQubitReadoutNoise([1, 2], ReadoutErr(0.05, 0.1))
            base_rule_test(rule)
        end

        # SetQubitReadoutNoise
        @testset "SetQubitReadoutNoise" begin
            rule = SetQubitReadoutNoise(Set([1, 3]), ReadoutErr(0.1, 0.05))
            base_rule_test(rule)
        end

        # Measurement noise via generalized OperationInstanceNoise
        @testset "Measurement OperationInstanceNoise" begin
            rule = OperationInstanceNoise(Measure(), PauliX(0.2); before=true)
            base_rule_test(rule)
        end

        # Exact measurement noise via generalized gate+qubits rule
        @testset "Exact Measurement OperationInstanceNoise" begin
            rule = ExactOperationInstanceQubitNoise(Measure(), [1], PauliZ(0.15); before=true)
            base_rule_test(rule)
        end

        # Set-based measurement noise via generalized gate+qubits rule
        @testset "Set Measurement OperationInstanceNoise" begin
            rule = SetOperationInstanceQubitNoise(Measure(), Set([1, 3]), PauliY(0.05); before=true)
            base_rule_test(rule)
        end

        # Reset noise via generalized OperationInstanceNoise
        @testset "Reset OperationInstanceNoise" begin
            rule = OperationInstanceNoise(Reset(), Depolarizing1(0.02))
            base_rule_test(rule)
        end

        # Exact reset noise via generalized gate+qubits rule
        @testset "Exact Reset OperationInstanceNoise" begin
            rule = ExactOperationInstanceQubitNoise(Reset(), [2], PauliX(0.1))
            base_rule_test(rule)
        end

        # Set-based reset noise via generalized gate+qubits rule
        @testset "Set Reset OperationInstanceNoise" begin
            rule = SetOperationInstanceQubitNoise(Reset(), Set([1, 2]), PauliZ(0.2))
            base_rule_test(rule)
        end

        # OperationInstanceNoise
        @testset "OperationInstanceNoise" begin
            gate = GateRX(π / 3)
            noise = PauliX(0.2)
            rule = OperationInstanceNoise(gate, noise)
            base_rule_test(rule)
        end

        # ExactOperationInstanceQubitNoise
        @testset "ExactOperationInstanceQubitNoise" begin
            gate = GateCX()
            # Again, need a 2-qubit noise for a 2-qubit gate
            noise = PauliNoise([0.25, 0.25, 0.25, 0.25], ["II", "XX", "YY", "ZZ"])
            rule = ExactOperationInstanceQubitNoise(gate, [1, 2], noise)
            base_rule_test(rule)
        end

        # SetOperationInstanceQubitNoise
        @testset "SetOperationInstanceQubitNoise" begin
            gate = GateRZ(π / 2)
            rule = SetOperationInstanceQubitNoise(gate, [1], PauliZ(0.3))
            base_rule_test(rule)
        end

        @testset "OperationInstance replace flag roundtrip" begin
            model = NoiseModel([
                    OperationInstanceNoise(GateH(), AmplitudeDamping(0.1); replace=true)
                ]; name="replace-op")
            loaded = noisemodel_roundtrip(model)
            @test loaded.rules[1] isa OperationInstanceNoise
            @test loaded.rules[1].replace
            @test !loaded.rules[1].before
        end

        @testset "ExactOperationInstance replace flag roundtrip" begin
            model = NoiseModel([
                    ExactOperationInstanceQubitNoise(GateH(), [1], AmplitudeDamping(0.1); replace=true)
                ]; name="replace-exact-op")
            loaded = noisemodel_roundtrip(model)
            @test loaded.rules[1] isa ExactOperationInstanceQubitNoise
            @test loaded.rules[1].replace
            @test !loaded.rules[1].before
        end

        @testset "SetOperationInstance replace flag roundtrip" begin
            model = NoiseModel([
                    SetOperationInstanceQubitNoise(GateH(), [1, 3], AmplitudeDamping(0.1); replace=true)
                ]; name="replace-set-op")
            loaded = noisemodel_roundtrip(model)
            @test loaded.rules[1] isa SetOperationInstanceQubitNoise
            @test loaded.rules[1].replace
            @test !loaded.rules[1].before
        end

        # IdleNoise Set qubits
        @testset "SetIdleQubitNoise" begin
            rule = SetIdleQubitNoise(PauliZ(0.1), [1])
            base_rule_test(rule)
        end

        # IdleNoise
        @testset "IdleNoise" begin
            rule = IdleNoise(PauliZ(0.1))
            base_rule_test(rule)
        end

        # # CustomNoiseRule
        # @testset "CustomNoiseRule" begin
        #     matcher = inst -> true
        #     generator = inst -> PauliX(0.05)
        #     rule = CustomNoiseRule(matcher, generator; priority_val=50, before=false)
        #     base_rule_test(rule)
        # end

        @testset "Composite NoiseModel" begin
            nm = NoiseModel([
                    # Readout noise rules
                    GlobalReadoutNoise(ReadoutErr(0.01, 0.02)),
                    ExactQubitReadoutNoise([1, 2], ReadoutErr(0.05, 0.1)),
                    SetQubitReadoutNoise([1, 3], ReadoutErr(0.1, 0.05)),

                    # Measurement/reset noise via generalized operation-instance rules
                    OperationInstanceNoise(Measure(), PauliX(0.02); before=true),
                    ExactOperationInstanceQubitNoise(Measure(), [2], PauliZ(0.03); before=true),
                    SetOperationInstanceQubitNoise(Measure(), [1, 3], PauliY(0.04); before=true),
                    OperationInstanceNoise(Reset(), PauliX(0.02)),
                    ExactOperationInstanceQubitNoise(Reset(), [1], PauliZ(0.03)),
                    SetOperationInstanceQubitNoise(Reset(), [1, 2], PauliY(0.04)),

                    # Operation-instance noise rules
                    OperationInstanceNoise(GateRX(π / 3), PauliX(0.1)),
                    ExactOperationInstanceQubitNoise(GateCX(), [1, 3], PauliNoise([0.40, 0.60], ["YX", "ZY"])),
                    SetOperationInstanceQubitNoise(GateRZ(π / 2), [1], PauliZ(0.05)),

                    # Idle noise
                    SetIdleQubitNoise(PauliZ(0.1), [1, 2]),
                    IdleNoise(PauliZ(0.1)),

                    # # Custom noise rule 
                    # CustomNoiseRule(
                    #     inst -> false,
                    #     inst -> PauliX(0.02);
                    #     priority_val=80,
                    #     before=false
                    # )
                ]; name="Composite NoiseModel")

            # Roundtrip via protobuf
            loaded = noisemodel_roundtrip(nm)

            # Structural assertions
            @test loaded.name == "Composite NoiseModel"
            @test length(loaded.rules) == length(nm.rules)

            # Check each rule structurally matches
            for (orig, restored) in zip(nm.rules, loaded.rules)
                @test typeof(orig) == typeof(restored)
            end
        end

    end
end
