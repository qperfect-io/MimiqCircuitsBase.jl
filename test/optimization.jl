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
using MimiqCircuitsBase: toproto, fromproto

@testset "OptimizationExperiment" begin
    @variables x y
    c = Circuit()
    push!(c, GateRX(x), 1)
    push!(c, GateRZ(y), 2)

    initparams = Dict(x => 0.1, y => 0.2)

    ex = OptimizationExperiment(c, initparams, optimizer="COBYLA", label="test_experiment", maxiters=100, zregister=3)

    @test ex.optimizer == "COBYLA"
    @test ex.label == "test_experiment"
    @test numparams(ex) == 2
    @test numqubits(ex) == 2
    @test MimiqCircuitsBase.isvalid(ex)

    θ = [1.0, 2.0]
    newex = changelistofparameters(ex, θ)

    @test newex.initparams[x] ≈ 1.0
    @test newex.initparams[y] ≈ 2.0

    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            proto = toproto(ex)
            ex2 = fromproto(proto)

            @test ex2.optimizer == ex.optimizer
            @test ex2.label == ex.label
            @test ex2.maxiters == ex.maxiters
            @test ex2.zregister == ex.zregister
            @test length(ex2.circuit) == length(ex.circuit)
            @test ex2.initparams == ex.initparams
        end
    end
end


@testset "OptimizationRun" begin
    # avoid `nothing` for protobuf strings
    @variables x y
    result = QCSResults("", "")
    params = Dict(x => 0.5, y => 1.2)
    run = OptimizationRun(1.23, params, result)

    @test getcost(run) ≈ 1.23
    @test getparam(run, x) ≈ 0.5
    @test getparam(run, y) ≈ 1.2
    @test getparams(run) == params

    @testset "ProtoBuf" begin
        run2 = fromproto(toproto(run))
        @test run2.cost ≈ run.cost
        @test run2.parameters == run.parameters
    end
end


@testset "OptimizationResults" begin
    @variables x
    run1 = OptimizationRun(1.0, Dict(x => 0.1), QCSResults("", ""))
    run2 = OptimizationRun(0.8, Dict(x => 0.2), QCSResults("", ""))
    runs = [run1, run2]

    res = OptimizationResults(run2, runs)

    @test getbest(res) == run2
    @test getcost(getbest(res)) ≈ 0.8
    @test costhistory(res) == [1.0, 0.8]
    @test length(res) == 2
    @test res[2] == run2

    @testset "ProtoBuf" begin
        res2 = fromproto(toproto(res))
        @test getcost(getbest(res2)) ≈ 0.8
        @test costhistory(res2) == [1.0, 0.8]
    end
end
