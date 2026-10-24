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

"""
    CliffordTBasis(; rotations=GridSynthRewrite())
    CliffordTBasis(; sk_depth)

Decomposition basis targeting the Clifford+T gate set.

Clifford+T is the standard universal gate set of error-corrected quantum
computing. The terminal operations of this basis are those of
[`StimBasis`](@ref) plus `GateT` and `GateTDG`, so the two bases always keep
the same Clifford and stabilizer operations:

- single-qubit Cliffords: `GateID`, `GateX`, `GateY`, `GateZ`, `GateH`,
  `GateHXY`, `GateHYZ`, `GateS`, `GateSDG`, `GateSX`, `GateSXDG`, `GateSY`,
  `GateSYDG`;
- two-qubit Cliffords: `GateCX`, `GateCY`, `GateCZ`, `GateSWAP`, `GateISWAP`,
  `GateISWAPDG`, `GateDCX`, `GateECR`;
- Pauli rotations by `±π/2`: `GateRXX`, `GateRYY`, `GateRZZ`, and `RPauli`
  with a non-identity Pauli string;
- the non-Clifford `GateT` and `GateTDG`;
- measurements, resets and measure-and-resets in the X, Y and Z bases,
  `MeasureXX`, `MeasureYY`, `MeasureZZ` and `MeasurePauli`;
- Pauli noise: `PauliX`, `PauliY`, `PauliZ`, `Depolarizing1`,
  `Depolarizing2` and `PauliNoise`;
- barriers and annotations;
- classical operations, which [`StimBasis`](@ref) does not keep;
- an `IfStatement` whose body is terminal in this basis, with any condition.
  [`StimBasis`](@ref) only keeps a conditional `GateX`, `GateY` or `GateZ`
  on a single bit.

# Decomposition Pipeline

Non-terminal operations are rewritten by the first rule that matches, in this
order:

1. [`SpecialAngleRewrite`](@ref): rotations by multiples of `π/4` to exact Clifford+T.
2. [`ToffoliToCliffordTRewrite`](@ref): `GateCCX` to Clifford+T with 7 T gates.
3. A `GateU` whose angles are all zero (a pure global phase) is dropped.
4. [`ZYZRewrite`](@ref): `GateU` to `RZ·RY·RZ`.
5. [`ToZRotationRewrite`](@ref): `GateRX`, `GateRY` to `GateRZ` and Cliffords.
6. The `rotations` rule (default [`GridSynthRewrite`](@ref)): remaining
   `GateRZ` to an approximate Clifford+T sequence.
7. [`CanonicalRewrite`](@ref): any other operation, toward `GateU` and `GateCX`.

The `rotations` rule only sees angles that step 1 could not decompose exactly.
The body of an `IfStatement` goes through the same pipeline and stays
conditional. No T-count optimization is performed on the result.

# Keyword Arguments

- `rotations::RewriteRule`: rule that synthesizes the remaining Z-rotations.
  The default [`GridSynthRewrite()`](@ref) approximates each rotation to
  operator-norm error `1e-10`. The rule must match `GateRZ` with a numeric
  angle and emit only gates of this basis.
- `sk_depth::Int`: use [`SolovayKitaevRewrite`](@ref) with this recursion
  depth as the `rotations` rule.

Throws an `ArgumentError` if both keywords are given, or if `rotations` does
not match `GateRZ`. Decomposing an operation that no rule handles, such as a
noise channel other than the Pauli ones above, throws a `DecompositionError`.

# Examples

```julia
# Decompose to Clifford+T; each arbitrary rotation is approximated to 1e-10
decompose(circuit; basis=CliffordTBasis())

# A looser error bound per rotation gives fewer T gates
decompose(circuit; basis=CliffordTBasis(rotations=GridSynthRewrite(epsilon=1e-6)))

# Solovay-Kitaev at depth 3 instead of gridsynth
decompose(circuit; basis=CliffordTBasis(sk_depth=3))

# Count the T gates of the result
decomposed = decompose(circuit; basis=CliffordTBasis())
t_count = count(inst -> getoperation(inst) isa Union{GateT, GateTDG}, decomposed)
```

See also [`DecompositionBasis`](@ref), [`StimBasis`](@ref), [`CanonicalBasis`](@ref).
"""
struct CliffordTBasis{R<:RewriteRule} <: DecompositionBasis
    rotations::R

    function CliffordTBasis(;
        sk_depth::Union{Nothing,Int} = nothing,
        rotations::Union{Nothing,RewriteRule} = nothing,
    )
        if !isnothing(sk_depth) && !isnothing(rotations)
            throw(ArgumentError("give either sk_depth or rotations, not both"))
        end
        if isnothing(rotations)
            rotations = isnothing(sk_depth) ? GridSynthRewrite() : SolovayKitaevRewrite(sk_depth)
        end
        matches(rotations, GateRZ(0.1)) || throw(
            ArgumentError("rotations rule $(typeof(rotations)) does not match GateRZ"),
        )
        new{typeof(rotations)}(rotations)
    end
