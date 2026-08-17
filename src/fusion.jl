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
# Clusters grow by absorbing the clusters that own a gate's wires. Merging is
# what makes `max_support` above two useful: on an entangling circuit every
# wire is owned after the first layer, so a gate that could only ever extend a
# single cluster would start a fresh one every time.
#
# Merging two clusters is only sound when nothing outside them sits in between,
# otherwise the contracted DAG gains a cycle and the circuit cannot be
# reordered. The `isopen` flag is what keeps that safe: see `seal!` below.

# An instruction is fusible iff it is a plain unitary gate with a concrete
# numeric matrix on ≤ N qubits. Requiring `AbstractGate` already excludes
# Barrier/Measure/Reset/AbstractKrausChannel/If/While (none subtype it), so we
# don't rely on `isunitary` alone — Barrier reports unitary but isn't a gate.
function _is_fusible(inst::Instruction, N::Int)
    op = getoperation(inst)
    op isa AbstractGate || return false
    numqubits(op) <= N || return false
    isunitary(typeof(op)) || return false
    M = try
        matrix(op)
    catch
        return false            # no concrete matrix ⇒ treat as a boundary
    end
    return !any(issymbolic, M)  # symbolic-parameter gates are boundaries
end

# Dense matrix for a cluster: re-express each member on its local position
# within the sorted support `S`, then compose in circuit order (later gate on
# the left). `matrix(::Vector{Instruction})` embeds each to the k-qubit space
# and folds the product, so k = |S|.
function _synthesize(c::Circuit, members::Vector{Int}, S::Vector{Int})
    localinsts = map(sort(members)) do i
        inst = c[i]
        lq = map(q -> findfirst(==(q), S), getqubits(inst))
        Instruction(getoperation(inst), lq...)
    end
    return matrix(localinsts)
end

@doc raw"""
    fuse(c::Circuit; max_support::Int=2) -> Circuit

Fuse runs of unitary gates spanning at most `max_support` qubits into single
[`GateCustom`](@ref) blocks, preserving the circuit's overall unitary exactly.

Raising `max_support` lets a block cover more wires and so emit fewer, wider
blocks. Which gates end up together is decided greedily, so the result is not
guaranteed to be the smallest possible circuit.

Non-unitary or opaque operations — measurements, resets, noise channels,
`Barrier`, `IfStatement`/`WhileStatement`, and gates with symbolic parameters —
are emitted unchanged and act as fusion boundaries: no gate fuses across one on
a shared wire. A cluster of a single gate is emitted as its original
instruction (never rewrapped as `GateCustom{1}`), and qubit indices are never
relabeled.

`max_support` defaults to `2`. Emitting `GateCustom{k}` for `k > 2` is legal;
whether a backend can apply it is that backend's concern.

## Examples

```jldoctest
julia> c = push!(Circuit(), GateH(), 1);

julia> push!(c, GateCX(), 1, 2);       # H then CX both act on qubits {1, 2}

julia> fused = fuse(c);                 # ... so they collapse into one block

julia> length(fused)
1

julia> getoperation(fused[1]) isa GateCustom
true
```
"""
function fuse(c::Circuit; max_support::Int=2)::Circuit
    n = length(c)
    nq = numqubits(c)

    owner = Dict{Int,Int}()             # qubit -> id of the cluster owning it
    members = Vector{Vector{Int}}()     # cluster id -> instruction indices (ascending)
    support = Vector{Set{Int}}()        # cluster id -> qubits it spans
    kinds = Vector{Symbol}()            # cluster id -> :fuse | :pass
    isopen = Vector{Bool}()             # cluster id -> still owns all of its support
    clusterof = Vector{Int}(undef, n)

    function newcluster!(i, qs, k)
        push!(members, [i])
        push!(support, Set{Int}(qs))
        push!(kinds, k)
        push!(isopen, k === :fuse)
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

    for i in 1:n
        inst = c[i]
        if !_is_fusible(inst, max_support)
            # The boundary *owns* every wire it depends on, so a later gate on
            # one of those wires can't fuse back into a cluster that sits before
            # the boundary. A few global observables synchronise the whole
            # register in the DAG, so mirror `_dag_qubits` here.
            dq = _dag_qubits(inst, nq)
            seal!(dq)
            cid = newcluster!(i, collect(getqubits(inst)), :pass)
            for q in dq
                owner[q] = cid
            end
            clusterof[i] = cid
            continue
        end

        qs = getqubits(inst)

        # Candidates are the open fusible clusters owning this gate's wires.
        # Merging several of them at once is what lets a cluster grow past two
        # qubits: every one absorbed is an operation removed from the output, so
        # take them cheapest-first to fit as many as `max_support` allows.
        cand = Int[]
        for q in qs
            g = get(owner, q, 0)
            g == 0 && continue
            kinds[g] === :fuse && isopen[g] && !(g in cand) && push!(cand, g)
        end
        sort!(cand; by=g -> length(setdiff(support[g], qs)))

        S = Set{Int}(qs)
        chosen = Int[]
        for g in cand
            u = union(S, support[g])
            if length(u) <= max_support
                S = u
                push!(chosen, g)
            end
        end

        if isempty(chosen)
            seal!(qs)
            cid = newcluster!(i, collect(qs), :fuse)
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
            union!(support[s], support[g])
            empty!(members[g])          # folded away, emits nothing
            empty!(support[g])
        end
        push!(members[s], i)
        union!(support[s], qs)
        clusterof[i] = s
        for q in S
            owner[q] = s
        end
    end

    # Contract the instruction DAG by cluster id and topologically sort it: any
    # topological order is a valid, equivalent circuit (independent clusters
    # commute). Merging only sinks keeps every cluster convex, so this is a DAG.
    nc = length(members)
    cg = SimpleDiGraph(nc)
    for e in edges(c)
        cu, cv = clusterof[src(e)], clusterof[dst(e)]
        cu != cv && add_edge!(cg, cu, cv)
    end
    order = topological_sort_by_dfs(cg)

    out = Circuit()
    for cid in order
        isempty(members[cid]) && continue
        if kinds[cid] == :pass || length(members[cid]) == 1  # no singleton demotion
            for i in members[cid]
                push!(out, c[i])  # verbatim: keeps qubits, bits and zvars intact
            end
        else
            S = sort!(collect(support[cid]))
            push!(out, GateCustom(_synthesize(c, sort!(members[cid]), S)), S...)
        end
    end
    return out
end
