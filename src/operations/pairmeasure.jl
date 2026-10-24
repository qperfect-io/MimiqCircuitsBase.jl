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
    MeasureZZ()

The MeasureZZ operation measures the joint parity of two qubits in the Z-basis.
This is achieved by applying a controlled-X (CX) gate, measuring the target qubit,
and then applying another CX gate to undo the entanglement. The measurement result
indicates whether the qubits are in the same or different states in the Z-basis.

See Also [`MeasureYY`](@ref), [`MeasureXX`](@ref)

## Examples

```jldoctest
julia> c = Circuit()
empty circuit

julia> push!(c, MeasureZZ(), 1, 2, 1)
2-qubit, 1-bit circuit with 1 instruction:
└── MZZ @ q[1:2], c[1]
```
"""
struct MeasureZZ <: AbstractMeasurement{2} end

opname(::Type{<:MeasureZZ}) = "MZZ"

inverse(::MeasureZZ) = error("Cannot invert measurements")

matches(::CanonicalRewrite, ::MeasureZZ) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureZZ, qtargets, ctargets, _)
    q1, q2 = qtargets
    c = ctargets[1]
    push!(builder, GateCX(), q1, q2)
    push!(builder, Measure(), q2, c)
    push!(builder, GateCX(), q1, q2)
    return builder
end

@doc raw"""
    MeasureXX()

The MeasureXX operation measures the joint parity of two qubits in the X-basis,
that is the two-qubit Pauli operator ``X \otimes X``.
Its decomposition applies a controlled-X (CX) gate from the first qubit to the
second and a Hadamard (H) gate on the first qubit. Together they map
``X \otimes X`` to ``Z`` on the first qubit, which is then measured.
The H and CX gates are applied again afterwards to undo the basis change, so the
qubits are left in the post-measurement state of the ``X \otimes X`` measurement.

A result of `0` indicates that the qubits are in the same state, while a
result of `1` indicates that they are in different states.


See Also [`MeasureYY`](@ref), [`MeasureZZ`](@ref)

## Examples

```jldoctest
julia> c = Circuit()
empty circuit

julia> push!(c, MeasureXX(), 1, 2, 1)
2-qubit, 1-bit circuit with 1 instruction:
└── MXX @ q[1:2], c[1]
```
"""
struct MeasureXX <: AbstractMeasurement{2} end

opname(::Type{<:MeasureXX}) = "MXX"

inverse(::MeasureXX) = error("Cannot invert measurements")

matches(::CanonicalRewrite, ::MeasureXX) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureXX, qtargets, ctargets, _)
    q1, q2 = qtargets
    c = ctargets[1]
    push!(builder, GateCX(), q1, q2)
    push!(builder, GateH(), q1)
    push!(builder, Measure(), q1, c)
    push!(builder, GateH(), q1)
    push!(builder, GateCX(), q1, q2)
    return builder
end

@doc raw"""
    MeasureYY()

The MeasureYY operation measures the joint parity of two qubits in the Y-basis,
that is the two-qubit Pauli operator ``Y \otimes Y``.
Its decomposition applies an S gate to both qubits, a controlled-X (CX) gate from
the first qubit to the second and a Hadamard (H) gate on the first qubit. Together
they map ``Y \otimes Y`` to ``Z`` on the first qubit, which is then measured.
The H and CX gates and an S† gate on both qubits are applied afterwards to undo the
basis change, so the qubits are left in the post-measurement state of the
``Y \otimes Y`` measurement.

A result of `0` indicates that the qubits are in the same state, while a
result of `1` indicates that they are in different states.


See Also [`MeasureXX`](@ref), [`MeasureZZ`](@ref)

## Examples

```jldoctest
julia> c = Circuit()
empty circuit

julia> push!(c, MeasureYY(), 1, 2, 1)
2-qubit, 1-bit circuit with 1 instruction:
└── MYY @ q[1:2], c[1]
```
"""
struct MeasureYY <: AbstractMeasurement{2} end

opname(::Type{<:MeasureYY}) = "MYY"

inverse(::MeasureYY) = error("Cannot invert measurements")

matches(::CanonicalRewrite, ::MeasureYY) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureYY, qtargets, ctargets, _)
    q1, q2 = qtargets
    c = ctargets[1]
    push!(builder, GateS(), qtargets)
    push!(builder, GateCX(), q1, q2)
    push!(builder, GateH(), q1)
    push!(builder, Measure(), q1, c)
    push!(builder, GateH(), q1)
    push!(builder, GateCX(), q1, q2)
    push!(builder, GateSDG(), qtargets)
    return builder
end
