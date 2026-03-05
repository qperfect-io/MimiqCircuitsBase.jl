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
    RuleBasis{R<:RewriteRule} <: DecompositionBasis

A decomposition basis that recursively applies a single rewrite rule until no
more matches are found.

This allows any [`RewriteRule`](@ref) to be used directly as a decomposition basis.

# Examples
```julia
# Use a rewrite rule as a basis directly
decompose(circuit; basis=FlattenContainers())

# Or explicitly wrap it (equivalent)
decompose(circuit; basis=RuleBasis(FlattenContainers()))
```
"""
struct RuleBasis{R<:RewriteRule} <: DecompositionBasis
    rule::R
end

# Terminal if rule does not apply
isterminal(basis::RuleBasis, op::Operation) = !matches(basis.rule, op)

function decompose!(builder, basis::RuleBasis, op::Operation, qtargets, ctargets, ztargets)
    return decompose_step!(builder, basis.rule, op, qtargets, ctargets, ztargets)
end
