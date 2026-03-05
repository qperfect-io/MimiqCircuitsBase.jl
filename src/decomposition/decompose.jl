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

# Cache for wrapped GateDecls to reuse identical decompositions
const WrappedDeclCache = Dict{Operation,GateDecl}

"""
    DecomposeIterator(source, basis; wrap=false, cache=nothing)

An iterator that yields instructions from recursive decomposition of `source`
to the given `basis`. Performs depth-first decomposition.
The `basis` argument can be a [`DecompositionBasis`](@ref) or a [`RewriteRule`](@ref).

If `wrap=true`, non-terminal operations will be wrapped into `GateDecl` (for gates)
or `Block` (for others) containing the full decomposition, rather than being flattened.

If `cache` is provided (a `Dict{Operation,GateDecl}`), wrapped GateDecls will be
cached and reused when the same operation is encountered again.

See also [`eachdecomposed`](@ref), [`decompose`](@ref).
"""
struct DecomposeIterator{B<:DecompositionBasis}
    stack::Vector{Instruction}
    buffer::Vector{Instruction}
    basis::B
    wrap::Bool
    cache::Union{Nothing,WrappedDeclCache}
end

_to_basis(b::DecompositionBasis) = b
_to_basis(r::RewriteRule) = RuleBasis(r)

function DecomposeIterator(inst::Instruction, basis::Union{DecompositionBasis,RewriteRule}; wrap::Bool=false, cache::Union{Nothing,WrappedDeclCache}=nothing)
    return DecomposeIterator(Instruction[inst], Instruction[], _to_basis(basis), wrap, cache)
end

function DecomposeIterator(insts::AbstractVector, basis::Union{DecompositionBasis,RewriteRule}; wrap::Bool=false, cache::Union{Nothing,WrappedDeclCache}=nothing)
    return DecomposeIterator(reverse(collect(insts)), Instruction[], _to_basis(basis), wrap, cache)
end

function DecomposeIterator(c::Circuit, basis::Union{DecompositionBasis,RewriteRule}; wrap::Bool=false, cache::Union{Nothing,WrappedDeclCache}=nothing)
    return DecomposeIterator(reverse(c._instructions), Instruction[], _to_basis(basis), wrap, cache)
end

function DecomposeIterator(op::Operation{N,M,L}, basis::Union{DecompositionBasis,RewriteRule}; wrap::Bool=false, cache::Union{Nothing,WrappedDeclCache}=nothing) where {N,M,L}
    inst = Instruction(op, Tuple(1:N), Tuple(1:M), Tuple(1:L))
    return DecomposeIterator(inst, basis; wrap=wrap, cache=cache)
end

Base.IteratorSize(::Type{<:DecomposeIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{<:DecomposeIterator}) = Base.HasEltype()
Base.eltype(::Type{<:DecomposeIterator}) = Instruction

function Base.iterate(it::DecomposeIterator, state=nothing)
    while !isempty(it.stack)
        inst = pop!(it.stack)
        op = getoperation(inst)

        if isterminal(it.basis, op)
            return inst, nothing
        end

        if it.wrap
            wrapped = _wrap_decomposition(inst, it.basis, it.cache)
            return wrapped, nothing
        end

        # Flatten mode: decompose and push onto stack
        empty!(it.buffer)
        decompose!(it.buffer, it.basis, op, getqubits(inst), getbits(inst), getztargets(inst))

        # Reverse onto stack to maintain order (DFS)
        append!(it.stack, reverse(it.buffer))
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

function _wrap_decomposition(inst::Instruction, basis::DecompositionBasis, cache::Union{Nothing,WrappedDeclCache})
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

    # Check cache first
    if op isa AbstractGate && cache !== nothing
        cached_decl = get(cache, target_op, nothing)
        if cached_decl !== nothing
            # If we found a generic decl, we call it with original parameters
            args = (sym_op !== nothing) ? original_params : ()
            return Instruction(cached_decl(args...), getqubits(inst), getbits(inst), getztargets(inst))
        end
    end

    nq = numqubits(op)
    nb = numbits(op)
    nz = numzvars(op)

    # Do ONE step of decomposition with canonical targets (1:N)
    buffer = Instruction[]
    decompose!(buffer, basis, target_op, Tuple(1:nq), Tuple(1:nb), Tuple(1:nz))

    # Now iterate over results with wrap=true to preserve nested structure
    # Pass the cache through so nested operations can also be cached/reused
    inner_circuit = Circuit()
    for sub_inst in buffer
        for final_inst in DecomposeIterator(sub_inst, basis; wrap=true, cache=cache)
            push!(inner_circuit, final_inst)
        end
    end

    if op isa AbstractGate
        decl_name = _wrapped_decl_name(op)

        # Args for GateDecl must be unwrapped symbolic variables (BasicSymbolic)
        decl_args = (sym_op !== nothing) ? Tuple(Symbolics.value.(sym_op_params)) : ()

        decl = GateDecl(decl_name, decl_args, inner_circuit._instructions)
        # Store in cache for future reuse
        if cache !== nothing
            cache[target_op] = decl
        end

        # Return call with original parameters
        call_args = (sym_op !== nothing) ? original_params : ()
        return Instruction(decl(call_args...), getqubits(inst), getbits(inst), getztargets(inst))
    else
        b = Block(nq, nb, nz)
        append!(b, inner_circuit)
        return Instruction(b, getqubits(inst), getbits(inst), getztargets(inst))
    end
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

If `wrap=true`, non-terminal operations will be wrapped into `GateDecl` or `Block`
containing their decomposition, rather than being flattened.

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

If `wrap=true`, non-terminal operations will be wrapped into `GateDecl` or `Block`
containing their decomposition. Identical operations will share the same GateDecl.

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
    for inst in DecomposeIterator(source, basis; wrap=wrap, cache=cache)
        push!(c, inst)
    end
    return c
end


