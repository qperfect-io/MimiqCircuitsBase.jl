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
using Random
using LinearAlgebra
using MimiqCircuitsBase
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
            @test eltype(M) <: ComplexF64 || eltype(M) <: Float64

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
    map(t -> checkpgate(t, 1, 3), Type[GateU3])
    map(t -> checkpgate(t, 1, 4), Type[GateU])
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
    @test_throws ArgumentError GateCustom(rand(ComplexF64, 3, 3))

    checkcustomgate(1, ComplexF64)
    checkcustomgate(2, ComplexF64)

    @test_throws "larger than 2 qubits" checkcustomgate(3, ComplexF64)
end

@testset "Rotations" begin
    function RX(theta)
        return exp(-im * theta / 2 * matrix(GateX()))
    end

    function RY(theta)
        return exp(-im * theta / 2 * matrix(GateY()))
    end

    function RZ(theta)
        return exp(-im * theta / 2 * matrix(GateZ()))
    end

    Random.seed!(20230501)
    for (theta, phi, lam) in [rand(3) for _ in 1:20]
        @test matrix(GateRX(theta)) ≈ RX(theta)
        @test matrix(GateRY(phi)) ≈ RY(phi)
        @test matrix(GateRZ(lam)) ≈ RZ(lam)
    end
end

@testset "Interactions" begin
    import MimiqCircuitsBase: _matrix

    function XXplusYY(theta, beta)
        RZ0p = kron(_matrix(GateRZ, beta), Matrix(I, 2, 2))
        RZ0m = kron(_matrix(GateRZ, -beta), Matrix(I, 2, 2))
        XX = kron(_matrix(GateX), _matrix(GateX))
        YY = kron(_matrix(GateY), _matrix(GateY))
        EXP = exp(-im * theta / 2 * (XX + YY) / 2)
        return RZ0m * EXP * RZ0p
    end

    function XXminusYY(theta, beta)
        RZ0p = kron(_matrix(GateRZ, beta), Matrix(I, 2, 2))
        RZ0m = kron(_matrix(GateRZ, -beta), Matrix(I, 2, 2))
        XX = kron(_matrix(GateX), _matrix(GateX))
        YY = kron(_matrix(GateY), _matrix(GateY))
        EXP = exp(-im * theta / 2 * (XX - YY) / 2)
        return RZ0p * EXP * RZ0m
    end

    function RXX(theta)
        XX = kron(_matrix(GateX), _matrix(GateX))
        return exp(-im * theta / 2 * XX)
    end

    function RYY(theta)
        YY = kron(_matrix(GateY), _matrix(GateY))
        return exp(-im * theta / 2 * YY)
    end

    function RZZ(theta)
        ZZ = kron(_matrix(GateZ), _matrix(GateZ))
        return exp(-im * theta / 2 * ZZ)
    end

    function RZX(theta)
        ZX = kron(_matrix(GateZ), _matrix(GateX))
        return exp(-im * theta / 2 * ZX)
    end

    Random.seed!(20230501)
    for (theta, beta) in [rand(2) for _ in 1:20]
        @test matrix(GateXXplusYY(theta, beta)) ≈ XXplusYY(theta, beta)
        @test matrix(GateXXminusYY(theta, beta)) ≈ XXminusYY(theta, beta)
        @test matrix(GateRXX(theta)) ≈ RXX(theta)
        @test matrix(GateRYY(theta)) ≈ RYY(theta)
        @test matrix(GateRZZ(theta)) ≈ RZZ(theta)
        @test matrix(GateRZX(theta)) ≈ RZX(theta)
    end
end

nothing
