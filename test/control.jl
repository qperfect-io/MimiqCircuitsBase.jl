using Test

@testset "Constructor" begin
    @test_throws ArgumentError Control(0, GateX())
    @test_throws ArgumentError Control(-1, GateX())

    for gate in [GateX(), GateRX(0.2), GateSWAP()]
        mygate1 = Control(1, gate)
        mygate2 = Control(1, gate)

        # two controls of the same matrix should always be egal
        @test mygate1 === mygate2

        @test opname(mygate1) != "Control"
        @test opname(mygate1)[1] == 'C'
        @test numqubits(mygate1) == 1 + numqubits(gate)
        @test numbits(mygate1) == 0

        if matrix(gate) === matrix(gate)
            @test matrix(mygate1) === matrix(mygate2)
        else
            @test matrix(mygate1) == matrix(mygate2)
        end
    end
end

