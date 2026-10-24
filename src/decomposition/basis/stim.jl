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
    StimBasis <: DecompositionBasis

Decomposition basis targeting the Stim stabilizer simulator gate set.

[Stim](https://github.com/quantumlib/Stim) is a high-performance stabilizer circuit
simulator by Craig Gidney. It supports only **Clifford gates**, stabilizer operations,
noise channels, and quantum error correction annotations.

# Decomposition Pipeline

The basis applies rewrite rules to decompose gates into Clifford operations:

1. A `GateU` whose angles are all zero (a pure global phase) is dropped.
2. [`ZYZRewrite`](@ref): GateU → RZ·RY·RZ Euler decomposition
3. [`SpecialAngleRewrite`](@ref) (Clifford-only): Rotations at k·π/2 → exact Clifford gates
4. [`CanonicalRewrite`](@ref): Fallback for other gates

Non-Clifford rotations (angles not multiples of π/2) are explicitly rejected
with a clear error message.

!!! warning "Clifford-only"
    Non-Clifford operations (T gates, arbitrary rotations) will cause decomposition
    to fail. Only rotations with angles that are multiples of π/2 can be decomposed.
    Use [`CliffordTBasis`](@ref) for circuits with non-Clifford gates.

# Terminal Operations

**Single-qubit Clifford gates:**
- Pauli: `GateID`, `GateX`, `GateY`, `GateZ`
- Hadamard: `GateH`, `GateHXY`, `GateHYZ`
- Phase: `GateS`, `GateSDG`
- √X: `GateSX`, `GateSXDG`
- √Y: `GateSY`, `GateSYDG`

**Two-qubit Clifford gates:**
- Controlled Paulis: `GateCX`, `GateCY`, `GateCZ`
- Swap: `GateSWAP`, `GateISWAP`, `GateISWAPDG`
- Double CX: `GateDCX`
- ECR: `GateECR`

**Pauli rotations by ±π/2:**
- `GateRXX`, `GateRYY`, `GateRZZ` with angle ±π/2
- `RPauli` with angle ±π/2 and a non-identity Pauli string

Angles are compared modulo 2π, since a rotation by 3π/2 equals a rotation by
-π/2 up to a global phase. Other angles are decomposed.

**Feedback:**
- `IfStatement` of `GateX`, `GateY` or `GateZ` conditioned on a single bit
  being `1`. The same gate conditioned on the bit being `0` is decomposed into
  the gate followed by the gate conditioned on `1`. Any other conditional
  operation has its body decomposed while staying conditional, and raises a
  `DecompositionError` if that does not lead to a conditional Pauli.

**Measurements:**
- Z-basis: `Measure`
- X-basis: `MeasureX`
- Y-basis: `MeasureY`
- Two-qubit parities: `MeasureXX`, `MeasureYY`, `MeasureZZ`
- Pauli products: `MeasurePauli`

**Resets:**
- Z-basis: `Reset`
- X-basis: `ResetX`
- Y-basis: `ResetY`

**Measure-and-reset:**
- Z-basis: `MeasureReset`
- X-basis: `MeasureResetX`
- Y-basis: `MeasureResetY`

**Noise channels:**
- Pauli errors: `PauliX`, `PauliY`, `PauliZ`
- Depolarizing: `Depolarizing1`, `Depolarizing2`
- Pauli channels: `PauliNoise`

**QEC annotations:**
- `Detector`, `ObservableInclude`, `QubitCoordinates`
- `Barrier`

# Stim Gate Mapping

| MIMIQ Operation | Stim Operation |
|-----------------|----------------|
| `GateID` | `I` |
| `GateX` | `X` |
| `GateY` | `Y` |
| `GateZ` | `Z` |
| `GateH` | `H` |
| `GateHXY` | `H_XY` |
| `GateHYZ` | `H_YZ` |
| `GateS` | `S` |
| `GateSDG` | `S_DAG` |
| `GateSX` | `SQRT_X` |
| `GateSXDG` | `SQRT_X_DAG` |
| `GateSY` | `SQRT_Y` |
| `GateSYDG` | `SQRT_Y_DAG` |
| `GateCX` | `CX` / `CNOT` |
| `GateCY` | `CY` |
| `GateCZ` | `CZ` |
| `GateSWAP` | `SWAP` |
| `GateISWAP` | `ISWAP` |
| `GateISWAPDG` | `ISWAP_DAG` |
| `GateRXX(±π/2)` | `SQRT_XX` / `SQRT_XX_DAG` |
| `GateRYY(±π/2)` | `SQRT_YY` / `SQRT_YY_DAG` |
| `GateRZZ(±π/2)` | `SQRT_ZZ` / `SQRT_ZZ_DAG` |
| `RPauli(P, ±π/2)` | `SPP` / `SPP_DAG` |
| `IfStatement(GateX(), bs"1")` | `CX rec[-k] q` |
| `IfStatement(GateY(), bs"1")` | `CY rec[-k] q` |
| `IfStatement(GateZ(), bs"1")` | `CZ rec[-k] q` |
| `Measure` | `M` |
| `MeasureX` | `MX` |
| `MeasureY` | `MY` |
| `MeasureXX` | `MXX` |
| `MeasureYY` | `MYY` |
| `MeasureZZ` | `MZZ` |
| `MeasurePauli` | `MPP` |
| `Reset` | `R` |
| `ResetX` | `RX` |
| `ResetY` | `RY` |
| `MeasureReset` | `MR` |
| `MeasureResetX` | `MRX` |
| `MeasureResetY` | `MRY` |
| `PauliX` | `X_ERROR` |
| `PauliY` | `Y_ERROR` |
| `PauliZ` | `Z_ERROR` |
| `Depolarizing1` | `DEPOLARIZE1` |
| `Depolarizing2` | `DEPOLARIZE2` |
| `PauliNoise` | `PAULI_CHANNEL_1`, `PAULI_CHANNEL_2` or `E` / `ELSE_CORRELATED_ERROR` |
| `Detector` | `DETECTOR` |
| `ObservableInclude` | `OBSERVABLE_INCLUDE` |
| `QubitCoordinates` | `QUBIT_COORDS` |

# Examples
```julia
# Decompose Clifford circuit to Stim-compatible gates
decompose(circuit; basis=StimBasis())

# This works (RZ(π/2) = S is Clifford)
decompose(GateRZ(π/2); basis=StimBasis())

# This fails (RZ(π/4) = T is non-Clifford)
decompose(GateRZ(π/4); basis=StimBasis())  # throws DecompositionError

# This also fails (arbitrary angle)
decompose(GateRZ(0.123); basis=StimBasis())  # throws DecompositionError
```

See also [`DecompositionBasis`](@ref), [`CliffordTBasis`](@ref), [`QASMBasis`](@ref).
"""
struct StimBasis <: DecompositionBasis end

# === Terminal Operations — Stim Clifford Gate Set ===

# --- Single-qubit Clifford gates ---

# Identity
isterminal(::StimBasis, ::GateID) = true

# Pauli gates
isterminal(::StimBasis, ::GateX) = true
isterminal(::StimBasis, ::GateY) = true
isterminal(::StimBasis, ::GateZ) = true

# Hadamard and its XY / YZ variants
isterminal(::StimBasis, ::GateH) = true
isterminal(::StimBasis, ::GateHXY) = true
isterminal(::StimBasis, ::GateHYZ) = true

# Phase gates (S = √Z)
isterminal(::StimBasis, ::GateS) = true
isterminal(::StimBasis, ::GateSDG) = true

# √X gates
isterminal(::StimBasis, ::GateSX) = true
isterminal(::StimBasis, ::GateSXDG) = true

# √Y gates
isterminal(::StimBasis, ::GateSY) = true
isterminal(::StimBasis, ::GateSYDG) = true

# --- Two-qubit Clifford gates ---

# Controlled Pauli gates
isterminal(::StimBasis, ::GateCX) = true
isterminal(::StimBasis, ::GateCY) = true
isterminal(::StimBasis, ::GateCZ) = true

# Swap family
isterminal(::StimBasis, ::GateSWAP) = true
isterminal(::StimBasis, ::GateISWAP) = true
isterminal(::StimBasis, ::GateISWAPDG) = true

# Double CX
isterminal(::StimBasis, ::GateDCX) = true

# Echoed Cross-Resonance
isterminal(::StimBasis, ::GateECR) = true

# --- Pauli rotations by ±π/2 (Stim's SQRT_XX, SQRT_YY, SQRT_ZZ, SPP) ---

_stim_is_half_pi(θ) = get_pi_factor_or_nothing(θ) in (2, 6)

isterminal(::StimBasis, g::GateRXX) = _stim_is_half_pi(g.θ)
isterminal(::StimBasis, g::GateRYY) = _stim_is_half_pi(g.θ)
isterminal(::StimBasis, g::GateRZZ) = _stim_is_half_pi(g.θ)
isterminal(::StimBasis, g::RPauli) = !isidentity(g.pauli) && _stim_is_half_pi(g.θ)

# --- Measurements (all Pauli bases) ---

isterminal(::StimBasis, ::Measure) = true
isterminal(::StimBasis, ::MeasureX) = true
isterminal(::StimBasis, ::MeasureY) = true
isterminal(::StimBasis, ::MeasureXX) = true
isterminal(::StimBasis, ::MeasureYY) = true
isterminal(::StimBasis, ::MeasureZZ) = true
isterminal(::StimBasis, ::MeasurePauli) = true

# --- Resets (all Pauli bases) ---

isterminal(::StimBasis, ::Reset) = true
isterminal(::StimBasis, ::ResetX) = true
isterminal(::StimBasis, ::ResetY) = true

# --- Measure-and-reset (all Pauli bases) ---

isterminal(::StimBasis, ::MeasureReset) = true
isterminal(::StimBasis, ::MeasureResetX) = true
isterminal(::StimBasis, ::MeasureResetY) = true

# --- Barriers ---

isterminal(::StimBasis, ::Barrier) = true

# --- Noise channels (Stim supports Pauli noise natively) ---

# Pauli error channels
isterminal(::StimBasis, ::PauliX) = true
isterminal(::StimBasis, ::PauliY) = true
isterminal(::StimBasis, ::PauliZ) = true

# Depolarizing noise
isterminal(::StimBasis, ::Depolarizing1) = true
isterminal(::StimBasis, ::Depolarizing2) = true

# Pauli channels
isterminal(::StimBasis, ::PauliNoise) = true

# --- Feedback (Stim's CX/CY/CZ with a measurement record as control) ---

isterminal(::StimBasis, op::IfStatement) =
    getoperation(op) isa Union{GateX,GateY,GateZ} && getbitstring(op) == bs"1"

# --- QEC Annotations ---

isterminal(::StimBasis, ::Detector) = true
isterminal(::StimBasis, ::ObservableInclude) = true
isterminal(::StimBasis, ::QubitCoordinates) = true
isterminal(::StimBasis, ::AbstractAnnotation) = true

# --- Fallback ---

isterminal(::StimBasis, ::Operation) = false

# === Decomposition Pipeline ===

# Pre-instantiated rules (avoid allocation in hot path)
const _STIM_ZYZ = ZYZRewrite()
const _STIM_SPECIAL_ANGLE_CLIFFORD = SpecialAngleRewrite(only_cliffords=true)
const _STIM_CANONICAL = CanonicalRewrite()

function decompose!(builder, basis::StimBasis, op::IfStatement, qtargets, ctargets, ztargets)
    inner = getoperation(op)
    condition = getbitstring(op)

    if length(condition) != 1
        throw(DecompositionError(
            "IfStatement with a $(length(condition))-bit condition cannot be decomposed into the Stim basis. " *
            "Stim only conditions X, Y and Z gates on a single measurement record."
        ))
    end

    # P if c == 0 equals P, then P if c == 1, since P² = I.
    if inner isa Union{GateX,GateY,GateZ}
        push!(builder, inner, qtargets...)
        push!(builder, IfStatement(inner, bs"1"), qtargets..., ctargets...)
        return builder
    end

    if isterminal(basis, inner)
        throw(DecompositionError(
            "IfStatement of $(opname(inner)) cannot be decomposed into the Stim basis. " *
            "Stim only conditions X, Y and Z gates on a single measurement record."
        ))
    end

    # Rotations by multiples of π go straight to the Pauli they equal; the
    # general pipeline would pass through gates that cannot be conditioned.
    if matches(_STIM_SPECIAL_ANGLE_CLIFFORD, inner)
        return _decompose_ifstatement!(builder, _STIM_SPECIAL_ANGLE_CLIFFORD, op, qtargets, ctargets, ztargets)
    end

    return _decompose_ifstatement!(builder, basis, op, qtargets, ctargets, ztargets)
end

function decompose!(builder, ::StimBasis, op::Operation, qtargets, ctargets, ztargets)
    # A bare GateU with zero angles is only a global phase, so it expands to
    # nothing; ZYZRewrite refuses it. Under a Control the phase is a relative
    # phase; that case is a Control, not a GateU, and goes to CanonicalRewrite.
    if op isa GateU && all(p -> !issymbolic(p) && iszero(p), (op.θ, op.ϕ, op.λ))
        return builder
    end

    # Priority 1: GateU → ZYZ decomposition (RZ·RY·RZ)
    if matches(_STIM_ZYZ, op)
        return decompose_step!(builder, _STIM_ZYZ, op, qtargets, ctargets, ztargets)
    end

    # Priority 2: Special angles (Clifford-only) — handles rotations at k·π/2
    if matches(_STIM_SPECIAL_ANGLE_CLIFFORD, op)
        return decompose_step!(builder, _STIM_SPECIAL_ANGLE_CLIFFORD, op, qtargets, ctargets, ztargets)
    end

    # Explicitly reject non-Clifford rotations
    # This prevents infinite loops (RZ → U → ZYZ → RZ) and gives clear errors
    if op isa Union{GateRX,GateRY,GateRZ}
        throw(DecompositionError(
            "Rotation $(opname(op)) cannot be decomposed into the Stim basis. " *
            "Only rotations with angles that are multiples of π/2 are Clifford gates."
        ))
    end

    # Priority 3: Fallback to canonical decomposition
    if matches(_STIM_CANONICAL, op)
        return decompose_step!(builder, _STIM_CANONICAL, op, qtargets, ctargets, ztargets)
    end

    throw(DecompositionError(
        "Operation $(opname(op)) cannot be decomposed into the Stim basis."
    ))
end
