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

@testset "Inverse Constructor" begin
    #@test_throws ErrorException Inverse(Measure())
    #@test_throws ErrorException Inverse(Reset())

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
