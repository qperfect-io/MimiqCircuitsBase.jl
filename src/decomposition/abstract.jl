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

# --- RewriteRule — single-step transformations ---

"""
    RewriteRule

Abstract type for single-step rewrite rules that transform one operation into
a sequence of simpler operations.

A `RewriteRule` defines *how* to transform an operation, but not *when* to stop.
For recursive decomposition to a target set of operations, see [`DecompositionBasis`](@ref).

# Interface

Subtypes must implement:

- [`matches(rule, op)`](@ref): Return `true` if this rule can transform `op`.
- [`decompose_step!(builder, rule, op, qtargets, ctargets, ztargets)`](@ref): 
  Append the transformed instructions to `builder`.

# Examples
```julia
struct MyRewrite <: RewriteRule end

matches(::MyRewrite, ::GateToffoli) = true
matches(::MyRewrite, ::Operation) = false

function decompose_step!(builder, ::MyRewrite, op::GateToffoli, qt, ct, zt)
    # ... append decomposed instructions to builder
    return builder
end
```

See also [`CanonicalRewrite`](@ref), [`DecompositionBasis`](@ref).
"""
abstract type RewriteRule end

"""
    matches(rule::RewriteRule, op::Operation) -> Bool

Return `true` if `rule` can transform operation `op`.

This is used to check whether a rewrite rule is applicable before attempting
decomposition.

# Examples
```julia
matches(CanonicalRewrite(), GateH())  # true if CanonicalRewrite handles GateH
```

See also [`RewriteRule`](@ref), [`decompose_step!`](@ref).
"""
matches(::RewriteRule, ::Operation) = false

"""
    decompose_step!(builder, rule::RewriteRule, op::Operation, qtargets, ctargets, ztargets)

Apply `rule` to transform `op` and append the resulting instructions to `builder`.

This is the low-level interface that each [`RewriteRule`](@ref) must implement
for operations it [`matches`](@ref).

# Arguments

- `builder`: A circuit-like container (e.g., `Circuit`, `Vector{Instruction}`) to append to.
- `rule`: The rewrite rule to apply.
- `op`: The operation to transform.
- `qtargets`: Qubit indices for the operation.
- `ctargets`: Classical bit indices for the operation.
- `ztargets`: Z-variable indices for the operation.

# Returns

The `builder` with decomposed instructions appended.

See also [`RewriteRule`](@ref), [`matches`](@ref), [`decompose_step`](@ref).
"""
function decompose_step!(builder, rule::RewriteRule, op::Operation, qtargets, ctargets, ztargets)
    if matches(rule, op)
        # Programmer error: matches returns true but decompose_step! not implemented
        throw(ErrorException(
            "decompose_step! must be implemented for $(typeof(rule)) to decompose $(typeof(op))."
        ))
    end
    throw(DecompositionError(
        "Operation $(opname(op)) cannot be decomposed by $(typeof(rule))."
    ))
end

# --- DecompositionBasis — recursive decomposition to a target set ---

"""
    DecompositionBasis

Abstract type for decomposition targets that define a set of terminal operations
and how to decompose non-terminal operations.

A `DecompositionBasis` combines two concerns:

1. **What is terminal**: Operations that should not be decomposed further.
2. **How to decompose**: The transformation logic for non-terminal operations.

# Interface

Subtypes must implement:

- [`isterminal(basis, op)`](@ref): Return `true` if `op` is in the target set.
- [`decompose!(builder, basis, op, qtargets, ctargets, ztargets)`](@ref): 
  Append decomposed instructions to `builder` for non-terminal operations.

# Examples

```julia
struct CliffordT <: DecompositionBasis end

# Define terminal operations
isterminal(::CliffordT, ::GateH) = true
isterminal(::CliffordT, ::GateS) = true
isterminal(::CliffordT, ::GateT) = true
isterminal(::CliffordT, ::GateCX) = true
isterminal(::CliffordT, ::Operation) = false

# Define decomposition (can delegate to rewrite rules)
function decompose!(builder, ::CliffordT, op::Operation, qt, ct, zt)
    return decompose_step!(builder, CanonicalRewrite(), op, qt, ct, zt)
end
```

See also [`CanonicalBasis`](@ref), [`RewriteRule`](@ref), [`decompose`](@ref).
"""
abstract type DecompositionBasis end

"""
    isterminal(basis::DecompositionBasis, op::Operation) -> Bool

Return `true` if `op` is terminal in the given `basis`.

Terminal operations are not decomposed further—they represent the target
instruction set that [`decompose`](@ref) reduces circuits to.

# Examples

```julia
isterminal(CanonicalBasis(), GateU())   # true
isterminal(CanonicalBasis(), GateH())   # false (will be decomposed)
```

See also [`DecompositionBasis`](@ref), [`decompose`](@ref).
"""
isterminal(::DecompositionBasis, ::Operation) = false

# --- ancilla options and decomposition context ---

# Ancilla options of a basis. Every basis that supports them stores one and
# returns it from `_ancillaoptions`; the others use the defaults, which keep
# every decomposition inside the targets of the operation it decomposes.
struct _AncillaOptions
    borrow::Bool
    max_ancillas::Int
    allow_measurement::Bool

    function _AncillaOptions(borrow::Bool, max_ancillas::Integer, allow_measurement::Bool)
        max_ancillas >= 0 || throw(ArgumentError("max_ancillas must be non-negative, got $max_ancillas"))
        return new(borrow, max_ancillas, allow_measurement)
    end
end

