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

module MimiqCircuitsBase

import Base: typename

using BiMaps
using JSON
using JSONSchema
using LinearAlgebra

const CIRCUIT_SCHEMA = Schema(JSON.parsefile(joinpath(@__DIR__, "..", "schemas", "circuit.json")))

include("utils.jl")
include("matrices.jl")

# abstract gate types
export AbstractGate
export ParametricGate
export gatename, matrix, hilbertspacedim, numparams, numqubits, inverse, parnames
include("abstract.jl")

# single-qubit simple gates
export GateX, GateY, GateZ, GateH, GateS, GateSDG, GateT, GateTDG, GateSX, GateSXDG, GateID
include("singlequbit.jl")

# single-qubit parametric gates
export GateP, GateRX, GateRY, GateRZ, GateR, GateU1, GateU2, GateU2DG, GateU3, GateU
include("gates/gatep.jl")
include("gates/gaterx.jl")
include("gates/gatery.jl")
include("gates/gaterz.jl")
include("gates/gater.jl")
include("gates/gateu1.jl")
include("gates/gateu2.jl")
include("gates/gateu2dg.jl")
include("gates/gateu3.jl")
include("gates/gateu.jl")

# two-qubit simple gates
export GateCX, GateCY, GateCZ, GateCH, GateSWAP, GateISWAP, GateISWAPDG, GateCS, GateCSDG, GateCSX, GateCSXDG, GateECR, GateDCX,GateDCXDG
include("twoqubit.jl")

# two-qubit parametric gates
export GateCP, GateCRX, GateCRY, GateCRZ, GateCU, GateCR, GateRXX, GateRZZ, GateRYY, GateXXplusYY, GateXXminusYY
include("gates/gatecp.jl")
include("gates/gatecrx.jl")
include("gates/gatecry.jl")
include("gates/gatecrz.jl")
include("gates/gatecu.jl")
include("gates/gatecr.jl")
include("gates/gaterxx.jl")
include("gates/gaterzz.jl")
include("gates/gateryy.jl")
include("gates/gatexxplusyy.jl")
include("gates/gatexxminusyy.jl")

# multi-qubit simple gates
export GateCCX, GateCSWAP
include("multiqubit.jl")

# custom gates
export Gate
include("gates/custom.jl")

# circuits and circuit-embedded gates
export Circuit, CircuitGate
export getgate, gettarget, gettargets
include("circuit.jl")

# functions for circuits
export depth
include("circuit_function.jl")

# bimap of gates and their names
include("bimap.jl")

# OpenQASM parsers
export openqasmid, from_qasm
include("openqasm.jl")

# JSON serialization
export tojson, fromjson
include("json.jl")

# Bit states (states with defined values of the qubits) 
export BitState
export nonzeros
export bitstate_to_integer
export bitstate_to_index
export @bs_str
export bits
export to01
include("bitstates.jl")

end # module Circuits

