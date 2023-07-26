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
    struct Reset <: Operation{1}

Quantum operation that resets the status of one qubit to the ``\ket{0}``
state.

# Examples

```jldoctest
julia> push!(Circuit(), Reset(), 1)
2-qubit circuit with 1 gates:
└── Reset @ q1
```

"""
struct Reset <: Operation{1,0} end

inverse(::Reset) = error("Cannot invert Measurements")

opname(::Type{<:Reset}) = "Reset"

function Base.show(io::IO, ::Reset)
    print(io, opname(Reset))
end

# Convenience functions for adding Reset.
# Since Reset are singleton types we can allow to use e.g.
# push!(c, Reset, 1, 1)
# to avoid writing 2 parentheses more.
function Instruction(::Type{Reset}, qtarget; kwargs...)
    Instruction(Reset(), (qtarget,), (); kwargs...)
end

Base.insert!(c::Circuit, i::Integer, ::Type{Reset}, args...) = insert!(c, i, Reset(), args...)

Base.push!(c::Circuit, ::Type{Reset}, args...) = push!(c, Reset(), args...)
