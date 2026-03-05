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

# ======================= #
# QUANTUM-VOLUME CIRCUIT  #
# ======================= #

"""
    qv_circuit(n; depth::Int=n, rng=Random.GLOBAL_RNG)

Quantum Volume circuit following IBM's Quantum Volume protocol.

Each layer applies random ``SU(4)`` unitaries to random qubit pairs.
Standard QV uses `depth = n`` (square circuit).

# Arguments
- `n::Int`: Number of qubits (also width)
- `depth::Int=n`: Circuit depth (number of layers)
- `rng::AbstractRNG`: Random number generator
"""
function qv_circuit(n::Int; depth::Int=n, rng::AbstractRNG=Random.GLOBAL_RNG)
    n > 0 || throw(ArgumentError("n must be positive"))
    depth > 0 || throw(ArgumentError("depth must be positive"))

    c = Circuit()

    for _ in 1:depth
        perm = randperm(rng, n)

        for i in 1:2:(n-1)
            q1, q2 = perm[i], perm[i+1]
            _add_random_su4!(c, q1, q2, rng)
        end

        # Odd qubit gets random single-qubit gate
        if isodd(n)
            _add_random_u!(c, perm[n], rng)
        end
    end

    return c
end

# Random SU(4)
function _add_random_su4!(c, q1, q2, rng)
    _add_random_u!(c, q1, rng)
    _add_random_u!(c, q2, rng)
    push!(c, GateCX(), q1, q2)
    _add_random_u!(c, q1, rng)
    _add_random_u!(c, q2, rng)
    push!(c, GateCX(), q1, q2)
    _add_random_u!(c, q1, rng)
    _add_random_u!(c, q2, rng)
end

# Random SU(2)
function _add_random_u!(c, q, rng)
    θ = acos(1 - 2 * rand(rng))
    ϕ = 2π * rand(rng)
    λ = 2π * rand(rng)
    push!(c, GateU(θ, ϕ, λ), q)
end
