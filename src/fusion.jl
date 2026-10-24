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

# Clustering gate-fusion pass.
#
# Replaces runs of fusible unitary gates spanning ≤ `max_support` qubits with a
# single `GateCustom` whose matrix is the ordered product of the run.
# Boundaries (measurements, resets, noise channels, control flow, barriers, and
# anything without a concrete numeric unitary) are emitted verbatim and are
# never fused across on a shared wire.
#
# Runs that are diagonal in the computational basis get their own, usually
# wider, budget `max_diagonal_support` and collapse into a `GateCustomDiagonal`:
# composing two diagonals is an elementwise product of `2^k` entries, so both the
# block and the work to build it stay linear in the state size rather than
# quadratic. A cluster keeps that budget only while every member is diagonal;
# absorbing one dense gate drops it back to `max_support`.
#
# Clusters grow by absorbing the clusters that own a gate's wires. Merging is
# what makes `max_support` above two useful: on an entangling circuit every
# wire is owned after the first layer, so a gate that could only ever extend a
# single cluster would start a fresh one every time.
#
# Merging two clusters is only sound when nothing outside them sits in between,
# otherwise the contracted DAG gains a cycle and the circuit cannot be
# reordered. The `isopen` flag is what keeps that safe: see `seal!` below.

# Off-diagonal weight below this is dropped when a gate is classified as
# diagonal: a fused block accumulates rounding noise where the exact gate has
# zeros, and refusing to see those gates as diagonal would make fusion depend on
# the last bits of the mantissa.
const _DIAGONAL_ATOL = 1e-12

_isdiagonalmatrix(M) =
    all(abs(M[i, j]) <= _DIAGONAL_ATOL for i in axes(M, 1), j in axes(M, 2) if i != j)

# What a single instruction contributes to a cluster: its numeric diagonal if it
# is diagonal in the computational basis, its numeric matrix if it is not, and
# `nothing` if it cannot be fused at all (a boundary).
#
# Requiring `AbstractGate` already excludes
# Barrier/Measure/Reset/AbstractKrausChannel/If/While (none subtype it), so we
# don't rely on `isunitary` alone — Barrier reports unitary but isn't a gate.
# Gates with symbolic parameters have no numeric matrix and are boundaries too.
function _fusiondata(inst::Instruction, max_support::Int, max_diagonal_support::Int)
    op = getoperation(inst)
    op isa AbstractGate || return nothing
    isunitary(typeof(op)) || return nothing
    nq = numqubits(op)
    nq <= max(max_support, max_diagonal_support) || return nothing

    # Densifying a wide `GateCustomDiagonal` just to notice it is diagonal would
    # defeat the point of storing it as a diagonal in the first place.
    if op isa GateCustomDiagonal
        issymbolic(op) && return nothing
        return nq <= max_diagonal_support ? ComplexF64.(unwrappeddiagonal(op)) : nothing
    end

    M = try
        matrix(op)
    catch
        return nothing          # no concrete matrix ⇒ treat as a boundary
    end
    any(issymbolic, M) && return nothing

    U = ComplexF64.(unwrapvalue.(M))
    if _isdiagonalmatrix(U) && nq <= max_diagonal_support
        return diag(U)
    end
    return nq <= max_support ? U : nothing
end

_isdiagonaldata(data) = data isa AbstractVector

# Dense matrix for a cluster: re-express each member on its local position
# within the sorted support `S`, then compose in circuit order (later gate on
# the left), embedding each to the k-qubit space with k = |S|.
#
# Folds in `ComplexF64` rather than going through
# `matrix(::Vector{Instruction})`, whose contract is to return `Complex{Num}`:
# `_fusiondata` has already established that every member has a concrete numeric
# matrix, and `GateCustom` converts the result on construction anyway.
function _synthesize(c::Circuit, members::Vector{Int}, S::Vector{Int})
    localinsts = map(sort(members)) do i
        inst = c[i]
        lq = map(q -> findfirst(==(q), S), getqubits(inst))
        Instruction(getoperation(inst), lq...)
    end
    N = length(S)
    return _foldmatrices(map(inst -> matrix(inst, N), localinsts), N, ComplexF64)
end

# Diagonal counterpart of `_synthesize`: diagonals compose elementwise, so the
# cluster's diagonal is the product of its members', each read at the entry its
# own targets select. Order is irrelevant here — diagonal gates commute — but
# members are walked in circuit order anyway.
#
# `S` is sorted and the first qubit of a target list is the most significant bit,
# so the qubit `S[p]` contributes bit `k - p` of the cluster index.
function _synthesize_diagonal(c::Circuit, members::Vector{Int}, S::Vector{Int}, data::Dict{Int,Vector{ComplexF64}})
    k = length(S)
    d = ones(ComplexF64, 1 << k)
    for i in sort(members)
        gd = data[i]
        shifts = map(q -> k - findfirst(==(q), S), getqubits(c[i]))
        for x in 0:(1<<k-1)
            j = 0
            for sh in shifts
                j = (j << 1) | ((x >> sh) & 1)
            end
            d[x+1] *= gd[j+1]
        end
    end
    return d
