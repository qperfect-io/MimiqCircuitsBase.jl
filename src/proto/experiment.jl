#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
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

function toproto(t::ParameterTable)
    return experiment_pb.ParameterTable(
        [toproto(Symbolics.value(s).name) for s in t.symbols],
        UInt64(length(t)),
        # Row-major on the wire, while Julia matrices are column-major.
        vec(permutedims(t.values)),
    )
end

function fromproto(msg::experiment_pb.ParameterTable)
    symbols = [Num(fromproto(s)) for s in msg.symbols]
    npoints = Int(msg.npoints)
    if length(msg.values) != npoints * length(symbols)
        throw(ArgumentError(
            "a table of $npoints points over $(length(symbols)) symbols needs $(npoints * length(symbols)) values, not $(length(msg.values))",
        ))
    end
    values = permutedims(reshape(msg.values, length(symbols), npoints))
    return ParameterTable(symbols, values)
end

toproto(ex::SweepExperiment) =
    experiment_pb.SweepExperiment(toproto(ex.circuit), toproto(ex.table))

fromproto(msg::experiment_pb.SweepExperiment) =
    SweepExperiment(fromproto(msg.circuit), fromproto(msg.table))

const EQUIVALENCEMETHODS = Dict(
    "samples" => experiment_pb.EquivalenceMethod.SAMPLES,
    "amplitudes" => experiment_pb.EquivalenceMethod.AMPLITUDES,
)

toproto(ex::EquivalenceExperiment) = experiment_pb.EquivalenceExperiment(
    toproto(ex.c1),
    toproto(ex.c2),
    EQUIVALENCEMETHODS[ex.method],
)

function fromproto(msg::experiment_pb.EquivalenceExperiment)
    method = findfirst(==(msg.method), EQUIVALENCEMETHODS)
    return EquivalenceExperiment(fromproto(msg.c1), fromproto(msg.c2); method=method)
end
