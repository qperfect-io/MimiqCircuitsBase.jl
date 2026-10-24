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

# What the simplification passes know about each operation: a table entry per
# distinct operation, with the facts the passes reason with. The gates the
# passes create are described by a code and float parameters, and only become
# operations when the result is built, since building one wraps its parameters
# as symbolic numbers and deriving its matrix goes through Symbolics.

# Entries below this are zero when deciding identity, commutation, cancellation
# and diagonality.
const _SIMPLIFY_ATOL = 1e-12

# Gates wider than this never get a dense matrix: it has 4^n entries.
const _SIMPLIFY_MAXMATRIXQUBITS = 6

# `Delay` has an identity matrix but marks idle time for noise, so the passes
# never move or rewrite it.
_isplaingate(op::Operation) = op isa AbstractGate && !(op isa Delay) && isunitary(typeof(op))

# Numeric matrix of a unitary gate on at most six qubits, or `nothing`.
function _numericmatrix(op::Operation)
    op isa AbstractGate && isunitary(typeof(op)) || return nothing
    numqubits(op) <= _SIMPLIFY_MAXMATRIXQUBITS || return nothing
    M = try
        matrix(op)
    catch
        return nothing
    end
    # `Num <: Real`, so a symbolic matrix is recognised by its entries, not by
    # being real or complex.
    eltype(M) <: Union{AbstractFloat,Complex{<:AbstractFloat}} && return ComplexF64.(M)
    any(issymbolic, M) && return nothing
    return ComplexF64.(unwrapvalue.(M))
end

_isidentitymatrix(M) = isapprox(M, I; atol=_SIMPLIFY_ATOL)

# Off-diagonal entries that are exactly zero, symbolically or numerically.
# A controlled gate is diagonal exactly when the gate it controls is.
function _isdiagonalop(op::Operation)
    _isplaingate(op) || return false
    op isa Control && return _isdiagonalop(getoperation(op))
    op isa GateCustomDiagonal && return true
    numqubits(op) <= _SIMPLIFY_MAXMATRIXQUBITS || return false
    M = try
        matrix(op)
    catch
        return false
    end
    return all(M[i, j] isa Complex{Num} ? isequal(M[i, j], 0) : abs(M[i, j]) <= _SIMPLIFY_ATOL
               for i in axes(M, 1), j in axes(M, 2) if i != j)
end

_isdiagonalmatrix(M::Matrix{ComplexF64}) =
    all(abs(M[i, j]) <= _SIMPLIFY_ATOL for i in axes(M, 1), j in axes(M, 2) if i != j)

# Position of the target among the qubits of a multi-controlled X (`GateX`,
# `GateCX`, `GateCCX`, `Control(n, GateX())`), or 0 for any other gate.
_xtarget(op::Operation) =
    op isa GateX ? 1 : (op isa Control && getoperation(op) isa GateX) ? numqubits(op) : 0

# 1 for X, 2 for CX, 3 for SWAP: the gates of linear reversible circuits.
_lineargate(op::Operation) = op isa GateX ? 1 : op isa GateCX ? 2 : op isa GateSWAP ? 3 : 0

# Gates that compose by adding their first parameter, provided all the others
# agree.
const _ADDITIVE_GATES = Union{GateRX,GateRY,GateRZ,GateP,GateU1,GateR,GateRXX,GateRYY,
    GateRZZ,GateRZX,GateXXplusYY,GateXXminusYY}

# What two gates must share to merge by adding their first parameter, or
# `nothing` if the gate does not merge that way.
_mergekey(::Operation) = nothing
_mergekey(op::_ADDITIVE_GATES) = (typeof(op), getparams(op)[2:end]...)
_mergekey(op::RPauli) = (RPauli, string(op.pauli))
function _mergekey(op::Control{N}) where {N}
    inner = _mergekey(getoperation(op))
    return isnothing(inner) ? nothing : (Control, N, inner)
end

_firstparam(op::Operation) = getparams(op)[1]
_firstparam(op::RPauli) = op.θ
_firstparam(op::Control) = _firstparam(getoperation(op))

_withfirstparam(op::Operation, x) = typeof(op)(x, getparams(op)[2:end]...)
_withfirstparam(op::RPauli, x) = RPauli(op.pauli, x)
_withfirstparam(op::Control{N}, x) where {N} = Control(N, _withfirstparam(getoperation(op), x))

