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
    QubitLoss()

Marks a qubit as lost (Deterministic Loss).

At the point where `QubitLoss` is applied, the qubit is considered lost.
All **subsequent** quantum operations that touch this qubit are ignored
until a `QubitReload` on the same qubit is encountered.

See also [`QubitReload`](@ref), [`Reset`](@ref).

## Examples

```jldoctests
julia> c = push!(Circuit(), QubitLoss(), 1)
1-qubit circuit with 1 instruction:
└── QubitLoss @ q[1]
```
"""
struct QubitLoss <: Operation{1,0,0} end

opname(::Type{<:QubitLoss}) = "QubitLoss"

function Base.show(io::IO, ::QubitLoss)
    print(io, opname(QubitLoss))
end

function Base.show(io::IO, ::MIME"text/plain", ::QubitLoss)
    print(io, opname(QubitLoss))
end

inverse(::QubitLoss) = error("QubitLoss is not invertible")
