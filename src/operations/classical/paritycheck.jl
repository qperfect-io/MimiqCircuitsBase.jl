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
    struct ParityCheck{N} <: AbstractClassical{N}

Performs a parity check on N-1 classical bits and stores the result in the first bit.

It performs sum modulo 2 of the inputs.

## Examples

```jldoctests
julia> ParityCheck(5)
⨊

julia> push!(Circuit(), ParityCheck(5), 1, 3, 5, 8, 13)
13-bit circuit with 1 instruction:
└── c[1] = ⨊ c[3, 5, 8, 13]

```
"""
struct ParityCheck{N} <: AbstractClassical{N}
    function ParityCheck(N::Integer)
        if N < 3
            throw(ArgumentError("ParityCheck must act on at least 3 classical bits"))
        end
        new{N}()
    end
end

ParityCheck() = ParityCheck(3)

opname(::Type{<:ParityCheck}) = "⨊"

inverse(::ParityCheck) = error("Inverse not defined for ParityCheck.")

function Base.show(io::IO, ::MIME"text/plain", inst::Instruction{0,N,0,<:ParityCheck{N}}) where {N}
    bits = getbits(inst)
    space = get(io, :compact, false) ? "" : " "
    print(io, "c[", bits[1], "] = ⨊ c[", join(bits[2:end], ",$space"), "]")
end
