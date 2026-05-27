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
    LossErr(p)

A probabilistic qubit-loss event.

`LossErr(p)` marks a point in the circuit where the qubit is lost with
probability `p`.


See also: [`QubitReload`](@ref).

## Examples
```jldoctests
julia> c = push!(Circuit(), LossErr(0.1), 1)
1-qubit circuit with 1 instruction:
└── LossErr(0.1) @ q[1]
``` 
"""
struct LossErr <: Operation{1,0,0}
    p::Num
    function LossErr(p::Number)
        if !(p isa Symbolics.Num)
            if p < 0 || p > 1
                throw(ArgumentError("Loss probability p must be between 0 and 1."))
            end
        end
        new(p)
    end
end

function evaluate(op::LossErr, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(op.p, d)
    p = Symbolics.value(evaluated_p)

    if p isa Real
        if p < 0 || p > 1
            throw(ArgumentError("Loss probability p must be between 0 and 1 after evaluation."))
        end
        return LossErr(p)
    else
        return LossErr(evaluated_p)
    end
end

opname(::Type{<:LossErr}) = "LossErr"

function Base.show(io::IO, op::LossErr)
    print(io, opname(LossErr), "(", op.p, ")")
end

function Base.show(io::IO, ::MIME"text/plain", op::LossErr)
    print(io, opname(LossErr), "(", op.p, ")")
end

inverse(::LossErr) = error("LossErr is not invertible")
