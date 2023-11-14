using MimiqCircuitsBase
using Test

include("utils.jl")

filelist = [
    "bitstates.jl",
    "gates.jl",
    "proto.jl",
    "instruction.jl",
    "circuit.jl",
    "control.jl",
    "inverse.jl"
]

@testset "MimiqCircuitsBase.jl" begin
    @testset "$filename" for filename in filelist
        @debug "Running $filename"
        include(filename)
    end
end

nothing
