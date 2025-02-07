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
    evaluate(object, dictionary)

Evaluate all the parametric expression in `object` using the values specified
in the given in the variable, value dictionary, returning a new object
constructed on the evaluated parameters.

## Examples

Evaluate a single parametric gate
```jldoctest
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> g  = GateRX(θ)
RX(θ)

julia> evaluate(g, Dict(θ => 3π))
RX(3π)
```
"""
function evaluate end

function evaluate(g, rules...)
    d = Dict(pairs...)
    return evaluate(g, d)
end

function evaluate(g::Num, d::Dict=Dict())
    return Symbolics.substitute(g, d)
end

function evaluate(g::T, d::Dict=Dict()) where {T<:AbstractOperator}
    args = [Symbolics.substitute(getparam(g, n), d) for n in parnames(T)]
    return T(args...)
end

function evaluate(control::Control{N,M,L,T}, d::Dict=Dict()) where {N,M,L,T}
    return Control(N, evaluate(control.op, d))
end

evaluate(g::Inverse{N,T}, d::Dict=Dict()) where {N,T} = Inverse(evaluate(g.op, d))

evaluate(g::Power{P,T}, d::Dict=Dict()) where {P,T} = Power(evaluate(g.op, d), P)

function evaluate(g::GateCustom, d::Dict=Dict())
    Unew = map(g.U) do x
        Symbolics.substitute(x, d)
    end
    GateCustom(Unew)
end

function evaluate(g::Operator, d::Dict=Dict())
    Onew = map(g.O) do x
        Symbolics.substitute(x, d)
    end
    Operator(Onew)
end

function evaluate(g::GateCall{N,M}, d::Dict=Dict()) where {N,M}
    decl = g._decl
    args = map(x -> Symbolics.substitute(x, d), g._args)
    return GateCall(decl, args...)
end

function evaluate(ev::ExpectationValue, d::Dict=Dict())
    return ExpectationValue(evaluate(getoperation(ev), d))
end

evaluate(g::Operation, ::Dict) = g

function evaluate(inst::Instruction, d::Dict)
    return Instruction(
        evaluate(getoperation(inst), d),
        getqubits(inst),
        getbits(inst),
        getztargets(inst)
    )
end

function evaluate(circ::Circuit, d::Dict)
    c = Circuit()
    for inst in circ
        push!(c, evaluate(inst, d))
    end
    return c
end

function evaluate!(circ::Circuit, d::Dict)
    for i in eachindex(circ)
        circ[i] = evaluate(circ[i], d)
    end
    return circ
end

# Pauli Strings will not be evaluated, since the stored string is not a parameter.
function evaluate(g::PauliString{N}, _::Dict=Dict()) where {N}
    return g
end

function evaluate(g::T, _::Dict=Dict()) where {T<:AbstractKrausChannel}
    return g
end
