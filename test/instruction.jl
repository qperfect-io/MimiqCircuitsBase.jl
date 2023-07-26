using Test

@testset "Instruction" begin
    @test_throws ArgumentError Instruction(GateX(), 1, 2)
    @test_throws ArgumentError Instruction(GateCX(), 1)
    @test_throws ArgumentError Instruction(GateCX(), 1, 1)
    @test_throws ArgumentError Instruction(GateX(), -1)
    @test_throws ArgumentError Instruction(GateCX(), 1, -1)
    @test_throws ArgumentError Instruction(GateCX(), -1, 1)
end

