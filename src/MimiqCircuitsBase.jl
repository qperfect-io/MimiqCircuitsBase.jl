#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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

using LinearAlgebra
using ProtoBuf
using Symbolics
import Symbolics: inverse
using Reexport
using Statistics
using Random
using Bijections: Bijection
using SymbolicUtils
using InteractiveUtils: subtypes
using NearestNeighbors
using Graphs

# documentation of function
include("docstrings.jl")

include("exceptions.jl")
include("bitvectors.jl")
include("utils.jl")
include("matrices.jl")
include("shortestzip.jl")
include("lazybuilder.jl")


# abstract operations
export Operation
export opname
export hilbertspacedim
export numqubits
export numbits
export numzvars
export qregsizes
export cregsizes
export zregsizes
export iswrapper
export listvars
include("operation.jl")

# instructions apply quantum operations to specific qubits
# and classical bits
export AbstractInstruction
export Instruction
export getqubit
export getqubits
export getbit
export getbits
export getztarget
export getztargets
export getoperation
include("instruction.jl")

# abstract operator and parametric operators
export AbstractOperator
export matrix
export unwrappedmatrix
export parnames
export numparams
export getparam
export getparams
export opsquared
include("operations/operator.jl")

# abstract gates and parametric gates
export AbstractGate
include("operations/gate.jl")

export RescaledGate
export rescale
export rescale!
export getscale
include("operations/rescaledgate.jl")

export AbstractKrausChannel
export probabilities
export unwrappedprobabilities
export cumprobabilities
export unwrappedcumprobabilities
export krausmatrices
export unwrappedkrausmatrices
export krausoperators
export squaredkrausoperators
export unitarymatrices
export unwrappedunitarymatrices
export unitarygates
export ismixedunitary
include("operations/krauschannel.jl")

# circuits and circuit-embedded gates

export AbstractCircuit
export specify_operations
include("abstractcircuit.jl")


export emplace!
include("circuit/push.jl")
include("circuit/insert.jl")
include("circuit/emplace.jl")

export DepthFirstDAGIterator
export BreadthFirstDAGIterator
export topological_sort_by_bfs
export traverse_by_dfs
export traverse_by_bfs
include("graph_iterators.jl")

export Circuit
include("circuit.jl")


# initial, ahead of time decomposition definitions
include("decomposition/abstract.jl")
include("decomposition/rules/canonical.jl")

# matrix decompositions
include("matrix_decompositions/zyz.jl")
include("matrix_decompositions/csd.jl")
include("matrix_decompositions/qsd.jl")

export isunitary
export isopalias
include("abstract.jl")



# Bit strings
export BitString
export nonzeros
export bitstring_to_integer
export bitstring_to_index
export @bs_str
export tobits
export to01
include("bitstrings.jl")

export Control
export control
export numcontrols
export numtargets
include("operations/control.jl")

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
export parallel
include("operations/parallel.jl")

export Block
include("operations/block.jl")

export Repeat
include("operations/repeat.jl")

export GateU
include("operations/gates/standard/u.jl")

export GateP
include("operations/gates/standard/phase.jl")

export GateID
include("operations/gates/standard/id.jl")

export GateX
export GateY
export GateZ
include("operations/gates/standard/pauli.jl")

export GateH
export GateHXY
export GateHXZ
export GateHYZ
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

export GateSY
export GateSYDG
include("operations/gates/standard/sy.jl")

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
export GateISWAPDG
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

export Delay
include("operations/gates/delay.jl")

# custom gates
export GateCustom
include("operations/gates/custom.jl")

# generalized gates
export PhaseGradient
include("operations/generalized/phasegradient.jl")

export QFT
include("operations/generalized/qft.jl")

export PolynomialOracle
include("operations/generalized/polynomialoracle.jl")

export Diffusion
include("operations/generalized/diffusion.jl")

export PauliString
export @pauli_str
include("operations/generalized/paulistrings.jl")

export GateRNZ
include("operations/generalized/rnz.jl")

# other non-gate type instructions
export Barrier
include("operations/barrier.jl")

export Reset
export ResetX
export ResetY
export ResetZ
include("operations/reset.jl")

