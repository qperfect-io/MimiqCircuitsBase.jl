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

struct QCSResults
    # name of the simulator used
    simulator::Union{Nothing,String}

    # version of the simulator used
    version::Union{Nothing,String}

    # fidelity estimates
    fidelities::Vector{Float64}

    # fidelity estimates
    avggateerrors::Vector{Float64}

    # final classical states content
    cstates::Vector{BitVector}

    # final zstates content
    zstates::Vector{Vector{ComplexF64}}

    # final amplitudes
    amplitudes::Dict{BitState,ComplexF64}

    # precise timings of the execution
    timings::Dict{String,Float64}
end

QCSResults() = QCSResults(nothing, nothing, [], [], [], [], Dict(), Dict())

QCSResults(simulator, version) = QCSResults(simulator, version, [], [], [], [], Dict(), Dict())

function sampleshistogram(r::QCSResults)
    d = Dict{BitVector,Int}()

    for c in r.cstates
        if haskey(d, c)
            d[c] += 1
        else
            d[c] = 1
        end
    end

    return d
end

function _maxkeyvalue(d)
    maxkey, maxvalue = first(d)
    for (key, value) in d
        if value > maxvalue
            maxkey = key
            maxvalue = value
        end
    end
    maxkey, maxvalue
end

function Base.show(io::IO, ::MIME"text/plain", r::QCSResults)
    print(io, typeof(r))
    println(":")

    if !isnothing(r.simulator)
        print(io, "├── simulator: ", r.simulator)
        if isnothing(r.version)
            print('\n')
        else
            println(" ", r.version)
        end
    end

    if !isempty(r.timings)
        for (k, v) in r.timings
            println(io, "├── $k time: $(v)s")
        end
    end

    if !isempty(r.fidelities)
        println(io, "├── fidelity estimate (min,max): ", round.(extrema(r.fidelities); digits=3))
    end

    if !isempty(r.avggateerrors)
        println(io, "├── average ≥2-qubit gate error (min,max): ", round.(extrema(r.avggateerrors); digits=3))
    end

    println(io, "├── ", length(r.fidelities), " executions")
    println(io, "├── ", length(r.amplitudes), " amplitudes")
    print(io, "└── ", length(r.cstates), " samples")
end


