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

# ======================================== #
# TROTTER CIRCUIT (Hamiltonian simulation) #
# ======================================== #

@doc raw"""
    trotter_heisenberg_circuit(n_qubits, n_steps, dt; periodic=false)

First-order Trotter decomposition for 1D Heisenberg model:

```math
H = \sum_i \left(X_i X_{i+1} + Y_i Y_{i+1} + Z_i Z_{i+1}\right)
```

Each Trotter step applies:

```math
    \mathrm{e}^{-\im dt XX} \mathrm{e}^{-\im dt YY} \mathrm{e}^{-\im dt ZZ}
```

for each bond.

Key features: Physically motivated, specific two-qubit gate pattern (RXX, RYY, RZZ).
"""
function trotter_heisenberg_circuit(n_qubits::Int, n_steps::Int, dt::Real; 
                                    periodic::Bool=false)
    c = Circuit()
    
    # Determine bonds
    bonds = collect(1:(n_qubits-1))
    if periodic && n_qubits > 2
        push!(bonds, n_qubits)  # Bond from n to 1
    end
    
    for step in 1:n_steps
        for i in bonds
            j = i < n_qubits ? i + 1 : 1  # Handle periodic
            
            # exp(-i dt XX): RXX(2*dt)
            push!(c, GateRXX(2dt), i, j)
            
            # exp(-i dt YY): RYY(2*dt)
            push!(c, GateRYY(2dt), i, j)
            
            # exp(-i dt ZZ): RZZ(2*dt)
            push!(c, GateRZZ(2dt), i, j)
        end
    end
    
    return c
end

@doc raw"""
    trotter_transverse_ising_circuit(n_qubits, n_steps, J, h, dt)

First-order Trotter decomposition for the one-dimensional, nearest-neighbor transverse-field Ising model:

```math
H = -J \sum_i Z_i Z_{i+1} - h \sum_i X_i
```

Each Trotter step applies:

```math
\mathrm{e}^{-\im dt ZZ}
```

for nearest-neighbor qubits.

Key features: Physically motivated, specific two-qubit gate pattern (RZZ).
"""
function trotter_transverse_ising_circuit(n_qubits::Int, n_steps::Int, 
                                          J::Real, h::Real, dt::Real)
    c = Circuit()
    
    for step in 1:n_steps
        # ZZ interactions: exp(i J dt Z_i Z_{i+1})
        for i in 1:(n_qubits-1)
            push!(c, GateRZZ(-2J * dt), i, i+1)
        end
        
        # Transverse field: exp(i h dt X_i)
        for i in 1:n_qubits
            push!(c, GateRX(-2h * dt), i)
        end
    end
    
    return c
end
