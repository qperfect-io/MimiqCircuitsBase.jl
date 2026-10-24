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

# The form the simplification passes work on, and the relations between two
# gates. A circuit becomes a vector of `_SInst`, each an entry of one operation
# table shared by every pass of a run, and only turns back into a `Circuit` at
# the end.

# How far back along the wires a gate looks for a partner to cancel or merge
# with. Each step costs a commutation check.
# ponytail: fixed window, make it a keyword if circuits need deeper lookback.
const _SIMPLIFY_LOOKBACK = 64

const _NOTARGETS = Int[]

# An instruction: an entry of the table on some targets. `orig` is the index of
# the input instruction it still is, unchanged, or 0.
struct _SInst
    entry::Int
    qubits::Vector{Int}
    bits::Vector{Int}
    zvars::Vector{Int}
    orig::Int
end

_SInst(entry::Int, qubits::Vector{Int}) = _SInst(entry, qubits, _NOTARGETS, _NOTARGETS, 0)

mutable struct _Ctx
    entries::Vector{_Entry}
    ids::Dict{Operation,Int}
    classes::Dict{Any,Int}
    codes::Dict{Tuple{_GateCode,Vector{Float64}},Int}
    sums::Dict{Tuple{Int,Float64},Int}
    relations::Dict{NTuple{4,Int},Bool}     # (kind, entry a, entry b, layout)
    built::Dict{Int,Operation}
end

_Ctx() = _Ctx(_Entry[], Dict{Operation,Int}(), Dict{Any,Int}(),
    Dict{Tuple{_GateCode,Vector{Float64}},Int}(), Dict{Tuple{Int,Float64},Int}(),
    Dict{NTuple{4,Int},Bool}(), Dict{Int,Operation}())

function _mergeclass!(ctx::_Ctx, key)
    isnothing(key) && return 0
    return get!(ctx.classes, key, length(ctx.classes) + 1)
end

function _push!(ctx::_Ctx, e::_Entry)
    push!(ctx.entries, e)
    return length(ctx.entries)
end

# The entry of an operation, created on first sight.
function _opid!(ctx::_Ctx, op::Operation)
    return get!(ctx.ids, op) do
        M = _numericmatrix(op)
        key = _mergekey(op)
        class = _mergeclass!(ctx, key)
        first = NaN
        if class != 0
            p = _firstparam(op)
            issymbolic(p) || (first = Float64(unwrapvalue(p)))
        end
        plain = _isplaingate(op)
        e = _Entry(op, plain, op isa AbstractGate && isunitary(typeof(op)), numqubits(op), M,
            isnothing(M) && _isdiagonalop(op), _xtarget(op), op isa GateRX, class, first,
            _lineargate(op), op isa Union{Amplitude,BondDim,SchmidtRank,VonNeumannEntropy})
        _push!(ctx, e)
    end
end

# The entry of a created gate.
function _addcode!(ctx::_Ctx, code::_GateCode, params::Vector{Float64})
    return get!(ctx.codes, (code, params)) do
        M = _codematrix(code, params)
        class, first = 0, NaN
        if code in (_CODE_P, _CODE_RZ, _CODE_RX, _CODE_RY)
            # `_mergekey` of a one-parameter rotation is its type alone.
            class = _mergeclass!(ctx, (_CODE_GATES[Int(code)+1],))
            first = params[1]
        end
        xt = code == _CODE_X ? 1 : code == _CODE_CX ? 2 : 0
        e = _Entry(_CodeOrigin(code, params), true, true, size(M, 1) == 4 ? 2 : 1, M, false, xt,
            false, class, first, code == _CODE_X ? 1 : code == _CODE_CX ? 2 : 0, false)
        _push!(ctx, e)
    end
end

