using Random
using LinearAlgebra
using Symbolics

Random.seed!(20230501)

function checknpgate(gatetype, N)
    @testset "$(opname(gatetype))" begin
        # if is non parametric, then should not have parameters
        @test numparams(gatetype) == 0

        # since it is not parametric, then it should be a singleton type
        @test Base.issingletontype(gatetype)

        inst = gatetype()

        # proper hilbert space dimension and number of qubits
        @test hilbertspacedim(inst) == 2^N
        @test numqubits(inst) == N
        @test numbits(inst) == 0

        # same name bewtween an instance or a gate type
        @test opname(inst) === opname(gatetype)

        M = matrix(inst)

        # check that the matrix is square and that it has the proper dimensions
        @test all(x -> x == hilbertspacedim(inst), size(M))

        # matrix should be egal every time we get it
        @test M === matrix(inst)

        # matrices of two different instances should be egal (also instances
        # are egal)
        inst2 = gatetype()
        @test M === matrix(inst2)

        # inverse is the inverse
        @test M * matrix(inverse(inst)) ≈ I

        # check if Power works for the gate
        @test matrix(Power(inst, 2)) ≈ M^2
        @test matrix(Power(inst, 1 // 2)) ≈ complex(M)^(1 // 2)
        # equivalence (almost) between Power and power
        @test matrix(Power(inst, 1.23)) ≈ matrix(power(inst, 1.23))

        # checks if Inverse works for the gate
        # equivalence (almost) between Inverse and inverse
        @test matrix(Inverse(inst)) ≈ matrix(inverse(inst))
    end
end

function checkpgate(gatetype, N, numpars)
    @testset "$(opname(gatetype))" begin
        # if it is parametric, then it should have parameters
        @test numparams(gatetype) != 0
        @test numparams(gatetype) == numpars

        # since it is parametric, then it should not be a singleton type
        @test !Base.issingletontype(gatetype)

        # check that the parameters functions are consistent
        @test length(parnames(gatetype)) == numpars

        @testset "defined params" begin
            randpars = rand(numpars)
            inst = gatetype(randpars...)

            @test length(getparams(inst)) == numpars
            @test all(getparams(inst) .== randpars)

            for name in parnames(gatetype)
                @test getparam(inst, name) isa Num
            end

            # proper hilbert space dimension and number of qubits
            @test hilbertspacedim(inst) == 2^N
            @test numqubits(inst) == N
            @test numbits(inst) == 0

            # same name bewtween an instance or a gate type
            @test opname(inst) == opname(gatetype)

            M = matrix(inst)

            # check that the matrix is square and that it has the proper dimensions
            @test all(x -> x == hilbertspacedim(inst), size(M))

            # check that the matrix is non symbolic
            @test eltype(M) <: ComplexF64

            # matrix should be equal every time we get it from the same gate
            @test M == matrix(inst)

            # matrices of two different instances with same parameters should be egal)
            inst2 = gatetype(copy(randpars)...)
            @test M == matrix(inst2)

            # if we have different parameters the matrices should be different
            inst3 = gatetype(rand(numpars)...)
            @test M != matrix(inst3)

            # inverse is the inverse
            @test M * matrix(inverse(inst)) ≈ I

            # check if Power works for the gate
            @test matrix(Power(inst, 2)) ≈ M^2
            @test matrix(Power(inst, 1 // 2)) ≈ complex(M)^(1 // 2)
            # equivalence (almost) between Power and power
            @test matrix(Power(inst, 1.23)) ≈ matrix(power(inst, 1.23))

            # checks if Inverse works for the gate
            # equivalence (almost) between Inverse and inverse
            @test matrix(Inverse(inst)) ≈ matrix(inverse(inst))
        end

        @testset "undefined params" begin
            @test 1 == 1
        end
    end
end

@testset "Non parametric 1-qubit gates" begin
    map(
        t -> checknpgate(t, 1),
        Type[GateX, GateY, GateZ, GateH, GateS, GateID],
    )
end

@testset "Non parametric 2-qubit gates" begin
    map(
        t -> checknpgate(t, 2),
        Type[GateSWAP, GateISWAP, GateDCX, GateECR],
    )
end

@testset "Parametric 1-qubit gates" begin
    map(t -> checkpgate(t, 1, 1), Type[GateP, GateRX, GateRY, GateRZ, GateU1])
    map(t -> checkpgate(t, 1, 2), Type[GateR, GateU2])
    map(t -> checkpgate(t, 1, 3), Type[GateU, GateU3])
end

@testset "Parametric 2-qubit gates" begin
    map(t -> checkpgate(t, 2, 1), Type[GateRXX, GateRZZ, GateRYY])
    map(t -> checkpgate(t, 2, 2), Type[GateXXplusYY, GateXXminusYY])
end

@testset "Matrices" begin
    X = matrix(GateX())
    Y = matrix(GateY())
    Z = matrix(GateZ())
    ID = matrix(GateID())

    @test X * X == ID
    @test Y * Y == ID
    @test Z * Z == ID
    @test -im * X * Y * Z == ID
    for M in [X, Y, Z]
        @test det(M) == -1.0
        @test tr(M) == 0.0
    end

    S = matrix(GateS())

    @test S * S ≈ Z

    SDG = matrix(GateSDG())

    @test inv(S) ≈ SDG

    T = matrix(GateT())

    @test T * T ≈ S

    SX = matrix(GateSX())

    @test SX * SX ≈ X

    @test matrix(GateRX(π)) ≈ cis(-π / 2) * matrix(GateX())
    @test matrix(GateRY(π)) ≈ cis(-π / 2) * matrix(GateY())
    @test matrix(GateRZ(π)) ≈ cis(-π / 2) * matrix(GateZ())
end

function checkcustomgate(N, T)
    M = 2^N
    mat = T.(randunitary(M))
    gate = GateCustom(mat)

    @test gate isa GateCustom{N}
    @test matrix(gate) == mat
end

@testset "Custom Gates" begin
    @test_throws "Custom matrix should be" GateCustom(rand(ComplexF64, 3, 3))

    checkcustomgate(1, ComplexF64)
    checkcustomgate(2, ComplexF64)

    @test_throws "larger than 2 qubits" checkcustomgate(3, ComplexF64)
end

nothing