export AbstractMeasurement
export Measure
export MeasureX
export MeasureY
export MeasureZ
include("operations/measure.jl")

export MeasureXX
export MeasureYY
export MeasureZZ
include("operations/pairmeasure.jl")

export MeasureReset
export MeasureResetX
export MeasureResetY
export MeasureResetZ
include("operations/measurereset.jl")

export Amplitude
export getbitstring
include("operations/amplitude.jl")

export BondDim
export VonNeumannEntropy
export SchmidtRank
include("operations/entanglement.jl")

export ExpectationValue
include("operations/expectationvalue.jl")

export Operator
include("operations/operators/custom.jl")

export DiagonalOp
include("operations/operators/diagonals.jl")

export Projector0
export Projector1
export ProjectorX0
export ProjectorX1
export ProjectorY0
export ProjectorY1
export ProjectorZ0
export ProjectorZ1
export Projector00
export Projector01
export Projector10
export Projector11
include("operations/operators/projectors.jl")

export SigmaMinus
export SigmaPlus
include("operations/operators/sigmas.jl")

export Kraus
export MixedUnitary
include("operations/noisechannels/kraus.jl")
include("operations/noisechannels/mixedunitary.jl")

export PauliNoise
export PauliX
export PauliY
export PauliZ
include("operations/noisechannels/standard/pauli.jl")

export Depolarizing
export Depolarizing1
export Depolarizing2
include("operations/noisechannels/standard/depolarizing.jl")

export AmplitudeDamping
export GeneralizedAmplitudeDamping
include("operations/noisechannels/standard/ampdamping.jl")

export PhaseAmplitudeDamping
export ThermalNoise
include("operations/noisechannels/standard/phaseampdamping.jl")

export ProjectiveNoise
export ProjectiveNoiseX
export ProjectiveNoiseY
export ProjectiveNoiseZ
include("operations/noisechannels/standard/projectivenoise.jl")

export ReadoutErr
include("operations/redouterr.jl")

export decorate
export decorate!
export decorate_on_match_parallel
export decorate_on_match_parallel!
export decorate_on_match_single
export decorate_on_match_single!
export add_noise!
export add_noise
include("addnoise.jl")

export sample_mixedunitaries
include("samplenoise.jl")

# annotations
export AbstractAnnotation
export Detector
export QubitCoordinates
export ShiftCoordinates
export ObservableInclude
export Tick
export getnotes
include("operations/annotations.jl")

# classical operations
export And
export Not
export Or
export Xor
export ParityCheck
export SetBit0
export SetBit1
export AbstractClassical
include("operations/classical.jl")

# complex algebra
export Add
export Multiply
export Pow
include("operations/complex.jl")

# Pauli Rotation
export RPauli
include("operations/generalized/rpauli.jl")

include("dsl.jl")

export GateDecl
export @gatedecl
export GateCall
include("gatedecl.jl")

# decompositions
export CanonicalRewrite
export SpecialAngleRewrite
export ToZRotationRewrite
export ZYZRewrite
export ToffoliToCliffordTRewrite
export SolovayKitaevRewrite
export FlattenContainers

export DecompositionBasis
export RuleBasis
export CanonicalBasis
export CliffordTBasis
export QASMBasis
export StimBasis
export FlattenedBasis

export decompose_step, decompose_step!
export decompose, decompose!
export DecompositionIterator
export eachdecomposed
include("decomposition.jl")

# hamiltonians
export Hamiltonian
export getcoefficient
export push_lietrotter!
export push_suzukitrotter!
export push_expval!
export add_terms!
export HamiltonianTerm
export push_yoshidatrotter!
include("hamiltonian.jl")

# macros
export @circuit, @block, @on, @gatedecl
# include("circuit_macro.jl") # consolidated in dsl.jl


export evaluate
@reexport using Symbolics: @variables, inverse, variable
include("evaluate.jl")

export issymbolic
include("symbolics.jl")

include("instruction_extra.jl")

export GATES
export OPERATIONS
export GENERALIZED
export NOISECHANNELS
include("operations/list.jl")

# Simulation results
export QCSResults
export histsamples
include("qcsresults.jl")

