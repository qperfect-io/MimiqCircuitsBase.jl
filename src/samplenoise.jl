#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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

"""
    sample_mixedunitaries(c; rng, ids=false)

Samples one unitary gate for each mixed unitary Kraus channel in the circuit.

This is possible because for mixed unitary noise channels the
probabilities of each Kraus operator are fixed (state-independent).

Note: This function is internally called (before applying any gate) when
executing a circuit with noise using trajectories, but it can also be used to
generate samples of circuits without running them.

See also [`ismixedunitary`](@ref), [`MixedUnitary`](@ref), [`probabilities`](@ref),
and [`unitarygates`](@ref).

## Arguments

* `c`: Circuit to be sampled.
* `rng`: (optional) Random number generator.
* `ids`: (optional) Boolean, default=`false`. When the selected Kraus operator is an
  identity it has no effect on the circuit. The parameter `ids` decides
  whether to add it to the circuit (`ids=true``) or not (`ids=false`; default).
  Usually, most of the Kraus operators selected will be identity gates.

## Returns

A copy of circuit but with every mixed unitary Kraus channel replaced by one of the
unitary gates of the channel (or nothing if identity and `ids==false`).

## Examples

Gates and non-mixed-unitary Kraus channels remain unchanged.

```jldoctests sample
julia> using Random

julia> c = push!(Circuit(), GateH(), 1:3);

julia> push!(c, Depolarizing1(0.5), 1:3);

julia> push!(c, AmplitudeDamping(0.5), 1:3)
3-qubit circuit with 9 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── Depolarizing(1,0.5) @ q[1]
├── Depolarizing(1,0.5) @ q[2]
├── Depolarizing(1,0.5) @ q[3]
├── AmplitudeDamping(0.5) @ q[1]
├── AmplitudeDamping(0.5) @ q[2]
└── AmplitudeDamping(0.5) @ q[3]

julia> rng = MersenneTwister(42);

julia> sample_mixedunitaries(c; rng=rng, ids=true)
3-qubit circuit with 9 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── Y @ q[1]
├── ID @ q[2]
├── ID @ q[3]
├── AmplitudeDamping(0.5) @ q[1]
├── AmplitudeDamping(0.5) @ q[2]
└── AmplitudeDamping(0.5) @ q[3]
```

By default identities are not included.

```jldoctests sample
julia> rng = MersenneTwister(42);

julia> sample_mixedunitaries(c; rng=rng)
3-qubit circuit with 7 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── Y @ q[1]
├── AmplitudeDamping(0.5) @ q[1]
├── AmplitudeDamping(0.5) @ q[2]
└── AmplitudeDamping(0.5) @ q[3]
```

Different calls to the function generate different results.

```jldoctests sample
julia> sample_mixedunitaries(c; rng=rng)
3-qubit circuit with 6 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── AmplitudeDamping(0.5) @ q[1]
├── AmplitudeDamping(0.5) @ q[2]
└── AmplitudeDamping(0.5) @ q[3]

julia> sample_mixedunitaries(c; rng=rng)
3-qubit circuit with 6 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── AmplitudeDamping(0.5) @ q[1]
├── AmplitudeDamping(0.5) @ q[2]
└── AmplitudeDamping(0.5) @ q[3]
```
"""
function sample_mixedunitaries(c::Circuit; rng=Random.GLOBAL_RNG, ids=false)
    scirc = Circuit()

    for inst in c
        op = getoperation(inst)
        if op isa AbstractKrausChannel && ismixedunitary(typeof(op))
            #cumulative_probs = cumsum(probabilities(op))
            cumulative_probs = unwrappedcumprobabilities(op)    # PERF: good if cached

            # Sample
            r = rand(rng)
            index = searchsortedfirst(cumulative_probs, r)

            # Substitute noise by instance
            gate = unitarygates(op)[index]
            if ids || !isidentity(gate)
                push!(scirc, unitarygates(op)[index], getqubits(inst)...)
            end
        else
            push!(scirc, inst)
        end
    end

    return scirc
end

