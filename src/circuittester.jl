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

@doc raw"""
    CircuitTesterExperiment(c1::Circuit, c2::Circuit; method::String="samples")

Represents a circuit equivalence checking experiment.

# Arguments
- `c1::Circuit`: First circuit.
- `c2::Circuit`: Second circuit.
- `method::String`: Verification method. Can be "samples" (default) or "amplitudes".
    - "samples": Measures the final state.
    - "amplitudes": Computes the amplitude of the all-zero state.
"""
struct CircuitTesterExperiment
    c1::Circuit
    c2::Circuit
    method::String

    function CircuitTesterExperiment(c1::Circuit, c2::Circuit; method::String="samples")
        if method ∉ ["samples", "amplitudes"]
            throw(ArgumentError("Method must be one of \"samples\" or \"amplitudes\""))
        end

        return new(c1, c2, method)
    end
end

numqubits(ex::CircuitTesterExperiment) = maximum([numqubits(ex.c1), numqubits(ex.c2)]) * 2

@doc raw"""
    build_circuit(ex::CircuitTesterExperiment)

Constructs the circuit for the circuit tester experiment.
"""
function build_circuit(ex::CircuitTesterExperiment)
    c1 = ex.c1
    c2 = ex.c2

    nqinput = maximum([numqubits(c1), numqubits(c2)])
    size_circuits = nqinput

    c = Circuit()

    if nqinput == 0
        return c
    end

    input = collect(1:nqinput)
    test_ancilla = collect(1:nqinput) .+ size_circuits

    # Prepare Bell state for Choi-Jamiolkowski isomorphism
    bell_circuit = Circuit()
    push!(bell_circuit, GateH(), input)
    push!(bell_circuit, GateCX(), input, test_ancilla)
    append!(c, bell_circuit)

    # Apply channel and inverse channel
    append!(c, c1)
    append!(c, inverse(c2))

    # Uncompute Bell state to map identity to computational basis zero state
    append!(c, inverse(bell_circuit))

    total_qubits = size_circuits + nqinput

    if ex.method == "samples"
        # Measure in computational basis
        push!(c, Measure(), 1:total_qubits, 1:total_qubits)
    elseif ex.method == "amplitudes"
        # Project to target state and store amplitude
        push!(c, Amplitude(BitString("0"^total_qubits)), 1)
    end

    return c
end

"""
    interpret_results(ex::CircuitTesterExperiment, results::QCSResults)

Verifies the results of the circuit tester experiment. Returns the probability of the all-zero state.
"""
function interpret_results(ex::CircuitTesterExperiment, results::QCSResults)
    nqinput = maximum([numqubits(ex.c1), numqubits(ex.c2)])

    if nqinput == 0
        return 1.0
    end

    if ex.method == "amplitudes"
        # Calculate average probability from amplitudes
        if isempty(results.zstates)
            return 0.0
        end

        total_prob = 0.0
        counter = 0

        for zstate in results.zstates
            if !isempty(zstate)
                amp = zstate[1]
                prob = abs(amp)^2
                total_prob += prob
                counter += 1
            end
        end

        if counter == 0
            return 0.0
        end
        return total_prob / counter
    end

    # Equivalence implies probability of |0...0> is 1.0
    total_samples = length(results.cstates)
    if total_samples == 0
        return 0.0
    end

    total_qubits = 2 * nqinput
    target_state = BitString("0"^total_qubits)

    zeros_count = count(bs -> bs == target_state, results.cstates)
    return zeros_count / total_samples
end

function Base.show(io::IO, ex::CircuitTesterExperiment)
    print(io, "CircuitTesterExperiment(...,...,")
    print(io, "method=", ex.method)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", ex::CircuitTesterExperiment)
    println(io, "Choi-isomorphism circuit equivalence test:")

    println(io, "├── a == b",)

    print(io, "│   ├── a: ",)
    _print_instcontainer_header(io, ex.c1)
    println(io)

    print(io, "│   └── b: ",)
    _print_instcontainer_header(io, ex.c2)
    println(io)

    print(io, "└── compare ", ex.method)
end
