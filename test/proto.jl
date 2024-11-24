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

using MimiqCircuitsBase: toproto, fromproto, circuit_pb
using ProtoBuf: ProtoEncoder, ProtoDecoder, encode, decode

@testset "Circuit" begin
    @variables λ

    @circuit c begin
        # basic gate
        push!(c, GateX(), 1)

        # parametric
        push!(c, GateRX(λ), 1)

        # parametric with value
        push!(c, GateRX(π / 2), 1)

        # controlled
        push!(c, GateCX(), 1, 2)
        push!(c, GateCRX(λ), 2, 1)
        push!(c, GateCRX(1.23), 2, 1)

        # power
        push!(c, GateSX(), 1)

        # inverse
        push!(c, GateSXDG(), 3)

        # controlled-inverse
        push!(c, GateCSXDG(), 121, 3)

        # powers with non-rational powers
        push!(c, Power(GateX(), 1.23), 1)
        push!(c, Power(GateSWAP(), 1.23), 1, 2)

        # multi-controlled
        push!(c, GateCCX(), 1, 2, 3)
        push!(c, GateC3X(), 1, 2, 3, 4)
        push!(c, Control(5, GateSWAP()), 1:7...)

        # non-unitary
        push!(c, Measure(), 321, 123)
        push!(c, MeasureX(), 321, 123)
        push!(c, MeasureY(), 321, 123)
        push!(c, MeasureZ(), 321, 123)
        push!(c, MeasureXX(), 321, 213, 123)
        push!(c, MeasureYY(), 321, 213, 123)
        push!(c, MeasureZZ(), 321, 213, 123)
        push!(c, MeasureReset(), 321, 123)
        push!(c, MeasureResetX(), 321, 123)
        push!(c, MeasureResetY(), 321, 123)
        push!(c, MeasureResetZ(), 321, 123)
        push!(c, Reset(), 121)

        # barrier
        push!(c, Barrier(3), 1, 2, 121)

        # algorithm
        push!(c, QFT(4), 1:4...)
        push!(c, PhaseGradient(4), 1:4...)
        push!(c, Diffusion(4), 1:4...)
        push!(c, PolynomialOracle(2, 2, 1, 2, 3, 4), 1:2..., 3:4...)

        # Delay
        push!(c, Delay(0.5), 1)

        # gate declaration
        @gatedecl ansatz(θ) = begin
            c = Circuit()
            push!(c, GateX(), 1)
            push!(c, GateRX(θ), 2)
            return c
        end

        push!(c, ansatz(λ), 1, 2)
    end

    fname, _ = mktemp()

    saveproto(fname, c)
    newc = loadproto(fname, Circuit)

    @test length(newc) == length(c)

    for i in 1:length(c)
        inst = c[i]
        ninst = newc[i]
        @test typeof(getoperation(inst)) == typeof(getoperation(ninst))
        @test typeof(getqubits(inst)) == typeof(getqubits(ninst))
        @test typeof(getbits(inst)) == typeof(getbits(ninst))
    end
end

function circuits_are_equivalent(circuit1::Circuit, circuit2::Circuit)
    return typeof(circuit1._instructions) == typeof(circuit2._instructions)
end

# Base test function for noise channels
function base_noise_channel_test(noise_channel::AbstractKrausChannel, temp_filename::String)
    circuit = Circuit()
    push!(circuit, noise_channel, 1)
    saveproto(temp_filename, circuit)

    cloded = loadproto(temp_filename, typeof(circuit))

    @test circuits_are_equivalent(cloded, circuit)

    # Additional checks to ensure proper loading
    @test length(cloded._instructions) == length(circuit._instructions)
    for (inst1, inst2) in zip(circuit._instructions, cloded._instructions)
        @test typeof(inst1.op) == typeof(inst2.op)
        @test inst1.qtargets == inst2.qtargets
        @test inst1.ctargets == inst2.ctargets
    end
end

