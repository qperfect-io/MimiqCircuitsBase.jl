#
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

@variables θ φ ψ

@testset "ParameterTable" begin
    @testset "constructors agree" begin
        m = [0.0 1.0; 0.5 2.0; 1.0 3.0]
        a = ParameterTable([θ, φ], m)
        b = ParameterTable(θ => [0.0, 0.5, 1.0], φ => [1.0, 2.0, 3.0])
        c = ParameterTable([Dict(θ => 0.0, φ => 1.0), Dict(θ => 0.5, φ => 2.0),
            Dict(θ => 1.0, φ => 3.0)])
        for t in (a, b, c)
            @test length(t) == 3
            @test isequal(listvars(t), [θ, φ])
            @test Matrix(t) == m
        end
    end

    @testset "points" begin
        t = ParameterTable(θ => [0.0, 0.5], φ => [1, 2])
        @test t[2] == Dict(θ => 0.5, φ => 2.0)
        @test collect(t) == [t[1], t[2]]
        @test eltype(ParameterTable) == Dict{MimiqCircuitsBase.Symbolics.Num,Float64}
    end

    @testset "values are exact numbers" begin
        t = ParameterTable([Dict(θ => π), Dict(θ => 1 // 2)])
        @test Matrix(t) == reshape([Float64(π), 0.5], 2, 1)
    end

    @testset "invalid tables" begin
        @test_throws DimensionMismatch ParameterTable([θ, φ], zeros(3, 1))
        @test_throws DimensionMismatch ParameterTable(θ => [0, 1], φ => [0])
        @test_throws ArgumentError ParameterTable([θ, θ], zeros(1, 2))
        @test_throws ArgumentError ParameterTable([2θ], zeros(1, 1))
        @test_throws ArgumentError ParameterTable([Dict(θ => 0), Dict(φ => 0)])
        @test_throws ArgumentError ParameterTable([Dict(θ => 0), Dict(θ => 0, φ => 1)])
        @test_throws ArgumentError ParameterTable(Dict[])
        @test_throws ArgumentError ParameterTable()
    end

    @testset "product" begin
        t = ParameterTable(θ => [0.0, 1.0]) * ParameterTable(φ => [0.0, 2.0, 4.0])
        @test isequal(listvars(t), [θ, φ])
        # The first table varies slowest.
        @test Matrix(t) == [0.0 0.0; 0.0 2.0; 0.0 4.0; 1.0 0.0; 1.0 2.0; 1.0 4.0]
        @test_throws ArgumentError t * ParameterTable(θ => [0.0])
    end

    @testset "gridtable is the product of its columns" begin
        g = gridtable(θ => [0.0, 1.0], φ => [0.0, 2.0, 4.0], ψ => [5.0, 6.0])
        p = ParameterTable(θ => [0.0, 1.0]) * ParameterTable(φ => [0.0, 2.0, 4.0]) *
            ParameterTable(ψ => [5.0, 6.0])
        @test length(g) == 12
        @test isequal(listvars(g), listvars(p))
        @test Matrix(g) == Matrix(p)
        @test Matrix(gridtable(θ => [1.0, 2.0])) == reshape([1.0, 2.0], 2, 1)
    end

    @testset "hcat pairs points" begin
        t = hcat(ParameterTable(θ => [0.0, 1.0]), ParameterTable(φ => [5.0, 6.0]),
            ParameterTable(ψ => [7.0, 8.0]))
        @test isequal(listvars(t), [θ, φ, ψ])
        @test Matrix(t) == [0.0 5.0 7.0; 1.0 6.0 8.0]
        @test_throws DimensionMismatch hcat(ParameterTable(θ => [0.0]),
            ParameterTable(φ => [0.0, 1.0]))
        @test_throws ArgumentError hcat(ParameterTable(θ => [0.0]), ParameterTable(θ => [1.0]))
    end

    @testset "vcat appends points" begin
        a = ParameterTable(θ => [0.0], φ => [1.0])
        b = ParameterTable(φ => [3.0], θ => [2.0])   # same symbols, other order
        t = vcat(a, b, a)
        @test isequal(listvars(t), [θ, φ])
        @test Matrix(t) == [0.0 1.0; 2.0 3.0; 0.0 1.0]
        @test_throws ArgumentError vcat(a, ParameterTable(θ => [0.0]))
    end

    @testset "indexing" begin
        t = ParameterTable(θ => [0.0, 0.5, 1.0], φ => [1.0, 2.0, 3.0])
        @test t[end] == t[3]
        @test firstindex(t) == 1
        @test t[2:3] == ParameterTable(θ => [0.5, 1.0], φ => [2.0, 3.0])
        @test t[[3, 1]] == ParameterTable(θ => [1.0, 0.0], φ => [3.0, 1.0])
    end

    @testset "equality" begin
        a = ParameterTable(θ => [0.0, 0.5], φ => [1.0, 2.0])
        b = ParameterTable(θ => [0.0, 0.5], φ => [1.0, 2.0])
        @test a == b
        @test isequal(a, b)
        @test hash(a) == hash(b)
        @test length(Set([a, b])) == 1
        @test a != ParameterTable(θ => [0.0, 0.5], φ => [1.0, 3.0])
        # The symbol order is part of the layout.
        @test a != ParameterTable(φ => [1.0, 2.0], θ => [0.0, 0.5])
    end

    @testset "show" begin
        t = ParameterTable(θ => [0.0, 0.5])
        @test sprint(show, t) == "ParameterTable(2 points over (θ))"
        long = sprint(show, MIME"text/plain"(), ParameterTable(θ => collect(1.0:20.0)))
        @test occursin("⋮", long)
        @test count('\n', long) == 11
    end
end

@testset "SweepExperiment" begin
    c = push!(Circuit(), GateRX(θ), 1)
    push!(c, GateRY(φ), 1)

    @testset "points are evaluated circuits" begin
        ex = SweepExperiment(c, gridtable(θ => [0.0, π], φ => [0.0, π / 2]))
        @test length(ex) == 4
        @test ex[2] == evaluate(c, Dict(θ => 0.0, φ => π / 2))
        @test !issymbolic(ex[4])
        @test collect(ex) == [ex[i] for i in 1:4]
        @test numqubits(ex) == 1
        @test isequal(Set(listvars(ex)), Set([θ, φ]))
    end

    @testset "the table must bind exactly the circuit's symbols" begin
        err = try
            SweepExperiment(c, ParameterTable(θ => [0.0]))
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("no values for φ", err.msg)

        err = try
            SweepExperiment(c, ParameterTable(θ => [0.0], φ => [0.0], ψ => [0.0]))
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("ψ", err.msg)

        @test_throws ArgumentError SweepExperiment(push!(Circuit(), GateH(), 1),
            ParameterTable(θ => [0.0]))
    end

    @testset "indexing and equality" begin
        ex = SweepExperiment(c, gridtable(θ => [0.0, π], φ => [0.0, π / 2]))
        @test ex[end] == ex[4]
        sub = ex[2:3]
        @test sub isa SweepExperiment
        @test length(sub) == 2
        @test sub[1] == ex[2]
        @test sub == SweepExperiment(c, ex.table[2:3])
        @test hash(sub) == hash(SweepExperiment(c, ex.table[2:3]))
        @test sub != ex
    end

    @testset "symbols inside a block" begin
        bc = push!(Circuit(), Block(push!(Circuit(), GateRX(θ), 1)), 1)
        ex = SweepExperiment(bc, ParameterTable(θ => [0.0, π]))
        @test ex[2] == push!(Circuit(), Block(push!(Circuit(), GateRX(π), 1)), 1)
    end
end
