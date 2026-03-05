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

function toproto(param::Symbol)
    return circuit_pb.Symbol(string(param))
end

function fromproto(param::optim_pb.ParametersDictItem)
    return Symbolics.Num(fromproto(param.key)) => param.value
end

function fromproto(params::Vector{optim_pb.ParametersDictItem})
    return Dict(fromproto(p) for p in params)
end

function toproto(ex::OptimizationExperiment)
    circuit_pb_obj = toproto(ex.circuit)

    initparams_pb = [
        optim_pb.ParametersDictItem(
            toproto(Symbolics.value(k).name),
            v
        ) for (k, v) in ex.initparams
    ]

    optim_pb.OptimizationExperiment(
        circuit_pb_obj,
        ex.optimizer,
        initparams_pb,
        isnothing(ex.maxiters) ? 0 : UInt64(ex.maxiters),
        UInt64(ex.zregister),
        ex.label
    )
end

function fromproto(msg::optim_pb.OptimizationExperiment)
    circuit = fromproto(msg.circuit)
    optimizer = msg.optimizer
    label = msg.label == "" ? "mimiq_paramoptimize" : msg.label

    return OptimizationExperiment(
        circuit,
        fromproto(msg.initparams);
        optimizer=optimizer,
        label=label,
        maxiters=(msg.maxiters == 0 ? nothing : Int(msg.maxiters)),
        zregister=Int(msg.zregister),
    )
end

function toproto(run::OptimizationRun)
    param_map = [
        optim_pb.ParametersDictItem(
            toproto(Symbolics.value(k).name),
            v
        ) for (k, v) in run.parameters
    ]
    return optim_pb.OptimizationRun(run.cost, param_map, toproto(run.results))
end

function fromproto(msg::optim_pb.OptimizationRun)
    return OptimizationRun(msg.cost, fromproto(msg.parameters), fromproto(msg.results))
end

function fromproto(msg::optim_pb.OptimizationResults)
    best = fromproto(msg.best)
    history = [fromproto(h) for h in msg.history]
    return OptimizationResults(best, history)
end

function toproto(res::OptimizationResults)
    return optim_pb.OptimizationResults(
        toproto(res.best),
        [toproto(h) for h in res.history],
    )
end