# Adding two numeric `Num`s still builds a symbolic term first, which is slow.
_addparams(x, y) = issymbolic(x) || issymbolic(y) ? x + y : unwrapvalue(x) + unwrapvalue(y)

# The gates the passes create.
@enum _GateCode begin
    _CODE_U
    _CODE_P
    _CODE_RZ
    _CODE_RX
    _CODE_RY
    _CODE_H
    _CODE_CX
    _CODE_X
    _CODE_T
    _CODE_S
    _CODE_Z
    _CODE_SDG
    _CODE_TDG
    _CODE_SX
    _CODE_SXDG
    _CODE_Y
    _CODE_SY
    _CODE_SYDG
end

const _CODE_GATES = (GateU, GateP, GateRZ, GateRX, GateRY, GateH, GateCX, GateX, GateT, GateS,
    GateZ, GateSDG, GateTDG, GateSX, GateSXDG, GateY, GateSY, GateSYDG)

_codegate(code::_GateCode, params) = _CODE_GATES[Int(code)+1](params...)

# Matrix of a created gate, computed from floats.
function _codematrix(code::_GateCode, p::Vector{Float64})
    h = 1 / sqrt(2)
    if code == _CODE_U
        θ, ϕ, λ, γ = p
        c, s = cos(θ / 2), sin(θ / 2)
        return ComplexF64[cis(γ)*c -cis(γ + λ)*s; cis(γ + ϕ)*s cis(γ + ϕ + λ)*c]
    elseif code == _CODE_P
        return ComplexF64[1 0; 0 cis(p[1])]
    elseif code == _CODE_RZ
        return ComplexF64[cis(-p[1] / 2) 0; 0 cis(p[1] / 2)]
    elseif code == _CODE_RX
        c, s = cos(p[1] / 2), sin(p[1] / 2)
        return ComplexF64[c -im*s; -im*s c]
    elseif code == _CODE_RY
        c, s = cos(p[1] / 2), sin(p[1] / 2)
        return ComplexF64[c -s; s c]
    elseif code == _CODE_H
        return ComplexF64[h h; h -h]
    elseif code == _CODE_CX
        return ComplexF64[1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]
    elseif code == _CODE_X
        return ComplexF64[0 1; 1 0]
    elseif code == _CODE_Y
        return ComplexF64[0 -im; im 0]
    elseif code == _CODE_Z
        return ComplexF64[1 0; 0 -1]
    elseif code == _CODE_S
        return ComplexF64[1 0; 0 im]
    elseif code == _CODE_SDG
        return ComplexF64[1 0; 0 -im]
    elseif code == _CODE_T
        return ComplexF64[1 0; 0 cis(π / 4)]
    elseif code == _CODE_TDG
        return ComplexF64[1 0; 0 cis(-π / 4)]
    elseif code == _CODE_SX
        return ComplexF64[0.5+0.5im 0.5-0.5im; 0.5-0.5im 0.5+0.5im]
    elseif code == _CODE_SXDG
        return ComplexF64[0.5-0.5im 0.5+0.5im; 0.5+0.5im 0.5-0.5im]
    elseif code == _CODE_SY
        return ComplexF64[0.5+0.5im -0.5-0.5im; 0.5+0.5im 0.5+0.5im]
    else # _CODE_SYDG
        return ComplexF64[0.5-0.5im 0.5-0.5im; -0.5+0.5im 0.5-0.5im]
    end
end

# Single-qubit gates that are a rotation about Z, X or Y fall in one of two
# forms, B P(λ) B† or B RZ(λ) B†, with B one of these bases. Two gates of the
# same form and basis compose by adding their angles. The forms differ by a
# global phase, which is why they are kept apart.
const _FAMILY_BASES = (
    ComplexF64[1 0; 0 1],                           # Z
    ComplexF64[1 1; 1 -1] / sqrt(2),                # X: H Z H = X
    ComplexF64[1 1; im -im] / sqrt(2),              # Y: (S H) Z (S H)† = Y
)

const _PHASE_FAMILIES = 1:3       # family k: B_k P(λ) B_k†, λ mod 2π
const _ROTATION_FAMILIES = 4:6    # family k + 3: B_k RZ(λ) B_k†, λ mod 4π

