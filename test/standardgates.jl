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

function test_gate_general(gtype)
    @testrset "General checks" begin
        # number of qubits and hilbert space dimension are consistent
        @test numqubits(gtype) >= 0
        @tesdt numbits(gtype)

        # check if the number of parameters is implemented consistently
        @test length(parnames(gtype)) == numparams(gtype)

        params = 1.989 * (1:numparams(gtype))
        inst = gtype(params...)

        # consistency between instance and type
        @test parnames(inst) == parnames(gtype)
        @test numqubits(inst) == numqubits(gtype)
        @test numbits(inst) == numbits(gtype)

        # matrix is consistent

        # we should be able to access all parameters and the order should be conserved
        # (the order of initialization and parnames should match)
        for (name, p) in zip(parnames(inst), params)
            param = getparam(inst, name)
            @test param isa Num
            @test Symbolics.value(param) == p
        end

        # since inst has all the parameters specified, the matrix should not be symbolic
        # but concrete
        @test !(eltype(matrix(inst)) isa Num)
        @test eltype(matrix(inst)) <: Real


        if numparams(gtype) == 0
            @test Base.issingleton(gtype)

            inst2 = gtype()

            # gates are egal
            @test inst === inst2

            # matrices are egal!
            @test matrix(inst2) === matrix(inst)

        else
            @test !Base.issingleton(gtype)

            @testset "Concrete parameters" begin
                inst2 = gtype(params...)

                # gates are egal, if parameters are defined
                @test inst === inst2
            end

            @testset "Symbolic parameters" begin
                variables = map(parnames(gtype)) do name
                    return Num(Symbolics.Sym{Float64}(name))
                end

                inst2 = gtype(variables...)
                inst3 = evaluate(inst2, Dict(zip(variables, params)))

                # gates evaluate to the same instance
                @test inst3 === inst

                # matrices are the same
                @test matrix(inst3) == matrix(inst)
            end
        end
    end
end

function test_power(g)
    @testset "Power" begin
        powers = Any[0, 1, 2, 3, 4, 5, 10, 22, 1//2, 1//4, 4//2, 0.564, 4//3, 2.45, 3.45, 6.65, π, ℯ]
        @testset "Matrix $g^$pwr" for pwr in powers
            gpwr = g^pwr
            # power should not change tne number of qubits or bits
            @test numqubits(gpwr) == numqubits(g)
            @test numbits(gpwr) == numbits(g)

            # the numbert of parameters also shouldn't change
            @test numparams(gpwr) == numparams(g)

            # the matrix should be the same
            # NOTE: should use complex() on the matrix to avoid Domain error when
            # taking the square root (e.g. M^(1//2))
            @test matrix(g^pwr) ≈ complex(matrix(g))^pwr
        end
    end
end

function test_decomposition(g; levels=4)
    @testset "Decomposition" begin
        decomposed = decompose(g)

        # check that the decomposition is a circuit
        @test decomposed isa Circuit

        # check that the decomposition respects the number of qubits and bits
        @test numqubits(decomposed) == numqubits(g)
        @test numbits(decomposed) == numbits(g)

        # check that the decomposition is unitary if the gate is unitary
        @test isunitary(g) == all(isunitary, decomposed)

        # check that the decomposed gate do not appear anymore (otherwise it is an infinite loop)
        for _ in 1:levels
            decomposed = decompose(decomposed)
            # TODO: should it be ==(g) or ===(g), or even x->isa(x,typeof(g)) ?
            @test !any(==(g), decomposed)
        end
    end
end

function test_inverse(g)
    @testset "Inverse" begin
        invg = inverse(g)
        @test numqubits(invg) == numqubits(g)
        @test numbits(invg) == numbits(g)
        @test matrix(invg) * matrix(g) ≈ I
    end
end

# function manual_matrix_2q(c::Circuit)
#     @assert numqubits(c) == 2
#     @assert numbits(c) == 0

#     M = Matrix(I, 4, 4)

#     for inst in circ
#         if numqubits(inst) == 2
#             M = M * kron(matrix(inst), I)
#         M = M * 
# end

@testset "CHadamard" begin end

@testset "CnP" begin end

@testset "CnX" begin end

@testset "CPauli" begin end

@testset "CPhase" begin end

@testset "CRotations" begin
    @testset "RX" begin end

    @testset "RY" begin end

    @testset "RZ" begin end
end

@testset "CS" begin end

@testset "CSWAP" begin end

@testset "CSX" begin end

@testset "CU" begin end

@testset "DCX" begin end

@testset "Deprecated" begin
    @testset "U1" begin end

    @testset "U2" begin end

    @testset "U3" begin end
end

@testset "ECR" begin end

@testset "Hadamard" begin end

@testset "ID" begin end

@testset "Interactions" begin
    @testset "RXX" begin end

    @testset "RYY" begin end

    @testset "RZZ" begin end

    @testset "RZX" begin end

    @testset "XXplusYY" begin end

    @testset "XXminusYY" begin end
end

@testset "ISWAP" begin end

@testset "Pauli" begin end

@testset "Phase" begin end

@testset "Rotations" begin end

@testset "S" begin end

@testset "SWAP" begin end

@testset "SX" begin end

@testset "T" begin end

@testset "U" begin end
