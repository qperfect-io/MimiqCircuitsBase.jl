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

@doc raw"""
    module BenchmarkCircuits

Collection of benchmark quantum circuits with diverse connectivity patterns, gate distributions, 
and algorithmic structures for testing and benchmarking quantum circuit simulators.

# Circuit Catalog

| Function | Category | Qubits | Description |
|:---------|:---------|:-------|:------------|
| [`random_circuit`](@ref) | Random | Any | Configurable random gate mix |
| [`random_clifford_circuit`](@ref) | Random | Any | Clifford-only (classically simulable) |
| [`ghz_circuit`](@ref) | State Prep | Any | GHZ state, star topology |
| [`wstate_circuit`](@ref) | State Prep | Any | W state, cascaded rotations |
| [`graph_state_circuit`](@ref) | State Prep | Any | Graph state from edge list |
| [`graph_state_linear`](@ref) | State Prep | Any | Linear graph state |
| [`graph_state_ring`](@ref) | State Prep | Any | Ring graph state |
| [`graph_state_star`](@ref) | State Prep | Any | Star graph state |
| [`graph_state_complete`](@ref) | State Prep | Any | Complete graph state |
| [`qft_circuit`](@ref) | Algorithm | Any | Quantum Fourier Transform |
| [`variational_ansatz`](@ref) | VQE/QAOA | Any | Hardware-efficient ansatz |
| [`qv_circuit`](@ref) | Benchmark | Any | IBM Quantum Volume |
| [`bricklayer_circuit`](@ref) | Topology | Any | 1D alternating bonds |
| [`grid_circuit`](@ref) | Topology | rows×cols | 2D nearest-neighbor |
| [`tree_circuit`](@ref) | Topology | 2ᵈ-1 | Binary tree structure |
| [`swap_network_circuit`](@ref) | Topology | Any | All-to-all via SWAP |
| [`qaoa_maxcut_circuit`](@ref) | Algorithm | Any | MaxCut QAOA |
| [`qaoa_complete_graph`](@ref) | Algorithm | Any | QAOA on complete graph |
| [`qaoa_random_graph`](@ref) | Algorithm | Any | QAOA on random graph |
| [`grover_circuit`](@ref) | Algorithm | Any | Grover's search |
| [`qpe_circuit`](@ref) | Algorithm | n+target | Phase estimation |
| [`trotter_heisenberg_circuit`](@ref) | Simulation | Any | Heisenberg model |
| [`trotter_transverse_ising_circuit`](@ref) | Simulation | Any | Transverse Ising model |
| [`iqp_circuit`](@ref) | Complexity | Any | IQP circuit |
| [`iqp_random_circuit`](@ref) | Complexity | Any | Random IQP circuit |
| [`fermionic_swap_circuit`](@ref) | Chemistry | Any | Particle-conserving gates |


# Circuit Properties Summary

| Circuit | Depth | Two-Qubit Gates | Connectivity | Classical Simulation |
|:--------|:------|:----------------|:-------------|:---------------------|
| `ghz_circuit(n)` | O(1) | n-1 | Star | Easy (stabilizer) |
| `wstate_circuit(n)` | O(n) | 2(n-1) | Linear | Easy (few excitations) |
| `qft_circuit(n)` | O(n²) | O(n²) | All-to-all | Hard |
| `variational_ansatz` | O(layers) | O(n·layers) | Configurable | Hard |
| `qv_circuit(n)` | O(n) | O(n²) | Random pairs | Hard |
| `bricklayer_circuit` | O(layers) | O(n·layers) | 1D NN | Moderate (MPS) |
| `grid_circuit` | O(layers) | O(n·layers) | 2D NN | Hard |
| `random_clifford_circuit` | O(gates) | O(gates) | Random | Easy (stabilizer) |
| `trotter_*_circuit` | O(steps) | O(n·steps) | 1D NN | Moderate |
| `iqp_circuit` | O(1) | O(edges) | Graph | Hard (sampling) |
"""
module BenchmarkCircuits

using MimiqCircuitsBase
using Random
using StatsBase

export random_circuit
export random_clifford_circuit

export ghz_circuit

export qft_circuit

export variational_ansatz

export qv_circuit

export bricklayer_circuit
export grid_circuit

export qaoa_maxcut_circuit
export qaoa_complete_graph
export qaoa_random_graph

export trotter_heisenberg_circuit
export trotter_transverse_ising_circuit

export grover_circuit

export wstate_circuit

export swap_network_circuit

export tree_circuit

export graph_state_circuit
export graph_state_complete
export graph_state_linear
export graph_state_ring
export graph_state_star

export qpe_circuit

export iqp_circuit
export iqp_random_circuit

export fermionic_swap_circuit

# Include split files
include("circuits/bricklayer.jl")
include("circuits/ghz.jl")
include("circuits/graphstate.jl")
include("circuits/grid2d.jl")
include("circuits/grover.jl")
include("circuits/iqp.jl")
include("circuits/qaoa.jl")
include("circuits/qft.jl")
include("circuits/qpe.jl")
include("circuits/qv.jl")
include("circuits/random.jl")
include("circuits/swaps.jl")
include("circuits/tree.jl")
include("circuits/trotter.jl")
include("circuits/vqe.jl")
include("circuits/wstate.jl")

end # module BenchmarkCircuits