@testset "Noise Channel Protobuf Tests" begin
    mktempdir() do tmpdir
        temp_filename = joinpath(tmpdir, "test.pb")

        @testset "PhaseAmplitudeDamping Protobuf Test" begin
            pad = PhaseAmplitudeDamping(1, 1, 1)
            base_noise_channel_test(pad, temp_filename)
        end

        @testset "AmplitudeDamping Protobuf Test" begin
            ad = AmplitudeDamping(0.5)
            base_noise_channel_test(ad, temp_filename)
        end

        @testset "GeneralizedAmplitudeDamping Protobuf Test" begin
            gad = GeneralizedAmplitudeDamping(0.5, 0.3)
            base_noise_channel_test(gad, temp_filename)
        end

        @testset "ThermalNoise Protobuf Test" begin
            tn = ThermalNoise(2.0, 1.0, 1.0, 0.1)
            base_noise_channel_test(tn, temp_filename)
        end

        @testset "PauliX Protobuf Test" begin
            px = PauliX(0.5)
            base_noise_channel_test(px, temp_filename)
        end

        @testset "PauliY Protobuf Test" begin
            py = PauliY(0.5)
            base_noise_channel_test(py, temp_filename)
        end

        @testset "PauliZ Protobuf Test" begin
            pz = PauliZ(0.5)
            base_noise_channel_test(pz, temp_filename)
        end

        @testset "PauliNoise Protobuf Test" begin
            pn = PauliNoise([0.25, 0.25, 0.25, 0.25], ["I", "X", "Y", "Z"])
            base_noise_channel_test(pn, temp_filename)
        end

        @testset "Kraus Protobuf Test" begin
            # Define complex matrices for Kraus
            unitary1 = [1 0; 0 sqrt(0.5)]
            unitary2 = [0 sqrt(0.5); 0 0]
            kraus = Kraus([unitary1, unitary2])
            base_noise_channel_test(kraus, temp_filename)
        end

        @testset "MixedUnitary Protobuf Test" begin
            # Define complex matrices for MixedUnitary
            unitary1 = [1 0; 0 1]
            unitary2 = [0 1; 1 0]
            mu = MixedUnitary([0.5, 0.5], [unitary1, unitary2])
            base_noise_channel_test(mu, temp_filename)
        end
        @testset "ProjectiveNoise" begin
            mu = ProjectiveNoise("X")
            base_noise_channel_test(mu, temp_filename)
        end
    end
end

# Base test function for operators
function operator_channel_test(operator::T) where {T<:AbstractOperator}
    backforth = fromproto(toproto(operator))
    numqubits(backforth) == numqubits(operator)

    @test backforth isa T

    # this test should be almost the same as above, but adds also the protobuf
    # encoding and decoding part. Just to check if there is no strange thing
    # happening with the Protobuf library

    # save
    iobuffer = IOBuffer()
    e = ProtoEncoder(iobuffer)
    tp = toproto(operator)
    encode(e, tp)

    # load
    seekstart(iobuffer)
    loaded = fromproto(decode(ProtoDecoder(iobuffer), typeof(tp)))

    @test loaded isa T
    @test loaded == operator
end

@testset "Operator Channel Protobuf Tests" begin
    mktempdir() do tmpdir
        temp_filename = joinpath(tmpdir, "test.pb")

        optypes = [
            Projector0, Projector1,
            ProjectorX0, ProjectorX1,
            ProjectorY0, ProjectorY1,
            Projector00, Projector01, Projector10, Projector11,
            SigmaMinus, SigmaPlus,
        ]

        @testset "$(opname(optype))" for optype in optypes
            @testset "No value (default is 1)" begin
                operator_channel_test(optype())
            end
            @testset "Explicit 1" begin
                op = optype(1)
                operator_channel_test(optype(1))
            end
            @testset "Float value" begin
                op = optype(3.123)
                operator_channel_test(optype(3.123))
            end
        end
    end
end
