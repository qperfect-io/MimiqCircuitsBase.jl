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

#==
function emplacedo(f, args...)
    c = emplace!(Circuit(), args...)
    f(c)
end

@testset "emplace!" begin
    emplacedo(GateCX(), 1, 2) do c
        @test length(c) == 1
        @test numqubits(c) == 2
        @test getoperation(c[1]) === GateCX()
    end

    emplacedo(GateCX(), [1], 2) do c
        @test length(c) == 1
        @test numqubits(c) == 2
        @test getoperation(c[1]) === GateCX()
    end

    emplacedo(GateCX(), [1:4], 5) do c
        @test length(c) == 4
        @test numqubits(c) == 5
        @test all(x -> getoperation(x) === GateCX(), c)
    end

    emplacedo(control(GateX()), [1], 2) do c
        @test length(c) == 1
        @test numqubits(c) == 2
        @test getoperation(c[1]) === GateCX()
    end

    emplacedo(power(control(PolynomialOracle(1, 2, 3, 4)), 5), [1, 2], [3, 4, 5], [6, 7, 8, 9]) do c
        @test length(c) == 1
        @test numqubits(c) == 9
        @test getoperation(c[1]) isa Control{2}
        @test getoperation(getoperation(c[1])) isa Power{2}
        @test getoperation(getoperation(getoperation(c[1]))) === PolynomialOracle(3, 4, 1, 2, 3, 4)
    end
end
==#
