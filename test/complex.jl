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

using Test

@testset "Pow" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            backforth = fromproto(toproto(Pow(2.123)))
            @test backforth isa Pow
            @test backforth.exponent == 2.123
        end

        @testset "saveproto / loadproto" begin
            g = Pow(2.123)
            c = push!(Circuit(), g, 3)
            testsaveloadproto(c)
        end
    end
end

@testset "Add" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            backforth = fromproto(toproto(Add(2)))
            @test backforth isa Add{2}
            @test backforth.term == 0.0

            backforth = fromproto(toproto(Add(1, 3.0)))
            @test backforth isa Add{1}
            @test backforth.term == 3.0

            backforth = fromproto(toproto(Add(3, 4.0)))
            @test backforth isa Add{3}
            @test backforth.term == 4.0
        end

        @testset "saveproto / loadproto" begin
            c = push!(Circuit(), Add(3), 1, 2, 3)
            push!(c, Add(5), 1, 2, 3, 4, 5)
            push!(c, Add(5, 2.0), 1, 2, 3, 4, 5)
            testsaveloadproto(c)
        end
    end
end

@testset "Multiply" begin
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            backforth = fromproto(toproto(Multiply(2)))
            @test backforth isa Multiply{2}
            @test backforth.factor == 1.0

            backforth = fromproto(toproto(Multiply(1, 3.21)))
            @test backforth isa Multiply{1}
            @test backforth.factor == 3.21

            backforth = fromproto(toproto(Multiply(2, 3.21)))
            @test backforth isa Multiply{2}
            @test backforth.factor == 3.21
        end

        @testset "saveproto / loadproto" begin
            c = push!(Circuit(), Multiply(3), 1, 2, 3)
            push!(c, Multiply(5), 1, 2, 3, 4, 5)
            push!(c, Multiply(5, 2.0), 1, 2, 3, 4, 5)
            testsaveloadproto(c)
        end
    end
end
