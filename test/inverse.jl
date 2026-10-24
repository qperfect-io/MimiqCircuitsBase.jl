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

@testset "Inverse Constructor" begin

    for gate in [GateX(), GateRX(0.2), GateSWAP()]
        mygate1 = Inverse(gate)
        mygate2 = Inverse(gate)

        # two controls of the same matrix should always be egal
        @test mygate1 === mygate2

        @test opname(mygate1) != "Inverse"
        @test opname(mygate1)[end] == '†'
        @test numqubits(mygate1) == numqubits(gate)
        @test numbits(mygate1) == 0

        if matrix(gate) === matrix(gate)
            @test matrix(mygate1) === matrix(mygate2)
        else
            @test matrix(mygate1) == matrix(mygate2)
        end

        @test matrix(gate) * matrix(mygate1) ≈ I
    end
end

@testset "Inverse Decomposition" begin
    decomp = decompose_step(Inverse(Parallel(2, GateH())))

    @test length(decomp) == 2
    @test getoperation(decomp[1]) isa GateH
    @test getoperation(decomp[2]) isa GateH
    @test getqubits(decomp[1]) == (2,)
    @test getqubits(decomp[2]) == (1,)
end

@testset "Inverse of a canonical primitive" begin
    # GateU has no canonical rewrite of its own, so its inverse is taken directly.
    decomp = decompose_step(Inverse(GateU(0.3, 0.7, 1.1)))
    @test length(decomp) == 1
    @test getoperation(decomp[1]) == GateU(-0.3, -1.1, -0.7, 0.0)
end
