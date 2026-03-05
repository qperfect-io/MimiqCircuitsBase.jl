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
    MeasureReset()

This operation measures a qubit q, stores the value in a classical bit c,
then applies a X operation to the qubit if the measured value is 1, effectively
resetting the qubit to the :math:`\\ket{0}` state.


See also [`MeasureResetX`](@ref), [`MeasureResetY`](@ref), [`IfStatement`](@ref), [`GateH`](@ref).

## Examples

```jldoctests
julia> MeasureReset()
MR

julia> decompose(MeasureReset())
1-qubit, 1-bit circuit with 2 instructions:
├── M @ q[1], c[1]
└── Reset @ q[1]

julia> c = push!(Circuit(), MeasureReset(), 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── MR @ q[1], c[1]

julia> push!(c, MeasureReset(), 3, 4)
3-qubit, 4-bit circuit with 2 instructions:
├── MR @ q[1], c[1]
└── MR @ q[3], c[4]
```
"""
struct MeasureReset <: AbstractMeasurement{1} end

opname(::Type{<:MeasureReset}) = "MR"

inverse(::MeasureReset) = error("MeasureReset is not invertible.")

power(::MeasureReset, p) = error("MeasureReset cannot be elevated to a power.")

control(::MeasureReset, num_qubits) = error("Controlled MeasureReset is not defined.")

iswrapper(::MeasureReset) = false

matches(::CanonicalRewrite, ::MeasureReset) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureReset, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(builder, Measure(), q, c)
    push!(builder, Reset(), q)
    return builder
end

@doc raw"""
    MeasureResetX()

The MeasureResetX operation first applies a Hadamard gate (H) to the qubit,
performs a measurement and reset operation similar to the MeasureReset operation,
and then applies another Hadamard gate. This sequence effectively measures the
qubit in the X-basis and resets it to the `|+>` state.


See also [`MeasureReset`](@ref), [`MeasureResetY`](@ref), [`IfStatement`](@ref), [`GateH`](@ref).

## Examples

```jldoctests
julia> MeasureResetX()
MRX

julia> decompose(MeasureResetX())
1-qubit, 1-bit circuit with 4 instructions:
├── U(π/2,0,π) @ q[1]
├── M @ q[1], c[1]
├── Reset @ q[1]
└── U(π/2,0,π) @ q[1]

julia> c = push!(Circuit(), MeasureResetX(), 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── MRX @ q[1], c[1]

julia> push!(c, MeasureResetX(), 3, 4)
3-qubit, 4-bit circuit with 2 instructions:
├── MRX @ q[1], c[1]
└── MRX @ q[3], c[4]
```
"""
struct MeasureResetX <: AbstractMeasurement{1} end

opname(::Type{<:MeasureResetX}) = "MRX"

inverse(::MeasureResetX) = error("MeasureResetX is not invertible.")

power(::MeasureResetX, p) = error("MeasureResetX cannot be elevated to a power.")

control(::MeasureResetX, num_qubits) = error("Controlled MeasureResetX is not defined.")

iswrapper(::MeasureResetX) = false

matches(::CanonicalRewrite, ::MeasureResetX) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureResetX, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(builder, GateH(), q)
    push!(builder, MeasureReset(), q, c)
    push!(builder, GateH(), q)
    return builder
end

@doc raw"""
    MeasureResetY()

The MeasureResetY operation applies (HYZ) gate to
the qubit, performs a MeasureReset operation,
and then applies another HYZ gate. 
This sequence effectively measures the qubit in
the Y-basis.


See aclso [`MeasureResetX`](@ref), [`MeasureReset`](@ref), [`IfStatement`](@ref), [`GateHYZ`](@ref).

## Examples

```jldoctests
julia> MeasureResetY()
MRY

julia> decompose(MeasureResetY())
1-qubit, 1-bit circuit with 12 instructions:
├── U(π/2,0,π) @ q[1]
├── U(0,0,π/2) @ q[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,π) @ q[1]
├── U(0,0,0,-1π/4) @ q[1]
├── M @ q[1], c[1]
├── Reset @ q[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,π/2) @ q[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,π) @ q[1]
└── U(0,0,0,-1π/4) @ q[1]

julia> c = push!(Circuit(), MeasureResetY(), 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── MRY @ q[1], c[1]

julia> push!(c, MeasureResetY(), 3, 4)
3-qubit, 4-bit circuit with 2 instructions:
├── MRY @ q[1], c[1]
└── MRY @ q[3], c[4]
```
"""
struct MeasureResetY <: AbstractMeasurement{1} end

opname(::Type{<:MeasureResetY}) = "MRY"

inverse(::MeasureResetY) = error("MeasureResetY is not invertible.")

power(::MeasureResetY, p) = error("MeasureResetY cannot be elevated to a power.")

control(::MeasureResetY, num_qubits) = error("Controlled MeasureResetY is not defined.")

iswrapper(::MeasureResetY) = false

matches(::CanonicalRewrite, ::MeasureResetY) = true

function decompose_step!(builder, ::CanonicalRewrite, ::MeasureResetY, qtargets, ctargets, _)
    q = qtargets[1]
    c = ctargets[1]
    push!(builder, GateHYZ(), q)
    push!(builder, MeasureReset(), q, c)
    push!(builder, GateHYZ(), q)
    return builder
end

@doc raw"""
    MeasureResetZ()

This operation is an alias for [`MeasureReset`](@ref) Operation.

"""
const MeasureResetZ = MeasureReset
