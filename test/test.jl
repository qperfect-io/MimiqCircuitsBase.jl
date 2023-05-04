using Random
using LinearAlgebra

Random.seed!(19890501)

function checknpgate(gatetype, n, N)
    @testset "$(gatename(gatetype))" begin

        # since it is not parametric, then it should be a singleton type
        @test Base.issingletontype(gatetype)

        inst = gatetype()

        # proper hilbert space dimension and number of qubits
        @test hilbertspacedim(inst) == N
        @test numqubits(inst) == n

        # same name bewtween an instance or a gate type
        @test gatename(inst) === gatename(gatetype)

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
    end
end

function checkpgate(gatetype, n, N, numpars)
    @testset "$(gatename(gatetype))" begin

        # since it is parametric, then it should not be a singleton type
        @test !Base.issingletontype(gatetype)

        randpars = rand(numpars)
        inst = gatetype(randpars...)

        # proper hilbert space dimension and number of qubits
        @test hilbertspacedim(inst) == N
        @test numqubits(inst) == n

        # same name bewtween an instance or a gate type
        @test gatename(inst) === gatename(gatetype)

        M = matrix(inst)

        # check that the matrix is square and that it has the proper dimensions
        @test all(x -> x == hilbertspacedim(inst), size(M))

        # matrix should be egal every time we get it
        @test M === matrix(inst)

        inst2 = gatetype(copy(randpars)...)
        #@test inst2 == inst

        # matrices of two different instances with same parameters should be egal)
        @test M == matrix(inst2)

        # if we have different parameters the matrices should be different
        inst3 = gatetype(rand(numpars)...)
        #@test inst3 != inst
        @test M != matrix(inst3)

        # inverse is the inverse
        @test M * matrix(inverse(inst)) ≈ I
    end
end

@testset "Non parametric 1-qubit gates" begin
    map(
        t -> checknpgate(t, 1, 2),
        Type[GateX, GateY, GateZ, GateH, GateS, GateSDG, GateTDG, GateSX, GateSXDG, GateID],
    )
end

@testset "Non parametric 2-qubit gates" begin
    map(
        t -> checknpgate(t, 2, 4),
        Type[GateCX, GateCY, GateCZ, GateCH, GateSWAP, GateISWAP, GateISWAPDG, GateCS, GateCSDG, GateCSX, GateCSXDG, GateDCX, GateDCXDG, GateECR],
    )
end

@testset "Non parametric 3-qubit gates" begin
    map(t -> checknpgate(t, 3, 8), Type[GateCCX, GateCSWAP])
end

@testset "Parametric 1-qubit gates" begin
    map(t -> checkpgate(t, 1, 2, 1), Type[GateP, GateRX, GateRY, GateRZ, GateU1])
    map(t -> checkpgate(t, 1, 2, 2), Type[GateR, GateU2])
    map(t -> checkpgate(t, 1, 2, 3), Type[GateU, GateU3])
end

@testset "Parametric 2-qubit gates" begin
    map(t -> checkpgate(t, 2, 4, 1), Type[GateCP, GateCRX, GateCRY, GateCRZ, GateRXX, GateRZZ, GateRYY])
    map(t -> checkpgate(t, 2, 4, 2), Type[GateCR, GateXXplusYY, GateXXminusYY])
    map(t -> checkpgate(t, 2, 4, 4), Type[GateCU])
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
end

function checkcustomgate(N, T)
    M = 2^N
    mat = rand(T, M, M)
    gate = Gate(mat)

    @test gate isa Gate{N,T}
    @test matrix(gate) == mat
end

@testset "Custom Gates" begin
    @test_throws "Wrong matrix" Gate(rand(ComplexF64, 3, 3))

    checkcustomgate(1, ComplexF64)
    checkcustomgate(1, Float64)
    checkcustomgate(2, ComplexF64)
    checkcustomgate(2, Float64)
    checkcustomgate(3, ComplexF64)
    checkcustomgate(3, Float64)
end

@testset "CircuitGate" begin
    @test_throws ArgumentError CircuitGate(GateX(), 1, 2)
    @test_throws ArgumentError CircuitGate(GateCX(), 1)

    g = CircuitGate(GateX(), 1)
    @test matrix(g) === matrix(GateX())

end

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
        @test gc.gate == GateCX()
    end
end

nothing
