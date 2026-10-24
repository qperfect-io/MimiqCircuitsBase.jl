#
# Copyright © 2026 QPerfect. All Rights Reserved.
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

# The simplification passes on the compact form. Each returns the new circuit
# and whether it differs from the input.

function _remove_identities(ctx::_Ctx, c::Vector{_SInst})
    keep(inst) = (M = _mat(ctx.entries[inst.entry]); isnothing(M) || !_isidentitymatrix(M))
    out = filter(keep, c)
    return out, length(out) != length(c)
end

_samequbits(qa, qb) = length(qa) == length(qb) && all(q -> q in qb, qa)

# The engine of `cancel_inverses` and `merge_rotations`. Each gate walks back
# over earlier instructions on its wires, past those it commutes with, until it
# finds one on the same qubits that `combine` accepts (see `_cancelpair`).
# Moving the gate back is sound because it commutes with everything it passed.
function _peephole(combine, ctx::_Ctx, c::Vector{_SInst})
    nq = _numqubits(c)
    out = Union{_SInst,Nothing}[]
    sizehint!(out, length(c))
    onwire = [Int[] for _ in 1:nq]      # qubit -> indices into `out` touching it
    syncpoint = 0                       # last full-register synchronisation point
    ptrs = Int[]                        # per wire of the gate: next index to visit
    changed = false

    for inst in c
        done = false
        if ctx.entries[inst.entry].plain
            qs = inst.qubits
            # Walk the wires' histories backwards together, newest first; each
            # is already in order, so this is a merge rather than a sort.
            empty!(ptrs)
            for q in qs
                push!(ptrs, length(onwire[q]))
            end
            step = 0
            while true
                j = 0
                for (k, q) in enumerate(qs)
                    ptrs[k] > 0 && (j = max(j, onwire[q][ptrs[k]]))
                end
                for (k, q) in enumerate(qs)
                    ptrs[k] > 0 && onwire[q][ptrs[k]] == j && (ptrs[k] -= 1)
                end
                step += 1
                (j <= syncpoint || step > _SIMPLIFY_LOOKBACK) && break
                prev = out[j]
                isnothing(prev) && continue
                if ctx.entries[prev.entry].plain && _samequbits(prev.qubits, qs)
                    r = combine(ctx, prev, inst)
                    if r === :cancel
                        out[j] = nothing
                        done = true
                        break
                    elseif r isa Int
                        out[j] = _SInst(r, prev.qubits)
                        done = true
                        break
                    end
                end
                _commutes(ctx, prev, inst) || break
            end
        end
        if done
            changed = true
            continue
        end
        push!(out, inst)
        ctx.entries[inst.entry].isglobal && (syncpoint = length(out))
        for q in _dagqubits(ctx, inst, nq)
            push!(onwire[q], length(out))
        end
    end
    return _SInst[inst for inst in out if !isnothing(inst)], changed
end

function _resynthesize_1q(ctx::_Ctx, c::Vector{_SInst})
    nq = _numqubits(c)
    out = Union{_SInst,Nothing}[]
    sizehint!(out, length(c))
    runs = Dict{Int,Vector{Tuple{Int,Matrix{ComplexF64}}}}()  # qubit -> (index, matrix)
    changed = false

    # The run's gates are adjacent on their wire, so its replacement can take
    # the place of the first one.
    function flush!(q)
        run = pop!(runs, q, nothing)
        (isnothing(run) || length(run) < 2) && return
        U = prod(last.(reverse(run)))
        for (j, _) in run
            out[j] = nothing
        end
        changed = true
        _isidentitymatrix(U) && return
        e = _addcode!(ctx, _CODE_U, collect(Float64, _zyz_decomposition(U)))
        out[first(run[1])] = _SInst(e, [q])
    end

    for inst in c
        M = length(inst.qubits) == 1 ? _mat(ctx.entries[inst.entry]) : nothing
        if isnothing(M)
            foreach(flush!, _dagqubits(ctx, inst, nq))
            push!(out, inst)
        else
            push!(out, inst)
            push!(get!(runs, inst.qubits[1], Tuple{Int,Matrix{ComplexF64}}[]), (length(out), M))
        end
    end
    foreach(flush!, collect(keys(runs)))
    return _SInst[inst for inst in out if !isnothing(inst)], changed
end

_istwoqubit(inst::_SInst) = length(inst.qubits) == 2
_istwoqubit(inst::Instruction) = numqubits(inst) == 2

function _clusters(ctx::_Ctx, c::Vector{_SInst}, max_support::Int, data)
    nq = _numqubits(c)
    return _fuseclusters(length(c), nq, i -> c[i].qubits, i -> _dagqubits(ctx, c[i], nq),
        i -> c[i].bits, i -> c[i].zvars, data, max_support, max_support)
end

# `_fusiondata` for two-qubit blocks: the gate's matrix, or its diagonal.
function _densedata(ctx::_Ctx, inst::_SInst)
    e = ctx.entries[inst.entry]
    (e.fusable && e.nq <= 2 && !isnothing(e.matrix)) || return nothing
    return _isdiagonalmatrix(e.matrix) ? diag(e.matrix) : e.matrix
