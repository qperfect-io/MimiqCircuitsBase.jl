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
    QASMBasis <: DecompositionBasis

Decomposition basis targeting the OpenQASM 2.0 gate library.

This basis includes all gates defined in `qelib1.inc` (the standard QASM 2.0 library)
plus common extensions, making it suitable for exporting circuits to QASM format or
running on QASM-compatible backends.

# Terminal Operations

The following gate categories are terminal (not decomposed further):

**Fundamental gates (OpenQASM 2.0 built-in):**
- `GateU`, `GateCX` — the universal basis for QASM 2.0

**Single-qubit gates from qelib1.inc:**
- Legacy U gates: `GateU3`, `GateU2`, `GateU1`
- Pauli: `GateID`, `GateX`, `GateY`, `GateZ`
- Hadamard: `GateH`
- Phase: `GateS`, `GateSDG`, `GateT`, `GateTDG`
- Rotations: `GateRX`, `GateRY`, `GateRZ`

**Two-qubit gates from qelib1.inc:**
- Controlled Paulis: `GateCY`, `GateCZ`
- Controlled Hadamard: `GateCH`
- Swap family: `GateSWAP`
- Controlled rotations: `GateCRX`, `GateCRY`, `GateCRZ`
- Ising coupling: `GateRXX`, `GateRZZ`

**Three-qubit gates from qelib1.inc:**
- `GateCCX` (Toffoli), `GateCSWAP` (Fredkin)

**Four-qubit gates from qelib1.inc:**
- `GateC3X`

**Non-unitary operations:**
- `Measure`, `Reset`, `Barrier`
- `IfStatement` (if inner operation is terminal)

**Oher operations:**
- `GateCall` (custom gate invocations)

# Examples
```julia
# Decompose to QASM-compatible gates
decompose(circuit; basis=QASMBasis())

# Export to OpenQASM 2.0
qasm_circuit = decompose(circuit; basis=QASMBasis())
saveqasm(qasm_circuit, "output.qasm")
```

See also [`DecompositionBasis`](@ref), [`CanonicalBasis`](@ref), [`CliffordTBasis`](@ref).
"""
struct QASMBasis <: DecompositionBasis end

# === terminal operations — OpenQASM 2.0 / qelib1.inc ===

# --- Fundamental gates (QASM 2.0 built-in) ---

isterminal(::QASMBasis, ::GateU) = true
isterminal(::QASMBasis, ::GateCX) = true


# --- Single-qubit gates from qelib1.inc ---

# Legacy U gates
isterminal(::QASMBasis, ::GateU3) = true
isterminal(::QASMBasis, ::GateU2) = true
isterminal(::QASMBasis, ::GateU1) = true

# Pauli gates
isterminal(::QASMBasis, ::GateID) = true
isterminal(::QASMBasis, ::GateX) = true
isterminal(::QASMBasis, ::GateY) = true
isterminal(::QASMBasis, ::GateZ) = true

# Hadamard
isterminal(::QASMBasis, ::GateH) = true

# Phase gates
isterminal(::QASMBasis, ::GateS) = true
isterminal(::QASMBasis, ::GateSDG) = true
isterminal(::QASMBasis, ::GateT) = true
isterminal(::QASMBasis, ::GateTDG) = true

# Rotation gates
isterminal(::QASMBasis, ::GateRX) = true
isterminal(::QASMBasis, ::GateRY) = true
isterminal(::QASMBasis, ::GateRZ) = true

# --- Two-qubit gates from qelib1.inc ---

# Controlled Pauli gates
isterminal(::QASMBasis, ::GateCY) = true
isterminal(::QASMBasis, ::GateCZ) = true
isterminal(::QASMBasis, ::GateCH) = true

# Controlled rotation gates
isterminal(::QASMBasis, ::GateCRX) = true
isterminal(::QASMBasis, ::GateCRY) = true
isterminal(::QASMBasis, ::GateCRZ) = true

# Swap
isterminal(::QASMBasis, ::GateSWAP) = true

# Ising coupling gates
isterminal(::QASMBasis, ::GateRXX) = true
isterminal(::QASMBasis, ::GateRZZ) = true

# --- Three-qubit gates from qelib1.inc ---

isterminal(::QASMBasis, ::GateCCX) = true # Toffoli
isterminal(::QASMBasis, ::GateCSWAP) = true # Fredkin
isterminal(::QASMBasis, ::GateC3X) = true

# --- Non-unitary operations ---

isterminal(::QASMBasis, ::Measure) = true
isterminal(::QASMBasis, ::Reset) = true
isterminal(::QASMBasis, ::Barrier) = true

# --- Custom gate calls (user-defined gates) ---

# A GateCall is terminal only if all instructions inside its declaration are terminal.
# This ensures nested non-terminal operations (e.g. Inverse{GateCall}) are decomposed.
function isterminal(basis::QASMBasis, gc::GateCall)
    return all(inst -> isterminal(basis, getoperation(inst)), gc._decl._instructions)
end

# --- Conditional operations ---

# IfStatement is terminal if its inner operation is terminal
isterminal(basis::QASMBasis, op::IfStatement) = isterminal(basis, getoperation(op))

# --- Fallback ---

isterminal(::QASMBasis, ::Operation) = false

# === Decomposition — delegate to CanonicalRewrite ===

function decompose!(builder, ::QASMBasis, op::Operation, qtargets, ctargets, ztargets)
    if matches(CanonicalRewrite(), op)
        return decompose_step!(builder, CanonicalRewrite(), op, qtargets, ctargets, ztargets)
    end
    throw(DecompositionError(
        "Operation $(opname(op)) cannot be decomposed into the OpenQASM 2.0 basis."
    ))
end