# The entry of `base`'s gate with first parameter `value`, and matrix `M`.
function _addsum!(ctx::_Ctx, base::Int, value::Float64, M)
    b = ctx.entries[base]
    return get!(ctx.sums, (b.mergeclass, value)) do
        e = _Entry(_SumOrigin(base, value), b.plain, b.fusable, b.nq, M, b.diag, b.xtarget,
            b.xaxis, b.mergeclass, value, b.linear, b.isglobal)
        _push!(ctx, e)
    end
end

# The operation of an entry, built once.
function _op(ctx::_Ctx, id::Int)
    o = ctx.entries[id].origin
    o isa Operation && return o
    return get!(ctx.built, id) do
        o isa _CodeOrigin ? _codegate(o.code, o.params) : _withfirstparam(_op(ctx, o.base), o.value)
    end
end

# Qubits an instruction depends on for ordering: all of them for the global
# observables.
_dagqubits(ctx::_Ctx, inst::_SInst, nq::Int) =
    ctx.entries[inst.entry].isglobal ? collect(1:nq) : inst.qubits

_numqubits(c::Vector{_SInst}) = maximum((maximum(i.qubits; init=0) for i in c); init=0)

# Positions of the qubits of `qa` and `qb` within their sorted union, packed in
# one integer, or 0 when the union is wider than four qubits.
function _layoutcode(qa, qb)
    n = length(qa) + count(q -> !(q in qa), qb)
    n <= 4 || return 0
    rank(q) = 1 + count(<(q), qa) + count(x -> x < q && !(x in qa), qb)
    code = 1
    for q in qa
        code = 8code + rank(q)
    end
    code *= 8
    for q in qb
        code = 8code + rank(q)
    end
    return code
end

# `M`, acting on the qubits at positions `locs` (first is most significant),
# as a matrix on `n` qubits.
function _embedmatrix(M::Matrix{ComplexF64}, locs, n::Int)
    rest = [p for p in 1:n if !(p in locs)]
    sub(x) = foldl((acc, p) -> (acc << 1) | ((x >> (n - p)) & 1), locs; init=0)
    out = zeros(ComplexF64, 1 << n, 1 << n)
    for r in 0:(1<<n)-1, c in 0:(1<<n)-1
        all(p -> (r >> (n - p)) & 1 == (c >> (n - p)) & 1, rest) || continue
        out[r+1, c+1] = M[sub(r)+1, sub(c)+1]
    end
    return out
end

_localqubits(qubits, S) = map(q -> findfirst(==(q), S), qubits)

# Matrices of `a` and `b` embedded on the sorted union of their qubits.
function _jointmatrices(ctx::_Ctx, a::_SInst, b::_SInst)
    S = sort!(unique!(vcat(a.qubits, b.qubits)))
    return (_embedmatrix(_mat(ctx.entries[a.entry]), _localqubits(a.qubits, S), length(S)),
        _embedmatrix(_mat(ctx.entries[b.entry]), _localqubits(b.qubits, S), length(S)))
end

# Commutation decided by structure, at any width, or `nothing` when structure
# says nothing. A multi-controlled X flips its target when all its controls
# are set, so it commutes with another one unless either's target is among the
# other's controls, with a diagonal gate unless that gate touches its target,
# and with an X rotation unless that sits on one of its controls.
function _structuralcommute(ctx::_Ctx, a::_SInst, b::_SInst)
    ta, tb = ctx.entries[a.entry].xtarget, ctx.entries[b.entry].xtarget
    ta == 0 && tb == 0 && return nothing
    if ta == 0
        a, b, ta, tb = b, a, tb, ta
    end
    x = a.qubits[ta]
    if tb != 0
        y = b.qubits[tb]
        return x == y || (!(x in b.qubits) && !(y in a.qubits))
    end
    eb = ctx.entries[b.entry]
    eb.diag && return !(x in b.qubits)
    eb.xaxis && return b.qubits[1] == x || !(b.qubits[1] in a.qubits)
    return nothing
end

const _RELATION_COMMUTES = 1
const _RELATION_INVERSE = 2

