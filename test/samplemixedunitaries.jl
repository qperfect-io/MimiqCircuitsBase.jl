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

@testset "samplemixedunitaries" begin
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, PauliX(0.5), 1)
    push!(c, MixedUnitary([0.3, 0.7], [GateCX(), GateSWAP()]), 1, 2)
    push!(c, ExpectationValue(GateZ()), 1, 1)
    push!(c, Measure(), 2, 1)

    for _ in 1:20
        sampled = collect(@test_deprecated samplemixedunitaries(c))
        @test length(sampled) == length(c)
        @test sampled[1] == c[1]
        @test getoperation(sampled[2]) in (GateID(), GateX())
        @test getqubits(sampled[2]) == (1,)
        @test getoperation(sampled[3]) in (GateCX(), GateSWAP())
        @test getqubits(sampled[3]) == (1, 2)
        @test sampled[4] == c[4]
        @test getztargets(sampled[4]) == (1,)
        @test sampled[5] == c[5]
    end

    # a drawn lossy branch emits a Loss on its marked qubit
    lossy = push!(Circuit(), MixedUnitary([0.0, 1.0], [GateID(), GateX()]; lossy=[Int[], [1]]), 2)
    @test collect(@test_deprecated samplemixedunitaries(lossy)) == [Instruction(GateX(), 2), Instruction(Loss(1.0), 2)]
end
