#!/usr/bin/env julia

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

using Pkg
Pkg.activate(joinpath(@__DIR__))

using MimiqCircuitsBase

include("circuits.jl")
using .BenchmarkCircuits

using Random

function main()
    ns = 2 .^ (1:7)
    nns = 2 .^ (1:3)

    for n in ns
        name = "bricklayer_$(n)x$(n).pb"
        println("Generating $name")
        circuit = bricklayer_circuit(n, n; rng=MersenneTwister(n))
        saveproto(name, circuit)
    end

    for n in ns
        name = "fermionic_swap_$(n)x$(n).pb"
        println("Generating $name")
        circuit = fermionic_swap_circuit(n, n; rng=MersenneTwister(n))
        saveproto(name, circuit)
    end

    for n in ns
        name = "ghz_$(n).pb"
        println("Generating $name")
        circuit = ghz_circuit(n)
        saveproto(name, circuit)
    end

    for n in ns
        name = "qv_$(n).pb"
        println("Generating $name")
        circuit = qv_circuit(n; rng=MersenneTwister(n))
        saveproto(name, circuit)
    end

    for n in ns
        name = "random_clifford_toffoli_$(n)x$(n).pb"
        println("Generating $name")
        gate_filter(gate) = gate isa GateX || gate isa GateH || gate isa GateCCX || gate isa GateS || gate isa GateSDG || gate isa GateZ || gate isa GateCX
        circuit = random_circuit(n, n; rng = MersenneTwister(n), gate_filter=gate_filter)
        saveproto(name, circuit)
    end

    for n in ns
        name = "variational_ansatz_$(n)x$(n).pb"
        println("Generating $name")
        circuit = variational_ansatz(n, n; rng=MersenneTwister(n))
        saveproto(name, circuit)
    end

    for n in nns
        name = "grid_circuit_$(n)x$(n)x$(n).pb"
        println("Generating $name")
        circuit = grid_circuit(n, n, n; rng=MersenneTwister(n))
        saveproto(name, circuit)
    end

    return nothing
end

main()
