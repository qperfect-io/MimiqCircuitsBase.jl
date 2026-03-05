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

# ======================================= #
# GROVER'S ALGORITHM (Oracle + Diffusion) #
# ======================================= #

@doc raw"""
    grover_circuit(n_qubits, n_iterations, marked_state::BitString)

Grover's search algorithm circuit.

Structure:

```math
    H^{\otimes n} \rightarrow \left[Oracle \cdot Diffusion\right]^k
```

Key features: Multi-controlled gates (oracle), reflection structure.
"""
function grover_circuit(n_qubits::Int, n_iterations::Int, marked_state::BitString)
    c = Circuit()

    # Initial superposition
    push!(c, GateH(), 1:n_qubits)

    for iter in 1:n_iterations
        # Oracle: flip phase of |marked_state⟩
        # Implement as controlled-Z with controls based on bit pattern
        _add_oracle!(c, n_qubits, marked_state)

        # Diffusion operator: 2|s⟩⟨s| - I where |s⟩ = H^⊗n|0⟩
        # = H^⊗n (2|0⟩⟨0| - I) H^⊗n
        push!(c, GateH(), 1:n_qubits)
        push!(c, GateX(), 1:n_qubits)

        # Multi-controlled Z (flip |11...1⟩)
        push!(c, control(n_qubits - 1, GateZ()), (1:n_qubits)...)

        push!(c, GateX(), 1:n_qubits)
        push!(c, GateH(), 1:n_qubits)
    end

    return c
end

function _add_oracle!(c::Circuit, n_qubits::Int, marked::BitString)
    # Flip qubits where marked_state has 0
    for q in 1:n_qubits
        if marked[q] == 0
            push!(c, GateX(), q)
        end
    end

    # Multi-controlled Z
    push!(c, control(n_qubits - 1, GateZ()), (1:n_qubits)...)

    # Unflip
    for q in 1:n_qubits
        if marked[q] == 0
            push!(c, GateX(), q)
        end
    end
end
