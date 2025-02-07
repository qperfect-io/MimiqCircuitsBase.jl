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
    decompose(operation)
    decompose(circuit)

Decompose the given operation or circuit into a circuit of more elementary gates.
If applied recursively, it will decompose the given object into a circuit of
[`GateCX`](@ref) and [`GateU`](@ref) gates.

See also [`decompose!`](@ref).
"""
function decompose end

"""
    decompose!(circuit, operation[, qtargets, ctargets])

In place version of [`decompose`](@ref).

It decomposes the given object, appending all the resulting operations to the
given circuit. The optional `qtargets` and `ctargets` arguments can be used to
map the qubits and classical bits of the decomposed operation to the ones
of the target circuit.
"""
function decompose! end

function decompose!(circuit::Circuit, g::Operation, qtargets, ctargets, ztargets)
    push!(circuit, g, qtargets..., ctargets..., ztargets...)
end

function decompose!(circuit::Circuit, inst::Instruction)
    return decompose!(circuit, getoperation(inst), getqubits(inst), getbits(inst), getztargets(inst))
end

function _checkdecompose!(circuit::Circuit, inst::Instruction{N,M,T}, issupported::Function) where {N,M,T}
    # PERF: speed here can be highly improved
    if issupported(getoperation(inst))
        push!(circuit, inst)
    else
        decomposed = decompose(inst)
        for inst2 in decomposed
            _checkdecompose!(circuit, inst2, issupported)
        end
    end
end

issupported_default(::T) where {T<:Operation} = issupported_default(T)
issupported_default(::Type{GateU}) = true
issupported_default(::Type{GateCX}) = true
issupported_default(::Type{<:Barrier}) = true
issupported_default(::Type{<:Measure}) = true
issupported_default(::Type{<:Reset}) = true
issupported_default(::Type{<:IfStatement{N,M,T}}) where {N,M,T} = issupported_default(T)
issupported_default(::Type{<:AbstractGate}) = false
issupported_default(::Type{<:GateCustom}) = true
issupported_default(::Type{<:Amplitude}) = true
issupported_default(::Type{<:Not}) = true
issupported_default(::Type{<:ExpectationValue}) = true
issupported_default(::Type{T}) where {T<:Union{MeasureReset,MeasureResetX, MeasureResetY, MeasureResetZ}} = false
issupported_default(::Type{T}) where {T<:Union{MeasureX, MeasureY}} = false
issupported_default(::Type{T}) where {T<:Union{MeasureXX, MeasureYY, MeasureZZ}} = false
issupported_default(::Type{T}) where {T<:Union{Detector, ObservableInclude, ShiftCoordinates, QubitCoordinates, Tick, }} = true
issupported_default(::Type{ResetX}) = false
issupported_default(::Type{ResetY}) = false
issupported_default(::Type{<:AbstractKrausChannel}) = true
issupported_default(::Type{<:AbstractOperator}) = true
issupported_default(::Type{T}) where {T<:Union{SchmidtRank,BondDim,VonNeumannEntropy}} = true
issupported_default(::Type{<:Detector}) = true
issupported_default(::Type{<:QubitCoordinates}) = true
issupported_default(::Type{<:ShiftCoordinates}) = true
issupported_default(::Type{<:PolynomialOracle}) = true

function decompose!(circuit::Circuit, todecompose::Circuit; issupported=issupported_default)
    for inst in todecompose
        _checkdecompose!(circuit, inst, issupported)
    end

    return circuit
end

function decompose(circuit::Circuit; kwargs...)
    return decompose!(Circuit(), circuit; kwargs...)
end

decompose(g::Operation{N,M,L}) where {N,M,L} = decompose!(Circuit(), g, 1:N, 1:M, 1:L)

decompose(inst::Instruction) = decompose!(Circuit(), inst)


