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

# ============================================= #
# TREE TOPOLOGY CIRCUIT (Binary tree structure) #
# ============================================= #
@doc raw"""
    tree_circuit(depth; rng=Random.GLOBAL_RNG)

Binary tree structured circuit.

```
n_qubits = 2^depth - 1 (perfect binary tree)
```
```text
Tree structure (depth=3, 7 qubits):
           1
         /   \
        2     3
       / \   / \
      4   5 6   7
```

Key features: Logarithmic depth for global entanglement, different scaling than linear chains.
"""
function tree_circuit(depth::Int; rng=Random.GLOBAL_RNG)
    n_qubits = 2^depth - 1
    c = Circuit()
    
    # Initial layer
    for q in 1:n_qubits
        push!(c, GateH(), q)
        push!(c, GateRZ(rand(rng) * 2π), q)
    end
    
    # Tree edges: parent i has children 2i and 2i+1
    for level in 1:(depth-1)
        # Nodes at this level
        start_node = 2^(level-1)
        end_node = 2^level - 1
        
        for parent in start_node:end_node
            left_child = 2 * parent
            right_child = 2 * parent + 1
            
            if left_child <= n_qubits
                push!(c, GateCX(), parent, left_child)
                push!(c, GateRY(rand(rng) * 2π), left_child)
            end
            if right_child <= n_qubits
                push!(c, GateCX(), parent, right_child)
                push!(c, GateRY(rand(rng) * 2π), right_child)
            end
        end
    end
    
    # Reverse pass (bottom-up)
    for level in (depth-1):-1:1
        start_node = 2^(level-1)
        end_node = 2^level - 1
        
        for parent in start_node:end_node
            left_child = 2 * parent
            right_child = 2 * parent + 1
            
            if right_child <= n_qubits
                push!(c, GateCZ(), parent, right_child)
            end
            if left_child <= n_qubits
                push!(c, GateCZ(), parent, left_child)
            end
        end
    end
    
    return c
end