_AncillaOptions(; borrow::Bool=false, max_ancillas::Integer=0, allow_measurement::Bool=false) = _AncillaOptions(borrow, max_ancillas, allow_measurement)

_ancillaoptions(::DecompositionBasis) = _AncillaOptions()

# Clean ancillas handed out while a circuit is decomposed. The iterator keeps
# it up to date as instructions stream out: `AncillaAlloc` raises the window
# depth of its qubit and `AncillaFree` lowers it. A qubit whose depth drops to
# 0 is free, and stays free until an instruction touches it. Qubits a rule
# takes leave the free list at once, before their `AncillaAlloc` is streamed.
mutable struct _AncillaAllocator
    next::Int
    remaining::Int
    depth::Dict{Int,Int}
    free::Vector{Int}
end

_AncillaAllocator(next::Integer, remaining::Integer) = _AncillaAllocator(next, remaining, Dict{Int,Int}(), Int[])

_available(alloc::_AncillaAllocator) = length(alloc.free) + alloc.remaining

# Take up to `k` clean ancillas: free ones first, lowest index first, then new
# ones numbered after the circuit.
function _take_clean!(alloc::_AncillaAllocator, k::Integer)
    taken = Int[]
    sort!(alloc.free)
    while length(taken) < k && !isempty(alloc.free)
        push!(taken, popfirst!(alloc.free))
    end
    while length(taken) < k && alloc.remaining > 0
        push!(taken, alloc.next)
        alloc.next += 1
        alloc.remaining -= 1
    end
    return taken
end

"""
    DecompositionContext(; nqubits=0, borrow=false, unitary_only=false)

State that [`decompose`](@ref) hands to a basis and its rules, next to the
operation and its targets.

- `nqubits`: width of the circuit being decomposed. Qubits `1:nqubits` that
  are not targets of the operation may be borrowed. `0` means the width is
  unknown, and nothing is borrowed.
- `borrow`: whether rules may borrow qubits outside the operation's targets.
  A borrowed qubit can be in any state; the decomposition acts as the
  identity on it.
- `unitary_only`: set when the result must be unitary, as for the body of a
  wrapped `GateDecl` or of an `IfStatement`.

[`decompose`](@ref) also hands out clean ancillas through the context when
the basis has `max_ancillas > 0`. A rule that takes them brackets their use
with [`AncillaAlloc`](@ref) and [`AncillaFree`](@ref) and returns them in
``|0⟩``. With `allow_measurement=true` on the basis, the context also holds
a classical bit, numbered after those of the circuit, that rules may measure
an ancilla into.

Bases and rules that do not use the context receive it through the
fallback methods of [`decompose!`](@ref) and [`decompose_step!`](@ref),
which drop it and call the 6-argument form.
"""
struct DecompositionContext
    nqubits::Int
    borrow::Bool
    unitary_only::Bool
    allocator::Union{Nothing,_AncillaAllocator}
    # Bit that measuring rules write to, or 0 when they may not measure.
    bit::Int
end

function DecompositionContext(; nqubits::Integer=0, borrow::Bool=false, unitary_only::Bool=false)
    nqubits >= 0 || throw(ArgumentError("nqubits must be non-negative, got $nqubits"))
    return DecompositionContext(nqubits, borrow, unitary_only, nothing, 0)
end

const _NO_CONTEXT = DecompositionContext()

# The context for a circuit `nqubits` wide with `nbits` bits. Clean ancillas
# and the measured bit are numbered after them, so a circuit of unknown width
# gets none.
function DecompositionContext(basis::DecompositionBasis, nqubits::Integer, nbits::Integer=0)
    opts = _ancillaoptions(basis)
    alloc = (opts.max_ancillas > 0 && nqubits > 0) ? _AncillaAllocator(nqubits + 1, opts.max_ancillas) : nothing
    bit = (opts.allow_measurement && nbits > 0) ? nbits + 1 : 0
    return DecompositionContext(nqubits, opts.borrow, false, alloc, bit)
end

# The same context for a result that must be unitary.
_unitary(ctx::DecompositionContext) = DecompositionContext(ctx.nqubits, ctx.borrow, true, ctx.allocator, ctx.bit)

_can_measure(ctx::DecompositionContext) = ctx.bit > 0 && !ctx.unitary_only

_available(ctx::DecompositionContext) = isnothing(ctx.allocator) ? 0 : _available(ctx.allocator)

_take_clean!(ctx::DecompositionContext, k::Integer) = isnothing(ctx.allocator) || k <= 0 ? Int[] : _take_clean!(ctx.allocator, k)

# Bases and rules that do not use the context keep their 6-argument method.
function decompose!(builder, basis::DecompositionBasis, op::Operation, qtargets, ctargets, ztargets, ::DecompositionContext)
    return decompose!(builder, basis, op, qtargets, ctargets, ztargets)
end

function decompose_step!(builder, rule::RewriteRule, op::Operation, qtargets, ctargets, ztargets, ::DecompositionContext)
    return decompose_step!(builder, rule, op, qtargets, ctargets, ztargets)
end

# Qubits a rule may borrow for an operation on `qtargets`, at most `k`,
# nearest to the targets first so that MPS chains stay local.
function _borrowable(ctx::DecompositionContext, qtargets, k::Integer)
    (ctx.borrow && k > 0) || return Int[]
    targets = Set(qtargets)
    free = [q for q in 1:ctx.nqubits if !(q in targets)]
    sort!(free; by=q -> (minimum(t -> abs(q - t), qtargets), q))
    return free[1:min(k, length(free))]
end
