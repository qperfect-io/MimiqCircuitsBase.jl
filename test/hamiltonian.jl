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
using MimiqCircuitsBase
using MimiqCircuitsBase: toproto, fromproto, hamiltonian_pb

@testset "HamiltonianTerm" begin
    @testset "Constructor" begin
        @testset "Single qubit term" begin
            p = pauli"X"
            term = HamiltonianTerm(1.5, p, 1)

            @test getcoefficient(term) == 1.5
            @test getoperation(term) == p
            @test getqubits(term) == (1,)
        end

        @testset "Multi qubit term" begin
            p = pauli"XY"
            term = HamiltonianTerm(2.0, p, 1, 2)

            @test getcoefficient(term) == 2.0
            @test getoperation(term) == p
            @test getqubits(term) == (1, 2)
        end
    end

    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin

            @testset "Single qubit term" begin
                p = pauli"X"
                term = HamiltonianTerm(1.5, p, 1)
                backforth = fromproto(toproto(term))

                @test backforth isa HamiltonianTerm
                @test getcoefficient(backforth) == 1.5
                @test getoperation(backforth) == p
                @test getqubits(backforth) == (1,)
            end

            @testset "Multi qubit term" begin
                p = pauli"XY"
                term = HamiltonianTerm(2.0, p, 1, 2)
                backforth = fromproto(toproto(term))

                @test backforth isa HamiltonianTerm
                @test getcoefficient(backforth) == 2.0
                @test getoperation(backforth) == p
                @test getqubits(backforth) == (1, 2)
            end

            @testset "Negative coefficient" begin
                p = pauli"Z"
                term = HamiltonianTerm(-3.0, p, 1)
                backforth = fromproto(toproto(term))

                @test backforth isa HamiltonianTerm
                @test getcoefficient(backforth) == -3.0
                @test getoperation(backforth) == p
                @test getqubits(backforth) == (1,)
            end
        end
    end
end

@testset "Hamiltonian" begin
    @testset "Basics" begin
        @testset "Empty Hamiltonian" begin
            h = Hamiltonian()
            @test length(h.terms) == 0
            @test numqubits(h) == 0
        end

        @testset "Adding terms" begin
            h = Hamiltonian()
            p1 = pauli"X"
            p2 = pauli"Y"
            term1 = HamiltonianTerm(1.0, p1, 1)
            term2 = HamiltonianTerm(2.0, p2, 2)

            push!(h, term1)
            @test length(h.terms) == 1
            @test numqubits(h) == 1

            push!(h, term2)
            @test length(h.terms) == 2
            @test numqubits(h) == 2
        end

        @testset "Adding terms directly" begin
            h = Hamiltonian()
            p1 = pauli"X"
            p2 = pauli"Y"

            push!(h, 1.0, p1, 1)
            @test length(h.terms) == 1
            @test numqubits(h) == 1

            push!(h, 2.0, p2, 2)
            @test length(h.terms) == 2
            @test numqubits(h) == 2
        end
    end

    @testset "Indexing and iteration" begin
        h = Hamiltonian()
        terms = []

        for (i, pauli) in enumerate([pauli"X", pauli"Y", pauli"Z"])
            term = HamiltonianTerm(Float64(i), pauli, i)
            push!(h, term)
            push!(terms, term)
        end

        @testset "Indexing" begin
            @test h[1] == terms[1]
            @test h[2] == terms[2]
            @test h[3] == terms[3]
        end

        @testset "Slicing" begin
            h1 = h[1:2]
            h1[1] == terms[1]
            h1[2] == terms[2]
        end

        @testset "Iteration" begin
            for (i, term) in enumerate(h)
                @test term == terms[i]
            end
        end
    end

    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            h = Hamiltonian()
            push!(h, 1.0, PauliString("Z"), 1)
            push!(h, -0.5, PauliString("XY"), 2, 3)
    
            h_proto = toproto(h)
            h_restored = fromproto(h_proto)
    
            @test h_restored isa Hamiltonian
            @test length(h_restored) == length(h)
            @test getoperation(h_restored[1]) == getoperation(h[1])
            @test getcoefficient(h_restored[2]) ≈ getcoefficient(h[2])
            @test getqubits(h_restored[2]) == getqubits(h[2])
        end

        @testset "saveproto / loadproto" begin
            h = Hamiltonian()
            push!(h, 1.0, pauli"X", 1)
            push!(h, 0.75, pauli"ZZ", 2, 3)
    
            path = tempname() * ".pb"
            saveproto(path, h)
    
            @test isfile(path)
    
            h_loaded = loadproto(path, Hamiltonian)
    
            @test h_loaded isa Hamiltonian
            @test length(h_loaded) == length(h)
            @test getoperation(h_loaded[2]) == getoperation(h[2])
            @test getqubits(h_loaded[2]) == getqubits(h[2])
            @test getcoefficient(h_loaded[1]) ≈ getcoefficient(h[1])
        
        end 
    
    end
end

@testset "push_expval!" begin
    h = Hamiltonian()

    # Create a simple hamiltonian
    N = 4
    for i in 1:N
        for j in i+1:N
            push!(h, 1.12, pauli"XX", i, j)
            push!(h, 1.23, pauli"YY", i, j)
            push!(h, 1.34, pauli"ZZ", i, j)
        end
        push!(h, 1.45, pauli"Z", i)
    end

    @testset "Error handling" begin
        # Wrong number of qubits should throw an error
        @test_throws ArgumentError push_expval!(Circuit(), h, 1:(N-1)...)
        @test_throws ArgumentError push_expval!(Circuit(), h, 1:(N+1)...)
    end

    @testset "Basics" begin
        c = push_expval!(Circuit(), h, 1:N...)

        @test length(c) > 0

        @test count(x -> getoperation(x) isa Multiply, c) == length(h)
        @test count(x -> getoperation(x) isa ExpectationValue, c) == length(h)

        for inst in c
            op = getoperation(inst)
            @test op isa Multiply || op isa Add || op isa ExpectationValue
        end
    end
end

@testset "push_lietrotter!" begin
    h = Hamiltonian()
    push!(h, 1.0, pauli"XX", 1, 2)
    push!(h, 0.5, pauli"Y", 1)

    qubits = (1, 2)
    t = 1.0
    steps = 2

    c = Circuit()
    push_lietrotter!(c, qubits, h, t, steps)

    # Each step is a macro gate, like trotter(t/steps)
    @test length(c) == steps
    @test all(inst -> getoperation(inst) isa GateCall, c)

    # Optional: test that the GateCall name matches the declaration
    for inst in c
        @test getoperation(inst)._decl.name == :trotter
    end

    # Error case: qubit mismatch
    @test_throws ArgumentError push_lietrotter!(Circuit(), (1,), h, t, steps)
end

@testset "push_suzukitrotter!" begin
    h = Hamiltonian()
    push!(h, 1.0, pauli"XX", 1, 2)
    push!(h, 0.5, pauli"Y", 1)

    qubits = (1, 2)
    t = 1.0
    steps = 2
    order = 2

    c = Circuit()
    push_suzukitrotter!(c, qubits, h, t, steps, order)

    @test length(c) == steps
    @test all(inst -> getoperation(inst) isa GateCall, c)

    for inst in c
        @test occursin("suzukitrotter", string(getoperation(inst)._decl.name))
    end

    # Error case: odd order
    @test_throws ArgumentError push_suzukitrotter!(Circuit(), qubits, h, t, steps, 3)

    # Error case: qubit mismatch
    @test_throws ArgumentError push_suzukitrotter!(Circuit(), (1,), h, t, steps, 2)
end


