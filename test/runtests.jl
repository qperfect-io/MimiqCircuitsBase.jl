#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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

include("utils.jl")

filelist = [
    "bitstrings.jl",
    "gates.jl",
    "proto.jl",
    "proto/zregister.jl",
    "instruction.jl",
    "circuit.jl",
    "control.jl",
    "inverse.jl",
    "decompositions.jl",
    "operators.jl",
    "noise.jl",
    "power.jl",
    "paulistrings.jl",
    "noisefunctions.jl",
    "rescaledgate.jl",
    "annotations.jl",
    "classical.jl"
]

@testset "MimiqCircuitsBase.jl" begin
    @testset "$filename" for filename in filelist
        @debug "Running $filename"
        include(filename)
    end
end

nothing