# (family, λ) of a 2×2 unitary, or (0, 0.0) if it has none.
function _rotationfamily(M::Matrix{ComplexF64})
    size(M) == (2, 2) || return (0, 0.0)
    for (k, B) in enumerate(_FAMILY_BASES)
        D = B' * M * B
        (abs(D[1, 2]) <= _SIMPLIFY_ATOL && abs(D[2, 1]) <= _SIMPLIFY_ATOL) || continue
        abs(D[1, 1] - 1) <= _SIMPLIFY_ATOL && return (k, angle(D[2, 2]))
        abs(D[1, 1] - conj(D[2, 2])) <= _SIMPLIFY_ATOL && return (k + 3, 2 * angle(D[2, 2]))
    end
    return (0, 0.0)
end

# Named gates by (family, λ in units of π/4), so that merges come back as
# `GateS` rather than `GateP(π/2)`.
const _NAMED_FAMILY_GATES = Dict{Tuple{Int,Int},_GateCode}(
    (1, 1) => _CODE_T, (1, 2) => _CODE_S, (1, 4) => _CODE_Z, (1, 6) => _CODE_SDG,
    (1, 7) => _CODE_TDG, (2, 2) => _CODE_SX, (2, 4) => _CODE_X, (2, 6) => _CODE_SXDG,
    (3, 2) => _CODE_SY, (3, 4) => _CODE_Y, (3, 6) => _CODE_SYDG,
)

# (code, params) of the gate of `family` with angle `λ`, or `nothing` when it
# is the identity.
function _familygate(family::Int, λ::Float64)
    period = family in _PHASE_FAMILIES ? 8 : 16
    q = λ / (π / 4)
    if abs(q - round(q)) <= 1e-9
        k = mod(round(Int, q), period)
        k == 0 && return nothing
        family in _PHASE_FAMILIES && haskey(_NAMED_FAMILY_GATES, (family, k)) &&
            return (_NAMED_FAMILY_GATES[(family, k)], Float64[])
    end
    family == 1 && return (_CODE_P, [λ])
    family == 4 && return (_CODE_RZ, [λ])
    family == 5 && return (_CODE_RX, [λ])
    family == 6 && return (_CODE_RY, [λ])
    B = _FAMILY_BASES[family]
    return (_CODE_U, collect(Float64, _zyz_decomposition(B * ComplexF64[1 0; 0 cis(λ)] * B')))
end

# Where an operation comes from, so that it can be built at the end.
struct _CodeOrigin
    code::_GateCode
    params::Vector{Float64}
end

struct _SumOrigin
    base::Int           # the entry whose operation this is
    value::Float64      # with this first parameter
end

const _Origin = Union{Operation,_CodeOrigin,_SumOrigin}

struct _Entry
    origin::_Origin
    plain::Bool         # a unitary gate other than `Delay`: what the passes move
    fusable::Bool       # a unitary gate, `Delay` included: what blocks absorb
    nq::Int
    matrix::Union{Nothing,Matrix{ComplexF64}}   # of a fusable gate on ≤ 6 qubits
    diag::Bool
    family::Int         # see `_rotationfamily`
    angle::Float64
    xtarget::Int        # see `_xtarget`
    xaxis::Bool         # commutes with X on its one qubit
    mergeclass::Int     # see `_mergekey`; 0 for none
    first::Float64      # first parameter of a merging gate, NaN if symbolic
    linear::Int         # see `_lineargate`
    isglobal::Bool      # depends on the whole register, see `_dag_qubits`
end

function _Entry(origin::_Origin, plain, fusable, nq, M, structdiag, xtarget, symbolicrx,
    mergeclass, first, linear, isglobal)
    m = plain ? M : nothing
    family, angle = isnothing(m) ? (0, 0.0) : _rotationfamily(m)
    diag = isnothing(m) ? structdiag : _isdiagonalmatrix(m)
    return _Entry(origin, plain, fusable, nq, M, diag, family, angle, xtarget,
        symbolicrx || family in (2, 5), mergeclass, first, linear, isglobal)
end

# The matrix the passes reason with: none for anything but a plain gate.
_mat(e::_Entry) = e.plain ? e.matrix : nothing