export CircuitTesterExperiment
export build_circuit
export interpret_results
include("circuittester.jl")

# Optimization
export isvalid
export costhistory
export changeparameters
export changelistofparameters
export getcost
export getbest
export getresultofbest
export getresultsofhistory
export OptimizationResults
export OptimizationRun
export OptimizationExperiment
include("optimization.jl")

export AbstractNoiseRule
export priority
export matches
export before
export apply_rule
export GlobalReadoutNoise
export ExactQubitReadoutNoise
export SetQubitReadoutNoise
export OperationInstanceNoise
export ExactOperationInstanceQubitNoise
export SetOperationInstanceQubitNoise
export CustomNoiseRule
export NoiseModel
export describe
export apply_noise_model
export apply_noise_model!
export add_rule!
export add_operation_noise!
export add_readout_noise!
export IdleNoise
export SetIdleQubitNoise
export add_idle_noise!
include("noisemodel.jl")

# functions for circuits
export depth
export remove_unused
export remove_swaps
include("circuit_extras.jl")

# clean a proto file (arguement: path to the file)
function _clean_proto_file(fname)
    pbpath = _getjuliaprotopath(fname)
    lines = readlines(pbpath)
    for i in 1:length(lines)
        if occursin(r"^import\s(?!\.\.)[\w.]+_pb$", lines[i])
            lines[i] = replace(lines[i], "import " => "import ..")
        end
        if occursin(r"include", lines[i])
            lines[i] = ""
        end
        if occursin(r"# original file", lines[i])
            lines[i] = ""
        end
    end

    open(pbpath, "w") do io
        join(io, lines, "\n")
    end
end

# generate the path to the Julia proto file from the proto file name
function _getjuliaprotopath(fname)
    pbfname = replace(fname, r"\.proto$" => "_pb.jl")
    return joinpath(@__DIR__, "proto", pbfname)
end


# generate the proto files, if they don't exist
function _generateproto(fname)
    pbpath = _getjuliaprotopath(fname)
    if !isfile(pbpath)
        @info "Generating $pbpath from $fname"
        protojl(fname, joinpath(@__DIR__, "proto"), joinpath(@__DIR__, "proto"))
        _clean_proto_file(fname)
        return true
    end
    return false
end

function _generateallproto()
    gen = _generateproto("bitvector.proto")
    gen = _generateproto("pauli.proto") || gen
    gen = _generateproto("hamiltonian.proto") || gen
    gen = _generateproto("qcsresults.proto") || gen
    gen = _generateproto("circuit.proto") || gen
    gen = _generateproto("optim.proto") || gen
    gen = _generateproto("noisemodel.proto") || gen

    if gen
        _clean_proto_file("bitvector.proto")
        _clean_proto_file("pauli.proto")
        _clean_proto_file("hamiltonian.proto")
        _clean_proto_file("qcsresults.proto")
        _clean_proto_file("circuit.proto")
        _clean_proto_file("optim.proto")
        _clean_proto_file("noisemodel.proto")
    end
end

_generateallproto()

include("proto/bitvector_pb.jl")
include("proto/pauli_pb.jl")
include("proto/hamiltonian_pb.jl")
include("proto/circuit_pb.jl")
include("proto/qcsresults_pb.jl")
include("proto/optim_pb.jl")
include("proto/noisemodel_pb.jl")

include("proto/bitstring.jl")
include("proto/pauli.jl")
include("proto/hamiltonian.jl")
include("proto/qcsresults.jl")
include("proto/circuit.jl")
include("proto/optim.jl")
include("proto/noisemodel.jl")

export show_mimiq_hierarchy
include("generating_list.jl")

export saveproto
export loadproto
include("proto/proto.jl")

# Iterators
export samplemixedunitaries
include("iterators.jl")
import .CircuitIterators: samplemixedunitaries

include("recipes.jl")

export draw
include("circuit/draw.jl")

# Export Aliases for shorter gate names
include("aliases.jl")
export Aliases

# NOTE: disable precompilation when profiling runtime performance, as
# it can lead to wrong traces
include("_precompile.jl")
_precompile_()

end # module Circuits
