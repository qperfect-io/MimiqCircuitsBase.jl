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

# --- decomposition iterator ---

# Cache for wrapped declarations to reuse identical decompositions. The key is
# the (symbolic) operation, the numbers of borrowed and clean qubits its body
# was offered, and whether it may measure: a measuring body is a BlockDecl and
# must not be reused where only unitaries are allowed.
const WrappedDeclCache = Dict{Tuple{Operation,Int,Int,Bool},Union{GateDecl,BlockDecl}}

"""
    DecomposeIterator(source, basis; wrap=false, cache=nothing, nqubits)

An iterator that yields instructions from recursive decomposition of `source`
to the given `basis`. Performs depth-first decomposition.
The `basis` argument can be a [`DecompositionBasis`](@ref) or a [`RewriteRule`](@ref).

If `wrap=true`, non-terminal operations are wrapped, rather than flattened, into a
`GateDecl` (for gates) or a `Block` (for other operations, such as `MeasureReset`)
holding their full decomposition. A gate whose decomposition measures an
ancilla (`allow_measurement=true`) becomes a `BlockDecl` instead of a `GateDecl`. Gates inside a `Block` are wrapped as well.

If `cache` is provided (a `WrappedDeclCache`), wrapped declarations will be
cached and reused when the same operation is encountered again.

`nqubits` is the width of the circuit, which bounds the qubits a basis with
`borrow=true` may borrow. It defaults to `numqubits(source)` for a `Circuit`
and to `0` (borrow nothing) for anything else, so the result never depends
on the values of the target indices alone.

Throws an `ArgumentError` if the basis borrows qubits and `source` contains
`Loss` or `Reload`: losses act on qubits a borrowing decomposition relies on.
Resolve them first, for example with [`lower_losses`](@ref).

See also [`eachdecomposed`](@ref), [`decompose`](@ref).
"""
struct DecomposeIterator{B<:DecompositionBasis}
    stack::Vector{Instruction}
    buffer::Vector{Instruction}
    ready::Vector{Instruction}
    basis::B
    wrap::Bool
    cache::Union{Nothing,WrappedDeclCache}
    ctx::DecompositionContext
end

_to_basis(b::DecompositionBasis) = b
_to_basis(r::RewriteRule) = RuleBasis(r)

_haslosses(::Operation) = false
_haslosses(::Union{Loss,Reload}) = true
_haslosses(op::Union{IfStatement,WhileStatement,Repeat}) = _haslosses(op.op)
_haslosses(op::Block) = any(inst -> _haslosses(getoperation(inst)), op._instructions)
_haslosses(op::BlockCall) = any(inst -> _haslosses(getoperation(inst)), op._decl._instructions)

function DecomposeIterator(insts::AbstractVector, basis::Union{DecompositionBasis,RewriteRule}; wrap::Bool=false, cache::Union{Nothing,WrappedDeclCache}=nothing, nqubits::Integer=0, nbits::Integer=0, ctx::Union{Nothing,DecompositionContext}=nothing)
    basis = _to_basis(basis)
    if isnothing(ctx)
        ctx = DecompositionContext(basis, nqubits, nbits)
        if ctx.borrow && any(inst -> _haslosses(getoperation(inst)), insts)
            throw(ArgumentError("cannot borrow qubits in a circuit with Loss or Reload; resolve the losses first, for example with lower_losses"))
        end
    end
    return DecomposeIterator(reverse(collect(Instruction, insts)), Instruction[], Instruction[], basis, wrap, cache, ctx)
end

function DecomposeIterator(inst::Instruction, basis::Union{DecompositionBasis,RewriteRule}; kwargs...)
    return DecomposeIterator(Instruction[inst], basis; kwargs...)
end

function DecomposeIterator(c::Circuit, basis::Union{DecompositionBasis,RewriteRule}; nqubits::Integer=numqubits(c), nbits::Integer=numbits(c), kwargs...)
    nbits = max(nbits, numbits(c))
    if _ancillaoptions(_to_basis(basis)).allow_measurement && nbits == 0
        # Such a circuit is sampled on all its qubits; a measured ancilla bit
        # would make it sampled on that bit alone.
        throw(ArgumentError("allow_measurement needs a circuit with classical bits"))
    end
    return DecomposeIterator(c._instructions, basis; nqubits=max(nqubits, numqubits(c)), nbits=nbits, kwargs...)
end

function DecomposeIterator(op::Operation{N,M,L}, basis::Union{DecompositionBasis,RewriteRule}; kwargs...) where {N,M,L}
    inst = Instruction(op, Tuple(1:N), Tuple(1:M), Tuple(1:L))
    return DecomposeIterator(inst, basis; kwargs...)