end

function _resynthesize_2q(ctx::_Ctx, c::Vector{_SInst})
    data = Dict{Int,Any}()      # per entry: computing it per instruction allocates
    cl = _clusters(ctx, c, 2, i -> get!(() -> _densedata(ctx, c[i]), data, c[i].entry))
    out = _SInst[]
    sizehint!(out, length(c))
    changed = false
    for cid in cl.order
        members = sort(cl.members[cid])
        isempty(members) && continue
        S = sort!(collect(cl.support[cid]))
        n2q = count(i -> _istwoqubit(c[i]), members)
        if cl.kinds[cid] == :fuse && length(S) == 2 && n2q >= 2
            Ms = [_embedmatrix(ctx.entries[c[i].entry].matrix, _localqubits(c[i].qubits, S), 2)
                  for i in members]
            ncx, gates = _kak_synthesis(_foldmatrices(Ms, 2, ComplexF64))
            if ncx < n2q
                for (code, params, qs) in gates
                    push!(out, _SInst(_addcode!(ctx, code, params), [S[q] for q in qs]))
                end
                changed = true
                continue
            end
        end
        append!(out, c[i] for i in members)
    end
    return out, changed
end

function _resynthesize_linear(ctx::_Ctx, c::Vector{_SInst})
    cl = _clusters(ctx, c, _numqubits(c), i -> ctx.entries[c[i].entry].linear != 0 ? :linear : nothing)
    out = _SInst[]
    sizehint!(out, length(c))
    changed = false
    for cid in cl.order
        members = sort(cl.members[cid])
        isempty(members) && continue
        if cl.kinds[cid] == :fuse && length(members) > 1
            S = sort!(collect(cl.support[cid]))
            gates = [(ctx.entries[c[i].entry].linear, _localqubits(c[i].qubits, S)) for i in members]
            cx, xs = _linear_synthesis(_affinemap(gates, length(S))...)
            if (length(cx), length(cx) + length(xs)) <
               (count(i -> _istwoqubit(c[i]), members), length(members))
                ecx, ex = _addcode!(ctx, _CODE_CX, Float64[]), _addcode!(ctx, _CODE_X, Float64[])
                append!(out, _SInst(ecx, [S[ctrl], S[t]]) for (ctrl, t) in cx)
                append!(out, _SInst(ex, [S[q]]) for q in xs)
                changed = true
                continue
            end
        end
        append!(out, c[i] for i in members)
    end
    return out, changed
end

_simplifycost(c) = (count(_istwoqubit, c), length(c))

# Pass functions and what they run on the compact form.
const _SIMPLIFY_PASSES = Dict{Function,Function}()

function _runpass(ctx::_Ctx, pass, c::Vector{_SInst})
    impl = _SIMPLIFY_PASSES[pass]
    return impl(ctx, c)
end

# Rounds of `passes` until a round no longer lowers the number of two-qubit
# gates or, failing that, of instructions. A pass that already ran on the
# current circuit is skipped until another pass changes it.
function _simplify(ctx::_Ctx, c::Vector{_SInst}, passes, maxiter::Integer)
    cost = _simplifycost(c)
    version = 0
    seen = fill(-1, length(passes))
    for _ in 1:maxiter
        next = c
        for (k, pass) in enumerate(passes)
            seen[k] == version && continue
            d, changed = _runpass(ctx, pass, next)
            changed && (version += 1)
            seen[k] = version
            next = d
        end
        nextcost = _simplifycost(next)
        nextcost < cost || break
        c, cost = next, nextcost
    end
    return c
end

# A circuit in compact form, against a fresh table.
function _compact(c::Circuit)
    ctx = _Ctx()
    insts = Vector{_SInst}(undef, length(c))
    for (i, inst) in enumerate(c)
        bits, zvars = getbits(inst), getztargets(inst)
        insts[i] = _SInst(_opid!(ctx, getoperation(inst)), collect(Int, getqubits(inst)),
            isempty(bits) ? _NOTARGETS : collect(Int, bits),
            isempty(zvars) ? _NOTARGETS : collect(Int, zvars), i)
    end
    return ctx, insts
end

# Back to a circuit: unchanged instructions are the input's own.
function _expand(ctx::_Ctx, c::Vector{_SInst}, input::Circuit)
    return Circuit(Instruction[inst.orig != 0 ? input[inst.orig] :
                               Instruction(_op(ctx, inst.entry), inst.qubits...) for inst in c])
end

# Run built-in passes on `c`: once each in order when `maxiter` is 0, in
# rounds as `simplify` does otherwise.
function _runsimplify(c::Circuit, passes, maxiter::Integer)
    ctx, insts = _compact(c)
    if maxiter == 0
        for pass in passes
            insts = first(_runpass(ctx, pass, insts))
        end
    else
        insts = _simplify(ctx, insts, passes, maxiter)
    end
    return _expand(ctx, insts, c)
end
