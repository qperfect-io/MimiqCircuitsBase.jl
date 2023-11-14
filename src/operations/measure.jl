#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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
    Measure()

Single qubit measurement operation in the computational basis

The operation projects the quantum states and stores the result of such
measurement is stored in a classical register.

!!! warn
    `Measure` is non-reversible.

See also [`Operation`](@ref), [`Reset`](@ref).

## Examples

```jldoctests
julia> Measure()
Measure

julia> c = push!(Circuit(), Measure, 1, 1)
1-qubit circuit with 1 instructions:
└── Measure @ q1, c1

julia> push!(c, Measure(), 3, 4)
3-qubit circuit with 2 instructions:
├── Measure @ q1, c1
└── Measure @ q3, c4
```
"""
struct Measure <: Operation{1,1} end

opname(::Type{<:Measure}) = "Measure"

inverse(::Measure) = error("Cannot invert measurements")

function Base.show(io::IO, ::Measure)
    print(io, opname(Measure))
end

