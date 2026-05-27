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
    CheckLoss()

Reports whether a qubit is lost or present.

- Output bit = 1 → qubit is present
- Output bit = 0 → qubit is lost

This operation does *not* measure or collapse the quantum state.
It only queries the simulator’s internal “lost qubit” status.

See also: [`LossErr`](@ref), [`QubitReload`](@ref).

## Examples

```jldoctests
julia> c = push!(Circuit(), CheckLoss(), 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── CL @ q[1], c[1]
```
"""
struct CheckLoss <: Operation{1,1,0} end

opname(::Type{<:CheckLoss}) = "CL"

function Base.show(io::IO, ::CheckLoss)
    print(io, opname(CheckLoss))
end

inverse(::CheckLoss) = error("CheckLoss is not invertible")

function Base.show(io::IO, ::MIME"text/plain", ::CheckLoss)
    print(io, opname(CheckLoss))
end
