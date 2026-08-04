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
# Replaces maximal runs of fusible unitary gates acting on ≤ `max_support`
# qubits with a single `GateCustom` whose matrix is the ordered product of the
# run. Boundaries (measurements, resets, noise channels, control flow,
# barriers, and anything without a concrete numeric unitary) are emitted
# verbatim and are never fused across on a shared wire.

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

Fuse maximal runs of adjacent unitary gates acting on at most `max_support`
qubits into single [`GateCustom`](@ref) blocks, preserving the circuit's overall
unitary exactly.

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

    owner = Dict{Int,Int}()             # qubit -> id of the fusible cluster owning it
    members = Vector{Vector{Int}}()     # cluster id -> instruction indices (ascending)
    support = Vector{Set{Int}}()        # cluster id -> qubits it spans
    kinds = Vector{Symbol}()            # cluster id -> :fuse | :pass
    clusterof = Vector{Int}(undef, n)

    function newcluster!(i, qs, k)
        push!(members, [i])
        push!(support, Set{Int}(qs))
        push!(kinds, k)
        return length(members)
    end

    for i in 1:n
        inst = c[i]
        if !_is_fusible(inst, max_support)
            cid = newcluster!(i, collect(getqubits(inst)), :pass)
            # The boundary *owns* every wire it depends on, so a later gate on
            # one of those wires can't fuse back into a cluster that sits before
            # the boundary. A few global observables synchronise the whole
            # register in the DAG, so mirror `_dag_qubits` here.
            for q in _dag_qubits(inst, nq)
                owner[q] = cid
            end
            clusterof[i] = cid
            continue
        end

        qs = getqubits(inst)
        live = Set{Int}(owner[q] for q in qs if haskey(owner, q))
        if length(live) == 1
            g = first(live)
            # Join only a fusible cluster that already owns the immediate
            # predecessor on each shared wire (fresh wires carry no owner). A
            # boundary-owned wire has `kinds[g] == :pass`, which blocks the join.
            if kinds[g] == :fuse && length(union(support[g], qs)) <= max_support
                push!(members[g], i)
                union!(support[g], qs)
                for q in qs
                    owner[q] = g
                end
                clusterof[i] = g
                continue
            end
        end
        # 0 live (all wires fresh), ≥2 live (a bridge that would merge
        # clusters), a boundary-owned wire, or a single owner the gate no
        # longer fits: start a fresh cluster.
        cid = newcluster!(i, collect(qs), :fuse)
        for q in qs
            owner[q] = cid
        end
        clusterof[i] = cid
    end

    # Contract the instruction DAG by cluster id and topologically sort it: any
    # topological order is a valid, equivalent circuit (independent clusters
    # commute). Single-owner greedy keeps every cluster convex, so this is a DAG.
    nc = length(members)
    cg = SimpleDiGraph(nc)
    for e in edges(c)
        cu, cv = clusterof[src(e)], clusterof[dst(e)]
        cu != cv && add_edge!(cg, cu, cv)
    end
    order = topological_sort_by_dfs(cg)

    out = Circuit()
    for cid in order
        if kinds[cid] == :pass || length(members[cid]) == 1  # no singleton demotion
            for i in members[cid]
                push!(out, c[i])  # verbatim: keeps qubits, bits and zvars intact
            end
        else
            S = sort!(collect(support[cid]))
            push!(out, GateCustom(_synthesize(c, members[cid], S)), S...)
        end
    end
    return out
end
