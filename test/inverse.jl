using Test

@testset "Inverse Constructor" begin
    #@test_throws ErrorException Inverse(Measure())
    #@test_throws ErrorException Inverse(Reset())

    for gate in [GateX(), GateRX(0.2), GateSWAP()]
        mygate1 = Inverse(gate)
        mygate2 = Inverse(gate)

        # two controls of the same matrix should always be egal
        @test mygate1 === mygate2

        @test opname(mygate1) == "Inverse"
        @test numqubits(mygate1) == numqubits(gate)
        @test numbits(mygate1) == 0

        if matrix(gate) === matrix(gate)
            @test matrix(mygate1) === matrix(mygate2)
        else
            @test matrix(mygate1) == matrix(mygate2)
        end

        @test matrix(gate) * matrix(mygate1) ≈ I
    end
end
