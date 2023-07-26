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
    struct Measure <: Operation{1}

Single qubit measurement operation in the computational basis

This operation is non-reversible

# Examples

Measure project the qubit state and optionally store the result of the
measurement for that qubit in a classical register.

To just apply the measurement on qubit `1` and discard the result, do:
```jldoctest
julia> push!(Circuit(), Measure(), 1)
2-qubit circuit with 1 gates:
└── Measure @ q1
```

In order to store the result on the 2nd bit, call:

```jldoctest
julia> push!(Circuit(), Measure(), 1 => 2)
2-qubit circuit with 1 gates:
└── Measure @ q1, c1
```

"""
struct Measure <: Operation{1,1} end

inverse(::Measure) = error("Cannot invert Measurements")

opname(::Type{<:Measure}) = "Measure"

function Base.show(io::IO, ::Measure)
    print(io, opname(Measure))
end

# Convenience functions for adding Measure.
# Since Measure are singleton types we can allow to use e.g.
# push!(c, Measure, 1, 1)
# to avoid writing 2 parentheses more.
function Instruction(::Type{Measure}, qtarget, ctarget; kwargs...)
    Instruction(Measure(), (qtarget,), (ctarget,); kwargs...)
end

Base.insert!(c::Circuit, i::Integer, ::Type{Measure}, args...) = insert!(c, i, Measure(), args...)

Base.push!(c::Circuit, ::Type{Measure}, args...) = push!(c, Measure(), args...)
