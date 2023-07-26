@testset "Circuit" begin
    c = Circuit()

    @test numqubits(c) == 0
    @test isempty(c)

    push!(c, GateCX(), 1, 2)
    @test !isempty(c)
    @test length(c) == 1
    @test numqubits(c) == 2

    push!(c, GateCX(), 2, 3)
    @test length(c) == 2
    @test numqubits(c) == 3

    push!(c, GateCX(), 3, 4)
    @test length(c) == 3
    @test numqubits(c) == 4

    for gc in c
        @test getoperation(gc) == GateCX()
    end
end
