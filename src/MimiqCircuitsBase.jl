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

# abstract operations
export ParametricGate
export Operation
export opname
export inverse
export hilbertspacedim
export numbits, numqubits
include("operation.jl")

# instructions apply quantum operations to specific qubits
# and classical bits
export Instruction
export getqubit, getqubits
export getbit, getbits
export getoperation
include("instruction.jl")

# circuits and circuit-embedded gates
export Circuit
include("circuit.jl")

# functions for circuits
export depth
include("circuit_extras.jl")

# Bit states (states with defined values of the qubits) 
export BitState
export nonzeros
export bitstate_to_integer
export bitstate_to_index
export @bs_str
export bits
export to01
include("bitstates.jl")

# abstract gates and parametric gates
export Gate
export matrix
export ParametricGate
export parnames
export numparams
include("operations/gate.jl")

# single-qubit simple gates
export GateX
export GateY
export GateZ
export GateH
export GateS
export GateSDG
export GateT
export GateTDG
export GateSX
export GateSXDG
export GateID
include("operations/gates/singlequbit.jl")

# single-qubit parametric gates
export GateP
export GateRX
export GateRY
export GateRZ
export GateR
export GateU1
export GateU2
export GateU2DG
export GateU3
export GateU
include("operations/gates/singlequbitpar.jl")

# two-qubit simple gates
export GateCX
export GateCY
export GateCZ
export GateCH
export GateSWAP
export GateISWAP
export GateISWAPDG
export GateCS
export GateCSDG
export GateCSX
export GateCSXDG
export GateECR
export GateDCX
export GateDCXDG
include("operations/gates/twoqubit.jl")

# two-qubit parametric gates
export GateCP
export GateCRX
export GateCRY
export GateCRZ
export GateCU
export GateCR
export GateRXX
export GateRZZ
export GateRYY
export GateXXplusYY
export GateXXminusYY
include("operations/gates/twoqubitpar.jl")

# multi-qubit simple gates
export GateCCX
export GateCSWAP
include("operations/gates/multiqubit.jl")

# custom gates
export GateCustom
include("operations/gates/custom.jl")

# other non-gate type instructions
export Barrier
include("operations/barrier.jl")

export Reset
include("operations/reset.jl")

export Measure
include("operations/measure.jl")

export IfStatement
include("operations/ifstatement.jl")

export Control
include("operations/control.jl")

export Parallel
include("operations/parallel.jl")

# bimap of gates and their names
include("bimap.jl")

# JSON serialization
export tojson, fromjson
include("json.jl")

end # module Circuits

