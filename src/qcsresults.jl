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
    cstates::Vector{BitString}

    # final zstates content
    zstates::Vector{Vector{ComplexF64}}

    # final amplitudes
    amplitudes::Dict{BitString,ComplexF64}

    # precise timings of the execution
    timings::Dict{String,Float64}
end

QCSResults() = QCSResults(nothing, nothing, [], [], [], [], Dict(), Dict())

QCSResults(simulator, version) = QCSResults(simulator, version, [], [], [], [], Dict(), Dict())

function histsamples(r::QCSResults)
    d = Dict{BitString,Int}()

    for c in r.cstates
        if haskey(d, c)
            d[c] += 1
        else
            d[c] = 1
        end
    end

    return d
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
        println(io, "├── timings:")
        timings = collect(r.timings)
        for (k, v) in timings[1:end-1]
            println(io, "│   ├── $k time: $(v)s")
        end
        println(io, "│   └── $(timings[end][1]) time: $(timings[end][2])s")
    end

    if length(r.fidelities) == 1
        println(io, "├── fidelity estimate: ", round.(r.fidelities[1]; digits=3))
    elseif !isempty(r.fidelities)
        println(io, "├── fidelity estimate:")
        println(io, "│   ├── mean: ", round.(mean(r.fidelities); digits=3))
        println(io, "│   ├── median: ", round.(median(r.fidelities); digits=3))
        println(io, "│   └── std: ", round.(std(r.fidelities); digits=3))
    end

    if length(r.avggateerrors) == 1
        println(io, "├── average >=2-qubit gate error estimate: ", round.(r.avggateerrors[1]; digits=3))
    elseif !isempty(r.avggateerrors)
        println(io, "├── average >=2-qubit gate error estimate:")
        println(io, "│   ├── mean: ", round.(mean(r.avggateerrors); digits=3))
        println(io, "│   ├── median: ", round.(median(r.avggateerrors); digits=3))
        println(io, "│   └── std: ", round.(std(r.avggateerrors); digits=3))
    end

    if !isempty(r.cstates)
        println(io, "├── most sampled:")
        h = histsamples(r)
        h = sort(collect(h), by=x -> x[2], rev=true)[1:min(5, length(h))]
        for (k, v) in h[1:end-1]
            println(io, "│   ├── ", k, " => ", v)
        end
        println(io, "│   └── ", h[end][1], " => ", h[end][2])
    end

    if !isempty(r.amplitudes)
        println(io, "├── amplitudes:")
        amplitudes = collect(r.amplitudes)
        for (k, v) in amplitudes[1:end-1]
            println(io, "│   ├── ", k, " => ", v)
        end
        println(io, "│   └── ", amplitudes[end][1], " => ", amplitudes[end][2])
    end


    println(io, "├── ", length(r.fidelities), " executions")
    println(io, "├── ", length(r.amplitudes), " amplitudes")
    print(io, "└── ", length(r.cstates), " samples")
end

function Base.show(io::IO, ::MIME"text/html", r::QCSResults)
    print(io, "<h3>QCSRresults</h3>")
    print(io, "<h4>Simulator</h4>")
    print(io, "<table>")
    print(io, "<tr><td>", r.simulator, " ", r.version, "</td><tr>")
    print(io, "</table>")

    print(io, "<h4>Timings</h4>")
    print(io, "<table>")
    for (k, v) in r.timings
        print(io, "<tr><td>", k, " time</td><td>", v, "s</td></tr>")
    end
    print(io, "</table>")

    if !isempty(r.fidelities)
        print(io, "<h4>Fideilty estimate</h4>")
        print(io, "<table>")
        if length(r.fidelities) == 1
            print(io, "<tr><td>Single run value</td><td>", round.(r.fidelities[1]; digits=3), "</td></tr>")
        else
            print(io, "<tr><td>Mean</td><td>", round.(mean(r.fidelities); digits=3), "</td></tr>")
            print(io, "<tr><td>Median</td><td>", round.(median(r.fidelities); digits=3), "</td></tr>")
            print(io, "<tr><td>Standard Deviation</td><td>", round.(std(r.fidelities); digits=3), "</td></tr>")
        end
        print(io, "</table>")
    end

    if !isempty(r.avggateerrors)
        print(io, "<h4>Average >=2-qubit gate error estimate</h4>")
        print(io, "<table>")
        if length(r.avggateerrors) == 1
            print(io, "<tr><td>Single run value</td><td>", round.(r.avggateerrors[1]; digits=3), "</td></tr>")
        else
            print(io, "<tr><td>Mean</td><td>", round.(mean(r.avggateerrors); digits=3), "</td></tr>")
            print(io, "<tr><td>Median</td><td>", round.(median(r.avggateerrors); digits=3), "</td></tr>")
            print(io, "<tr><td>Standard Deviation</td><td>", round.(std(r.avggateerrors); digits=3), "</td></tr>")
        end
        print(io, "</table>")
    end

    print(io, "<h4>Statistics</h4>")
    print(io, "<table>")
    print(io, "<tr><td>Number of executions</td><td>", length(r.fidelities), "</td></tr>")
    print(io, "<tr><td>Number of samples</td><td>", length(r.cstates), "</td></tr>")
    print(io, "<tr><td>Number of amplitudes</td><td>", length(r.amplitudes), "</td></tr>")
    print(io, "</table>")

    if !isempty(r.cstates)
        print(io, "<h4>Samples</h4>")
        print(io, "<table>")
        h = histsamples(r)
        h = sort(collect(h), by=x -> x[2], rev=true)[1:min(5, length(h))]
        for (k, v) in h
            print(io, "<tr><td>", k, "</td><td>", v, "</td></tr>")
        end
        print(io, "</table>")
    end

    if !isempty(r.amplitudes)
        print(io, "<h4>Amplitudes</h4>")
        print(io, "<table>")
        for (k, v) in r.amplitudes
            print(io, "<tr><td>", k, "</td><td>", v, "</td></tr>")
        end
        print(io, "</table>")
    end

end
