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
    CliffordTBasis <: DecompositionBasis

Decomposition basis targeting the Clifford+T universal gate set.

The Clifford+T gate set is fault-tolerant and widely used in error-corrected
quantum computing. It consists of:

- **Single-qubit Clifford**: H, S, S†, X, Y, Z, SX, SX†, SY, SY†
- **T gates**: T, T† (the non-Clifford gates enabling universality)
- **Two-qubit Clifford**: CX (CNOT), CY, CZ, SWAP, iSWAP

# Decomposition Pipeline

The basis applies rewrite rules in the following priority order:

1. [`SpecialAngleRewrite`](@ref): Rotations with angles k·π/4 → exact Clifford+T
2. [`ToffoliToCliffordTRewrite`](@ref): CCX → 7 T gates + Cliffords
3. [`ControlledPhaseToCliffordTRewrite`](@ref): CP, CRZ → Clifford+T
4. [`SwapToCliffotdRewrite`](@ref): SWAP → 3 CNOTs
5. [`ZYZRewrite`](@ref): GateU → RZ·RY·RZ
6. [`ToZRotationRewrite`](@ref): RX, RY → RZ + Cliffords
7. [`SolovayKitaevRewrite`](@ref): Arbitrary RZ → approximate Clifford+T
8. [`CanonicalRewrite`](@ref): Fallback for other gates

# Examples
```julia
# Decompose to Clifford+T
decompose(circuit; basis=CliffordTBasis())

# Check T-count after decomposition
decomposed = decompose(circuit; basis=CliffordTBasis())
t_count = count(inst -> getoperation(inst) isa Union{GateT, GateTDG}, decomposed)
```

# Performance Notes

- Exact decompositions (SpecialAngleRewrite) are preferred when applicable
- Solovay-Kitaev is only used as a last resort for arbitrary angles
- T-count optimization is not performed; use a dedicated pass for that

See also [`DecompositionBasis`](@ref), [`CanonicalBasis`](@ref).
"""
struct CliffordTBasis <: DecompositionBasis
    sk_depth::Int

    function CliffordTBasis(; sk_depth::Int = 3)
        new(sk_depth)
    end
end

# --- terminal operations — the Clifford+T gate set ---

# Identity
isterminal(::CliffordTBasis, ::GateID) = true

# Pauli gates (single-qubit Clifford)
isterminal(::CliffordTBasis, ::GateX) = true
isterminal(::CliffordTBasis, ::GateY) = true
isterminal(::CliffordTBasis, ::GateZ) = true

# Hadamard (single-qubit Clifford)
isterminal(::CliffordTBasis, ::GateH) = true

# Phase gates (single-qubit Clifford)
isterminal(::CliffordTBasis, ::GateS) = true
isterminal(::CliffordTBasis, ::GateSDG) = true

# √X gates (single-qubit Clifford)
isterminal(::CliffordTBasis, ::GateSX) = true
isterminal(::CliffordTBasis, ::GateSXDG) = true

# √Y gates (single-qubit Clifford)
isterminal(::CliffordTBasis, ::GateSY) = true
isterminal(::CliffordTBasis, ::GateSYDG) = true

# T gates (non-Clifford, enables universality)
isterminal(::CliffordTBasis, ::GateT) = true
isterminal(::CliffordTBasis, ::GateTDG) = true

# Two-qubit Clifford gates
isterminal(::CliffordTBasis, ::GateCX) = true
isterminal(::CliffordTBasis, ::GateCY) = true
isterminal(::CliffordTBasis, ::GateCZ) = true
isterminal(::CliffordTBasis, ::GateSWAP) = true
isterminal(::CliffordTBasis, ::GateISWAP) = true
isterminal(::CliffordTBasis, ::GateISWAPDG) = true
isterminal(::CliffordTBasis, ::GateDCX) = true
isterminal(::CliffordTBasis, ::GateECR) = true

# Measurement, reset, barriers
isterminal(::CliffordTBasis, ::Measure) = true
isterminal(::CliffordTBasis, ::Reset) = true
isterminal(::CliffordTBasis, ::Barrier) = true

# Classical operations pass through
isterminal(::CliffordTBasis, ::AbstractClassical) = true

# Annotations pass through
isterminal(::CliffordTBasis, ::AbstractAnnotation) = true

# Fallback
isterminal(::CliffordTBasis, ::Operation) = false

# --- decomposition pipeline ---

# Pre-instantiated rules (avoid allocation in hot path)
const _CLIFFORDT_SPECIAL_ANGLE = SpecialAngleRewrite()
const _CLIFFORDT_TOFFOLI = ToffoliToCliffordTRewrite()
const _CLIFFORDT_ZYZ = ZYZRewrite()
const _CLIFFORDT_TO_Z = ToZRotationRewrite()
const _CLIFFORDT_CANONICAL = CanonicalRewrite()

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

    # Priority 3: GateU → ZYZ decomposition
    if matches(_CLIFFORDT_ZYZ, op)
        return decompose_step!(builder, _CLIFFORDT_ZYZ, op, qtargets, ctargets, ztargets)
    end

    # Priority 4: RX, RY → RZ + Cliffords
    if matches(_CLIFFORDT_TO_Z, op)
        return decompose_step!(builder, _CLIFFORDT_TO_Z, op, qtargets, ctargets, ztargets)
    end

    # Priority 5: Arbitrary RZ → Solovay-Kitaev approximation
    sk_rule = SolovayKitaevRewrite(basis.sk_depth)
    if matches(sk_rule, op)
        return decompose_step!(builder, sk_rule, op, qtargets, ctargets, ztargets)
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
