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

@testset "IfStatement Constructor and Decomposition" begin
    # Basic construction with 1-qubit gate and 1-bit condition
    gate = GateX()
    bs = BitString("1")
    ifs = IfStatement(gate, bs)

    @test opname(ifs) == "IF"
    @test numqubits(ifs) == 1
    @test numbits(ifs) == numbits(gate) + length(bs)
    @test numzvars(ifs) == 0
    @test getoperation(ifs) === gate
    @test getbitstring(ifs) == bs

    # Construction with a block containing both qubit, bits and zvars
    c = Circuit()
    push!(c, GateX(), 1)
    push!(c, Measure(), 1, 1)
    push!(c, ExpectationValue(GateX()), 1, 1)
    b = Block(c)
    bs2 = BitString("0")
    ifs2 = IfStatement(b, bs2)

    @test numqubits(ifs2) == numqubits(b)
    @test numbits(ifs2) == numbits(b) + length(bs2)
    @test numzvars(ifs2) == numzvars(b)

    # Check decompose on block with mixed operations
    d = decompose(ifs2)
    @test d isa Circuit
    @test length(d._instructions) == length(b._instructions)


    # Check that condition bits are appended correctly after operation bits
    for inst in d._instructions
        op = getoperation(inst)
        nb_op = numbits(getoperation(op))
        nb_cond = length(getbitstring(op))
        @test numbits(inst) == nb_op + nb_cond
    end

    # Test evaluate preserves bitstring
    d2 = evaluate(ifs2, Dict())
    @test getbitstring(d2) == bs2

end
