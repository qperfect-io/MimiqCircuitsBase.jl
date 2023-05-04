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
    tojson(circuit)

Returns a JSON string representing the given circuit.
"""
function tojson end

"""
    fromjson(str)
    fromjson(parsed_json_dict)

Returns a circuit from a JSON string or parsed JSON.
"""
function fromjson end

function tojson(c::Circuit)
    gates = []

    for g in c
        gate_dict = Dict("name" => gatename(g.gate), "targets" => collect(g.targets))
        if g.gate isa ParametricGate
            gate_dict["params"] = map(x -> getfield(g.gate, x), collect(parnames(g.gate)))
        end
        if g.gate isa Gate
            N = numqubits(g.gate)
            gate_dict["matrix"] = reshape(complex(matrix(g.gate)), 2^(2 * N))
            gate_dict["numqubits"] = N
        end
        push!(gates, gate_dict)
    end
    data = Dict("gates" => gates)

    if !isnothing(validate(CIRCUIT_SCHEMA, data))
        @warn "Validation of JSON Schema failed" validate(CIRCUIT_SCHEMA, data)
        error("Invalid json circuit format.")
    end
    JSON.json(data)
end

fromjson(s::AbstractString) = fromjson(JSON.parse(s))

function fromjson(data::Dict)
    if !isnothing(validate(CIRCUIT_SCHEMA, data))
        @warn "Validation of JSON Schema failed" validate(CIRCUIT_SCHEMA, data)
        error("Invalid json circuit format.")
    end

    gates = data["gates"]

    c = Circuit()

    for g in gates
        gatetype = BiMaps.getright(GATES, g["name"], nothing)

        # since we validated the schema, this should never happen
        if isnothing(gatetype)
            if g["name"] == "Custom"
                gatetype = Gate
            else
                gn = g["name"]
                error("Erro in JSON. No such gate as $gn")
            end
        end

        targets = g["targets"]
        if gatetype <: ParametricGate
            pars = g["params"]
            push!(c, gatetype(pars...), targets...)
        elseif gatetype <: Gate
            N = g["numqubits"]
            U = reshape(map(d -> d["re"] + im * d["im"], g["matrix"]), (2^N, 2^N))

            push!(c, gatetype(U), targets...)
        else
            push!(c, gatetype(), targets...)
        end
    end

    c
end

