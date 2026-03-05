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
using MimiqCircuitsBase
using Test

include("TestUtils.jl")
using .TestUtils

filelist = [
    "bitstrings.jl",
    "gates.jl",
    "standardgates.jl",
    "proto.jl",
    "proto/zregister.jl",
    "instruction.jl",
    "circuit.jl",
    "control.jl",
    "inverse.jl",
    "operators.jl",
    "noise.jl",
    "power.jl",
    "paulistrings.jl",
    "noisefunctions.jl",
    "rescaledgate.jl",
    "annotations.jl",
    "classical.jl",
    "complex.jl",
    "rpauli.jl",
    "hamiltonian.jl",
    "block.jl",
    "dsl.jl",
    "gatedecl.jl",
    "repeat.jl",
    "listvars.jl",
    "optimization.jl",
    "noisemodel.jl",
    "noisemodelproto.jl",
    "ifstatement.jl",
    "matrix_decompositions.jl",
    "circuitequality.jl",
    "dagcircuit.jl",
    "circuittester.jl",
    "test_rewrite_rules.jl",
    "test_decompositions.jl",
    "test_decomposition_bases.jl",
    "test_parametric_wrap.jl",
    "remove_swaps.jl",
]

@testset "MimiqCircuitsBase.jl" begin
    @testset "$filename" for filename in filelist
        @debug "Running $filename"
        include(filename)
    end
end

nothing
