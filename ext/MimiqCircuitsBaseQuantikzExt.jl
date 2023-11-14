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

module MimiqCircuitsBaseQuantikzExt

using Quantikz
using MimiqCircuitsBase

_latexpi(s::AbstractString) = replace(s, "π" => "{\\pi}")

function toquantikz(circ::Circuit)
    qz = []

    for inst in circ
        op = getoperation(inst)
        if op isa Control
            wop = getoperation(op)
            controls = collect(getqubits(inst)[1:numcontrols(op)])
            targets = collect(getqubits(inst)[numcontrols(op)+1:end])
            if wop isa GateX
                push!(qz, MultiControl(controls, [], targets, []))
            elseif wop isa GateSWAP
                push!(qz, MultiControl(controls, [], [], targets))
            else
                qzop = MultiControlU(_latexpi(string(wop)), controls, [], targets)
                push!(qz, qzop)
            end
        elseif op isa Measure
            push!(qz, Measurement(getqubit(inst, 1), getbit(inst, 1)))
            push!(qz, Id(getqubit(inst, 1)))
        elseif op isa Reset
            push!(qz, Measurement(getqubit(inst, 1)))
            push!(qz, Initialize("\\ket{0}", collect(getqubits(inst))))
        elseif op isa Barrier
            continue
        elseif op isa GateSWAP
            push!(qz, SWAP(getqubits(inst)...))
        elseif op isa AbstractGate{1}
            push!(qz, U(_latexpi(string(op)), getqubit(inst, 1)))
        elseif op isa AbstractGate{2}
            push!(qz, MultiControlU(_latexpi(string(op)), [], [], collect(getqubits(inst))))
        end
    end
    return qz
end

Quantikz.displaycircuit(circ::Circuit, args...; kwargs...) = displaycircuit(toquantikz(circ), args...; kwargs...)

Quantikz.savecircuit(circ::Circuit, args...; kwargs...) = savecircuit(toquantikz(circ), args...; kwargs...)

end # module
