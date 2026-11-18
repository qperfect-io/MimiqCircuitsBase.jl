#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
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
    BlockDecl(name, args, instructions; numancillas=0)
    BlockDecl(name, args, circuit; numancillas=0)
    BlockDecl(name, args, block; numancillas=numancillas(block))

Declare a named, parametric block of instructions.

A `BlockDecl` is to [`Block`](@ref) what [`GateDecl`](@ref) is to a gate: a
reusable definition with symbolic arguments. Unlike a `GateDecl`, its body can
hold any instruction, including measurements, resets, noise, classical
operations and conditionals, and it can act on bits and z-variables.

A declaration is not an operation and cannot be added to a circuit. Calling it
with values for its arguments gives a [`BlockCall`](@ref), which can. Every call
refers to the same declaration, so a block used many times is stored, and
serialized, only once.

* `name` is a `Symbol` used for display.
* `args` is a tuple of distinct symbolic variables, the formal arguments.
* the body is a vector of instructions, a [`Circuit`](@ref) or a
  [`Block`](@ref). It is copied. When given a `Block`, the declaration keeps its
  number of qubits, bits and z-variables; otherwise they are the ones the
  instructions use.
* the `numancillas` keyword is the number of the last qubits of each call that
  are clean ancillas, found and returned in ``|0⟩``. It defaults to that of the
  block, or to 0 for the other bodies. See [`numancillas`](@ref).

Every symbol in the body must be one of `args`. To leave a value open, make it
an argument and pass a symbol in the call.

Throws an `ArgumentError` if an argument is not a symbol, if two arguments are
the same, or if the body uses a symbol that is not an argument.

## Examples

Declare a parametric syndrome extraction with [`@blockdecl`](@ref), then call it
twice with different angles:

```jldoctest
julia> @blockdecl syndrome(θ) begin
           @on GateRX(θ) q=1
           @on GateCX() q=(1, 2)
           @on Measure() q=2 c=1
       end
block syndrome(θ) =
├── RX(θ) @ q[1]
├── CX @ q[1], q[2]
└── M @ q[2], c[1]

julia> c = Circuit();

julia> push!(c, syndrome(0.1), 1, 2, 1);

julia> push!(c, syndrome(0.2), 3, 4, 2)
4-qubit, 2-bit circuit with 2 instructions:
├── syndrome(0.1) @ q[1:2], c[1]
└── syndrome(0.2) @ q[3:4], c[2]

julia> decompose_step(c)
4-qubit, 2-bit circuit with 6 instructions:
├── RX(0.1) @ q[1]
├── CX @ q[1], q[2]
├── M @ q[2], c[1]
├── RX(0.2) @ q[3]
├── CX @ q[3], q[4]
└── M @ q[4], c[2]
```

See also [`BlockCall`](@ref), [`@blockdecl`](@ref), [`Block`](@ref),
[`GateDecl`](@ref).
"""
struct BlockDecl{N,M,L,P}
    name::Symbol
    _arguments::NTuple{P,Symbolics.BasicSymbolic}
    _instructions::Vector{<:Instruction}
    numancillas::Int

    function BlockDecl{N,M,L}(name, args, instructions; numancillas::Integer=0) where {N,M,L}
        args = Tuple(Symbolics.value.(args))

        if !all(SymbolicUtils.issym, args)
            throw(ArgumentError("All BlockDecl arguments must be symbols."))
        end

        if !allunique(args)
            throw(ArgumentError("BlockDecl arguments must be distinct."))
        end

        for v in unique(reduce(vcat, listvars.(instructions); init=Num[]))
            if !any(a -> isequal(Symbolics.value(v), a), args)
                throw(ArgumentError("BlockDecl body uses symbol $v, which is not one of its arguments."))
            end
        end

        for inst in instructions
            _check_instruction_block(inst, N, M, L)
        end

        _check_numancillas(numancillas, N)

        return new{N,M,L,length(args)}(Symbol(name), args, copy(instructions), numancillas)
    end
end

function BlockDecl(name, args, instructions::Vector{<:Instruction}; kwargs...)
    nq = numqubits(instructions)
    nc = numbits(instructions)
    nz = numzvars(instructions)
    return BlockDecl{nq,nc,nz}(name, args, instructions; kwargs...)
end

BlockDecl(name, args, c::Circuit; kwargs...) = BlockDecl(name, args, c._instructions; kwargs...)

function BlockDecl(name, args, b::Block{N,M,L}; numancillas::Integer=b.numancillas) where {N,M,L}
    return BlockDecl{N,M,L}(name, args, b._instructions; numancillas=numancillas)
end

numancillas(decl::BlockDecl) = decl.numancillas

numqubits(::BlockDecl{N}) where {N} = N
numbits(::BlockDecl{N,M}) where {N,M} = M
numzvars(::BlockDecl{N,M,L}) where {N,M,L} = L

function Base.:(==)(d1::BlockDecl, d2::BlockDecl)
    d1 === d2 && return true
    numqubits(d1) == numqubits(d2) || return false
    numbits(d1) == numbits(d2) || return false
    numzvars(d1) == numzvars(d2) || return false
    d1.name == d2.name || return false
    isequal(d1._arguments, d2._arguments) || return false
    d1.numancillas == d2.numancillas || return false
    return d1._instructions == d2._instructions
end

Base.iterate(d::BlockDecl) = iterate(d._instructions)
Base.iterate(d::BlockDecl, state) = iterate(d._instructions, state)
Base.firstindex(d::BlockDecl) = firstindex(d._instructions)
Base.lastindex(d::BlockDecl) = lastindex(d._instructions)
Base.length(d::BlockDecl) = length(d._instructions)
Base.isempty(d::BlockDecl) = isempty(d._instructions)
Base.getindex(d::BlockDecl, i::Integer) = getindex(d._instructions, i)
Base.eltype(d::BlockDecl) = eltype(d._instructions)
Base.keys(d::BlockDecl) = keys(d._instructions)

@doc raw"""
    BlockCall(decl, args...)

