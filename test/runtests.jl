using MimiqCircuitsBase
using Test

include("utils.jl")

filelist = String["gates.jl", "instruction.jl", "circuit.jl", "json.jl", "bitstates.jl"]

@testset "MimiqCircuitsBase.jl" begin
    @testset "$filename" for filename in filelist
        @debug "Running $filename"
        include(filename)
    end
end

nothing
