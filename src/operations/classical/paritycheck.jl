#
# Copyright © 2025-2025 QPerfect. All Rights Reserved.
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

@doc raw"""
    ParityCheck(N=3)

Deprecated alias of [`Xor`](@ref).

`ParityCheck(N)` returns `Xor(N)`, which computes the same parity of `N-1`
classical bits into the first bit, and emits a deprecation warning. No
operation is ever of type `ParityCheck`.

## Examples

```jldoctest
julia> ParityCheck(5)
c[?1] = c[?2] ⊻ c[?3] ⊻ c[?4] ⊻ c[?5]

```
"""
struct ParityCheck{N} <: AbstractClassical{N}
    function ParityCheck(N::Integer)
        Base.depwarn("`ParityCheck` is deprecated, use `Xor` instead.", :ParityCheck)
        return Xor(N)
    end
end

ParityCheck() = ParityCheck(3)
