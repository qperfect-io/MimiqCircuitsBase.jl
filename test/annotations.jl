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
using Base: show_signature_function
using Test

@testset "Detector" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            @test toproto(Detector(13, rand(7))) isa circuit_pb.Detector

            notes = [98.123, 0.2334, 0.654]
            nb = 13

            backforth = fromproto(toproto(Detector(nb, notes)))
            @test backforth isa Detector
            @test numbits(backforth) == nb
            @test getnotes(backforth) == notes

            backforth = fromproto(toproto(Detector(nb)))
            @test backforth isa Detector
            @test numbits(backforth) == nb
            @test getnotes(backforth) == []
        end

        @testset "saveproto / loadproto" begin
            g = Detector(4, rand(7))
            c = push!(Circuit(), g, 1, 3, 5, 8)
            testsaveloadproto(c)
        end
    end
end

@testset "QubitCoordinates" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            @test toproto(QubitCoordinates(rand(7))) isa circuit_pb.SimpleAnnotation

            notes = [98.123, 0.2334, 0.654]

            backforth = fromproto(toproto(QubitCoordinates(notes)))
            @test backforth isa QubitCoordinates
            @test getnotes(backforth) == notes

            backforth = fromproto(toproto(QubitCoordinates()))
            @test backforth isa QubitCoordinates
            @test getnotes(backforth) == []
        end

        @testset "saveproto / loadproto" begin
            g = QubitCoordinates(rand(7))
            c = push!(Circuit(), g, 3)
            testsaveloadproto(c)
        end
    end
end

@testset "ShiftCoordinates" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            @test toproto(ShiftCoordinates(rand(7))) isa circuit_pb.SimpleAnnotation

            notes = [98.123, 0.2334, 0.654]

            backforth = fromproto(toproto(ShiftCoordinates(notes)))
            @test backforth isa ShiftCoordinates
            @test getnotes(backforth) == notes

            backforth = fromproto(toproto(ShiftCoordinates()))
            @test backforth isa ShiftCoordinates
            @test getnotes(backforth) == []
        end

        @testset "saveproto / loadproto" begin
            g = ShiftCoordinates(rand(7))
            c = push!(Circuit(), g)
            testsaveloadproto(c)
        end
    end
end

@testset "Tick" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            @test toproto(Tick()) isa circuit_pb.SimpleAnnotation

            backforth = fromproto(toproto(Tick()))
            @test backforth isa Tick
            @test getnotes(backforth) == []
        end

        @testset "saveproto / loadproto" begin
            g = Tick()
            c = push!(Circuit(), g)
            testsaveloadproto(c)
        end
    end
end

@testset "ObservableInclude" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            @test toproto(ObservableInclude(13, rand(0:454, 7))) isa circuit_pb.ObservableInclude

            notes = [98, 2, 3]
            nb = 13

            backforth = fromproto(toproto(ObservableInclude(nb, notes)))
            @test backforth isa ObservableInclude
            @test numbits(backforth) == nb
            @test getnotes(backforth) == notes

            backforth = fromproto(toproto(ObservableInclude(nb)))
            @test backforth isa ObservableInclude
            @test numbits(backforth) == nb
            @test getnotes(backforth) == []
        end

        @testset "saveproto / loadproto" begin
            g = ObservableInclude(4, rand(0:554, 7))
            c = push!(Circuit(), g, 1, 3, 5, 8)
            testsaveloadproto(c)
        end
    end
end
