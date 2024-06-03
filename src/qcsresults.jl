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

"""
    QCSRresults()
    QCSRresults(simulator, version, fidelities, avggateerrors, cstates, zstates, amplitudes, timings)

Storage for the results of a quantum circuit simulation.

# Fields

* `simulator`: name of the simulator used,
* `version`: version of the simulator used,
* `fidelities`: fidelity estimates,
* `avggateerrors`: average multiqubit gate errors,
* `cstates`: classical states content,
* `zstates`: complex valued states content (not used),
* `amplitudes`: amplitudes,
* `timings`: precise timings of the execution.
"""
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

function _helper_roundfidelity(fid)
    if fid ≈ 1.0
        return 1.0
    end
    floor(fid; sigdigits=3)
end

function _helper_rounderror(err)
    if err ≈ 0.0
        return 0.0
    end
    ceil(err; sigdigits=3)
end

function Base.show(io::IO, ::MIME"text/plain", r::QCSResults)
    print(io, typeof(r))
    println(io, ":")

    if !isnothing(r.simulator)
        print(io, "├── simulator: ", r.simulator)
        if isnothing(r.version)
            print(io, '\n')
        else
            println(io, " ", r.version)
        end
    end

    if !isempty(r.timings)
        println(io, "├── timings:")
        timings = collect(filter(((k, v),) -> v > 1e-7, r.timings))
        for (k, v) in timings[1:end-1]
            println(io, "│   ├── $k time: $(v)s")
        end
        println(io, "│   └── $(timings[end][1]) time: $(timings[end][2])s")
    end

    if length(r.fidelities) == 1
        println(io, "├── fidelity estimate: ", _helper_roundfidelity(r.fidelities[1]))
    elseif !isempty(r.fidelities)
        println(io, "├── fidelity estimate:")
        println(io, "│   ├── min, max: ", _helper_roundfidelity(minimum(r.fidelities)), ", ", _helper_roundfidelity(maximum(r.fidelities)))
        println(io, "│   ├── mean: ", _helper_roundfidelity(mean(r.fidelities)))
        println(io, "│   ├── median: ", _helper_roundfidelity(median(r.fidelities)))
        println(io, "│   └── std: ", _helper_roundfidelity(std(r.fidelities)))
    end

    if length(r.avggateerrors) == 1
        println(io, "├── average multi-qubit gate error estimate: ", _helper_rounderror(r.avggateerrors[1]))
    elseif !isempty(r.avggateerrors)
        println(io, "├── average multi-qubit gate error estimate:")
        println(io, "│   ├── min, max: ", _helper_rounderror(minimum(r.avggateerrors)), ", ", _helper_rounderror(maximum(r.avggateerrors)))
        println(io, "│   ├── mean: ", _helper_rounderror(mean(r.avggateerrors)))
        println(io, "│   ├── median: ", _helper_rounderror(median(r.avggateerrors)))
        println(io, "│   └── std: ", _helper_rounderror(std(r.avggateerrors)))
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
    print(io, "<table><tbody>")

    print(io, "<tr><td colspan=2 align=\"center\"><strong>QCSRresults</strong></td></tr>")

    print(io, "<tr><td colspan=2></td></tr>")

    print(io, "<tr><td colspan=2 align=\"center\"><strong>Simulator</strong></td></tr>")
    print(io, "<tr><td colspan=2>", r.simulator, " ", r.version, "</td><tr>")

    print(io, "<tr><td colspan=2></td></tr>")

    print(io, "<tr><td colspan=2 align=\"center\"><strong>Timings</strong></td></tr>")

    for (k, v) in filter(((k, v),) -> v > 1e-7, r.timings)
        print(io, "<tr><td>", k, " time</td><td>", v, "s</td></tr>")
    end

    if !isempty(r.fidelities)
        print(io, "<tr><td colspan=2></td></tr>")
        print(io, "<tr><td colspan=2 align=\"center\"><strong>Fidelity estimate</strong></td></tr>")
        if length(r.fidelities) == 1
            print(io, "<tr><td>Single run value</td><td>", _helper_roundfidelity(r.fidelities[1]), "</td></tr>")
        else
            print(io, "<tr><td>Min, Max</td><td>", _helper_roundfidelity(minimum(r.fidelities)), ", ", _helper_roundfidelity(maximum(r.fidelities)), "</td></tr>")
            print(io, "<tr><td>Mean</td><td>", _helper_roundfidelity(mean(r.fidelities)), "</td></tr>")
            print(io, "<tr><td>Median</td><td>", _helper_roundfidelity(median(r.fidelities)), "</td></tr>")
            print(io, "<tr><td>Standard Deviation</td><td>", _helper_roundfidelity(std(r.fidelities)), "</td></tr>")
        end
    end

    if !isempty(r.avggateerrors)
        print(io, "<tr><td colspan=2></td></tr>")
        print(io, "<tr><td colspan=2 align=\"center\"><strong>Average multiqubit error estimate</strong></td></tr>")
        if length(r.avggateerrors) == 1
            print(io, "<tr><td>Single run value</td><td>", _helper_rounderror(r.avggateerrors[1]), "</td></tr>")
        else
            print(io, "<tr><td>Min, Max</td><td>", _helper_rounderror(minimum(r.avggateerrors)), ",", _helper_rounderror(maximum(r.avggateerrors)), "</td></tr>")
            print(io, "<tr><td>Mean</td><td>", _helper_rounderror(mean(r.avggateerrors)), "</td></tr>")
            print(io, "<tr><td>Median</td><td>", _helper_rounderror(median(r.avggateerrors)), "</td></tr>")
            print(io, "<tr><td>Standard Deviation</td><td>", _helper_rounderror(std(r.avggateerrors)), "</td></tr>")
        end
    end

    print(io, "<tr><td colspan=2></td></tr>")
    print(io, "<tr><td colspan=2 align=\"center\"><strong>Statistics</strong></td></tr>")
    print(io, "<tr><td>Number of executions</td><td>", length(r.fidelities), "</td></tr>")
    print(io, "<tr><td>Number of samples</td><td>", length(r.cstates), "</td></tr>")
    print(io, "<tr><td>Number of amplitudes</td><td>", length(r.amplitudes), "</td></tr>")

    if !isempty(r.cstates)
        print(io, "<tr><td colspan=2></td></tr>")
        print(io, "<tr><td colspan=2 align=\"center\"><strong>Samples</strong></td></tr>")
        h = histsamples(r)
        h = sort(collect(h), by=x -> x[2], rev=true)[1:min(10, length(h))]
        for (k, v) in h
            print(io, "<tr><td style=\"text-align:left;font-family: monospace;\">", k, "</td><td style=\"text-align:left;font-family: monospace;\">", v, "</td></tr>")
        end
    end

    if !isempty(r.amplitudes)
        print(io, "<tr><td colspan=2></td></tr>")
        print(io, "<tr><td colspan=2 align=\"center\"><strong>Amplitudes</strong></td></tr>")
        for (k, v) in r.amplitudes
            print(io, "<tr><td>", k, "</td><td>", v, "</td></tr>")
        end
    end

    print(io, "</tbody></table>")

    return nothing
end
