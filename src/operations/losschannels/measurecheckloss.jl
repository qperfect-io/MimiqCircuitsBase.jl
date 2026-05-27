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
    MeasureCheckLoss()

Measures a qubit **and** reports whether it is lost or present.

- First output bit  = quantum measurement result (0 or 1)
- Second output bit = qubit presence status  
    - `1` → qubit is present  
    - `0` → qubit is lost  

If the qubit is lost, the measurement result is simulator-defined  
(typically forced to 0). This operation *does* collapse the state
**only when the qubit is present**.

See also: [`CheckLoss`](@ref), [`LossErr`](@ref), [`QubitReload`](@ref).

## Examples

```jldoctests
julia> c = push!(Circuit(), MeasureCheckLoss(), 1, 1, 2)
1-qubit, 2-bit circuit with 1 instruction:
└── MCL @ q[1], c[1:2]
```
"""
struct MeasureCheckLoss <: Operation{1,2,0} end

opname(::Type{<:MeasureCheckLoss}) = "MCL"

function Base.show(io::IO, ::MeasureCheckLoss)
    print(io, opname(MeasureCheckLoss))
end

inverse(::MeasureCheckLoss) = error("MeasureCheckLoss is not invertible")

function Base.show(io::IO, ::MIME"text/plain", ::MeasureCheckLoss)
    print(io, opname(MeasureCheckLoss))
end

