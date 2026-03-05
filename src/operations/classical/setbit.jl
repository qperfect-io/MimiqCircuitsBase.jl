#.
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
    struct SetBit0 <: AbstractClassical{1}

Classical operation that sets a classical bit to 0.
`0 → 0` and `1 → 0`.

## Examples

```jldoctests
julia> SetBit0()
Set0

julia> push!(Circuit(), SetBit0(),1)
1-bit circuit with 1 instruction:
└── c[1] = 0
```
"""
struct SetBit0 <: AbstractClassical{1} end

opname(::Type{<:SetBit0}) = "Set0"

inverse(::SetBit0) = SetBit1()

function Base.show(io::IO, ::MIME"text/plain", inst::Instruction{0,1,0,<:SetBit0})
    c = getbit(inst, 1)
    print(io, "c[$c] = 0")
end

@doc raw"""
    struct SetBit1 <: AbstractClassical{1}

Classical operation that sets a classical bit to 1.
`0 → 1` and `1 → 1`.

## Examples

```jldoctests
julia> SetBit1()
Set1

julia> push!(Circuit(), SetBit1(),1)
1-bit circuit with 1 instruction:
└── c[1] = 1
```
"""
struct SetBit1 <: AbstractClassical{1} end

opname(::Type{<:SetBit1}) = "Set1"

inverse(::SetBit1) = SetBit0()

function Base.show(io::IO, ::MIME"text/plain", inst::Instruction{0,1,0,<:SetBit1})
    c = getbit(inst, 1)
    print(io, "c[$c] = 1")
end
