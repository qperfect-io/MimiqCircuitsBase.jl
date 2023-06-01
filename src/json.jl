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
    instructions = []

    for g in c
        op = getoperation(g)
        dict = Dict(
            "name" => opname(op),
            "qtargets" => collect(getqubits(g)),
            "ctargets" => collect(getbits(g)),
        )
        if op isa ParametricGate
            dict["params"] = map(x -> getfield(op, x), collect(parnames(op)))
        end
        if op isa GateCustom
            N = numqubits(op)
            dict["matrix"] = reshape(complex(matrix(op)), 2^(2 * N))
            dict["numqubits"] = N
        end
        push!(instructions, dict)
    end
    data = Dict("instructions" => instructions)

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

    instructions = data["instructions"]

    c = Circuit()

    for g in instructions
        optype = BiMaps.getright(OPERATIONS, g["name"], nothing)

        # since we validated the schema, this should never happen
        if isnothing(optype)
            if g["name"] == "Custom"
                optype = GateCustom
            else
                gn = g["name"]
                error("Erro in JSON. No such operation as \"$gn\"")
            end
        end

        qtargets = tuple(g["qtargets"]...)
        ctargets = tuple(g["ctargets"]...)
        N = length(qtargets)
        M = length(ctargets)
        if optype <: ParametricGate
            pars = g["params"]
            op = optype(pars...)
            push!(c, Instruction{N,M,typeof(op)}(op, qtargets, ctargets))
        elseif optype <: GateCustom
            hdim = 2^N
            U = reshape(map(d -> d["re"] + im * d["im"], g["matrix"]), (hdim, hdim))
            op = optype(_decomplex.(U))
            push!(c, Instruction{N,M,typeof(op)}(op, qtargets, ctargets))
        else
            push!(c, Instruction{N,M,optype}(optype(), qtargets, ctargets))
        end
    end

    c
end

