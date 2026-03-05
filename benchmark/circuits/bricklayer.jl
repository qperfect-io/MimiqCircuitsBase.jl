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

# ================================================= #
# BRICK-LAYER CIRCUITS (Alternating even/odd bonds) #
# ================================================= #
"""
    bricklayer_circuit(n_qubits, n_layers; rng=Random.GLOBAL_RNG)

Brick-layer structure common in tensor network simulations and 
hardware-efficient ansätze. Alternates between even and odd qubit pairs.

```text
Structure (4 qubits, 2 layers):
    ┌───┐   ┌───┐
    ┤ R ├─■─┤ R ├───
    └───┘ │ └───┘   
    ┌───┐ │ ┌───┐   
    ┤ R ├─■─┤ R ├─■─
    └───┘   └───┘ │ 
    ┌───┐   ┌───┐ │ 
    ┤ R ├─■─┤ R ├─■─
    └───┘ │ └───┘   
    ┌───┐ │ ┌───┐   
    ┤ R ├─■─┤ R ├───
    └───┘   └───┘   
     even    odd
```

It has a regular, predictable pattern optimal for 1D chains.
"""
function bricklayer_circuit(n_qubits::Int, n_layers::Int; rng=Random.GLOBAL_RNG)
    c = Circuit()

    for layer in 1:n_layers
        # Single-qubit rotations
        for q in 1:n_qubits
            push!(c, GateRY(rand(rng) * 2π), q)
            push!(c, GateRZ(rand(rng) * 2π), q)
        end

        # Even bonds: (1,2), (3,4), (5,6), ...
        for q in 1:2:(n_qubits-1)
            push!(c, GateCX(), q, q + 1)
        end

        # Odd bonds: (2,3), (4,5), (6,7), ...
        for q in 2:2:(n_qubits-1)
            push!(c, GateCX(), q, q + 1)
        end
    end

    return c
end