Operation applying a [`BlockDecl`](@ref) to the given arguments.

It is usually created by calling the declaration, `decl(args...)`. The
arguments can be numbers or symbolic expressions; their count must match the
declaration's. The call keeps a reference to `decl`, not a copy.

A `BlockCall` acts on as many qubits, bits and z-variables as its declaration.
It is unitary when every instruction of the declaration is.

Throws an `ArgumentError` when the number of arguments is wrong.

## Examples

```jldoctest
julia> @blockdecl prep(θ) begin
           @on GateRY(θ) q=1
       end
block prep(θ) =
└── RY(θ) @ q[1]

julia> @variables φ;

julia> g = prep(2φ)
prep(2φ)

julia> evaluate(g, Dict(φ => 0.5))
prep(1)
```

See also [`BlockDecl`](@ref), [`@blockdecl`](@ref).
"""
struct BlockCall{N,M,L,P} <: Operation{N,M,L}
    _decl::BlockDecl{N,M,L,P}
    _args::NTuple{P,Num}

    function BlockCall(decl::BlockDecl{N,M,L,P}, args...) where {N,M,L,P}
        if length(args) != P
            throw(ArgumentError("Wrong number of arguments for BlockCall. Expected $P, got $(length(args))"))
        end
        return new{N,M,L,P}(decl, Tuple(args))
    end
end

(decl::BlockDecl)(args...) = BlockCall(decl, args...)

opname(::Type{<:BlockCall}) = "BlockCall"

numancillas(c::BlockCall) = numancillas(c._decl)

numparams(::Type{<:BlockCall{N,M,L,P}}) where {N,M,L,P} = P

isunitary(c::BlockCall) = all(isunitary, c._decl)

function Base.:(==)(c1::BlockCall, c2::BlockCall)
    c1._decl == c2._decl || return false
    return isequal(c1._args, c2._args)
end

function _bound_instructions(c::BlockCall)
    d = Dict(zip(c._decl._arguments, c._args))
    return [evaluate(inst, d) for inst in c._decl]
end

matches(::CanonicalRewrite, ::BlockCall) = true

function decompose_step!(builder, ::CanonicalRewrite, c::BlockCall, qtargets, ctargets, ztargets)
    for inst in _bound_instructions(c)
        qt = (qtargets[i] for i in getqubits(inst))
        bt = (ctargets[i] for i in getbits(inst))
        zt = (ztargets[i] for i in getztargets(inst))
        push!(builder, getoperation(inst), qt..., bt..., zt...)
    end
    return builder
end

function Base.show(io::IO, d::BlockDecl)
    print(io, "BlockDecl(", d.name, ", ", d._arguments, ", ")
    show(io, d._instructions)
    print(io, ")")
end

function Base.show(io::IO, m::MIME"text/plain", d::BlockDecl)
    print(io, "block ", d.name)
    if !isempty(d._arguments)
        print(io, "(")
        join(io, d._arguments, ",")
        print(io, ")")
    end
    if get(io, :compact, false)
        return nothing
    end
    println(io, " =")
    _show_instructions(io, m, d._instructions)
    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", c::BlockCall)
    print(io, c._decl.name)
    if numparams(c) != 0
        print(io, '(')
        join(io, (_displaynum(io, x) for x in c._args), ",")
        print(io, ')')
    end
end
