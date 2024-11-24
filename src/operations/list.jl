#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
    GATES

List of gates provided by the library.

## Single qubit gates

[`GateID`](@ref),
[`GateX`](@ref), [`GateY`](@ref), [`GateZ`](@ref),
[`GateH`](@ref),
[`GateS`](@ref), [`GateSDG`](@ref),
[`GateT`](@ref), [`GateTDG`](@ref),
[`GateSX`](@ref), [`GateSXDG`](@ref).
[`GateSY`](@ref), [`GateSYDG`](@ref).

## Single qubit parametric gates

[`GateU`](@ref), [`GateP`](@ref),
[`GateRX`](@ref), [`GateRY`](@ref), [`GateRZ`](@ref), [`GateR`](@ref),
[`GateU1`](@ref), [`GateU2`](@ref), [`GateU3`](@ref).

## Two qubit gates

[`GateCX`](@ref), [`GateCY`](@ref), [`GateCZ`](@ref),
[`GateCH`](@ref),
[`GateSWAP`](@ref), [`GateISWAP`](@ref),
[`GateCS`](@ref), [`GateCSDG`](@ref),
[`GateCSX`](@ref), [`GateCSXDG`](@ref),
[`GateECR`](@ref),
[`GateDCX`](@ref),

## Two qubit parametric gates

[`GateCP`](@ref),
[`GateCU`](@ref),
[`GateCRX`](@ref), [`GateCRY`](@ref), [`GateCRZ`](@ref),
[`GateRXX`](@ref), [`GateRYY`](@ref), [`GateRZZ`](@ref), [`GateRZX`](@ref),
[`GateXXplusYY`](@ref), [`GateXXminusYY`](@ref).

## Multi qubit Gates

[`GateCCX`](@ref), [`GateC3X`](@ref),
[`GateCCP`](@ref),
[`GateCSWAP`](@ref).

## Generalized gates

These defines an unitary quantum operation on non fixed number of qubits.

See [`GENERALIZED`](@ref) for a list of them.

## Operations

See [`OPERATIONS`](@ref) for a complete list of operations.

## Noise channels

These define a non-unitary quantum operation based on the Kraus representation.

See [`NOISECHANNELS`](@ref) for a list of them.

"""
const GATES = Type[
    GateU,
    GateP,
    GateID,
    GateX,
    GateY,
    GateZ,
    GateH,
    GateHXY,
    GateHYZ,
    GateS,
    GateSDG,
    GateT,
    GateTDG,
    GateSX,
    GateSXDG,
    GateSY,
    GateSYDG,
    GateRX,
    GateRY,
    GateRZ,
    GateR,
    GateU1,
    GateU2,
    GateU3,
    GateCX,
    GateCY,
    GateCZ,
    GateCH,
    GateSWAP,
    GateISWAP,
    GateCS,
    GateCSDG,
    GateCSX,
    GateCSXDG,
    GateECR,
    GateDCX,
    GateCP,
    GateCU,
    GateCRX,
    GateCRY,
    GateCRZ,
    GateRXX,
    GateRYY,
    GateRZZ,
    GateRZX,
    GateXXplusYY,
    GateXXminusYY,
    GateCCX,
    GateC3X,
    GateCCP,
    GateCSWAP,
    Delay
]

"""
    OPERATIONS

## Phases and other unitaries

See [`GATES`](@ref) for a complete list unitary gates.

[`GateCustom`](@ref)

For gate definitions and calls, see [`GateDecl`](@ref) and [`GateCall`](@ref)

## Other circuits elements

[`Barrier`](@ref), [`IfStatement`](@ref)

## Modifiers

[`Control`](@ref), [`Parallel`](@ref), [`Power`](@ref), [`Inverse`](@ref)

## Non-unitary operations

[`Measure`](@ref), [`MeasureX`](@ref), [`MeasureY`](@ref), [`MeasureZ`](@ref),
[`MeasureXX`](@ref), [`MeasureYY`](@ref), [`MeasureZZ`](@ref)
[`MeasureReset`](@ref), [`MeasureResetX`](@ref), [`MeasureResetY`](@ref), [`MeasureResetZ`](@ref),
[`Reset`](@ref),

## Algorithms or complex gate builders

See [`GENERALIZED`](@ref) for a complete list of generalized gates or algorithms.
"""
const OPERATIONS = nothing

"""
    GENERALIZED

Definition of complex unitary quantum opteration on a not fixed number of qubits,
or on multiple groups of qubits (registers).

Usually they are initialized with the number of qubits they operate on, or with
the size of each group of qubits they act on

[`QFT`](@ref), [`PhaseGradient`](@ref)
"""
const GENERALIZED = [
    PhaseGradient,
    QFT,
    Diffusion,
    PolynomialOracle,
    PauliString,
    GateCustom,
]


"""
    NOISECHANNELS

List of noise channels provided by the library.

## Not mixed-unitary noise channels

[`Kraus`](@ref),
[`AmplitudeDamping`](@ref),
[`GeneralizedAmplitudeDamping`](@ref),
[`PhaseAmplitudeDamping`](@ref),
[`ThermalNoise`](@ref),
[`Reset`](@ref),

## Mixed-Unitary noise channels

[`MixedUnitary`](@ref),
[`PauliNoise`](@ref),
[`PauliX`](@ref), [`PauliY`](@ref), [`PauliZ`](@ref),
[`Depolarizing`](@ref),
"""
const NOISECHANNELS = Type[
    Kraus,
    MixedUnitary,
    PauliNoise,
    PauliX,
    PauliY,
    PauliZ,
    Depolarizing,
    AmplitudeDamping,
    GeneralizedAmplitudeDamping,
    PhaseAmplitudeDamping,
    ThermalNoise,
    Reset,
    ResetX,
    ResetY,
    ProjectiveNoiseX,
    ProjectiveNoiseY,
    ProjectiveNoiseZ,
]
