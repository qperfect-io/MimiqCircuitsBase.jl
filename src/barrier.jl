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
    struct Barrier <: Operation

A barrier is a special operation that does not affect the quantum state or the
execution of a circuit, but it prevents compression or optimization operation
from being applied across it.

# Examples

```jldoctest
julia> push!(Circuit(), Barrier(), 1, 2)
2-qubit circuit with 1 gates:
└── Barrier @ q1, q2
```
"""
struct Barrier <: Operation end

inverse(b::Barrier) = b

opname(::Type{<:Barrier}) = "Barrier"

function Base.show(io::IO, ::Barrier)
    print(io, opname(Barrier))
end
