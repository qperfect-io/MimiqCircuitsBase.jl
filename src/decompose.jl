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

function decompose!(circuit::Circuit, g::Operation, qtargets, ctargets)
    push!(circuit, g, qtargets..., ctargets...)
end

function decompose!(circuit::Circuit, inst::Instruction)
    return decompose!(circuit, getoperation(inst), getqubits(inst), getbits(inst))
end

function _checkdecompose!(circuit::Circuit, inst::Instruction{N,M,T}; issupported=_ -> false) where {N,M,T}
    # PERF: speed here can be highly improved
    if issupported(getoperation(inst))
        push!(circuit, inst)
    else
        decompose!(circuit, inst)
    end
end

function decompose!(circuit::Circuit, todecompose::Circuit; kwargs...)
    for inst in todecompose
        _checkdecompose!(circuit, inst; kwargs...)
    end

    return circuit
end

function decompose(circuit::Circuit; kwargs...)
    return decompose!(Circuit(), circuit; kwargs...)
end

decompose(g::Operation{N,M}) where {N,M} = decompose!(Circuit(), g, 1:N, 1:M)

decompose(inst::Instruction) = decompose!(Circuit(), inst)
