#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
using LinearAlgebra: I, opnorm

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

@testset "Decomposition matches matrix" begin
    # A multi-controlled multi-target gate decomposes by decomposing the inner
    # gate first and re-wrapping each resulting single-target gate as
    # Control(N, ·), which recurses through power(GateU, 1/2). Diagonal inner
    # gates (θ = 0) used to lose their phase there, so the decomposition of the
    # whole operation no longer matched its matrix. This is the operation shape
    # that silently miscomputed Shor's modular arithmetic.
    tomat(M) = ComplexF64.(MimiqCircuitsBase.unwrapvalue.(M))

    function decomposed_unitary(op)
        n = numqubits(op)
        c = Circuit()
        push!(c, op, (1:n)...)
        return tomat(matrix(decompose(c)))
    end

    # Reference unitary for Control(N, gate): identity except the bottom-right
    # block (all controls set) which holds the gate's matrix.
    function control_matrix(ncontrols, gate)
        g = tomat(matrix(gate))
        d = size(g, 1)
        dim = 2^ncontrols * d
        m = Matrix{ComplexF64}(I, dim, dim)
        m[end-d+1:end, end-d+1:end] = g
        return m
    end

    # A two-qubit gate built from diagonal phase gates (Draper-adder shape).
    sub = Circuit()
    push!(sub, GateP(π), 1)
    push!(sub, GateP(π / 2), 2)
    twop = GateDecl(:twop, (), sub)()

    # Controls of a single-qubit diagonal GateU/GateP: matrix(op) is available.
    for op in (Control(2, GateU(0, 0, π, 0)), Control(2, GateP(π)))
        @test opnorm(tomat(matrix(op)) - decomposed_unitary(op)) < 1e-10
    end

    # Control of a multi-target GateCall: matrix(Control(·, GateCall)) is not
    # defined, so compare the decomposition against the reference control matrix
    # built from the (available) matrix of the wrapped gate. This is the exact
    # operation shape (multi-control of a multi-target block of diagonal gates)
    # that used to decompose to the identity on the target register.
    op = Control(2, twop)
    @test opnorm(control_matrix(2, twop) - decomposed_unitary(op)) < 1e-10
end

