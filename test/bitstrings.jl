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
@testset "BitString" begin
    @testset "To and from integers" begin
        for i in 0:2^8
            @test bitstring_to_integer(BitString(10, i)) == i
            @test bitstring_to_integer(BitString(11, i)) == i
        end

        bigi = BigInt(2)^300 - 234531213
        bitstring_to_integer(BitString(300, bigi)) == bigi

        typeof(bitstring_to_integer(BitString(10, 3))) == BigInt
    end

    @testset "String parsing and conversion" begin
        for i in 0:2^5
            bs = BitString(10, i)
            @test parse(BitString, string(bs)) == bs
        end
    end

    @testset "String literals" begin
        @test bs"1001" == BitString(4, [1, 4])
        @test bs"1101" == BitString(4, [1, 2, 4])
        @test bs"10001110000" == BitString(11, [1, 5, 6, 7])
    end

    @testset "Edge cases with integers" begin
        for nq in 1:20
            @test bitstring_to_integer(BitString(nq)) == 0
        end

        @test bitstring_to_integer(BitString(63, typemax(Int64)), Int64) == typemax(Int64)
        @test_throws ErrorException bitstring_to_integer(BitString(64, BigInt(typemax(Int64)) + 1), Int64)


        @test bitstring_to_integer(BitString(64, typemax(UInt64)), UInt64) == typemax(UInt64)
        @test_throws ErrorException bitstring_to_integer(BitString(65, BigInt(typemax(UInt64)) + 1), UInt64)


        @test_throws ErrorException bitstring_to_index(BitString(63, typemax(Int64)))
        @test bitstring_to_index(BitString(63, typemax(Int64) - 1)) == typemax(Int64)
        @test bitstring_to_index(BitString(63, 0)) == 1
    end
end

