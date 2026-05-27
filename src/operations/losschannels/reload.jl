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

@doc raw"""
    QubitReload()

Reloads a previously lost qubit.

At the point where `QubitReload` is applied, the qubit is reset to `|0⟩`.
Subsequent quantum operations on that qubit are enabled again.

See also [`LossErr`](@ref), [`Reset`](@ref).

## Examples
```jldoctests
julia> c = push!(Circuit(), QubitReload(), 1)
1-qubit circuit with 1 instruction:
└── QubitReload @ q[1]
```
"""
struct QubitReload <: Operation{1,0,0} end

opname(::Type{<:QubitReload}) = "QubitReload"

function Base.show(io::IO, op::QubitReload)
    print(io, opname(op))
end

function Base.show(io::IO, ::MIME"text/plain", op::QubitReload)
    print(io, opname(op))
end

inverse(::QubitReload) = error("QubitReload is not invertible")
