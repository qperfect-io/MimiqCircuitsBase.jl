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


@testset "Circuit equality and hashing" begin
    using MimiqCircuitsBase
    using Symbolics

    # Basic equality: identical instructions
    c1 = Circuit()
    push!(c1, GateRX(1.0), 1)

    c2 = Circuit()
    push!(c2, GateRX(1.0), 1)

    @test c1 == c2

    # Different numeric parameter => circuits not equal
    c3 = Circuit()
    push!(c3, GateRX(2.0), 1)

    @test c1 != c3

    # Symbolic parameter equality (structural match)
    @variables x y

    c4 = Circuit()
    c5 = Circuit()

    push!(c4, GateRY(x), 2)
    push!(c5, GateRY(x), 2)

    @test c4 == c5

    # Symbolic parameters structurally different => not equal
    c6 = Circuit()
    push!(c6, GateRY(x + y), 2)

    @test c4 != c6

    # Same operation type and same parameters => equal
    c7 = Circuit()
    push!(c7, GateRX(1.0), 1)

    @test c1 == c7

    # Numeric 1.0 vs 1 (normalized numeric comparison) => equal
    c8 = Circuit()
    push!(c8, GateRX(1), 1)

    @test c1 == c8

    # Multiple-instruction circuits identical => equal
    c9 = Circuit()
    c10 = Circuit()

    push!(c9, GateRX(1.0), 1)
    push!(c9, GateRY(2.0), 2)

    push!(c10, GateRX(1.0), 1)
    push!(c10, GateRY(2.0), 2)

    @test c9 == c10

    # Instruction order matters => not equal
    c11 = Circuit()
    push!(c11, GateRY(2.0), 2)
    push!(c11, GateRX(1.0), 1)

    @test c9 != c11
end
