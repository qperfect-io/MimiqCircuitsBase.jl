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
    matrix(gate)

Return the matrix associated to the specified quantum gate.
"""
function matrix end

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
    abstract type Operation

## Methods

* [`opname`](@ref)
* [`inverse`](@ref)
"""
abstract type Operation end

opname(::Type{Operation}) = ""
opname(::T) where {T<:Operation} = opname(T)

"""
    abstract type Gate{N} <: Operation

Supertype for all the `N`-qubit gates.

# Methods

* [`inverse`](@ref)
* [`numqubits`](@ref)
* [`opname`](@ref)
* [`hilbertspacedim`](@ref)
* [`matrix`](@ref)
"""
abstract type Gate{N} <: Operation end

numqubits(::Type{<:Gate{N}}) where {N} = N
numqubits(::Gate{N}) where {N} = N
numbits(::Type{<:Gate{N}}) where {N} = 0
numbits(::Gate{N}) where {N} = 0
hilbertspacedim(N::Integer) = 1 << N
hilbertspacedim(::Gate{N}) where {N} = 1 << N

"""
    abstract type ParametricGate{N}

Supertype for all the parametric `N`-qubit gates.

# Methods

* [`inverse`](@ref)
* [`numqubits`](@ref)
* [`opname`](@ref)
* [`hilbertspacedim`](@ref)
* [`matrix`](@ref)
* [`numparams`](@ref)
* [`parnames`](@ref)
"""
abstract type ParametricGate{N} <: Gate{N} end

"""
    numparams(gate)

Number of parameters for the given parametric gate. Zero for non parametric
gates.
"""
function numparams end

numparams(::T) where {T<:Gate} = numparams(T)

numparams(::Type{T}) where {T<:Gate} = 0

"""
    parnames(gate)

Name of the parameters allowed for the given gate
"""
function parnames end

parnames(::T) where {T<:Gate} = parnames(T)

parnames(::Type{T}) where {T<:Gate} = ()


opname(::Type{Gate}) = ""

matrix(g::ParametricGate) = g.U

function Base.show(io::IO, gate::Operation)
    print(io, opname(gate))
end

function Base.show(io::IO, gate::ParametricGate)
    compact = get(io, :compact, false)
    print(io, opname(gate), "(")
    join(io, map(x -> "$x=" * _shortenfloat_pi(getproperty(gate, x)), parnames(gate)), compact ? "," : ", ")
    print(io, ")")
end

