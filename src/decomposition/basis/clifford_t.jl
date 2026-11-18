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
    CliffordTBasis(; rotations=GridSynthRewrite(), borrow=false, max_ancillas=0, allow_measurement=false)
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
2. `GateECR` to `S`, `SX`, `CX` and `X`, as in [`StimBasis`](@ref), with no T gate.
3. [`ToffoliToCliffordTRewrite`](@ref): `GateCCX` to Clifford+T with 7 T gates.
4. A `GateU` whose angles are all zero (a pure global phase) is dropped.
5. [`ZYZRewrite`](@ref): `GateU` to `RZ·RY·RZ`.
6. [`ToZRotationRewrite`](@ref): `GateRX`, `GateRY` to `GateRZ` and Cliffords.
7. The `rotations` rule (default [`GridSynthRewrite`](@ref)): remaining
   `GateRZ` to an approximate Clifford+T sequence.
8. [`CanonicalRewrite`](@ref): any other operation, toward `GateU` and `GateCX`.
   A `GateRX`, `GateRY` or `GateRZ` that reaches this point has a symbolic
   angle and throws a `DecompositionError`.

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
- `borrow::Bool = false`: let decompositions borrow qubits of the circuit
  that the operation does not act on. A borrowed qubit can be in any state;
  the decomposition leaves it as it found it.
- `max_ancillas::Integer = 0`: let decompositions add up to this many clean
  ancillas, numbered after the qubits of the circuit and marked with
  [`AncillaAlloc`](@ref) and [`AncillaFree`](@ref). Ancillas freed by one
  operation are reused by the next.
- `allow_measurement::Bool = false`: with `max_ancillas`, let decompositions
  undo steps by measuring an ancilla into one extra bit, numbered after the
  bits of the circuit. A circuit without bits is refused with an
  `ArgumentError`. With a clean ancilla, a `GateCCX` then costs 4 T instead
  of 7.

The ancilla options only change how multi-controlled X gates are
decomposed. Circuits whose width is unknown, such as a lone operation, get
no ancillas.

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
    ancillas::_AncillaOptions

    function CliffordTBasis(;
        sk_depth::Union{Nothing,Int} = nothing,
        rotations::Union{Nothing,RewriteRule} = nothing,
        borrow::Bool = false,
        max_ancillas::Integer = 0,
        allow_measurement::Bool = false,
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
        new{typeof(rotations)}(rotations, _AncillaOptions(borrow, max_ancillas, allow_measurement))
    end
end

Base.:(==)(a::CliffordTBasis, b::CliffordTBasis) = a.rotations == b.rotations && a.ancillas == b.ancillas
Base.hash(b::CliffordTBasis, h::UInt) = hash(b.ancillas, hash(b.rotations, hash(CliffordTBasis, h)))

_ancillaoptions(basis::CliffordTBasis) = basis.ancillas

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
function decompose!(builder, basis::CliffordTBasis, op::IfStatement, qtargets, ctargets, ztargets, ctx::DecompositionContext=_NO_CONTEXT)
    return _decompose_ifstatement!(builder, basis, op, qtargets, ctargets, ztargets, ctx)
end

function decompose!(builder, basis::CliffordTBasis, op::Operation, qtargets, ctargets, ztargets)
    return _decompose_cliffordt!(builder, basis, op, qtargets, ctargets, ztargets, _NO_CONTEXT)
end

function decompose!(builder, basis::CliffordTBasis, op::Control, qtargets, ctargets, ztargets, ctx::DecompositionContext)
    return _decompose_cliffordt!(builder, basis, op, qtargets, ctargets, ztargets, ctx)
end

function _decompose_cliffordt!(
    builder,
    basis::CliffordTBasis,
    op::Operation,
    qtargets,
    ctargets,
    ztargets,
    ctx::DecompositionContext,
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

    # ECR is Clifford; the canonical rule would spend two T gates on it.
    if op isa GateECR
        return _decompose_ecr!(builder, qtargets)
    end

    # Priority 2: Toffoli gate (optimal T-count decomposition without
    # measurements; with them, CanonicalRewrite uses 4 T)
    if matches(_CLIFFORDT_TOFFOLI, op) && !(_can_measure(ctx) && _available(ctx) > 0)
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

    # A rotation left here has a symbolic angle that no rule can approximate;
    # the canonical rule would cycle RZ → U → RZ forever.
    if op isa Union{GateRX,GateRY,GateRZ}
        throw(DecompositionError(
            "Rotation $(opname(op)) has a symbolic angle and cannot be decomposed " *
            "into the Clifford+T basis. Evaluate it first."
        ))
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
            ctx,
        )
    end

    throw(
        DecompositionError(
            "Operation $(opname(op)) cannot be decomposed into the Clifford+T basis.",
        ),
    )
end