end

Base.:(==)(a::CliffordTBasis, b::CliffordTBasis) = a.rotations == b.rotations
Base.hash(b::CliffordTBasis, h::UInt) = hash(b.rotations, hash(CliffordTBasis, h))

# --- terminal operations: those of StimBasis, plus T and T† ---

# Delegating to StimBasis keeps the two terminal sets from drifting apart.
isterminal(::CliffordTBasis, op::Operation) = isterminal(StimBasis(), op)

isterminal(::CliffordTBasis, ::GateT) = true
isterminal(::CliffordTBasis, ::GateTDG) = true

# Classical operations touch no qubit, so they need no decomposition here
# even though Stim cannot run them.
isterminal(::CliffordTBasis, ::AbstractClassical) = true

# Clifford+T is a gate set, so any conditional gate of it is terminal, not
# only the single-bit conditional Paulis that Stim accepts.
isterminal(basis::CliffordTBasis, op::IfStatement) = isterminal(basis, getoperation(op))

# --- decomposition pipeline ---

# Pre-instantiated rules (avoid allocation in hot path)
const _CLIFFORDT_SPECIAL_ANGLE = SpecialAngleRewrite()
const _CLIFFORDT_TOFFOLI = ToffoliToCliffordTRewrite()
const _CLIFFORDT_ZYZ = ZYZRewrite()
const _CLIFFORDT_TO_Z = ToZRotationRewrite()
const _CLIFFORDT_CANONICAL = CanonicalRewrite()

# The body of a conditional goes through this pipeline too, so that, for
# example, a conditional rotation by a multiple of π/4 stays exact.
function decompose!(builder, basis::CliffordTBasis, op::IfStatement, qtargets, ctargets, ztargets)
    return _decompose_ifstatement!(builder, basis, op, qtargets, ctargets, ztargets)
end

function decompose!(
    builder,
    basis::CliffordTBasis,
    op::Operation,
    qtargets,
    ctargets,
    ztargets,
)
    # Priority 1: Special angles (exact, no approximation needed)
    if matches(_CLIFFORDT_SPECIAL_ANGLE, op)
        return decompose_step!(
            builder,
            _CLIFFORDT_SPECIAL_ANGLE,
            op,
            qtargets,
            ctargets,
            ztargets,
        )
    end

    # Priority 2: Toffoli gate (optimal T-count decomposition)
    if matches(_CLIFFORDT_TOFFOLI, op)
        return decompose_step!(
            builder,
            _CLIFFORDT_TOFFOLI,
            op,
            qtargets,
            ctargets,
            ztargets,
        )
    end

    # A bare GateU with zero angles is only a global phase, so it expands to
    # nothing. ZYZRewrite refuses it, and a rotations rule that matches only
    # GateRZ cannot absorb it. Under a Control the phase is a relative phase;
    # that case is a Control, not a GateU, and goes to CanonicalRewrite.
    if op isa GateU && all(p -> !issymbolic(p) && iszero(p), (op.θ, op.ϕ, op.λ))
        return builder
    end

    # Priority 3: GateU → ZYZ decomposition
    if matches(_CLIFFORDT_ZYZ, op)
        return decompose_step!(builder, _CLIFFORDT_ZYZ, op, qtargets, ctargets, ztargets)
    end

    # Priority 4: RX, RY → RZ + Cliffords
    if matches(_CLIFFORDT_TO_Z, op)
        return decompose_step!(builder, _CLIFFORDT_TO_Z, op, qtargets, ctargets, ztargets)
    end

    # Priority 5: Arbitrary RZ → approximate Clifford+T synthesis
    if matches(basis.rotations, op)
        return decompose_step!(builder, basis.rotations, op, qtargets, ctargets, ztargets)
    end

    # Priority 6: Fallback to canonical decomposition
    if matches(_CLIFFORDT_CANONICAL, op)
        return decompose_step!(
            builder,
            _CLIFFORDT_CANONICAL,
            op,
            qtargets,
            ctargets,
            ztargets,
        )
    end

    throw(
        DecompositionError(
            "Operation $(opname(op)) cannot be decomposed into the Clifford+T basis.",
        ),
    )
end
