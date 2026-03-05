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

@testset "Circuits equivalence" begin
    # Construct a (C3X)
    c1 = Circuit()
    push!(c1, Control(3, GateX()), 1:4...)
    @test numqubits(c1) == 4
    @test length(c1) == 1

    c2 = Circuit()

    # First partial control (1,2 => 5)
    push!(c2, Control(2, GateX()), 1, 2, 5)
    push!(c2, Control(2, GateX()), 5, 3, 4)

    # Uncompute ancilla
    push!(c2, Control(2, GateX()), 1, 2, 5)

    @test numqubits(c2) == 5
    @test length(c2) == 3

    # Build the experiment
    ex = CircuitTesterExperiment(c1, c2)
    tester = build_circuit(ex)

    @test numqubits(tester) == 10

    results_perfect = QCSResults("sim", "1.0", [1.0], [0.0], [bs"0000000000", bs"0000000000"], ComplexF64[], Dict{BitString,ComplexF64}(), Dict{String,Float64}())
    @test interpret_results(ex, results_perfect) ≈ 1.0

    results_bad = QCSResults("sim", "1.0", [0.0], [0.0], [bs"0000000000", bs"1111111111"], ComplexF64[], Dict{BitString,ComplexF64}(), Dict{String,Float64}())
    @test interpret_results(ex, results_bad) ≈ 0.5
end

@testset "Circuit tester using amplitudes" begin
    # Construct identical circuits
    c1 = Circuit()
    push!(c1, GateX(), 1)

    c2 = Circuit()
    push!(c2, GateX(), 1)

    # Test constructor
    ex = CircuitTesterExperiment(c1, c2; method="amplitudes")
    @test ex.method == "amplitudes"

    # Test build_circuit
    tester = build_circuit(ex)
    
    # Verify it has Amplitude instruction
    has_amplitude = false
    for instr in tester
        if getoperation(instr) isa Amplitude
            has_amplitude = true
            break
        end
    end
    @test has_amplitude

    # Test interpret_results
    # Perfect equivalence: each sample has prob |1.0|^2 = 1.0
    zstates_perf = [[1.0 + 0.0im], [1.0 + 0.0im]]
    results_perf = QCSResults("sim", "1.0", Float64[], Float64[], BitString[], zstates_perf, Dict{BitString,ComplexF64}(), Dict{String,Float64}())
    @test interpret_results(ex, results_perf) ≈ 1.0

    # Phase equivalence: each sample has prob |1.0im|^2 = 1.0
    zstates_phase = [[0.0 + 1.0im]]
    results_phase = QCSResults("sim", "1.0", Float64[], Float64[], BitString[], zstates_phase, Dict{BitString,ComplexF64}(), Dict{String,Float64}())
    @test interpret_results(ex, results_phase) ≈ 1.0

    # Imperfect equivalence: amp = 1/sqrt(2) -> prob = 0.5
    val = 1.0/sqrt(2.0)
    zstates_bad = [[Complex(val, 0.0)]]
    results_bad = QCSResults("sim", "1.0", Float64[], Float64[], BitString[], zstates_bad, Dict{BitString,ComplexF64}(), Dict{String,Float64}())
    @test interpret_results(ex, results_bad) ≈ 0.5

    # Empty results
    zstates_empty = Vector{Vector{ComplexF64}}()
    results_empty = QCSResults("sim", "1.0", Float64[], Float64[], BitString[], zstates_empty, Dict{BitString,ComplexF64}(), Dict{String,Float64}())
    @test interpret_results(ex, results_empty) ≈ 0.0
end
