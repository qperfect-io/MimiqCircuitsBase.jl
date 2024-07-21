#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

struct MeasureReset <: Operation{1, 1} end

opname(::Type{<:MeasureReset}) = "MeasureReset"

inverse(::MeasureReset) = error("MeasureReset is not inversible")

power(::MeasureReset, p) = error("MeasureReset^p is not defined.")

control(::MeasureReset, num_qubits) = error("Controlled MeasureReset is not defined.")

iswrapper(::MeasureReset) = false

function decompose!(circuit::Circuit, ::MeasureReset, qtargets, ctargets)
    push!(circuit, Measure(), qtargets, ctargets)
    push!(circuit, IfStatement(1, GateX(), 1), qtargets, ctargets)
    return circuit
end

function Base.show(io::IO, ::MeasureReset)
    print(io, opname(MeasureReset))
end
