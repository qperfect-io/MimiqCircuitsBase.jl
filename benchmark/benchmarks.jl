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

# MimiqCircuitsBase.jl Benchmark Suite
# ====================================
#
# This file defines the SUITE variable required by PkgBenchmark.
#
# Run with:
#     using PkgBenchmark
#     results = benchmarkpkg("MimiqCircuitsBase")
#     export_markdown("benchmark_results.md", results)
#
# Or directly:
#     julia --project=benchmark benchmark/run_benchmarks.jl

using BenchmarkTools
using MimiqCircuitsBase
using Random
using LinearAlgebra
using Graphs

const HAS_SYMBOLICS = true

# ===== #
# Setup #
# ===== #

const SUITE = BenchmarkGroup()

# Fixed seed for reproducibility
const RNG = MersenneTwister(42)

# Create symbolic variables
@variables θ ϕ λ γ

# ================ #
# Helper Functions #
# ================ #

include("circuits.jl")
using .BenchmarkCircuits

"""
    random_unitary_circuit(n_qubits, depth; rng=RNG)

Alias for `random_circuit` with `measure=false`.
"""
random_unitary_circuit(n, d; kwargs...) = random_circuit(n, d; measure=false, kwargs...)

"""
    symbolic_variational_ansatz(n_qubits, n_layers)

Helper to create a variational ansatz with symbolic parameters (θ, ϕ) reusing them cyclically,
mimicking the behavior of the old benchmark function.
"""
function symbolic_variational_ansatz(n_qubits, n_layers)
    n_rots = n_qubits * 2 * (n_layers + 1) # RY, RZ per qubit per layer + final
    # Alternating θ, ϕ
    params = [isodd(i) ? θ : ϕ for i in 1:n_rots]
    return variational_ansatz(n_qubits, n_layers; parameter_values=params)
end

# Include individual benchmark files
include("benchmarks/construction.jl")
include("benchmarks/iteration.jl")
include("benchmarks/metadata.jl")
include("benchmarks/instruction.jl")
include("benchmarks/matrix.jl")
include("benchmarks/decomposition.jl")
include("benchmarks/transforms.jl")
include("benchmarks/dag.jl")
include("benchmarks/noise.jl")
include("benchmarks/proto.jl")
include("benchmarks/symbolic.jl")
include("benchmarks/bitstring.jl")
include("benchmarks/workflows.jl")
include("benchmarks/allocations.jl")
include("benchmarks/advanced.jl")
include("benchmarks/hamiltonian.jl")
include("benchmarks/comprehensive_decomposition.jl")

# Export the suite
SUITE
