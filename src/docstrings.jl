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
    numqubits(operation)
    numqubits(instruction)
    numqubits(circuit)

Number of qubits on which the given operation or instruction is defined.

See also [`numbits`](@ref).

## Examples

```jldoctests
julia> numqubits(GateCX())
2

julia> numqubits(Measure())
1

julia> c = Circuit(); push!(c, GateX(), 1); push!(c, GateCX(),3,6)
6-qubit circuit with 2 instructions:
├── X @ q[1]
└── CX @ q[3], q[6]

julia> numqubits(c)
6
```
"""
function numqubits end

"""
    numbits(instruction)
    numbits(circuit)

Number of classical bits on which the given operation or instruction is defined.

See also [`numqubits`](@ref).

## Examples

```jldoctests
julia> numbits(GateCX())
0

julia> numbits(Measure())
1

julia> c = Circuit(); push!(c, Measure(), 1, 1); push!(c, Measure(),1,3)
1-qubit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[1], c[3]

julia> numbits(c)
3
```
"""
function numbits end

"""
    inverse(circuit)
    inverse(instruction)
    inverse(operation)

Inverse of the given circuit, instruction or operation.

When the inverse is not a known operation, it will return an [`Inverse`](@ref)
object that wraps the original operation.

!!! details
    It throws an error if the object is not invertible. Such for example, in the
    case of non unitary operations, or circuits containing [`Measure`](@ref) or
    [`Reset`](@ref).

See also [`matrix`](@ref), [`isunitary`](@ref), [`power`](@ref).

## Examples

```jldoctests; setup = :(@variables λ)
julia> inverse(GateRX(λ))
RX(-λ)

julia> inverse(GateCSX())
C(SX†)
```
"""
function inverse end

"""
    power(operation, exponent)

Elevate an operation to a given exponent.

It performs simplifications when possible otherwise wraps the operation in
a [`Power`](@ref) object.

See also [`Power`](@ref), [`inverse`](@ref), [`Inverse`](@ref).

## Examples

```jldoctests
julia> power(GateX(), 1//2)
SX

julia> power(GateX(), 0.5)
X^0.5

julia> GateX()^2
ID

julia> GateCSX()^2
CX
```
"""
function power end

"""
    opname(instruction)
    opname(operation)

Name of the underlying quantum operation in a human readable format.

See also [`numqubits`](@ref), [`numbits`](@ref).

## Examples

```jldoctests
julia> opname(GateX())
"X"

julia> opname(GateRX(π/2))
"RX"

julia> opname(Instruction(GateCX(),1,2))
"CX"

julia> opname(QFT(4))
"QFT"
```
"""
function opname end

"""
    getoperation(operation)
    getoperation(instruction)

Returns the quantum operation associated to the given instruction.

See also [`iswrapper`](@ref).

## Examples

```jldoctests
julia> getoperation(Instruction(GateX(), 1))
X

julia> getoperation(GateSX())
X

julia> getoperation(GateCX())
X
```
"""
function getoperation end

