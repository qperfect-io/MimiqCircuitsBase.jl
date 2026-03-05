#
# Copyright © 2025-2026 QPerfect. All Rights Reserved.
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

# ============================= #
# ALLOCATION-FOCUSED BENCHMARKS #
# ============================= #

SUITE["allocations"] = BenchmarkGroup(["Benchmarks focused on memory allocation patterns"])

# Instruction vector building
SUITE["allocations"]["inst_vector_100"] = @benchmarkable begin
    v = Vector{Instruction}()
    sizehint!(v, 100)
    for i in 1:100
        push!(v, Instruction(GateH(), (i,), (), ()))
    end
    v
end

SUITE["allocations"]["inst_vector_1000"] = @benchmarkable begin
    v = Vector{Instruction}()
    sizehint!(v, 1000)
    for i in 1:1000
        push!(v, Instruction(GateH(), (mod1(i, 50),), (), ()))
    end
    v
end

# Matrix reuse test
rx_gate = GateRX(0.5)
SUITE["allocations"]["matrix_repeated_100"] = @benchmarkable begin
    for _ in 1:100
        _ = matrix($rx_gate)
    end
end

# Circuit copy
circ_for_copy = random_circuit(20, 500)
SUITE["allocations"]["circuit_copy_500"] = @benchmarkable copy($circ_for_copy)
