#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
    Barrier(numqubits)

No-op operation that does not affect the quantum state or the execution of
a circuit, but prevents compression or optimization across it.

## Examples

```jldoctests
julia> Barrier(1)
Barrier

julia> Barrier(2)
Barrier

julia> c = push!(Circuit(), Barrier(1), 1)
1-qubit circuit with 1 instructions:
└── Barrier @ q[1]

julia> push!(c, Barrier(1), 1:3)
3-qubit circuit with 4 instructions:
├── Barrier @ q[1]
├── Barrier @ q[1]
├── Barrier @ q[2]
└── Barrier @ q[3]

julia> push!(c, Barrier(3), 1,2,3)
3-qubit circuit with 5 instructions:
├── Barrier @ q[1]
├── Barrier @ q[1]
├── Barrier @ q[2]
├── Barrier @ q[3]
└── Barrier @ q[1:3]
```
"""
struct Barrier{N} <: Operation{N,0,0}
    function Barrier(numqubits::Integer)
        new{numqubits}()
    end
end

Barrier() = LazyExpr(Barrier, LazyArg())

opname(::Type{<:Barrier}) = "Barrier"

qregsizes(::Barrier{N}) where {N} = (N,)

# barriers are no-ops, so
# barriers are their own inverse
inverse(::Barrier{N}) where {N} = Barrier{N}()

# barriers are no-ops, so
# power doesn't do anything
_power(::Barrier{N}, _) where {N} = Barrier{N}()

isunitary(::Type{<:Barrier}) = true

