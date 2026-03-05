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

# ===================== #
# DAG Circuit BENCHMARKS #
# ===================== #

SUITE["dag"] = BenchmarkGroup(["Benchmarks for DAG Circuit operations"])

# Construction
SUITE["dag"]["construct"] = BenchmarkGroup()

for n in [10, 50, 100]
    dag = random_circuit(20, n)
    SUITE["dag"]["construct"]["n$n"] = @benchmarkable Graphs.nv($dag) # First access to graph => gets computed
    SUITE["dag"]["ops_n$n"]["topological_sort"] = @benchmarkable Graphs.topological_sort_by_dfs($dag)
end
