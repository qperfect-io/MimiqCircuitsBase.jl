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
    openqasmid(gate)
    openqasmid(gate_type)

Returns the OpenQASM id of the given gate.
"""
function openqasmid end

# TODO: does it inline properly?
openqasmid(::T) where {T<:Gate} = openqasmid(T)

# TODO: nothing or just a nonvalid id?
openqasmid(::Type{GateCustom}) = nothing

openqasmid(::Type{GateP}) = 1
openqasmid(::Type{GateX}) = 2
openqasmid(::Type{GateY}) = 3
openqasmid(::Type{GateZ}) = 4
openqasmid(::Type{GateH}) = 5
openqasmid(::Type{GateS}) = 6
openqasmid(::Type{GateSDG}) = 7
openqasmid(::Type{GateT}) = 8
openqasmid(::Type{GateTDG}) = 9
openqasmid(::Type{GateSX}) = 10
openqasmid(::Type{GateID}) = 11

openqasmid(::Type{GateRX}) = 12
openqasmid(::Type{GateRY}) = 13
openqasmid(::Type{GateRZ}) = 14

openqasmid(::Type{GateCX}) = 15
openqasmid(::Type{GateCY}) = 16
openqasmid(::Type{GateCZ}) = 17
openqasmid(::Type{GateCH}) = 18
openqasmid(::Type{GateSWAP}) = 19
# TODO: missing ISWAP

openqasmid(::Type{GateCP}) = 20
openqasmid(::Type{GateCRX}) = 21
openqasmid(::Type{GateCRY}) = 22
openqasmid(::Type{GateCRZ}) = 23
openqasmid(::Type{GateCU}) = 24

openqasmid(::Type{GateCCX}) = 25
openqasmid(::Type{GateCSWAP}) = 26

const SIMPLE_QASM_TO_GATE = Dict(
    "h" => GateH(),
    "x" => GateX(),
    "y" => GateY(),
    "z" => GateZ(),
    "s" => GateS(),
    "sdg" => GateSDG(),
    "swap" => GateSWAP(),
    "cx" => GateCX(),
    "cy" => GateCY(),
    "cz" => GateCZ(),
    "ch" => GateCH(),
    "ecr" => GateECR(),
)

const PARAMETRIC_QASM_TO_GATE = Dict(
    r"\b(?:(?:u1)|(?:p))\((.*)\)" => λ -> GateU1(λ),
    r"\bu2\((.*)\)" => (ϕ, λ) -> GateU2(ϕ, λ),
    r"\bu3\((.*)\)" => (θ, ϕ, λ) -> GateU3(θ, ϕ, λ),
    r"\br\((.*)\)" => (θ, ϕ) -> GateR(θ, ϕ),
    r"\brx\((.*)\)" => θ -> GateRX(θ),
    r"\bry\((.*)\)" => θ -> GateRY(θ),
    r"\brz\((.*)\)" => λ -> GateRZ(λ),
    r"\bu\((.*)\)" => (θ, ϕ, λ) -> GateU(θ, ϕ, λ),
    r"\bcp\((.*)\)" => λ -> GateCP(λ),
    r"\bcrx\((.*)\)" => θ -> GateCRX(θ),
    r"\bcry\((.*)\)" => θ -> GateCRX(θ),
    r"\bcrz\((.*)\)" => θ -> GateCRY(θ),
    r"\bcu\((.*)\)" => (θ, ϕ, λ, γ) -> GateCU(θ, ϕ, λ, γ),
)

function parse_qasm_gate(gatestring::AbstractString)::Gate
    if gatestring in keys(SIMPLE_QASM_TO_GATE)
        return SIMPLE_QASM_TO_GATE[gatestring]
    else  # we have a parametric gate
        regex_gate = Tuple(
            filter(x -> match(x, gatestring) !== nothing, keys(PARAMETRIC_QASM_TO_GATE)),
        )[1]
        # e.g. for "u(pi/2,0,pi)" arg_string is "pi/2,0,pi"
        arg_string::String = match(regex_gate, gatestring).captures[1]
        # e.g. for arg_string "pi/2,0,pi" this would be Tuple(pi/2,0,pi)
        args = Tuple(map(x -> Float64(eval(Meta.parse(x))), split(arg_string, ",")))
        M = PARAMETRIC_QASM_TO_GATE[regex_gate](args...)
        return M
    end
end

const QASM_IGNORE = ["OPENQASM", "include", "measure", "creg", "barrier"]

function _read_qasm_reg(io::IO)
    while !eof(io)
        line = readline(io)
        if isempty(line) || all(isspace, line)
            @debug "Skipping empty line"
            continue
        end

        spl = split(replace(line, ";" => ""))

        if spl[begin] == "qreg"
            qnstr = spl[2][(findfirst("[", spl[2])[1]+1):(findfirst("]", spl[2])[1]-1)]
            return parse(Int, qnstr)
        elseif spl[begin] in QASM_IGNORE
            @debug "Ignoring line"
            continue
        else
            error("QASM 2.0 qreg definition must come before the first gate")
        end
    end
    error("QASM 2.0 no qreg definition")
end

"""
    from_qasm(file[; verbose = true])
    from_qasm(io[; verbose = true])

Compose a circuit by reading its definition from a simple QASM 2.0 file.

# Caveats

* This is not a complete parser of QASM file
* Circuit is assumed to be composed of only standard gates
* Other constructs will be ignored (loops, inputs, conditionals etc..)
* Includes or gate definition will not be parsed.
"""
function from_qasm end

function from_qasm(s::String; kwargs...)
    open(s) do io
        from_qasm(io; kwargs...)
    end
end

function from_qasm(io::IO; verbose=true)

    if readline(io) != "OPENQASM 2.0;"
        error("File or version of OpenQasm not supported")
    end

    nq = _read_qasm_reg(io)
    n1 = 0
    n2 = 0

    circuit = Circuit(nq)

    while !eof(io)
        line = readline(io)

        if isempty(line) || all(isspace, line)
            @debug "Skipping empty line"
            continue
        end

        spl = split(replace(line, ";" => ""))

        if spl[begin] in QASM_IGNORE
            @debug "Ignoring line"
        end

        if spl[begin] == "qreg"
            error("Multiple qreg definitions")
        end

        # parse the gate!
        gate = parse_qasm_gate(spl[1])

        if numqubits(gate) == 1
            qnstr = spl[2][(findfirst("[", spl[2])[1]+1):(findfirst("]", spl[2])[1]-1)]

            push!(circuit, gate, parse(Int, qnstr) + 1)

            n1 += 1

        elseif numqubits(gate) == 2

            qnstr1 = spl[2][(findfirst("[", spl[2])[1]+1):(findfirst("]", spl[2])[1]-1)]
            qnstr2 = spl[2][(findlast("[", spl[2])[1]+1):(findlast("]", spl[2])[1]-1)]

            push!(circuit, gate, parse(Int, qnstr1) + 1, parse(Int, qnstr2) + 1)
            n2 += 1

        else
            error("invalid $(numqubits(gate))-qubits gate")
        end
    end

    if verbose
        @info "INFO: read in circuit for $nq qubits with $n1 1-qubit and $n2 2-qubit gates."
    end

    return circuit
end
