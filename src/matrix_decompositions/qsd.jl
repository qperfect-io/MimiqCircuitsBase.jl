#
# Copyright © 2025-2025 QPerfect. All Rights Reserved.
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
    _qsd_decomposition(U::AbstractMatrix)

Perform Quantum Shannon Decomposition (QSD) on an N-qubit unitary ``U``.
Returns `(Circuit, Phase)` where `Circuit` implements ``U \cdot e^{-i \cdot \text{Phase}}``.
"""
function _qsd_decomposition(U::AbstractMatrix)
    n = size(U, 1)
    nb_qubits = Int(log2(n))

    if nb_qubits == 1
        return _decompose_1q(U, 1)
    end

    # Cosine-Sine Decomposition on the MSB (q1)
    # The matrix is partitioned 2x2 blocks of size 2^(N-1).
    # U = [L0 0; 0 L1] * M * [R0 0; 0 R1]
    L0, L1, R0, R1, theta = _csd_decomposition(U)

    circ = Circuit()

    # Targets for the sub-blocks (q2 ... qN)
    # Control is q1.
    sub_targets = collect(2:nb_qubits)

    # Right term: diag(R0, R1)
    pR = _append_multiplexed_unitary!(circ, R0, R1, 1, sub_targets)

    # Middle term: Multiplexed Ry
    # Encoded in theta. theta has length 2^(N-1).
    # M = MultiplexedRy(2 * theta) on q1 controlled by q2..qN
    # Controls correspond to q2..qN in standard order.
    _append_multiplexed_ry!(circ, 2 .* theta, 1, sub_targets)

    # Left term: diag(L0, L1)
    pL = _append_multiplexed_unitary!(circ, L0, L1, 1, sub_targets)

    return circ, pR + pL
end

function _decompose_1q(U, target)
    theta, phi, lambda, gamma = _zyz_decomposition(U)
    c = Circuit()
    push!(c, GateU(theta, phi, lambda, gamma), target)
    return c, 0.0
end

@doc raw"""
    _append_multiplexed_unitary!(circ, U0, U1, control, targets)

Appends decomposition of ``\operatorname{diag}(U_0, U_1)`` to `circ`.
Returns the common global phase offset.
"""
function _append_multiplexed_unitary!(circ, U0, U1, control, targets)
    # Base case: 1-qubit targets (total 2 qubits involved)
    if length(targets) == 1
        target = targets[1]

        # Decompose U0 and U1 into ZYZ
        t0, p0, l0, g0 = _zyz_decomposition(U0)
        t1, p1, l1, g1 = _zyz_decomposition(U1)

        # Structure: MRz(lambda) -> MRy(theta) -> MRz(phi) -> GlobalPhase

        _append_multiplexed_rz!(circ, [l0, l1], target, [control])
        _append_multiplexed_ry!(circ, [t0, t1], target, [control])
        _append_multiplexed_rz!(circ, [p0, p1], target, [control])

        # Calculate effective phase with correction for RzRyRz inherent phase (-p-l)/2
        phase0 = g0 + (p0 + l0) / 2
        phase1 = g1 + (p1 + l1) / 2

        push!(circ, GateP(phase1 - phase0), control)

        # Return common phase offset
        return phase0

    else
        # Recursive case
        return _append_multiplexed_unitary_recursive!(circ, U0, U1, control, targets)
    end
end

function _append_multiplexed_unitary_recursive!(circ, U0, U1, control, targets)
    c0, p0 = _qsd_decomposition(U0)
    c1, p1 = _qsd_decomposition(U1)

    mapping = Dict(i => targets[i] for i in 1:length(targets))

    push!(circ, GateX(), control)
    for inst in c0
        push!(circ, _add_control_remapped(inst, control, mapping))
    end
    push!(circ, GateX(), control)

    for inst in c1
        push!(circ, _add_control_remapped(inst, control, mapping))
    end

    # Correct relative phase between branch 0 (p0) and branch 1 (p1)
    # We align branch 1 to match branch 0's phase offset.
    push!(circ, GateP(p1 - p0), control)

    return p0
end

function _add_control_remapped(inst::Instruction, control_qubit, mapping)
    op = getoperation(inst)
    q = getqubits(inst)
    c = getbits(inst)
    z = getztargets(inst)

    new_q = [mapping[i] for i in q]
    # Add control to the operation
    return Instruction(Control(1, op), (control_qubit, new_q...), c, z)
end

"""
    _append_multiplexed_ry!(circ, angles, target, controls)

Appends a multiplexed Ry rotation on `target` controlled by `controls`.
`angles` has length 2^k where k = length(controls).
"""
function _append_multiplexed_ry!(circ, angles, target, controls)
    k = length(controls)
    n = length(angles)

    if k == 0
        push!(circ, GateRY(angles[1]), target)
        return
    end

    # Iterate over all 2^k control states
    for i in 1:n
        angle = angles[i]

        if abs(angle) < 1e-10
            continue
        end

        # Map linear index to control state bits
        state_idx = i - 1

        # Identify qubits that need X (where control bit is 0)
        active_x_indices = Int[]

        for bit_pos in 1:k
            # extract bit value from MSB-first state_idx
            bit_val = (state_idx >> (k - bit_pos)) & 1

            if bit_val == 0
                push!(active_x_indices, bit_pos)
            end
        end

        # Wrap operation with X-basis transform
        for idx in active_x_indices
            push!(circ, GateX(), controls[idx])
        end

        push!(circ, Control(k, GateRY(angle)), controls..., target)

        for idx in active_x_indices
            push!(circ, GateX(), controls[idx])
        end
    end
end

"""
    _append_multiplexed_rz!(circ, angles, target, controls)

Multiplexed Rz implementation.
"""
function _append_multiplexed_rz!(circ, angles, target, controls)
    k = length(controls)
    n = length(angles)

    if k == 0
        push!(circ, GateRZ(angles[1]), target)
        return
    end

    for i in 1:n
        angle = angles[i]

        if abs(angle) < 1e-10
            continue
        end

        state_idx = i - 1

        active_x_indices = Int[]
        for bit_pos in 1:k
            # MSB first mapping
            bit_val = (state_idx >> (k - bit_pos)) & 1
            if bit_val == 0
                push!(active_x_indices, bit_pos)
            end
        end

        for idx in active_x_indices
            push!(circ, GateX(), controls[idx])
        end

        push!(circ, Control(k, GateRZ(angle)), controls..., target)

        for idx in active_x_indices
            push!(circ, GateX(), controls[idx])
        end
    end
end
