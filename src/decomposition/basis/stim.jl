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

1. [`ZYZRewrite`](@ref): GateU → RZ·RY·RZ Euler decomposition
2. [`SpecialAngleRewrite`](@ref) (Clifford-only): Rotations at k·π/2 → exact Clifford gates
3. [`CanonicalRewrite`](@ref): Fallback for other gates

Non-Clifford rotations (angles not multiples of π/2) are explicitly rejected
with a clear error message.

!!! warning "Clifford-only"
    Non-Clifford operations (T gates, arbitrary rotations) will cause decomposition
    to fail. Only rotations with angles that are multiples of π/2 can be decomposed.
    Use [`CliffordTBasis`](@ref) for circuits with non-Clifford gates.

# Terminal Operations

**Single-qubit Clifford gates:**
- Pauli: `GateID`, `GateX`, `GateY`, `GateZ`
- Hadamard: `GateH`
- Phase: `GateS`, `GateSDG`
- √X: `GateSX`, `GateSXDG`
- √Y: `GateSY`, `GateSYDG`

**Two-qubit Clifford gates:**
- Controlled Paulis: `GateCX`, `GateCY`, `GateCZ`
- Swap: `GateSWAP`, `GateISWAP`, `GateISWAPDG`
- Double CX: `GateDCX`
- ECR: `GateECR`

**Measurements:**
- Z-basis: `Measure`
- X-basis: `MeasureX`
- Y-basis: `MeasureY`

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
| `Measure` | `M` |
| `MeasureX` | `MX` |
| `MeasureY` | `MY` |
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

# Hadamard
isterminal(::StimBasis, ::GateH) = true

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

# --- Measurements (all Pauli bases) ---

isterminal(::StimBasis, ::Measure) = true
isterminal(::StimBasis, ::MeasureX) = true
isterminal(::StimBasis, ::MeasureY) = true

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

function decompose!(builder, ::StimBasis, op::Operation, qtargets, ctargets, ztargets)
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
