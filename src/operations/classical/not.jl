#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

@doc raw"""
    struct Not <: AbstractClassical{1}

Classical operation that flips a classical bit:
`0 → 1` and `1 → 0`.

Acts only on classical registers and performs a deterministic logical inversion.

## Examples

```jldoctests
julia> Not()
~

julia> push!(Circuit(), Not(),1)
1-bit circuit with 1 instruction:
└── c[1] = ~c[1]
```
"""
struct Not <: AbstractClassical{1} end

opname(::Type{<:Not}) = "~"

inverse(::Not) = Not()

function Base.show(io::IO, ::MIME"text/plain", inst::Instruction{0,1,0,<:Not})
    c = getbit(inst, 1)
    print(io, "c[$c] = ~c[$c]")
end