function _commutes(ctx::_Ctx, a::_SInst, b::_SInst)
    ea, eb = ctx.entries[a.entry], ctx.entries[b.entry]
    (ea.plain && eb.plain) || return false
    ea.diag && eb.diag && return true
    r = _structuralcommute(ctx, a, b)
    isnothing(r) || return r
    # ponytail: symbolic gates only commute through the diagonal rule,
    # e.g. RZ(θ) does not pass a CX control. Needs per-generator rules.
    (isnothing(_mat(ea)) || isnothing(_mat(eb))) && return false
    layout = _layoutcode(a.qubits, b.qubits)
    layout == 0 && return false
    return get!(ctx.relations, (_RELATION_COMMUTES, a.entry, b.entry, layout)) do
        A, B = _jointmatrices(ctx, a, b)
        isapprox(A * B, B * A; atol=_SIMPLIFY_ATOL)
    end
end

# What combining `b` with an earlier `a` on the same set of qubits gives:
# `nothing` to keep looking, `:cancel` to delete both, or the entry that
# replaces `a`.
function _cancelpair(ctx::_Ctx, a::_SInst, b::_SInst)
    ea, eb = ctx.entries[a.entry], ctx.entries[b.entry]
    # Multi-controlled X gates on the same qubits are inverse when their
    # targets agree, whatever order the controls are listed in.
    if ea.xtarget != 0 && eb.xtarget != 0
        return a.qubits[ea.xtarget] == b.qubits[eb.xtarget] ? :cancel : nothing
    end
    if isnothing(_mat(ea)) || isnothing(_mat(eb))
        a.qubits == b.qubits || return nothing
        inv = try
            inverse(_op(ctx, a.entry))
        catch
            return nothing
        end
        return isequal(inv, _op(ctx, b.entry)) ? :cancel : nothing
    end
    # Numerically, so that pairs written differently, like SWAP(1,2)
    # SWAP(2,1) or CZ(1,2) CZ(2,1), cancel too.
    layout = _layoutcode(a.qubits, b.qubits)
    layout == 0 && return nothing
    isinv = get!(ctx.relations, (_RELATION_INVERSE, a.entry, b.entry, layout)) do
        A, B = _jointmatrices(ctx, a, b)
        _isidentitymatrix(B * A)
    end
    return isinv ? :cancel : nothing
end

# Gates of one merge class add their first parameters, which keeps them exact
# and symbolic angles symbolic. Different gates of one rotation family, like T
# and S, merge on the angles read from their matrices.
function _mergepair(ctx::_Ctx, a::_SInst, b::_SInst)
    a.qubits == b.qubits || return nothing
    ea, eb = ctx.entries[a.entry], ctx.entries[b.entry]
    if ea.mergeclass != 0 && ea.mergeclass == eb.mergeclass
        if isnan(ea.first) || isnan(eb.first)
            opa, opb = _op(ctx, a.entry), _op(ctx, b.entry)
            op = _withfirstparam(opa, _addparams(_firstparam(opa), _firstparam(opb)))
            M = _numericmatrix(op)
            !isnothing(M) && _isplaingate(op) && _isidentitymatrix(M) && return :cancel
            return _opid!(ctx, op)
        end
        # G(x) G(y) = G(x + y) for these gates, so the product is the merged
        # gate's matrix. Gates too wide for one still merge.
        ma, mb = _mat(ea), _mat(eb)
        M = isnothing(ma) || isnothing(mb) ? nothing : mb * ma
        !isnothing(M) && _isidentitymatrix(M) && return :cancel
        return _addsum!(ctx, a.entry, ea.first + eb.first, M)
    end
    fam = ea.family
    (fam != 0 && fam == eb.family) || return nothing
    g = _familygate(fam, ea.angle + eb.angle)
    return isnothing(g) ? :cancel : _addcode!(ctx, g...)
end
