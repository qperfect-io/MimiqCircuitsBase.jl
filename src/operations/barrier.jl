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
    struct Barrier <: Operation{1}

A barrier is a special operation that does not affect the quantum state or the
execution of a circuit, but it prevents compression or optimization operation
from being applied across it.

## Examples

```jldoctest
julia> push!(Circuit(), Barrier(), 1)
1-qubit circuit with 1 instructions:
└── Barrier @ q1

julia> push!(Circuit(), Barrier(4), 1:4...)
4-qubit circuit with 1 instructions:
└── Barrier @ q1, q2, q3, q4

julia> push!(Circuit(), Barrier(), 1:4)
4-qubit circuit with 4 instructions:
├── Barrier @ q1
├── Barrier @ q2
├── Barrier @ q3
└── Barrier @ q4
```
"""
struct Barrier{N} <: Operation{N,0} end

Barrier() = Barrier{1}()

Barrier(obj::Dict{String,<:Any}) = Barrier(obj["N"])
Barrier(obj::Dict{Symbol,<:Any}) = Barrier(obj[:N])

Barrier(N::Integer) = Barrier{N}()

inverse(b::Barrier) = b

opname(::Type{<:Barrier}) = "Barrier"

function Base.show(io::IO, ::Barrier)
    print(io, opname(Barrier))
end

# Convenience functions for adding barriers
# since Barriers depends on the number of targets, here we can automatically
# detect said number and build the proper Barrier operation.
function Instruction(::Type{Barrier}, qtargets::Vararg{Integer,N}; kwargs...) where {N}
    Instruction(Barrier{N}(), qtargets, (); kwargs...)
end

function Base.push!(c::Circuit, ::Type{Barrier}, qtargets::Vararg{Any,N}) where {N}
    push!(c, Barrier(N), qtargets...)
end

function Base.insert!(c::Circuit, i::Integer, ::Type{Barrier}, qts::Vararg{T,N}) where {T<:Integer,N}
    insert!(c, i, Instruction(Barrier{N}(), qts...))
end
