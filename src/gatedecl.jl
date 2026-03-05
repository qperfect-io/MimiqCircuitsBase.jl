#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    GateDecl(name, args, circuit)

Define a new gate of given name, arguments and circuit.

### Examples

A simple gate declaration, via the `@gatedecl` macro:
```jldoctests
julia> @gatedecl ansatz(θ) begin
           @on GateX() q=1
           @on GateRX(θ) q=2
       end
gate ansatz(θ) =
├── X @ q[1]
└── RX(θ) @ q[2]

julia> @variables λ;


julia> decompose_step(ansatz(λ))
2-qubit circuit with 2 instructions:
├── X @ q[1]
└── RX(λ) @ q[2]

```

## See also

[`GateCall`](@ref)
"""
struct GateDecl{N,M}
    name::Symbol
    _arguments::NTuple{M,Symbolics.BasicSymbolic}
    _instructions::Vector{<:Instruction}

    function GateDecl(name, args, instructions)
        if !all(x -> SymbolicUtils.issym(x), args)
            throw(ArgumentError("All GateDecl arguments must be symbols."))
        end

        if isempty(instructions)
            throw(ArgumentError("GateDecl instructions cannot be empty."))
        end

        if numqubits(instructions) == 0
            throw(ArgumentError("GateDecl instructions must act on qubits."))
        end

        if numbits(instructions) != 0
            throw(ArgumentError("GateDecl instructions cannot act on classical bits."))
        end

        if numzvars(instructions) != 0
            throw(ArgumentError("GateDecl instructions cannot act on z-bits."))
        end

        nq = numqubits(instructions)
        np = length(args)

        return new{nq,np}(name, args, copy(instructions))
    end
end

GateDecl(name, args, circuit::Circuit) = GateDecl(name, args, circuit._instructions)

# TODO: check for undefined parameters
# @gatedecl macro defined in dsl.jl

function Base.:(==)(d1::GateDecl, d2::GateDecl)
    d1.name == d2.name || return false
    d1._arguments == d2._arguments || return false
    d1._instructions == d2._instructions || return false
    return true
end

Base.iterate(c::GateDecl) = iterate(c._instructions)
Base.iterate(c::GateDecl, state) = iterate(c._instructions, state)
Base.firstindex(c::GateDecl) = firstindex(c._instructions)
Base.lastindex(c::GateDecl) = lastindex(c._instructions)
Base.length(c::GateDecl) = length(c._instructions)
Base.isempty(c::GateDecl) = isempty(c._instructions)
Base.getindex(c::GateDecl, i::Integer) = getindex(c._instructions, i)
Base.eltype(c::GateDecl) = eltype(c._instructions)
Base.keys(c::GateDecl) = keys(c._instructions)

@doc raw"""
    GateCall(decl, args...)

Gate corresponding to a call to a [`GateDecl`](@ref) definition.

It is created by calling a [`GateDecl`](@ref) with the proper number of
arguments.

## Examples

```jldoctests
julia> @gatedecl ansatz(θ) begin
           @on GateX() q=1
           @on GateRX(θ) q=2
       end
gate ansatz(θ) =
├── X @ q[1]
└── RX(θ) @ q[2]

julia> @variables λ;


julia> ansatz(λ)
ansatz(λ)

```

## See also

[`GateDecl`](@ref)
"""
struct GateCall{N,M} <: AbstractGate{N}
    _decl::GateDecl{N,M}
    _args::NTuple{M,Num}

    function GateCall(decl::GateDecl{N,M}, args...) where {N,M}
        if length(args) != M
            throw(ArgumentError("Wrong number of arguments for GateCall. Expected $M, got $(length(args))"))
        end
        return new{N,M}(decl, Tuple(args))
    end
end

opname(::Type{<:GateCall}) = "GateCall"

numparams(::Type{<:GateCall{N,M}}) where {N,M} = M

matches(::CanonicalRewrite, ::GateCall) = true

function decompose_step!(builder, ::CanonicalRewrite, cl::GateCall, qtargets, _, _)
    d = Dict(zip(cl._decl._arguments, cl._args))

    for inst in cl._decl._instructions
        op = evaluate(getoperation(inst), d)
        inst_qubits = [qtargets[q] for q in getqubits(inst)]
        push!(builder, op, inst_qubits...)
    end

    return builder
end

(decl::GateDecl)(args...) = GateCall(decl, args...)

function Base.show(io::IO, d::GateDecl)
    print(io, "GateDecl(", d.name, ", ", d._arguments, ", [")
    c = d._instructions
    print(io, c[1])

    if length(c) > 1
        for inst in c[2:end]
            print(io, ", ", inst, ", ")
        end
    end

    print(io, "])")

    return nothing
end

function Base.show(io::IO, m::MIME"text/plain", d::GateDecl)
    compact = get(io, :compact, false)

    if !compact
        print(io, "gate ", d.name, "(")
        join(io, d._arguments, ",")
        println(io, ") =")

        _show_instructions(io, m, d._instructions)
    else
        print(io, "gate ", d.name, "(")
        join(io, d._arguments, ",")
        println(io, ")")
    end

    nothing
end

function Base.show(io::IO, ::MIME"text/plain", g::GateCall)
    print(io, g._decl.name)
    if numparams(g) != 0
        print(io, '(')
        join(io, g._args, ",")
        print(io, ')')
    end
end

function matrix(g::GateCall{N}) where {N}
    iter = Iterators.map(decompose_step(g)) do inst
        matrix(inst, N)
    end
    return foldl(*, Iterators.reverse(iter); init=Matrix{Complex{Num}}(I, 2^N, 2^N))
end

function Base.:(==)(g1::GateCall, g2::GateCall)
    g1._decl == g2._decl || return false
    g1._args == g2._args || return false
    return true
end
