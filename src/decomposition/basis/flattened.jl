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

"""
    FlattenedBasis <: DecompositionBasis

A basis that flattens all container operations (`GateCall`, `Block`, etc.)
into their constituent instructions, while leaving all other operations
(including all gates) untouched.

This is useful for analyzing the "flat" structure of a circuit without
decomposing gates into a specific basis.

# Examples
```julia
# Expand all nested blocks/calls
flat_circuit = decompose(circuit; basis=FlattenedBasis())
```

See also [`FlattenContainers`](@ref).
"""
struct FlattenedBasis <: DecompositionBasis end

# Terminal for non-container operations
isterminal(::FlattenedBasis, ::GateCall) = false
isterminal(::FlattenedBasis, ::Block) = false
isterminal(::FlattenedBasis, ::Inverse{N,<:GateCall}) where {N} = false
isterminal(::FlattenedBasis, ::Inverse{N,<:Block}) where {N} = false

isterminal(::FlattenedBasis, ::Operation) = true

function decompose!(builder, ::FlattenedBasis, op::Operation, qtargets, ctargets, ztargets)
    if matches(FlattenContainers(), op)
        return decompose_step!(builder, FlattenContainers(), op, qtargets, ctargets, ztargets)
    end
    throw(DecompositionError("Operation $(opname(op)) matches FlattenedBasis but cannot be decomposed."))
end
