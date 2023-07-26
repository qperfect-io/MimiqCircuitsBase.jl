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
    tojson(circuit)
    tojson(instruction)
    tojson(operation)

Returns a JSON string representing the given object
"""
function tojson end

"""
    todict(circuit)
    todict(instruction)
    todict(operation)
"""
function todict end

"""
    fromjson(object, str)

Parse the JSON string given to the given object type.
"""
function fromjson end

"""
    fromdict(object, dict)

Returns the given object from the serialized JSON dictionary.
"""
function fromdict end

todict(op::Operation{N,M}) where {N,M} = Dict(:name => opname(op), :N => N, :M => M)
todict(op::ParametricGate{N}) where {N} = Dict(:name => opname(op), :N => N, :M => 0, :params => Dict(map(p -> p => getfield(op, p), parnames(op))...))
todict(op::GateCustom{N,<:Real}) where {N} = Dict(:name => opname(op), :N => N, :M => numbits(op), :U => todict.(reshape(matrix(op), hilbertspacedim(op)^2)), :iscomplex => false)
todict(op::GateCustom{N,<:Complex}) where {N} = Dict(:name => opname(op), :N => N, :M => numbits(op), :U => todict.(reshape(matrix(op), hilbertspacedim(op)^2)), :iscomplex => true)
todict(op::Parallel{N}) where {N} = Dict(:name => opname(op), :N => numqubits(op), :M => numbits(op), :repeats => N, :op => todict(op.op))
todict(op::Control{N}) where {N} = Dict(:name => opname(op), :N => numqubits(op), :M => numbits(op), :controls => N, :op => todict(op.op))
todict(op::IfStatement) = Dict(:name => opname(op), :N => numqubits(op), :M => numbits(op), :value => todict(op.val), :op => todict(op.op))
todict(x::Complex) = Dict(:re => real(x), :im => imag(x))
todict(x::Real) = x
todict(x::BitState) = string(x)

todict(inst::Instruction) = Dict(:op => todict(getoperation(inst)), :qtargets => collect(getqubits(inst)), :ctargets => collect(getbits(inst)))
todict(c::Circuit) = Dict(:instructions => todict.(c.instructions))

function fromdict(::Type{Operation}, obj::Dict{Symbol,<:Any})
    name = obj[:name]

    if name == opname(Barrier)
        fromdict(Barrier, obj)
    elseif name == opname(Control)
        fromdict(Control, obj)
    elseif name == opname(Parallel)
        fromdict(Parallel, obj)
    elseif name == opname(IfStatement)
        fromdict(IfStatement, obj)
    elseif name == opname(GateCustom)
        fromdict(GateCustom, obj)
    else
        optype = BiMaps.getright(OPERATIONS, name, nothing)
        if isnothing(optype)
            error("Cannot convert operation $name from JSON: not implemented.")
        end

        fromdict(optype, obj)
    end
end

function fromdict(T::Type{<:Operation{N,M}}, ::Dict{Symbol,<:Any}) where {N,M}
    T()
end

function fromdict(T::Type{<:ParametricGate{N}}, obj::Dict{Symbol,<:Any}) where {N}
    pn = parnames(T)
    p = obj[:params]
    T(map(x -> p[x], pn)...)
end

function fromdict(T::Type{<:Complex}, obj::Dict{Symbol,<:Any})
    T(obj[:re], obj[:im])
end

function fromdict(T::Type{<:Complex}, obj)
    T(obj)
end

function fromdict(T::Type{<:Real}, obj)
    T(obj)
end

function fromdict(T::Type{GateCustom}, obj::Dict{Symbol,<:Any})
    N = obj[:N]
    G = obj[:iscomplex] ? ComplexF64 : Float64
    U = reshape(fromdict.(G, obj[:U]), (2^N, 2^N))
    T(U)
end

function fromdict(::Type{Barrier}, obj::Dict{Symbol,<:Any})
    return Barrier(obj[:N])
end

function fromdict(::Type{Control}, obj::Dict{Symbol,<:Any})
    op = fromdict(Operation, obj[:op])
    controls = obj[:controls]
    return Control(controls, op)
end

function fromdict(::Type{Parallel}, obj::Dict{Symbol,<:Any})
    op = fromdict(Operation, obj[:op])
    repeats = obj[:repeats]
    return Parallel(repeats, op)
end

function fromdict(::Type{IfStatement}, obj::Dict{Symbol,<:Any})
    op = fromdict(Operation, obj[:op])
    val = fromdict(BitState, obj[:value])
    return IfStatement(op, val)
end

function fromdict(::Type{<:Instruction}, obj::Dict{Symbol,<:Any})
    op = fromdict(Operation, obj[:op])
    qtargets = tuple(obj[:qtargets]...)
    ctargets = tuple(obj[:ctargets]...)
    return Instruction(op, qtargets, ctargets)
end

function fromdict(::Type{Circuit}, obj::Dict{Symbol,<:Any})
    c = Circuit()

    for i in obj[:instructions]
        push!(c, fromdict(Instruction, i))
    end

    return c
end

function fromdict(T::Type{BitState}, obj::String)
    parse(T, obj)
end

fromjson(::Type{T}, str::AbstractString) where {T} = fromdict(T, JSON.parse(str; dicttype=Dict{Symbol,Any}))
tojson(c) = JSON.json(todict(c))

