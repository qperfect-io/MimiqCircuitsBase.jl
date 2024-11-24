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
using Test

function checkpoperator(optype, N, numpars)
    @testset "$(opname(optype))" begin
        # if it is parametric, then it should have parameters
        @test numparams(optype) != 0
        @test numparams(optype) == numpars

        # since it is parametric, then it should not be a singleton type
        @test !Base.issingletontype(optype)

        # check that the parameter functions are consistent
        @test length(parnames(optype)) == numpars

        @testset "defined params" begin
            randpars = rand(numpars)
            inst = optype(randpars...)

            @test length(getparams(inst)) == numpars
            @test all(getparams(inst) .== randpars)

            for name in parnames(optype)
                @test getparam(inst, name) isa Num
            end

            # proper hilbert space dimension and number of qubits
            @test hilbertspacedim(inst) == 2^N
            @test numqubits(inst) == N
            @test numbits(inst) == 0

            # same name bewtween an instance or a gate type
            @test opname(inst) == opname(optype)

            M = matrix(inst)

            # check that the matrix is square and that it has the proper dimensions
            @test all(x -> x == hilbertspacedim(inst), size(M))

            # check that the matrix is non symbolic
            @test eltype(M) <: ComplexF64 || eltype(M) <: Float64

            # matrix should be equal every time we get it from the same gate
            @test M == matrix(inst)

            # matrices of two different instances with same parameters should be egal)
            inst2 = optype(copy(randpars)...)
            @test M == matrix(inst2)

            # if we have different parameters the matrices should be different
            inst3 = optype(rand(numpars)...)
            @test M != matrix(inst3)
        end

        @testset "undefined params" begin
            @test 1 == 1
        end
    end
end

@testset "Operators definition" begin
    @test isdefined(MimiqCircuitsBase, :AbstractOperator)
    @test isdefined(MimiqCircuitsBase, :Operator)
    @test isdefined(MimiqCircuitsBase, :Projector0)
    @test isdefined(MimiqCircuitsBase, :Projector1)
    @test isdefined(MimiqCircuitsBase, :ProjectorX0)
    @test isdefined(MimiqCircuitsBase, :ProjectorX1)
    @test isdefined(MimiqCircuitsBase, :ProjectorY0)
    @test isdefined(MimiqCircuitsBase, :ProjectorY1)
    @test isdefined(MimiqCircuitsBase, :Projector00)
    @test isdefined(MimiqCircuitsBase, :Projector01)
    @test isdefined(MimiqCircuitsBase, :Projector10)
    @test isdefined(MimiqCircuitsBase, :Projector11)
    @test isdefined(MimiqCircuitsBase, :SigmaMinus)
    @test isdefined(MimiqCircuitsBase, :SigmaPlus)
    @test isdefined(MimiqCircuitsBase, :DiagonalOp)
end

@testset "Projection operators" begin
    map(t -> checkpoperator(t, 1, 1), Type[Projector0, Projector1, ProjectorX0, ProjectorX1, ProjectorY0, ProjectorY1])
    map(t -> checkpoperator(t, 2, 1), Type[Projector00, Projector01, Projector10, Projector11])
end

@testset "Sigma operators" begin
    map(t -> checkpoperator(t, 1, 1), Type[SigmaMinus, SigmaPlus])
end

@testset "Diagonal operators" begin
    map(t -> checkpoperator(t, 1, 2), Type[DiagonalOp])
end

@testset "Matrices operators -- no params" begin
    P0 = matrix(Projector0())
    P1 = matrix(Projector1())
    P00 = matrix(Projector00())
    P01 = matrix(Projector01())
    P10 = matrix(Projector10())
    P11 = matrix(Projector11())

    for M in [P0, P1, P00, P01, P10, P11]
        @test M * M == M
    end

    S01 = matrix(SigmaMinus())
    S10 = matrix(SigmaPlus())

    @test S01 * S10 == P0
    @test S10 * S01 == P1
end

@testset "Matrices operators -- params" begin
    a, b = rand(), rand()

    P0 = matrix(Projector0(a))
    P1 = matrix(Projector1(a))
    P00 = matrix(Projector00(a))
    P01 = matrix(Projector01(a))
    P10 = matrix(Projector10(a))
    P11 = matrix(Projector11(a))

    for M in [P0, P1, P00, P01, P10, P11]
        @test M * M == a .* M
    end

    S01 = matrix(SigmaMinus(a))
    S10 = matrix(SigmaPlus(a))

    @test S01 * S10 == a .* P0
    @test S10 * S01 == a .* P1

    Diag = matrix(DiagonalOp(a, b))

    @test Diag * Diag == matrix(DiagonalOp(a^2, b^2))
    @test P0 * Diag == a .* P0
    @test P1 * Diag == b .* P1
end

function checkcustomoperator(N)
    M = 2^N
    mat = rand(ComplexF64, M, M)
    op = Operator(mat)

    @test op isa Operator{N}
    @test matrix(op) == mat
end

@testset "Custom Operators" begin
    @test_throws ArgumentError Operator(rand(ComplexF64, 3, 3))

    checkcustomoperator(1)
    checkcustomoperator(2)

    @test_throws "larger than 2 qubits" checkcustomoperator(3)
end

