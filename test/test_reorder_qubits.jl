#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
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

@testset "reorder_qubits: top-level Amplitude bs permuted" begin
    # |ψ⟩ component labeled |01⟩ becomes |10⟩ after swapping qubit labels
    # 1 ↔ 2; Amplitude(bs"01") must rewrite to Amplitude(bs"10") so the
    # same physical component is queried.
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, Amplitude(bs"01"), 1)
    c2 = reorder_qubits(c, [2, 1])
    op = getoperation(c2[3])
    @test op isa Amplitude
    @test op.bs == bs"10"
end

@testset "reorder_qubits: IfStatement recursion descends into inner op" begin
    # Vase regression: IfStatement(Amplitude(bs"01"), bs"11") under
    # reorder [2, 1] — outer classical condition stays, inner Amplitude
    # gets its qubit-indexed bs permuted.
    c = Circuit()
    push!(c, GateCX(), 1, 2)                              # widen to 2 qubits
    push!(c, IfStatement(Amplitude(bs"01"), bs"11"), 1, 2, 1)
    c2 = reorder_qubits(c, [2, 1])
    outer = getoperation(c2[2])
    @test outer isa IfStatement
    @test getbitstring(outer) == bs"11"                   # unchanged
    inner = getoperation(outer)
    @test inner isa Amplitude
    @test inner.bs == bs"10"
end

@testset "reorder_qubits: Block treated transparently for embedded Amplitude" begin
    # Block holds general operations and is transparent for the outer
    # reorder: only the embedded `Amplitude.bs` is rewritten; the
    # block's instruction targets stay in the block's local frame.
    inner_circ = Circuit()
    push!(inner_circ, Amplitude(bs"01"), 1)
    block_op = Block(inner_circ)
    c = Circuit()
    push!(c, GateCX(), 1, 2)                              # widen to 2 qubits
    push!(c, block_op, 1)
    c2 = reorder_qubits(c, [2, 1])
    new_block = getoperation(c2[2])
    @test new_block isa Block
    inner_amp = getoperation(new_block[1])
    @test inner_amp isa Amplitude
    @test inner_amp.bs == bs"10"
end

@testset "reorder_qubits: identity permutation is a no-op on Amplitude" begin
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, GateH(), 2)
    push!(c, GateH(), 3)
    push!(c, Amplitude(bs"011"), 1)
    op = getoperation(reorder_qubits(c, [1, 2, 3])[end])
    @test op isa Amplitude
    @test op.bs == bs"011"
end

@testset "reorder_qubits: rejects non-permutations" begin
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, GateH(), 2)
    @test_throws ArgumentError reorder_qubits(c, [1, 1])
    @test_throws ArgumentError reorder_qubits(c, [1])
end
