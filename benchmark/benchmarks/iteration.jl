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

# ===================================== #
# CIRCUIT ITERATION & ACCESS BENCHMARKS #
# ===================================== #

SUITE["iteration"] = BenchmarkGroup(["Benchmarks for traversing circuits"])

for n in [10, 50, 100]
    circuit = random_circuit(20, n)

    # For-loop iteration
    SUITE["iteration"]["forloop_n$n"] = @benchmarkable begin
        count = 0
        for inst in $circuit
            count += 1
        end
        count
    end

    # Indexed access
    SUITE["iteration"]["getindex_n$n"] = @benchmarkable begin
        count = 0
        for i in 1:length($circuit)
            _ = $circuit[i]
            count += 1
        end
        count
    end

    # Collect
    SUITE["iteration"]["collect_n$n"] = @benchmarkable collect($circuit)

    # eachindex
    SUITE["iteration"]["eachindex_n$n"] = @benchmarkable begin
        count = 0
        for i in eachindex($circuit)
            count += 1
        end
        count
    end
end
