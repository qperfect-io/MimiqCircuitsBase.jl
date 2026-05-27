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

@testset "is_full_width_barrier: positive cases" begin
    c = Circuit()
    push!(c, Barrier(3), 1, 2, 3)
    @test is_full_width_barrier(c[1], 3)

    c2 = Circuit()
    push!(c2, Barrier(2), 1, 2)
    @test is_full_width_barrier(c2[1], 2)

    c1 = Circuit()
    push!(c1, Barrier(1), 1)
    @test is_full_width_barrier(c1[1], 1)
end

@testset "is_full_width_barrier: negative cases" begin
    # Barrier on a subset of qubits is not full-width.
    c = Circuit()
    push!(c, Barrier(2), 1, 2)
    @test !is_full_width_barrier(c[1], 3)

    # Single-qubit Barrier in a multi-qubit circuit is not full-width
    # (even if a run of N Barrier{1}s would together span 1:N — we do
    # NOT recognise runs here; insert a Barrier(N) instead).
    c2 = Circuit()
    push!(c2, Barrier(1), 1)
    @test !is_full_width_barrier(c2[1], 2)

    # A non-Barrier instruction is never a full-width barrier.
    c3 = Circuit()
    push!(c3, GateX(), 1)
    @test !is_full_width_barrier(c3[1], 1)
end
