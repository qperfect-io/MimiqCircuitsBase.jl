@testset "BitState" begin
    @testset "To and from integers" begin
        for i in 0:2^8
            @test bitstate_to_integer(BitState(10, i)) == i
            @test bitstate_to_integer(BitState(11, i)) == i
        end

        bigi = BigInt(2)^300 - 234531213
        bitstate_to_integer(BitState(300, bigi)) == bigi

        typeof(bitstate_to_integer(BitState(10, 3))) == BigInt
    end

    @testset "String parsing and conversion" begin
        for i in 0:2^5
            bs = BitState(10, i)
            @test parse(BitState, string(bs)) == bs
        end
    end

    @testset "String literals" begin
        @test bs"1001" == BitState(4, [1, 4])
        @test bs"1101" == BitState(4, [1, 2, 4])
        @test bs"10001110000" == BitState(11, [1, 5, 6, 7])
    end

    @testset "Edge cases with integers" begin
        for nq in 1:20
            @test bitstate_to_integer(BitState(nq)) == 0
        end

        @test bitstate_to_integer(BitState(63, typemax(Int64)), Int64) == typemax(Int64)
        @test_throws ErrorException bitstate_to_integer(BitState(64, BigInt(typemax(Int64)) + 1), Int64)


        @test bitstate_to_integer(BitState(64, typemax(UInt64)), UInt64) == typemax(UInt64)
        @test_throws ErrorException bitstate_to_integer(BitState(65, BigInt(typemax(UInt64)) + 1), UInt64)


        @test_throws ErrorException bitstate_to_index(BitState(63, typemax(Int64)))
        @test bitstate_to_index(BitState(63, typemax(Int64) - 1)) == typemax(Int64)
        @test bitstate_to_index(BitState(63, 0)) == 1
    end
end

