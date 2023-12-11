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
    IfStatement(numbits, op, num)

Applies the wrapper operation, only if the classical register is equal to `num`.

!!! warn
    Currentely not supported by the state vector and MPS simulators.

## Examples

`push!(IfStatement(GateX(), 10), 1,1,2,3,4,5)` is the equivalent of OpenQASM 2.0

```
creg c[5];
if (c==10) x q[0];
```

```jldoctest
julia> IfStatement(10, GateX(), 999)
If(c == 999) X
```
"""
struct IfStatement{N,M,T<:Operation{M,0}} <: Operation{M,N}
    op::Operation{M,0}
    val::Num

    function IfStatement{N,M}(op, val) where {N,M}
        new{N,M,T}(op, val)
    end

    function IfStatement(nb::Integer, op::T, val) where {T<:AbstractGate}
        new{nb,numqubits(op),T}(op, val)
    end
end

IfStatement(op::T, val) where {T<:AbstractGate} = LazyExpr(IfStatement, LazyArg(), op, val)

opname(::Type{<:IfStatement}) = "If"

inverse(::IfStatement) = error("Cannot inverse an IfStatement.")

_power(::IfStatement, n) = error("Cannot elevate an IfStatement to any power.")

getoperation(c::IfStatement) = c.op

iswrapper(::Type{<:IfStatement}) = true

function getunwrappedvalue(g::IfStatement)
    v = Symbolics.value(g.val)
    if v isa Number
        return v
    elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:π}}
        return π
    elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:ℯ}}
        return ℯ
    else
        throw(UndefinedParameterError("val", opname(g)))
    end
end

function Base.show(io::IO, s::IfStatement)
    print(io, opname(IfStatement), "(c == ", s.val, ") ", s.op)
end
