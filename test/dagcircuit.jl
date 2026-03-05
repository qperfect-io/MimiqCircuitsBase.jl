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

using MimiqCircuitsBase
using Test
using Graphs

@testset "DAG Circuit" begin
    @testset "Construction" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateX(), 1)
        push!(c, Measure(), 1, 1)

        dag = Circuit(c)
        @test nv(dag) == 3
        @test ne(dag) == 2
        @test has_edge(dag, 1, 2)
        @test has_edge(dag, 2, 3)
        @test !has_edge(dag, 1, 3) # No direct edge, only transitive

        @test dag[1] == c[1]
        @test dag[2] == c[2]
        @test dag[3] == c[3]
    end

    @testset "Parallel Ops" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateH(), 2)

        @test nv(c) == 2
        @test ne(c) == 0
    end

    @testset "Multi-qubit Ops" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateH(), 2)
        push!(c, GateCX(), 1, 2)

        @test nv(c) == 3
        @test ne(c) == 2
        @test has_edge(c, 1, 3) # q1 dep
        @test has_edge(c, 2, 3) # q2 dep
    end

    @testset "Bits and Z-targets" begin
        c = Circuit()
        push!(c, Measure(), 1, 1)
        push!(c, Measure(), 2, 1)

        @test nv(c) == 2
        @test ne(c) == 1
        @test has_edge(c, 1, 2)
    end

    @testset "Graphs Interface" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateH(), 2)
        push!(c, GateX(), 1)
        push!(c, GateCX(), 1, 2)
        push!(c, GateY(), 2)

        @test Graphs.is_directed(c)
        @test Graphs.is_directed(typeof(c))
        @test length(vertices(c)) == 5
        @test length(edges(c)) == 4

        @test outneighbors(c, 2) == [4]
        @test inneighbors(c, 2) == []
        @test outneighbors(c, 1) == [3]
        @test sort(inneighbors(c, 4)) == [2, 3]
        @test outneighbors(c, 4) == [5]
    end

    @testset "Traversal" begin
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateX(), 2)
        push!(c, GateY(), 2)
        push!(c, GateZ(), 1)
        push!(c, GateS(), 3)
        push!(c, GateRX(0.1), 1)
        push!(c, GateCX(), 1, 3)

        @testset "DAG DFS" begin
            insts = collect(traverse_by_dfs(c))

            @test length(insts) == length(c)

            i = 1
            while !(getoperation(insts[i]) isa GateH)
                i += 1
            end
            @test getoperation(insts[i]) isa GateH
            @test getoperation(insts[i+1]) isa GateZ
            @test getoperation(insts[i+2]) isa GateRX
        end

        @testset "DAG BFS" begin
            insts = collect(traverse_by_bfs(c))

            @test length(insts) == length(c)

            @test getoperation(insts[1]) isa GateH
            @test getoperation(insts[2]) isa GateX
            @test getoperation(insts[3]) isa GateS

        end
    end
end
