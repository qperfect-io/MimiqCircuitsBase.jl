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

# ======================================================= #
# GRAPH STATE CIRCUIT (Entanglement from graph structure) #
# ======================================================= #

@doc raw"""
    graph_state_circuit(n_qubits, edges)

Prepare a graph state ``\ket{G}`` defined by a graph `(V, E)`.

```math
    \ket{G} = \prod_{(i,j)\in E} \mathrm{CZ}_{ij} \ket{+}^{\otimes n}
```

Graph states are resources for measurement-based quantum computing.

Key difference: Single layer of `CZ` gates, structure determined by graph.
"""
function graph_state_circuit(n_qubits::Int, edges::Vector{Tuple{Int,Int}})
    c = Circuit()

    # Initialize in |+⟩ state
    push!(c, GateH(), 1:n_qubits)

    # Apply CZ for each edge
    for (i, j) in edges
        push!(c, GateCZ(), i, j)
    end

    return c
end

# Common graph types
function graph_state_linear(n::Int)
    edges = [(i, i + 1) for i in 1:(n-1)]
    graph_state_circuit(n, edges)
end

function graph_state_ring(n::Int)
    edges = [(i, mod1(i + 1, n)) for i in 1:n]
    graph_state_circuit(n, edges)
end

function graph_state_star(n::Int)
    edges = [(1, i) for i in 2:n]
    graph_state_circuit(n, edges)
end

function graph_state_complete(n::Int)
    edges = [(i, j) for i in 1:n for j in (i+1):n]
    graph_state_circuit(n, edges)
end
