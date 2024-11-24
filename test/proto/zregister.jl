#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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

@testset "z-register operations" begin
    function check_proto_amplitude(op, z)
        mktemp() do fname, _
            c1 = push!(Circuit(), op, z)
            saveproto(fname, c1)

            c2 = loadproto(fname, Circuit)

            @test typeof(c1[1]) == typeof(c2[1])

            @test getbitstring(getoperation(c1[1])) == getbitstring(getoperation(c2[1]))

            @test getqubits(c1[1]) == getqubits(c2[1])
            @test getbits(c1[1]) == getbits(c2[1])
            @test getztargets(c1[1]) == getztargets(c2[1])
        end
    end

    @testset "Amplitude" begin
        check_proto_amplitude(Amplitude(bs"000"), 1)
        check_proto_amplitude(Amplitude(bs"001"), 2)
        check_proto_amplitude(Amplitude(bs"101"), 3)
        check_proto_amplitude(Amplitude(bs"1"), 4)
        check_proto_amplitude(Amplitude(BitString(129, 543847)), 123)
    end

    function check_proto_singleton(op, q, z)
        mktemp() do fname, _
            c1 = push!(Circuit(), op, q, z)
            saveproto(fname, c1)

            c2 = loadproto(fname, Circuit)

            @test typeof(c1[1]) == typeof(c2[1])

            @test getqubits(c1[1]) == getqubits(c2[1])
            @test getbits(c1[1]) == getbits(c2[1])
            @test getztargets(c1[1]) == getztargets(c2[1])
        end
    end

    @testset "BondDim" begin
        check_proto_singleton(BondDim, 1, 1)
        check_proto_singleton(BondDim, 123, 129)
    end

    @testset "VonNeumannEntropy" begin
        check_proto_singleton(VonNeumannEntropy, 3, 1)
        check_proto_singleton(VonNeumannEntropy, 23, 129)
    end

    @testset "SchmidtRank" begin
        check_proto_singleton(SchmidtRank, 1, 1)
        check_proto_singleton(SchmidtRank, 123, 129)
    end

    function check_proto_expectation(op, qubits, z)
        mktemp() do fname, _
            c1 = push!(Circuit(), ExpectationValue(op), qubits..., z)
            saveproto(fname, c1)

            c2 = loadproto(fname, Circuit)

            @test typeof(c1[1]) == typeof(c2[1])

            op1 = getoperation(getoperation(c1[1]))
            op2 = getoperation(getoperation(c2[1]))

            @test typeof(op1) == typeof(op2)

            for (p1, p2) in zip(getparams(op1), getparams(op2))
                @test p1 == p2
            end

            @test getqubits(c1[1]) == getqubits(c2[1])
            @test getbits(c1[1]) == getbits(c2[1])
            @test getztargets(c1[1]) == getztargets(c2[1])
        end
    end

    @testset "ExpectationValue" begin
        check_proto_expectation(GateZ(), [123], 43)
        check_proto_expectation(GateRX(0.1231), [123], 43)
        check_proto_expectation(GateU(0.123, 3.213, 5.342, 9.434), [123], 43)
        check_proto_expectation(GateCX(), [12, 32], 43)
        check_proto_expectation(GateCH(), [12, 32], 43)
        check_proto_expectation(GateSWAP(), [12, 32], 43)
        check_proto_expectation(GateCRX(0.124), [12, 32], 43)
    end
end

