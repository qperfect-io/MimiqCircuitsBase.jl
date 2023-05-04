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
    abstract type AbstractGate{N}

Supertype for all the `N`-qubit gates.

# Methods

* [`numqubits`](@ref)
* [`hilbertspacedim`](@ref)
* [`gatename`](@ref)
"""
abstract type AbstractGate{N} end

"""
    numqubits(gate)
    numqubits(circuit)

Number of qubits on which the given operation is defined.
"""
function numqubits end

numqubits(::Type{<:AbstractGate{N}}) where {N} = N
numqubits(::AbstractGate{N}) where {N} = N

"""
    hilbertspacedim(gate)
    hilberspacedim(circuit)

Hilbert space dimension for the given quantum operation.
"""
function hilbertspacedim end

hilbertspacedim(::AbstractGate{N}) where {N} = 1 << N
hilbertspacedim(N::Integer) = 1 << N

"""
    abstract type ParametricGate{N}

Supertype for all the parametric `N`-qubit gates.

# Methods

* [`numparams`](@ref)
"""
abstract type ParametricGate{N} <: AbstractGate{N} end

"""
    numparams(gate)

Number of parameters for the given parametric gate. Zero for non parametric
gates.
"""
function numparams end

numparams(::T) where {T<:AbstractGate} = numparams(T)

numparams(::Type{T}) where {T<:AbstractGate} = 0

"""
    parnames(gate)

Name of the parameters allowed for the given gate
"""
function parnames end

parnames(::T) where {T<:AbstractGate} = parnames(T)

parnames(::Type{T}) where {T<:AbstractGate} = ()

"""
    gatename(gate)
    gatename(gate_type)

Returns the name of the given gate in a human readable format
"""
function gatename end

# TODO: does it inline properly?
gatename(::T) where {T<:AbstractGate} = gatename(T)

gatename(::Type{AbstractGate}) = ""

"""
    matrix(gate)

Return the matrix associated to the specified quantum gate.
"""
function matrix end

matrix(g::ParametricGate) = g.U

"""
    inverse(circuit)
    inverse(circuit_gate)
    inverse(gate)

Return the inverse of the given circuit, circuit gate or gate.
"""
function inverse end

function Base.show(io::IO, gate::AbstractGate)
    print(io, gatename(gate))
end

function Base.show(io::IO, gate::ParametricGate)
    compact = get(io, :compact, false)
    print(io, gatename(gate), "(")
    join(io, map(x -> "$x=" * _shortenfloat_pi(getproperty(gate, x)), parnames(gate)), compact ? "," : ", ")
    print(io, ")")
end