end

Base.IteratorSize(::Type{<:DecomposeIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{<:DecomposeIterator}) = Base.HasEltype()
Base.eltype(::Type{<:DecomposeIterator}) = Instruction

function Base.iterate(it::DecomposeIterator, state=nothing)
    while true
        # Wrapped calls come with their ancilla markers, queued here.
        isempty(it.ready) || return _emit!(it, pop!(it.ready)), nothing

        isempty(it.stack) && return nothing
        inst = pop!(it.stack)
        op = getoperation(inst)

        if isterminal(it.basis, op)
            return _emit!(it, inst), nothing
        end

        if it.wrap
            append!(it.ready, reverse(_wrap_decomposition(inst, it.basis, it.cache, it.ctx)))
            continue
        end

        # Flatten mode: decompose and push onto stack
        empty!(it.buffer)
        decompose!(it.buffer, it.basis, op, getqubits(inst), getbits(inst), getztargets(inst), it.ctx)

        # Reverse onto stack to maintain order (DFS)
        append!(it.stack, reverse(it.buffer))
    end
end

function _emit!(it::DecomposeIterator, inst::Instruction)
    _track!(it.ctx.allocator, inst)
    return inst
end

_track!(::Nothing, ::Instruction) = nothing

function _track!(alloc::_AncillaAllocator, inst::Instruction)
    op = getoperation(inst)
    if op isa AncillaAlloc
        q = getqubit(inst, 1)
        alloc.depth[q] = get(alloc.depth, q, 0) + 1
        filter!(!=(q), alloc.free)
    elseif op isa AncillaFree
        q = getqubit(inst, 1)
        d = get(alloc.depth, q, 0) - 1
        if d > 0
            alloc.depth[q] = d
        else
            delete!(alloc.depth, q)
            q in alloc.free || push!(alloc.free, q)
        end
    else
        # A qubit touched after it was freed is no longer known to be in |0⟩.
        for q in getqubits(inst)
            filter!(!=(q), alloc.free)
        end
    end
    return nothing
end

function _relax_wrapper_type(T::Type)
    # If T has no parameters, return T directly
    if isempty(T.parameters)
        return T
    end

    # Handle specific wrappers that forward arguments to their inner type
    if T <: Control
        # Control{N,M,L,T}
        N, M, L, InnerT = T.parameters
        return Control{N,M,L,Base.typename(InnerT).wrapper}
    elseif T <: Inverse
        # Inverse{N,T}
        N, InnerT = T.parameters
        return Inverse{N,Base.typename(InnerT).wrapper}
    elseif T <: Power
        # Power{P,N,T}
        P, N, InnerT = T.parameters
        return Power{P,N,Base.typename(InnerT).wrapper}
    end

    # Default: return the wrapper (e.g. GateRX)
    return Base.typename(T).wrapper
end

function _wrap_decomposition(inst::Instruction, basis::DecompositionBasis, cache::Union{Nothing,WrappedDeclCache}, ctx::DecompositionContext)
    op = getoperation(inst)

    # For gates, we try to canonicalize parametric gates to reuse the same GateDecl
    # e.g. GateRX(0.1) and GateRX(0.2) should both use the same GateDecl(GateRX(θ))
    sym_op = nothing
    sym_nums = nothing
    sym_op_params = nothing
    original_params = nothing

    if op isa AbstractGate && numparams(op) > 0
        if op isa GateCall
            # Special handling for GateCall:
            # - parameters are the arguments in `op._args`
            # - parnames returns fields (:_decl, :_args), which is not what we want
            # - constructor is GateCall(decl, args...)

            # Generate symbolic variables for arguments
            sym_nums = [Symbolics.variable(Symbol("arg$i")) for i in 1:numparams(op)]

            try
                # Reconstruct symbolic GateCall
                # GateCall(decl, args...)
                sym_op = GateCall(op._decl, sym_nums...)
                sym_op_params = sym_nums
                original_params = op._args
            catch
                sym_op = nothing
                sym_nums = nothing
            end
        else
            # Standard parametric gates AND Wrappers (Control, Inverse, Power)
            pnames = parnames(op)
            sym_nums = [Symbolics.variable(name) for name in pnames]

            try
                # Use helper to relax the wrapper type (strip concrete inner types)
                constructor = _relax_wrapper_type(typeof(op))
                sym_op = constructor(sym_nums...)
                sym_op_params = sym_nums
                original_params = getparams(op)
            catch
                sym_op = nothing
                sym_nums = nothing
            end
        end
    end

    # The operation we use for caching and decomposition
    # If successful, this is the symbolic version; otherwise the original concrete one
    target_op = (sym_op !== nothing) ? sym_op : op

    nq = numqubits(op)
    nb = numbits(op)
    nz = numzvars(op)

    # A gate body is built on targets 1:nq, followed by nb slots for the qubits
    # it may borrow and nc slots for clean ancillas. The borrowable qubits are
    # nearest-first in both frames, so slot nq+j stands for borrowable[j] at this
    # call site. Clean ancillas are taken at the call site once the body has
    # said how many it uses.
    isgate = op isa AbstractGate
    borrowable = isgate ? _borrowable(ctx, getqubits(inst), typemax(Int)) : Int[]
    nborrow = length(borrowable)
    nclean = (isgate && !isnothing(ctx.allocator)) ? _available(ctx.allocator) : 0
    # Only the rule that decomposes the operation itself gets clean ancillas;
    # the operations it produces are wrapped with none. With measurements
    # allowed, its body may measure into bit 1, the bit of the call site.
    measure = isgate && nclean > 0 && _can_measure(ctx)
    key = (target_op, nborrow, nclean, measure)

    # Call `op` on the data qubits, the first `nextra - L` borrowable ones and
    # `L` clean ancillas taken now, which the call-site markers bracket.
    function call(op, nextra, L, bits=getbits(inst))
        clean = _take_clean!(ctx, L)
        qubits = (getqubits(inst)..., borrowable[1:nextra-L]..., clean...)
        return Instruction[
            (Instruction(AncillaAlloc(), (q,), (), ()) for q in clean)...,
            Instruction(op, qubits, bits, getztargets(inst)),
            (Instruction(AncillaFree(), (q,), (), ()) for q in clean)...,
        ]
    end
    args = (sym_op !== nothing) ? original_params : ()
    call(decl::GateDecl{M}) where {M} = call(decl(args...), M - nq, numancillas(decl))
    call(decl::BlockDecl) = call(decl(args...), numqubits(decl) - nq, numancillas(decl), (ctx.bit,))

    # Check cache first
    if isgate && cache !== nothing
        cached_decl = get(cache, key, nothing)
        if cached_decl !== nothing
            # If we found a generic decl, we call it with original parameters
            return call(cached_decl)
        end
    end

    bodyalloc = nclean > 0 ? _AncillaAllocator(nq + nborrow + 1, nclean) : nothing
    bodyctx = DecompositionContext(nq + nborrow, ctx.borrow, isgate && !measure, bodyalloc, measure ? 1 : 0)
    innerctx = DecompositionContext(nq + nborrow, ctx.borrow, isgate, nothing, 0)

    # Do ONE step of decomposition with canonical targets (1:N)
    buffer = Instruction[]
    decompose!(buffer, basis, target_op, Tuple(1:nq), Tuple(1:nb), Tuple(1:nz), bodyctx)

    # Now iterate over results with wrap=true to preserve nested structure
    # Pass the cache through so nested operations can also be cached/reused.
    # Declaration bodies carry no ancilla markers: the call site has them.
    inner_circuit = Circuit()
    for sub_inst in buffer
        for final_inst in DecomposeIterator(sub_inst, basis; wrap=true, cache=cache, ctx=innerctx)
            getoperation(final_inst) isa Union{AncillaAlloc,AncillaFree} && continue
            push!(inner_circuit, final_inst)
        end
    end

    isgate || return call(Block(nq, nb, nz, inner_circuit._instructions), 0, 0)

    body, L = _compact_extra(inner_circuit._instructions, nq, nq + nborrow)

    decl_name = _wrapped_decl_name(op)

    # Args for the declaration must be unwrapped symbolic variables (BasicSymbolic)
    decl_args = (sym_op !== nothing) ? Tuple(Symbolics.value.(sym_op_params)) : ()

    # A body that measures cannot be a GateDecl; it becomes a BlockDecl whose
    # bit is the measured bit of the call site.
    decl = if all(inst -> getoperation(inst) isa AbstractGate, body)
        GateDecl(decl_name, decl_args, body; numancillas=L)
    else
        BlockDecl(decl_name, decl_args, body; numancillas=L)
    end
    # Store in cache for future reuse
    if cache !== nothing
        cache[key] = decl
    end

    # Return call with original parameters
    return call(decl)
end

# Renumber the extra qubits a body used, keeping their order: the borrowed
# slots (from nq+1 to nqb) first, then the clean ones (above nqb). The
# declaration is then only as wide as what it touches, with its clean
# ancillas last. Returns the body and the number of clean ancillas.
function _compact_extra(insts, nq, nqb)
    used = sort!(unique(q for inst in insts for q in getqubits(inst) if q > nq))
    remap = Dict(u => nq + i for (i, u) in enumerate(used))
    renumber(q) = get(remap, q, q)
    body = [Instruction(getoperation(inst), map(renumber, getqubits(inst)), getbits(inst), getztargets(inst)) for inst in insts]
    return body, count(>(nqb), used)
end

# Helper to generate meaningful names for wrapped GateDecls
function _wrapped_decl_name(op::Operation)
    return Symbol("MIMIQ_$(opname(typeof(op)))")
end

function _wrapped_decl_name(op::GateCall)
    return Symbol("MIMIQ_$(op._decl.name)")
end

function _wrapped_decl_name(op::Inverse{N,<:GateCall}) where {N}
    return Symbol("MIMIQ_$(getoperation(op)._decl.name)_dagger")
end

"""
    eachdecomposed(source; basis=CanonicalBasis(), wrap=false, cache=nothing)

Return an iterator over instructions resulting from decomposing `source` to the
given `basis`. The `basis` can be a [`DecompositionBasis`](@ref) or [`RewriteRule`](@ref).

This is memory-efficient for large circuits as it doesn't materialize the full
decomposed circuit at once.

If `wrap=true`, non-terminal operations are wrapped, rather than flattened, into a
`GateDecl` (for gates) or a `Block` (for other operations) holding their
decomposition.

If `cache` is provided (a `Dict{Operation,GateDecl}`), wrapped GateDecls will be
cached and reused when the same operation is encountered again.

# Examples
```julia
for inst in eachdecomposed(circuit)
    # process each primitive instruction
end

# Collect into a vector
insts = collect(eachdecomposed(circuit))
```

See also [`decompose`](@ref), [`DecomposeIterator`](@ref).
"""
function eachdecomposed(source; basis::Union{DecompositionBasis,RewriteRule}=CanonicalBasis(), wrap::Bool=false, cache::Union{Nothing,WrappedDeclCache}=nothing)
    return DecomposeIterator(source, _to_basis(basis); wrap=wrap, cache=cache)
end

# --- decompose — recursive decomposition to a basis ---

"""
    decompose(source; basis=CanonicalBasis(), wrap=false)::Circuit

Recursively decompose `source` until all operations are terminal in the given `basis`.

The `basis` argument can be a [`DecompositionBasis`](@ref) or a [`RewriteRule`](@ref).
If a rewrite rule is provided, it is applied recursively.

If `wrap=true`, non-terminal gates are wrapped into a `GateDecl` holding their
decomposition, and identical gates share the same `GateDecl`. Other non-terminal
operations, such as `MeasureReset` or `MeasurePauli`, are wrapped into a `Block`
holding their decomposition, whose gates are wrapped in turn.

# Examples
```julia
# Decompose to primitive operations (CX, U, Measure, Reset, ...)
decompose(circuit)

# Decompose to Clifford+T
decompose(circuit; basis=CliffordT())

# Keep structure with wrapped declarations
decompose(circuit; wrap=true)
```

See also [`decompose!`](@ref), [`decompose_step`](@ref), [`eachdecomposed`](@ref).
"""
function decompose(source; basis::Union{DecompositionBasis,RewriteRule}=CanonicalBasis(), wrap::Bool=false)
    return decompose!(Circuit(), source; basis=basis, wrap=wrap)
end

"""
    decompose!(circuit, source; basis=CanonicalBasis(), wrap=false)

Recursively decompose `source` to the given `basis` and append results to `circuit`.
The `basis` argument can be a [`DecompositionBasis`](@ref) or a [`RewriteRule`](@ref).
When `source` is a `Circuit`, clean ancillas and the measured bit are numbered
after the qubits and bits of both `circuit` and `source`.

    decompose!(circuit, basis, op, qtargets, ctargets, ztargets)

Low-level interface for defining how an `OperationBasis` decomposes a specific
operation. Implement this method to customize decomposition behavior for your basis.

See also [`decompose`](@ref), [`isterminal`](@ref).
"""
function decompose! end

function decompose!(c::Circuit, source; basis::Union{DecompositionBasis,RewriteRule}=CanonicalBasis(), wrap::Bool=false)
    basis = _to_basis(basis)
    # Create cache when wrapping to reuse identical GateDecls
    cache = wrap ? WrappedDeclCache() : nothing
    # Ancillas and the measured bit go after the qubits and bits of `c` too,
    # so that they never land on ones `c` already uses.
    width = source isa Circuit ? (nqubits=numqubits(c), nbits=numbits(c)) : (;)
    for inst in DecomposeIterator(source, basis; wrap=wrap, cache=cache, width...)
        push!(c, inst)
    end
    return c
end


