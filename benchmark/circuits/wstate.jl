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

# =================== #
# W-STATE PREPARATION #
# =================== #

@doc raw"""
    wstate_circuit(n_qubits)

Prepare the W state: 

```math
\ket{W_n} = \frac{1}{\sqrt{n}}\left(\ket{100...0} + \ket{010...0} + ... + \ket{000...1}\right)
```

Uses a cascade of controlled rotations.

Key features: Different entanglement structure than GHZ, involves controlled rotations with varying angles.
"""
function wstate_circuit(n_qubits::Int)
    c = Circuit()
    
    # Start with |100...0⟩
    push!(c, GateX(), 1)
    
    # Cascade: distribute the excitation
    for k in 1:(n_qubits-1)
        # Rotation angle to split amplitude correctly
        # After k-1 steps, amplitude is 1/√k on qubit k
        # Need to split to 1/√(k+1) on k and k+1
        θ = 2 * acos(sqrt(k / (k + 1)))
        
        # Controlled rotation: if qubit k is |1⟩, rotate to share with k+1
        push!(c, GateCRY(θ), k, k+1)
        
        # CNOT to flip the control qubit appropriately  
        push!(c, GateCX(), k+1, k)
    end
    
    return c
end