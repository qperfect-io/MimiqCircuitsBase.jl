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

using BiMaps
using LinearAlgebra
using ProtoBuf
using Symbolics
using Reexport

# documentation of function
include("docstrings.jl")

include("bitvectors.jl")
include("utils.jl")
include("matrices.jl")
include("shortestzip.jl")

export isunitary
export isopalias
include("abstract.jl")

# abstract operations
export Operation
export opname
export hilbertspacedim
export numqubits
export numbits
export iswrapper
include("operation.jl")

# instructions apply quantum operations to specific qubits
# and classical bits
export AbstractInstruction
export Instruction
export getqubit
export getqubits
export getbit
export getbits
export getoperation
include("instruction.jl")

# abstract gates and parametric gates
export AbstractGate
export matrix
export parnames
export numparams
export getparam
export getparams
include("operations/gate.jl")

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

export GPhase
include("operations/gphase.jl")

export Control
export numcontrols
export numtargets
include("operations/control.jl")
include("operations/decompositions/control.jl")

export Power
export power
include("operations/power.jl")

export IfStatement
include("operations/ifstatement.jl")

export Inverse
export inverse
include("operations/inverse.jl")

export Parallel
export numrepeats
include("operations/parallel.jl")

export GateU
export GateUPhase
include("operations/gates/standard/u.jl")

export GateP
include("operations/gates/standard/phase.jl")

export GateID
export GateID2
include("operations/gates/standard/id.jl")

export GateX
export GateY
export GateZ
include("operations/gates/standard/pauli.jl")

export GateH
include("operations/gates/standard/hadamard.jl")

export GateS
export GateSDG
include("operations/gates/standard/s.jl")

export GateT
export GateTDG
include("operations/gates/standard/t.jl")

export GateSX
export GateSXDG
include("operations/gates/standard/sx.jl")

export GateRX
export GateRY
export GateRZ
export GateR
include("operations/gates/standard/rotations.jl")

export GateU1
export GateU2
export GateU3
include("operations/gates/standard/deprecated.jl")

export GateCX
export GateCY
export GateCZ
include("operations/gates/standard/cpauli.jl")

export GateCH
include("operations/gates/standard/chadamard.jl")

export GateSWAP
include("operations/gates/standard/swap.jl")

export GateISWAP
include("operations/gates/standard/iswap.jl")

export GateCS
export GateCSDG
include("operations/gates/standard/cs.jl")

export GateCSX
export GateCSXDG
include("operations/gates/standard/csx.jl")

export GateECR
include("operations/gates/standard/ecr.jl")

export GateDCX
include("operations/gates/standard/dcx.jl")

export GateCP
include("operations/gates/standard/cphase.jl")

export GateCU
include("operations/gates/standard/cu.jl")

export GateCRX
export GateCRY
export GateCRZ
include("operations/gates/standard/crotations.jl")

export GateRXX
export GateRYY
export GateRZZ
export GateRZX
export GateXXplusYY
export GateXXminusYY
include("operations/gates/standard/interactions.jl")

export GateCCX
export GateC3X
include("operations/gates/standard/cnx.jl")

export GateCCP
include("operations/gates/standard/cnp.jl")

export GateCSWAP
include("operations/gates/standard/cswap.jl")

# custom gates
export GateCustom
include("operations/gates/custom.jl")

# generalized gates
export PhaseGradient
include("operations/generalized/phasegradient.jl")

export QFT
include("operations/generalized/qft.jl")

# other non-gate type instructions
export Barrier
include("operations/barrier.jl")

export Reset
include("operations/reset.jl")

export Measure
include("operations/measure.jl")

# decomposition
export decompose
export decompose!
include("decompose.jl")

# macros
export @circuit
include("circuit_macro.jl")

export GateDecl
export @gatedecl
export GateCall
include("gatedecl.jl")

export evaluate
@reexport using Symbolics: @variables
include("evaluate.jl")

export GATES
export OPERATIONS
include("operations/list.jl")

# simulation results
export QCSResults
include("qcsresults.jl")

const PROTOFILES = String["circuit", "qcsresults"]

# generate the proto files, if they don't exist
for file in PROTOFILES
    fname = "proto/$file.proto"
    if !isfile(joinpath(@__DIR__, fname))
        protojl(fname, joinpath(@__DIR__), joinpath(@__DIR__, "proto"))
    end
    include("proto/$(file)_pb.jl")
end

include("proto/circuit.jl")
include("proto/qcsresults.jl")

export saveproto
export loadproto
include("proto/proto.jl")

# disable precompilation when profiling runtime performance, as
# it can lead to wrong traces
#include("_precompile.jl")
#_precompile_()

end # module Circuits

