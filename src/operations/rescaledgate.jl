#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 3.0 (the "License");
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

# TODO: add documentation
@doc raw"""TODO
"""
struct RescaledGate{N,T} <: AbstractOperator{N}
    gate::T
    m::Num

    function RescaledGate(gate::T, m) where {N,T<:AbstractGate{N}}
        if !issymbolic(m) && (unwrapvalue(m) < 0 || unwrapvalue(m) > 1)
            throw(ArgumentError("Value of m must be between 0 and 1."))
        end
        new{N,T}(gate, m)
    end
end

opname(::Type{<:RescaledGate}) = "RescaledGate"

iswrapper(::Type{<:RescaledGate}) = true

getoperation(g::RescaledGate) = g.gate

parnames(::Type{<:RescaledGate{N,T}}) where {N,T} = (:m, parnames(T)...)

function getparam(op::RescaledGate, name)
    if name == :m
        return op.m
    end
    getparam(getoperation(op), name)
end

_matrix(::Type{RescaledGate{N,T}}, m, args...) where {N,T} = m .* _matrix(T, args...)

# TODO: add documentation
getscale(op::RescaledGate) = op.m

# TODO: add documentation
function rescale! end

function rescale!(op::RescaledGate, m)
    op.m *= m
    op
end

rescale(op::RescaledGate, m) = RescaledGate(getoperation(op), getscale(op) * m)

rescale(op::AbstractGate, m) = RescaledGate(op, m)

rescale!(::AbstractGate, _) = error("Cannot rescale agate in place. Use `rescale` instead.")

evaluate(op::RescaledGate, d::Dict) = RescaledGate(evaluate(getoperation(op), d), evaluate(getscale(op), d))

function Base.show(io::IO, op::RescaledGate)
    sep = get(io, :compact, false) ? ", " : ","
    print(io, opname(op), "(", getoperation(op), sep, getscale(op), ")")
end

function Base.show(io::IO, m::MIME"text/plain", op::RescaledGate)
    mult = get(io, :compact, false) ? "*" : " * "
    print(io, getscale(op), mult)
    show(io, m, getoperation(op))
end