end

@doc raw"""
    fuse(c::Circuit; max_support::Int=2, max_diagonal_support::Int=max_support) -> Circuit

Fuse runs of unitary gates spanning at most `max_support` qubits into single
[`GateCustom`](@ref) blocks, preserving the circuit's overall unitary exactly.

Raising `max_support` lets a block cover more wires and so emit fewer, wider
blocks. Which gates end up together is decided greedily, so the result is not
guaranteed to be the smallest possible circuit.

Runs where every gate is diagonal in the computational basis are budgeted
separately, by `max_diagonal_support`, and collapse into a
[`GateCustomDiagonal`](@ref) instead: such a block is `2^k` numbers rather than
`4^k`, and it is applied without mixing amplitudes, so it is usually worth
allowing wider than a dense one. A cluster keeps the diagonal budget only while
all of its gates are diagonal — the first dense gate joining it brings it back
under `max_support`.

Non-unitary or opaque operations — measurements, resets, noise channels,
`Barrier`, `IfStatement`/`WhileStatement`, and gates with symbolic parameters —
are emitted unchanged and act as fusion boundaries: no gate fuses across one on
a shared wire. A cluster of a single gate is emitted as its original
instruction (never rewrapped as `GateCustom{1}`), and qubit indices are never
relabeled.

`max_support` defaults to `2` and `max_diagonal_support` to `max_support`, so
diagonal runs are recognised but not widened unless asked. Emitting
`GateCustom{k}` or `GateCustomDiagonal{k}` for `k > 2` is legal; whether a
backend can apply it is that backend's concern — a backend that has to decompose
the block again is better served by a smaller budget.

## Examples

```jldoctest
julia> c = push!(Circuit(), GateH(), 1);

julia> push!(c, GateCX(), 1, 2);       # H then CX both act on qubits {1, 2}

julia> fused = fuse(c);                 # ... so they collapse into one block

julia> length(fused)
1

julia> getoperation(fused[1]) isa GateCustom
true

julia> d = push!(Circuit(), GateP(0.1), 1);

julia> push!(d, GateCZ(), 1, 2);        # both diagonal, so the block is too

julia> getoperation(fuse(d)[1]) isa GateCustomDiagonal
true
```
"""
function fuse(c::Circuit; max_support::Int=2, max_diagonal_support::Int=max_support)::Circuit
    cl = _fuseclusters(c, max_support, max_diagonal_support)

    out = Circuit()
    for cid in cl.order
        members = cl.members[cid]
        isempty(members) && continue
        if cl.kinds[cid] == :pass || length(members) == 1  # no singleton demotion
            for i in members
                push!(out, c[i])  # verbatim: keeps qubits, bits and zvars intact
            end
        elseif cl.isdiagonal[cid]
            S = sort!(collect(cl.support[cid]))
            d = _synthesize_diagonal(c, sort(members), S, cl.diagonals)
            push!(out, GateCustomDiagonal(d), S...)
        else
            S = sort!(collect(cl.support[cid]))
            push!(out, GateCustom(_synthesize(c, sort(members), S)), S...)
        end
    end
    return out
end

function _fuseclusters(c::Circuit, max_support::Int, max_diagonal_support::Int)
    nq = numqubits(c)
    # Building a gate's matrix is slow next to a lookup, and circuits repeat
    # the same few operations.
    datacache = Dict{Operation,Any}()
    data(i) = get!(() -> _fusiondata(c[i], max_support, max_diagonal_support), datacache,
        getoperation(c[i]))
    return _fuseclusters(length(c), nq, i -> getqubits(c[i]), i -> _dag_qubits(c[i], nq),
        i -> getbits(c[i]), i -> getztargets(c[i]), data, max_support, max_diagonal_support)
end

# The clustering behind `fuse`, shared with the simplification passes. Returns
# the clusters in an order that is a valid circuit order; `members[cid]` are
# the instruction indices of cluster `cid`, empty if it was folded into another.
#
# It works on any sequence of `n` instructions on `nq` qubits, given through
# functions of the instruction index: its `qubits`, the qubits it depends on
# for ordering (`dagqubits`, see `_dag_qubits`), its `bits` and `zvars`, and
# `data`, which decides what can join a cluster: `nothing` for a boundary, a
# vector for a diagonal gate, anything else for a dense one.
# `v`, sorted, with the elements of `qs` added.
function _addsorted!(v::Vector{Int}, qs)
    for q in qs
        i = searchsortedfirst(v, q)
        (i <= length(v) && v[i] == q) || insert!(v, i, q)
    end
    return v
end

