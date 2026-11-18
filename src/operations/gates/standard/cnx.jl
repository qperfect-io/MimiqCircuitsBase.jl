#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

@doc raw"""
    GateCCX()

Three-qubit, doubly-controlled ``X`` gate.

!!! details
    Implemented as an alias to ``Control(2, GateX())``.

!!! note
    By convention, the first two qubits are the controls and the third is the
    target.

## Examples

```jldoctest
julia> GateCCX(), numcontrols(GateCCX()), numtargets(GateCCX())
(Control(2, GateX()), 2, 1)

julia> matrix(GateCCX())
8×8 Matrix{Float64}:
 1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0
 0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0

julia> c = push!(Circuit(), GateCCX(), 1, 2, 3)
3-qubit circuit with 1 instruction:
└── C₂X @ q[1:2], q[3]

julia> power(GateCCX(), 2), inverse(GateCCX())
(Control(2, GateID()), Control(2, GateX()))

```

## Decomposition

```jldoctest
julia> decompose(GateCCX())
3-qubit circuit with 15 instructions:
├── U(π/2,0,π) @ q[3]
├── CX @ q[2], q[3]
├── U(0,0,-1π/4) @ q[3]
├── CX @ q[1], q[3]
├── U(0,0,π/4) @ q[3]
├── CX @ q[2], q[3]
├── U(0,0,-1π/4) @ q[3]
├── CX @ q[1], q[3]
├── U(0,0,π/4) @ q[2]
├── U(0,0,π/4) @ q[3]
├── U(π/2,0,π) @ q[3]
├── CX @ q[1], q[2]
├── U(0,0,π/4) @ q[1]
├── U(0,0,-1π/4) @ q[2]
└── CX @ q[1], q[2]

```
"""
const GateCCX = typeof(Control(2, GateX()))

matches(::CanonicalRewrite, ::GateCCX) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateCCX, qtargets, _, _)
    a, b, c = qtargets
    push!(builder, GateH(), c)

    push!(builder, GateCX(), b, c)
    push!(builder, GateTDG(), c)

    push!(builder, GateCX(), a, c)
    push!(builder, GateT(), c)

    push!(builder, GateCX(), b, c)
    push!(builder, GateTDG(), c)

    push!(builder, GateCX(), a, c)
    push!(builder, GateT(), b)
    push!(builder, GateT(), c)
    push!(builder, GateH(), c)

    push!(builder, GateCX(), a, b)
    push!(builder, GateT(), a)
    push!(builder, GateTDG(), b)

    push!(builder, GateCX(), a, b)

    return builder
end

"""
    GateC3X()

Four qubit, triply-controlled ``X`` gate.

!!! details
    Implemented as an alias to ``Control(3, GateX())``.

!!! note
    By convention, the first three qubits are the controls and the fourth is
    the target.

## Examples

```jldoctest
julia> GateC3X(), numcontrols(GateC3X()), numtargets(GateC3X())
(Control(3, GateX()), 3, 1)

julia> matrix(GateC3X())
16×16 Matrix{Float64}:
 1.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  …  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  1.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  1.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  1.0  0.0  0.0  …  0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  1.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  1.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     1.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  …  0.0  1.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  1.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0     0.0  0.0  0.0  0.0  0.0  0.0  1.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  …  0.0  0.0  0.0  0.0  0.0  1.0  0.0

julia> c = push!(Circuit(), GateC3X(), 1, 2, 3, 4)
4-qubit circuit with 1 instruction:
└── C₃X @ q[1:3], q[4]

julia> power(GateC3X(), 2), inverse(GateC3X())
(Control(3, GateID()), Control(3, GateX()))

```

## Decomposition

```jldoctest
julia> decompose(GateC3X())
4-qubit circuit with 31 instructions:
├── U(π/2,0,π) @ q[4]
├── U(0,0,π/8) @ q[1]
├── U(0,0,π/8) @ q[2]
├── U(0,0,π/8) @ q[3]
├── U(0,0,π/8) @ q[4]
├── CX @ q[1], q[2]
├── U(0,0,-1π/8) @ q[2]
├── CX @ q[1], q[2]
├── CX @ q[2], q[3]
⋮   ⋮
├── CX @ q[1], q[4]
├── U(0,0,π/8) @ q[4]
├── CX @ q[3], q[4]
├── U(0,0,-1π/8) @ q[4]
├── CX @ q[2], q[4]
├── U(0,0,π/8) @ q[4]
├── CX @ q[3], q[4]
├── U(0,0,-1π/8) @ q[4]
├── CX @ q[1], q[4]
└── U(π/2,0,π) @ q[4]

```
"""
const GateC3X = typeof(Control(3, GateX()))

function decompose_step!(builder, ::CanonicalRewrite, ::GateC3X, qtargets, _, _)
    a, b, c, d = qtargets

    push!(builder, GateH(), d)
    push!(builder, GateP(_π_8), qtargets)
    push!(builder, GateCX(), a, b)
    push!(builder, GateP(_mπ_8), b)
    push!(builder, GateCX(), a, b)
    push!(builder, GateCX(), b, c)
    push!(builder, GateP(_mπ_8), c)
    push!(builder, GateCX(), a, c)
    push!(builder, GateP(_π_8), c)
    push!(builder, GateCX(), b, c)
    push!(builder, GateP(_mπ_8), c)
    push!(builder, GateCX(), a, c)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(_mπ_8), d)
    push!(builder, GateCX(), b, d)
    push!(builder, GateP(_π_8), d)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(_mπ_8), d)
    push!(builder, GateCX(), a, d)
    push!(builder, GateP(_π_8), d)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(_mπ_8), d)
    push!(builder, GateCX(), b, d)
    push!(builder, GateP(_π_8), d)
    push!(builder, GateCX(), c, d)
    push!(builder, GateP(_mπ_8), d)
    push!(builder, GateCX(), a, d)
    push!(builder, GateH(), d)

    return builder
