#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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
    numqubits(gate)
    numqubits(barrier)
    numqubits(instruction)
    numqubits(circuit)

Number of qubits on which the given operation or instruction is defined.
"""
function numqubits end

"""
    numbits(instruction)
    numbits(circuit)

Number of classical bits on which the given operation or instruction is defined.
"""
function numbits end

"""
    hilbertspacedim(gate)
    hilberspacedim(circuit)

Hilbert space dimension for the given operation.
"""
function hilbertspacedim end

"""
    inverse(circuit)
    inverse(instruction)
    inverse(operation)

Return the inverse of the given operation.
"""
function inverse end

"""
    opname(instruction)
    opname(operation)

Returns the name of the given operation in a human readable format.
"""
function opname end

"""
    abstract type Operation{N,M}

## Parameters

* `N`: number of qubits the operation applies on.
* `M`: number of bits the operation applies on.

## Methods

* [`opname`](@ref)
* [`inverse`](@ref)
"""
abstract type Operation{N,M} end

opname(::Type{Operation}) = ""
opname(::T) where {T<:Operation} = opname(T)

numqubits(::Type{<:Operation{N,M}}) where {N,M} = N
numqubits(::Operation{N,M}) where {N,M} = N
numbits(::Type{<:Operation{N,M}}) where {N,M} = M
numbits(::Operation{N,M}) where {N,M} = M
hilbertspacedim(N::Integer) = 1 << N
hilbertspacedim(::Operation{N,M}) where {N,M} = 1 << N

function Base.show(io::IO, gate::Operation)
    print(io, opname(gate))
end

