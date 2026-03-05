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
    struct Xor{N} <: AbstractClassical{N}

Computes the bitwise XOR of N-1 classical bits and stores the result in the first given bit.

## Examples

```jldoctests
julia> Xor()
c[?1] = c[?2] ⊻ c[?3]

julia> push!(Circuit(), Xor(),1, 3, 4)
4-bit circuit with 1 instruction:
└── c[1] = c[3] ⊻ c[4]

julia> push!(Circuit(), Xor(5), 1, 3, 5, 8, 13)
13-bit circuit with 1 instruction:
└── c[1] = c[3] ⊻ c[5] ⊻ c[8] ⊻ c[13]

julia> push!(Circuit(), Xor(8), 1, 2, 3, 4, 5, 6, 7, 8)
8-bit circuit with 1 instruction:
└── c[1] = ⊻ @ c[2, 3, 4, 5, 6, 7, 8]

```
"""
struct Xor{N} <: AbstractClassical{N}
    function Xor(N)
        if N < 3
            throw(ArgumentError("Xor operation requires at least 3 classical bits."))
        end
        new{N}()
    end
end

Xor() = Xor(3)

opname(::Type{<:Xor}) = "⊻"

inverse(::Xor) = error("Inverse not defined for Xor.")

function Base.show(io::IO, ::MIME"text/plain", g::Instruction{0,N,0,<:Xor{N}}) where {N}
    compact = get(io, :compact, false)
    creg = getbits(g)
    if compact || N > 6
        space = compact ? "" : " "
        print(io, "c[$(creg[1])] = ⊻ @ c[", join(creg[2:N], ",$space"), "]")
    else
        print(io, "c[$(creg[1])] = ")
        join(io, map(z -> "c[$z]", creg[2:end]), " ⊻ ")
    end
    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", g::Xor{N}) where {N}
    compact = get(io, :compact, false)
    if compact || N > 6
        print(io, "c[?1] = ⊻ @ c[?2:?N]")
    else
        print(io, "c[?1] = ")
        join(io, map(z -> "c[?$z]", 2:N), " ⊻ ")
    end
    return nothing
end
