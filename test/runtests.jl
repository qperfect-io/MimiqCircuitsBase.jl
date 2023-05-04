using MimiqCircuitsBase
using Test

filelist = String["test.jl", "json.jl", "bitstates.jl"]

@testset "MimiqCircuitsBase.jl" begin
    @testset "$filename" for filename in filelist
        @debug "Running $filename"
        include(filename)
    end
end

nothing
