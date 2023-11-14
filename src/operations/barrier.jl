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
└── Barrier @ q1

julia> push!(c, Barrier, 1,2,3)
3-qubit circuit with 2 instructions:
├── Barrier @ q1
└── Barrier @ q1, q2, q3

julia> push!(c, Barrier(3), 1,2,3)
3-qubit circuit with 3 instructions:
├── Barrier @ q1
├── Barrier @ q1, q2, q3
└── Barrier @ q1, q2, q3
```
"""
struct Barrier{N} <: Operation{N,0}
    function Barrier(numqubits::Integer)
        new{numqubits}()
    end
end

Barrier() = (targets...) -> Instruction(Barrier(length(targets)), targets, ())

opname(::Type{<:Barrier}) = "Barrier"

# barriers are no-ops, so
# barriers are their own inverse
inverse(::Barrier{N}) where {N} = Barrier{N}()

# barriers are no-ops, so
# power doesn't do anything
_power(::Barrier{N}, _) where {N} = Barrier{N}()

isunitary(::Type{<:Barrier}) = true

# Convenience functions for adding a Barrier.
function Instruction(::Type{Barrier}, targets...)
    N = length(targets)
    Instruction(Barrier(N), targets, ())
end

Base.insert!(c::Circuit, i::Integer, ::Type{Barrier}, args...) = insert!(c, i, Barrier(length(args)), args...)

Base.push!(c::Circuit, ::Type{Barrier}, args...) = push!(c, Barrier(length(args)), args...)