function _fuseclusters(n::Int, nq::Int, qubits, dagqubits, bits, zvars, data,
    max_support::Int, max_diagonal_support::Int)

    owner = Dict{Int,Int}()             # qubit -> id of the cluster owning it
    members = Vector{Vector{Int}}()     # cluster id -> instruction indices (ascending)
    support = Vector{Vector{Int}}()     # cluster id -> qubits it spans, sorted
    kinds = Vector{Symbol}()            # cluster id -> :fuse | :pass
    isopen = Vector{Bool}()             # cluster id -> still owns all of its support
    isdiagonal = Vector{Bool}()         # cluster id -> every member is diagonal
    clusterof = Vector{Int}(undef, n)
    diagonals = Dict{Int,Vector{ComplexF64}}()  # instruction index -> its diagonal

    function newcluster!(i, qs, k, dg)
        push!(members, [i])
        push!(support, _addsorted!(Int[], qs))
        push!(kinds, k)
        push!(isopen, k === :fuse)
        push!(isdiagonal, dg)
        return length(members)
    end

    # A cluster stays *open* while it owns every wire it spans, which makes it a
    # sink in the contracted DAG: nothing downstream depends on it yet. Losing a
    # wire to a later instruction gives it a successor, and from then on merging
    # it could close a cycle (`A → X → B` with `X` left outside), so it is
    # sealed for good.
    function seal!(qs)
        for q in qs
            g = get(owner, q, 0)
            g == 0 || (isopen[g] = false)
        end
    end

    # Scratch space, reused from one gate to the next.
    cand, chosen, S = Int[], Int[], Int[]

    for i in 1:n
        d = data(i)
        if isnothing(d)
            # The boundary *owns* every wire it depends on, so a later gate on
            # one of those wires can't fuse back into a cluster that sits before
            # the boundary. A few global observables synchronise the whole
            # register in the DAG, so mirror `_dag_qubits` here.
            dq = dagqubits(i)
            seal!(dq)
            cid = newcluster!(i, collect(qubits(i)), :pass, false)
            for q in dq
                owner[q] = cid
            end
            clusterof[i] = cid
            continue
        end

        qs = qubits(i)
        gdiag = _isdiagonaldata(d)
        gdiag && (diagonals[i] = d)

        # Candidates are the open fusible clusters owning this gate's wires.
        # Merging several of them at once is what lets a cluster grow past two
        # qubits: every one absorbed is an operation removed from the output, so
        # take them cheapest-first to fit as many as the budget allows. A
        # diagonal gate takes diagonal clusters first: absorbing a dense one
        # forfeits `max_diagonal_support` for the whole run.
        empty!(cand)
        for q in qs
            g = get(owner, q, 0)
            g == 0 && continue
            kinds[g] === :fuse && isopen[g] && !(g in cand) && push!(cand, g)
        end
        length(cand) > 1 && sort!(cand; by=g -> (gdiag && !isdiagonal[g], count(q -> !(q in qs), support[g])))

        _addsorted!(empty!(S), qs)
        alldiag = gdiag
        empty!(chosen)
        for g in cand
            nu = length(S) + count(q -> !(q in S), support[g])
            dg = alldiag && isdiagonal[g]
            if nu <= (dg ? max_diagonal_support : max_support)
                _addsorted!(S, support[g])
                alldiag = dg
                push!(chosen, g)
            end
        end

        if isempty(chosen)
            seal!(qs)
            cid = newcluster!(i, collect(qs), :fuse, gdiag)
            for q in qs
                owner[q] = cid
            end
            clusterof[i] = cid
            continue
        end

        # Fold the chosen clusters into the earliest of them. Any other cluster
        # holding one of this gate's wires loses it here, so it is sealed.
        s = minimum(chosen)
        for q in qs
            g = get(owner, q, 0)
            (g == 0 || g in chosen) || (isopen[g] = false)
        end
        for g in chosen
            g == s && continue
            append!(members[s], members[g])
            for j in members[g]
                clusterof[j] = s
            end
            _addsorted!(support[s], support[g])
            empty!(members[g])          # folded away, emits nothing
            empty!(support[g])
        end
        push!(members[s], i)
        _addsorted!(support[s], qs)
        isdiagonal[s] = alldiag
        clusterof[i] = s
        for q in S
            owner[q] = s
        end
    end

    # Contract the instruction DAG by cluster id and topologically sort it: any
    # topological order is a valid, equivalent circuit (independent clusters
    # commute). Merging only sinks keeps every cluster convex, so this is a DAG.
    # The order is Kahn's, taking ready clusters first-in first-out and
    # successors by id.
    nc = length(members)
    cg = SimpleDiGraph(nc)
    lastq, lastb, lastz = Dict{Int,Int}(), Dict{Int,Int}(), Dict{Int,Int}()
    function link!(last, w, i)
        p = get(last, w, 0)
        p == 0 || clusterof[p] == clusterof[i] || add_edge!(cg, clusterof[p], clusterof[i])
        last[w] = i
    end
    for i in 1:n
        foreach(q -> link!(lastq, q, i), dagqubits(i))
        foreach(b -> link!(lastb, b, i), bits(i))
        foreach(z -> link!(lastz, z, i), zvars(i))
    end
    indeg = indegree(cg)
    order = findall(iszero, indeg)
    k = 1
    while k <= length(order)
        for d in sort(outneighbors(cg, order[k]))
            indeg[d] -= 1
            indeg[d] == 0 && push!(order, d)
        end
        k += 1
    end
    return (; order, members, kinds, isdiagonal, support, diagonals)
end
