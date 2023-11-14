@doc raw"""
    GateDecl(name, args, instructions)

Define a new gate of given name, arguments and instructions.

### Examples

A simple gate declaration, via the `@gatedecl` macro:
```@repl
decl = @gatedecl ansatz(θ) = begin
    insts = Instruction[]
    push!(insts, Instruction(GateX(), 1))
    push!(insts, Instruction(GateRX(θ), 2))
    return insts
end
@variables λ;
decompose(decl(λ))
```

## See also

[`GateCall`](@ref)
"""
struct GateDecl{N,M}
    name::Symbol
    arguments::NTuple{M,Symbolics.BasicSymbolic}
    instructions::Vector{Instruction}

    function GateDecl(name, args, instructions)
        if !all(x -> SymbolicUtils.issym(x), args)
            throw(ArgumentError("All GateDecl arguments must be symbols."))
        end

        if isempty(instructions)
            throw(ArgumentError("GateDecl instructions cannot be empty."))
        end

        nq = numqubits(instructions)
        np = length(args)

        new{nq,np}(name, args, instructions)
    end
end

# TODO: check for undefined parameters
macro gatedecl(decl)
    # check the syntax
    # should be `@gatedecl GateName(arg1, arg2, ...) = begin ... end``

    if decl.head != :(=)
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

    instructions = eval(newbody)

    if !(instructions isa Vector{Instruction})
        error("GateDecl body must return a vector of instructions.")
    end

    return :(GateDecl($(QuoteNode(name)), $vars, $instructions))
end

@doc raw"""
    GateCall(decl, args...)

Gate corresponding to a call to a [`GateDecl`](@ref) definition.

It is created by calling a [`GateDecl`](@ref) with the proper number of
arguments.

## Examples

```@repl
decl = @gatedecl ansatz(θ) = begin
    insts = Instruction[]
    push!(insts, Instruction(GateX(), 1))
    push!(insts, Instruction(GateRX(θ), 2))
    return insts
end;
@variables λ;
decl(λ)
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

function decompose!(circ::Circuit, cl::GateCall, qtargets, ctargets)
    d = Dict(zip(cl._decl.arguments, cl._args))
    for inst in cl._decl.instructions
        op = evaluate(getoperation(inst), d)
        qubits = [qtargets[i] for i in getqubits(inst)]
        bits = [ctargets[i] for i in getbits(inst)]
        push!(circ, op, qubits..., bits...)
    end
    return circ
end

(decl::GateDecl)(args...) = GateCall(decl, args...)

function Base.show(io::IO, d::GateDecl)
    compact = get(io, :compact, false)
    rows, _ = displaysize(io)
    n = length(d.instructions)
    if !compact
        print(io, "gate ", d.name, "(")
        join(io, d.arguments, ",")
        println(io, ") =")

        if rows - 4 <= 0
            print(io, "└── ...")
        elseif rows - 4 >= n
            for g in d.instructions[1:end-1]
                println(io, "├── ", g)
            end
            print(io, "└── ", d.instructions[end])
        else
            chunksize = div(rows - 6, 2)

            for g in d.instructions[1:chunksize]
                println(io, "├── ", g)
            end

            println(io, "⋮   ⋮")

            for g in d.instructions[end-chunksize:end-1]
                println(io, "├── ", g)
            end

            print(io, "└── ", d.instructions[end])
        end
    else
        print(io, "gate ", d.name, "(")
        join(io, d.arguments, ",")
        println(io, ")")
    end

    nothing
end

function Base.show(io::IO, g::GateCall)
    print(io, g._decl.name)
    if numparams(g) != 0
        print(io, '(')
        join(io, g._args, ",")
        print(io, ')')
    end
end