end

# A multi-controlled X can use qubits outside its targets. In order of
# preference:
#
# - clean ancillas and measurements: a ladder of ANDs computed with 4 T each
#   and uncomputed by measurement with none (Jones 2013, Gidney 2018), also
#   for the Toffoli;
# - clean ancillas: an AND ladder of relative-phase Toffolis (Maslov 2016)
#   computes the AND of the first controls into them, so 4 T per ancilla and
#   step instead of a full Toffoli;
# - borrowed qubits: one gives a linear count of Toffolis (Lemma 7.3 of
#   Barenco et al. 1995), n-2 give 4(n-2) (Lemma 7.2).
#
# GateC3X is included: its ancilla-free form needs π/8 phases, which have no
# exact Clifford+T decomposition.
function decompose_step!(builder, rule::CanonicalRewrite, control::Control{N,1,L,GateX}, qtargets, ctargets, ztargets, ctx::DecompositionContext) where {N,L}
    controls = collect(qtargets[1:N])
    target = qtargets[N+1]

    if N >= 2 && _can_measure(ctx)
        clean = _take_clean!(ctx, N - 1)
        if !isempty(clean)
            return _cnx_measured_ladder!(builder, controls, target, clean, ctx.bit)
        end
    end

    N >= 3 || return decompose_step!(builder, rule, control, qtargets, ctargets, ztargets)

    clean = _take_clean!(ctx, N - 2)
    if !isempty(clean)
        return _cnx_ladder!(builder, controls, target, clean)
    end

    borrowed = _borrowable(ctx, qtargets, N - 2)
    if !isempty(borrowed)
        return _controlx_decompose!(builder, controls, target, borrowed)
    end

    return decompose_step!(builder, rule, control, qtargets, ctargets, ztargets)
end

# Relative-phase Toffoli: a Toffoli up to a diagonal phase on its three qubits,
# with 4 T gates. It is its own inverse.
function _rccx!(builder, a, b, t)
    push!(builder, GateH(), t)
    push!(builder, GateT(), t)
    push!(builder, GateCX(), b, t)
    push!(builder, GateTDG(), t)
    push!(builder, GateCX(), a, t)
    push!(builder, GateT(), t)
    push!(builder, GateCX(), b, t)
    push!(builder, GateTDG(), t)
    push!(builder, GateH(), t)
    return builder
end

# C_n(X) with m clean ancillas, m <= n - 2. The ladder stores in ancilla i the
# AND of the first i+1 controls. The remaining controls and the last ancilla
# control the target, then the ladder is undone. The relative phases of the
# ladder cancel: they are diagonal, and the middle gate only reads the ladder
# qubits. With m < n - 2 the middle gate still has 3 or more controls; it
# borrows the qubits the ladder has already read, which sit idle meanwhile.
function _cnx_ladder!(builder, controls, target, ancillas)
    m = length(ancillas)
    for a in ancillas
        push!(builder, AncillaAlloc(), a)
    end
    ladder = _rccx!(Circuit(), controls[1], controls[2], ancillas[1])
    for i in 2:m
        _rccx!(ladder, ancillas[i-1], controls[i+1], ancillas[i])
    end
    rest = controls[m+2:end]
    append!(builder, ladder)
    _controlx_decompose!(builder, [ancillas[m]; rest], target, [controls[1:m+1]; ancillas[1:m-1]])
    append!(builder, inverse(ladder))
    for a in ancillas
        push!(builder, AncillaFree(), a)
    end
    return builder
end

# Logical AND of `a` and `b` into `t`, which must be in |0⟩. The relative
# Toffoli leaves a phase i on |111⟩ only, among the states it reaches from
# t = 0; the S† removes it.
function _and!(builder, a, b, t)
    _rccx!(builder, a, b, t)
    push!(builder, GateSDG(), t)
    return builder
end

# Undo `_and!(builder, a, b, t)` by measurement, without T gates. Measured in
# the X basis, `t` gives a random bit; when it is 1 the state has picked up a
# phase -1 where a and b are both 1, which a CZ conditioned on the bit undoes.
# The reset returns `t` to |0⟩.
function _unand!(builder, a, b, t, bit)
    push!(builder, GateH(), t)
    push!(builder, MeasureReset(), t, bit)
    push!(builder, IfStatement(GateCZ(), bs"1"), a, b, bit)
    return builder
end

# C_n(X) with m clean ancillas, m <= n - 1, and a bit to measure into. As
# `_cnx_ladder!`, but each step is an exact AND, undone by measurement.
function _cnx_measured_ladder!(builder, controls, target, ancillas, bit)
    m = length(ancillas)
    steps = [(i == 1 ? controls[1] : ancillas[i-1], controls[i+1], ancillas[i]) for i in 1:m]
    for a in ancillas
        push!(builder, AncillaAlloc(), a)
    end
    for (a, b, t) in steps
        _and!(builder, a, b, t)
    end
    rest = controls[m+2:end]
    _controlx_decompose!(builder, [ancillas[m]; rest], target, [controls[1:m+1]; ancillas[1:m-1]])
    for (a, b, t) in reverse(steps)
        _unand!(builder, a, b, t, bit)
    end
    for a in ancillas
        push!(builder, AncillaFree(), a)
    end
    return builder
end
