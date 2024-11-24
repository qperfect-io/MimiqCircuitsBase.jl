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
@doc raw"""
    GateDecl(name, args, circuit)

Define a new gate of given name, arguments and circuit.

### Examples

A simple gate declaration, via the `@gatedecl` macro:
```jldoctests
julia> @gatedecl ansatz(θ)  = begin
           c = Circuit()
           push!(c, GateX(), 1)
           push!(c, GateRX(θ), 2)
           return c
       end
gate ansatz(θ) =
├── X @ q[1]
└── RX(θ) @ q[2]

julia> @variables λ;


julia> decompose(ansatz(λ))
2-qubit circuit with 2 instructions:
├── X @ q[1]
└── RX(λ) @ q[2]

```

## See also

[`GateCall`](@ref)
"""
struct GateDecl{N,M}
    name::Symbol
    arguments::NTuple{M,Symbolics.BasicSymbolic}
    circuit::Circuit

    function GateDecl(name, args, circuit)
        if !all(x -> SymbolicUtils.issym(x), args)
            throw(ArgumentError("All GateDecl arguments must be symbols."))
        end

        if isempty(circuit)
            throw(ArgumentError("GateDecl instructions cannot be empty."))
        end

        if numqubits(circuit) == 0
            throw(ArgumentError("GateDecl instructions must act on qubits."))
        end

        if numbits(circuit) != 0
            throw(ArgumentError("GateDecl instructions cannot act on classical bits."))
        end

        if numzvars(circuit) != 0
            throw(ArgumentError("GateDecl instructions cannot act on z-bits."))
        end

        nq = numqubits(circuit)
        np = length(args)

        return new{nq,np}(name, args, deepcopy(circuit))
    end
end

# TODO: check for undefined parameters
macro gatedecl(decl)
    # check the syntax
    # should be `@gatedecl GateName(arg1, arg2, ...) = begin ... end``

    if decl.head != :(=) && decl.head != :function
        error("Wrong syntax for gate declaration")
    end

    call = decl.args[1]
    body = decl.args[2]

    if call.head != :call
        error("Wrong syntax for gate declaration.")
    end

    if body.head != :block
        error("Wrong syntax for gate declaration.")
    end

    if any(x -> x isa Expr && x.head == :macrocall && x.args[1] == :variables, body.args)
        error("GateDecl does not support @variables macro.")
    end

    name = call.args[1]
    args = call.args[2:end]

    if !all(x -> x isa Symbol, args)
        error("GateDecl only supports simple arguments.")
    end

    vars = Tuple(SymbolicUtils.Sym{Real}.(args))

    newbody = Expr(:block)

    for (nvar, var) in zip(args, vars)
        push!(newbody.args, :($nvar = $var))
    end

    append!(newbody.args, body.args)

    circuit = eval(newbody)

    if !(circuit isa Circuit)
        error("GateDecl body must return a unitary circuit.")
    end

    return esc(:($name = GateDecl($(QuoteNode(name)), $vars, $circuit)))
end

@doc raw"""
    GateCall(decl, args...)

Gate corresponding to a call to a [`GateDecl`](@ref) definition.

It is created by calling a [`GateDecl`](@ref) with the proper number of
arguments.

## Examples

```jldoctests
julia> @gatedecl ansatz(θ) = begin
           c = Circuit()
           push!(c, GateX(), 1)
           push!(c, GateRX(θ), 2)
           return c
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

function decompose(cl::GateCall)
    circ = Circuit()
    d = Dict(zip(cl._decl.arguments, cl._args))
    for inst in cl._decl.circuit
        op = evaluate(getoperation(inst), d)
        qubits = getqubits(inst)
        push!(circ, op, qubits...)
    end
    return circ
end

function decompose!(circuit::Circuit, cl::GateCall, qtargets, _, _)
    d = Dict(zip(cl._decl.arguments, cl._args))

    for inst in cl._decl.circuit
        op = evaluate(getoperation(inst), d)
        inst_qubits = [qtargets[q] for q in getqubits(inst)]
        push!(circuit, op, inst_qubits...)
    end

    return circuit
end

(decl::GateDecl)(args...) = GateCall(decl, args...)

function Base.show(io::IO, d::GateDecl)
    print(io, "GateDecl(", d.name, ", ", d.arguments, ", [")
    c = d.circuit
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
    rows, _ = displaysize(io)
    n = length(d.circuit)
    if !compact
        print(io, "gate ", d.name, "(")
        join(io, d.arguments, ",")
        println(io, ") =")

        if rows - 4 <= 0
            print(io, "└── ...")
        elseif rows - 4 >= n
            for g in d.circuit[1:end-1]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end
            print(io, "└── ")
            show(io, m, d.circuit[end])
        else
            chunksize = div(rows - 6, 2)

            for g in d.circuit[1:chunksize]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end

            println(io, "⋮   ⋮")

            for g in d.circuit[end-chunksize:end-1]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end

            print(io, "└── ")
            show(io, m, d.circuit[end])
        end
    else
        print(io, "gate ", d.name, "(")
        join(io, d.arguments, ",")
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
