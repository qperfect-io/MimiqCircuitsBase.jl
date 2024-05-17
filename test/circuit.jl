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

@testset "Circuit Symbolic Tests" begin
    @testset "Non-Symbolic Circuits" begin
        c = Circuit()
        push!(c, GateCX(), 1, 2)
        push!(c, GateCX(), 2, 3)
        push!(c, GateRX(rand()), 1)
        @test !issymbolic(c)
    end
    
    @testset "Symbolic Circuits" begin
        @variables x y
        c = Circuit()
        push!(c, GateP(x), 1)
        push!(c, GateU(rand(3)...),1)
        push!(c, GateCX(), 1, 2)
        
        @test issymbolic(c)
    end

    @testset "Evaluate" begin
        @variables x y
        c = Circuit()
        push!(c, GateU(rand(3)...), 1)
        push!(c, GateU(x, y, rand()), 1)
        push!(c, GateCX(), 1, 2)

        c1 = evaluate(c, Dict(x=>rand()))
        @test issymbolic(c1)

        c2  = evaluate(c, Dict(y=>rand()))
        @test issymbolic(c2)

        c3 = evaluate(c, Dict(x=>rand(), y=>rand()))
        @test !issymbolic(c3)
    end

    @testset "Simple Gates" begin
        @testset "$(string(GT))" for GT in GATES
            if numparams(GT) == 0
                @test !issymbolic(GT())
            end
        end
    end

    @testset "Control" begin
        @variables x

        @test !issymbolic(GateCX())

        @test !issymbolic(control(3, GateT()))
        
        @test !issymbolic(GateCRX(rand()))
        @test issymbolic(GateCRX(x))

        @test issymbolic(Control(3, GateP(x)))
        @test !issymbolic(Control(4, GateP(rand())))

        @test !issymbolic(GateCU(rand(4)...))
        @test issymbolic(GateCU(rand(3)..., x))
        @test issymbolic(GateCU(x, rand(3)...))
    end

    @testset "Power" begin
        @variables x

        @test !issymbolic(Power(GateX(),2))

        @test !issymbolic(Power(GateT(),1))
        
        @test !issymbolic(Power(GateXXplusYY(rand(),rand()),2))
        @test issymbolic(Power(GateRX(x),2))

        @test issymbolic(Power(GateP(x),3))
        @test !issymbolic(Power(GateP(rand()),3))

        @test !issymbolic(Power(GateU(rand(3)...),3))
        @test issymbolic(Power(GateU(rand(2)..., x),2))
        @test issymbolic(Power(GateU(x, rand(2)...),3))
    end

    @testset "Inverse" begin
        @variables x

        @test !issymbolic(Inverse(GateX()))

        @test !issymbolic(Inverse(GateT()))
        
        @test !issymbolic(Inverse(GateXXplusYY(rand(),rand())))
        @test issymbolic(Inverse(GateRX(x)))

        @test issymbolic(Inverse(GateP(x)))
        @test !issymbolic(Inverse(GateP(rand())))

        @test !issymbolic(Inverse(GateU(rand(3)...)))
        @test issymbolic(Inverse(GateU(rand(2)..., x)))
        @test issymbolic(Inverse(GateU(x, rand(2)...)))
    end

    @testset "Combination" begin
        @variables x

        @test !issymbolic(Inverse(Power(GateCX(),2)))

        @test !issymbolic(Inverse(Power(Control(3,GateT()),3)))
        
        @test !issymbolic(Inverse(Control(3,Power(GateXXplusYY(rand(),rand()),2))))

        @test issymbolic(Inverse(Control(3,Power(GateP(x),3))))
        @test !issymbolic(Inverse(Control(3,Power(GateP(rand()),2))))

        @test !issymbolic(Power(Inverse(Control(4,GateU(rand(3)...))),3))
        @test issymbolic(Inverse(Power(GateU(rand(2)..., x),3)))
        @test issymbolic(Inverse(Control(2,GateU(x, rand(2)...))))
    end
end
