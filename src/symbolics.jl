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


"""
Check whether the circuit contains any symbolic (unevaluated) parameters.

This method examines each instruction in the circuit to determine if any parameter remains
symbolic (i.e., unevaluated). It recursively checks through each instruction and its nested 
operations, if any.
Returns True if any parameter is symbolic (unevaluated), False if all parameters are fully evaluated.

## Examples

```jldoctests
julia> c = Circuit()
empty circuit


julia> push!(c, GateH(), 1)
1-qubit circuit with 1 instructions:
└── H @ q[1]

julia> issymbolic(c)
false

julia> @variables x y
2-element Vector{Symbolics.Num}:
 x
 y

julia> push!(c,Control(3,GateP(x+y)),1,2,3,4)
4-qubit circuit with 2 instructions:
├── H @ q[1]
└── C₃P(x + y) @ q[1:3], q[4]

julia> issymbolic(c)
true
```
"""
function issymbolic end
    
function issymbolic(op::Operation)
    for param in getparams(op)
        val = Symbolics.value(param)
        if !isa(val, Number)
            return true
        end
    end
    return false
end

issymbolic(inst::Instruction) = issymbolic(getoperation(inst))

issymbolic(c::Circuit) = any(issymbolic, c)