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

# src/decomposition/rules/flatten.jl

"""
    FlattenContainers <: RewriteRule

A rewrite rule that flattens container operations (`GateCall`, `Block`, and their
inverses) into their constituent instructions, without performing any gate-level
decomposition.

This is useful for:
- Expanding user-defined gates while preserving primitive gate structure
- Preparing circuits for analysis or visualization at a specific abstraction level
- Step-by-step expansion of nested circuit structures

# Examples
```julia
# Flatten one level of containers
flat = decompose_step(circuit; rule=FlattenContainers())

# Recursively flatten all containers (but keep gates intact)
fully_flat = decompose(circuit; basis=FlattenedBasis())
```

See also [`CanonicalRewrite`](@ref), [`GateCall`](@ref), [`Block`](@ref).
"""
struct FlattenContainers <: RewriteRule end

# Only match container types
matches(::FlattenContainers, ::GateCall) = true
matches(::FlattenContainers, ::Block) = true
matches(::FlattenContainers, ::Inverse{N,<:GateCall}) where {N} = true
matches(::FlattenContainers, ::Inverse{N,<:Block}) where {N} = true
matches(::FlattenContainers, ::Operation) = false

# Delegate to CanonicalRewrite to expand blocks
function decompose_step!(builder, ::FlattenContainers, cl::GateCall, qtargets, ctargets, ztargets)
    return decompose_step!(builder, CanonicalRewrite(), cl, qtargets, ctargets, ztargets)
end

function decompose_step!(builder, ::FlattenContainers, b::Block, qtargets, ctargets, ztargets)
    return decompose_step!(builder, CanonicalRewrite(), b, qtargets, ctargets, ztargets)
end

function decompose_step!(builder, ::FlattenContainers, inv::Inverse{N,<:GateCall}, qtargets, ctargets, ztargets) where {N}
    return decompose_step!(builder, CanonicalRewrite(), inv, qtargets, ctargets, ztargets)
end

function decompose_step!(builder, ::FlattenContainers, inv::Inverse{N,<:Block}, qtargets, ctargets, ztargets) where {N}
    return decompose_step!(builder, CanonicalRewrite(), inv, qtargets, ctargets, ztargets)
end
