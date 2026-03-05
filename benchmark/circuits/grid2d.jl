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

# ================================================ #
# 2D GRID CIRCUITS (Superconducting chip topology) #
# ================================================ #
"""
    grid_circuit(rows, cols, n_layers; rng=Random.GLOBAL_RNG)

2D grid topology mimicking superconducting quantum processors with nearest-neighbor connectivity
(Google Sycamore, IBM Heavy-Hex, etc.).

```text
Qubits numbered row-major:
    1 - 2 - 3
    |   |   |
    4 - 5 - 6
    |   |   |
    7 - 8 - 9
```

Each layer applies gates to all horizontal then all vertical edges.
"""
function grid_circuit(rows::Int, cols::Int, n_layers::Int; rng=Random.GLOBAL_RNG)
    c = Circuit()
    n_qubits = rows * cols

    # Helper: (row, col) -> qubit index (1-based)
    idx(r, c) = (r - 1) * cols + c

    for layer in 1:n_layers
        # Single-qubit layer
        for q in 1:n_qubits
            push!(c, GateSX(), q)
            push!(c, GateRZ(rand(rng) * 2π), q)
        end

        # Horizontal edges (within rows)
        for r in 1:rows
            for col in 1:(cols-1)
                # Alternate between CZ and fSim-like gates
                if (r + col + layer) % 2 == 0
                    push!(c, GateCZ(), idx(r, col), idx(r, col + 1))
                else
                    push!(c, GateISWAP(), idx(r, col), idx(r, col + 1))
                end
            end
        end

        # Vertical edges (within columns)
        for r in 1:(rows-1)
            for col in 1:cols
                if (r + col + layer) % 2 == 0
                    push!(c, GateCZ(), idx(r, col), idx(r + 1, col))
                else
                    push!(c, GateISWAP(), idx(r, col), idx(r + 1, col))
                end
            end
        end
    end

    return c
end
