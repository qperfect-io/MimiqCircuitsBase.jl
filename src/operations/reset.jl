#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    Reset()

Quantum operation that resets the status of one qubit to the ``\ket{0}``
state.

See also [`Operation`](@ref), [`Measure`](@ref).

## Examples

```jldoctests
julia> Reset()
Reset

julia> c = push!(Circuit(), Reset, 1)
1-qubit circuit with 1 instructions:
└── Reset @ q[1]

julia> push!(c, Reset(), 3)
3-qubit circuit with 2 instructions:
├── Reset @ q[1]
└── Reset @ q[3]
```
"""
struct Reset <: Operation{1,0} end

inverse(::Reset) = error("Cannot invert Reset operations")

opname(::Type{<:Reset}) = "Reset"

function Base.show(io::IO, ::Reset)
    print(io, opname(Reset))
end

