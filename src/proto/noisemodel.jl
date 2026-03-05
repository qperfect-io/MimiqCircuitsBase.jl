#
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


#############################
# NoiseRule wrapper (oneof)
#############################

function _to_operation(x, declcache)
    return circuit_pb.Operation(_build_oneof(x, declcache))
end

function fromproto(rule::noisemodel_pb.NoiseRule, declcache=nothing)
    inner = rule.kind.value
    return fromproto(inner, declcache)
end

#############################
# NoiseModel
#############################

function toproto(g::NoiseModel, declcache=nothing)
    rules = map(r -> toproto(r, declcache), g.rules)
    return noisemodel_pb.NoiseModel(g.name, rules)
end

function fromproto(g::noisemodel_pb.NoiseModel, declcache=nothing)
    rules = map(r -> fromproto(r, declcache), g.rules)
    return NoiseModel(rules; name=g.name)
end


#############################
# GlobalReadoutNoise
#############################

function toproto(g::GlobalReadoutNoise, declcache=nothing)
    msg = noisemodel_pb.GlobalReadoutNoise(
        _to_operation(g.noise, declcache)
    )
    return noisemodel_pb.NoiseRule(OneOf(:global_readout, msg))
end

function fromproto(g::noisemodel_pb.GlobalReadoutNoise, declcache=nothing)
    return GlobalReadoutNoise(fromproto(g.noise, declcache))
end


#############################
# ExactQubitReadoutNoise
#############################

function toproto(g::ExactQubitReadoutNoise, declcache=nothing)
    msg = noisemodel_pb.ExactQubitReadoutNoise(
        UInt32.(g.qubits),
        _to_operation(g.noise, declcache)
    )
    return noisemodel_pb.NoiseRule(OneOf(:exact_qubit_readout, msg))
end

function fromproto(g::noisemodel_pb.ExactQubitReadoutNoise, declcache=nothing)
    return ExactQubitReadoutNoise(Int.(g.qubits), fromproto(g.noise, declcache))
end


#############################
# SetQubitReadoutNoise
#############################

function toproto(g::SetQubitReadoutNoise, declcache=nothing)
    msg = noisemodel_pb.SetQubitReadoutNoise(
        UInt32.(collect(g.qubits)),
        _to_operation(g.noise, declcache)
    )
    return noisemodel_pb.NoiseRule(OneOf(:set_qubit_readout, msg))
end

function fromproto(g::noisemodel_pb.SetQubitReadoutNoise, declcache=nothing)
    return SetQubitReadoutNoise(Set(Int.(g.qubits)), fromproto(g.noise, declcache))
end

#############################
# OperationInstanceNoise
#############################

function toproto(g::OperationInstanceNoise, declcache=nothing)
    msg = noisemodel_pb.OperationInstanceNoise(
        _to_operation(g.operation, declcache),
        _to_operation(g.noise, declcache),
        g.before,
        g.replace
    )
    return noisemodel_pb.NoiseRule(OneOf(:operation_instance_noise, msg))
end

function fromproto(g::noisemodel_pb.OperationInstanceNoise, declcache=nothing)
    return OperationInstanceNoise(
        fromproto(g.operation, declcache),
        fromproto(g.noise, declcache);
        before=g.before,
        replace=g.replace
    )
end


#############################
# ExactOperationInstanceQubitNoise
#############################

function toproto(g::ExactOperationInstanceQubitNoise, declcache=nothing)
    msg = noisemodel_pb.ExactOperationInstanceQubitNoise(
        _to_operation(g.operation, declcache),
        UInt32.(g.qubits),
        _to_operation(g.noise, declcache),
        g.before,
        g.replace
    )
    return noisemodel_pb.NoiseRule(OneOf(:exact_operation_instance_noise, msg))
end

function fromproto(g::noisemodel_pb.ExactOperationInstanceQubitNoise, declcache=nothing)
    return ExactOperationInstanceQubitNoise(
        fromproto(g.operation, declcache),
        Int.(g.qubits),
        fromproto(g.noise, declcache);
        before=g.before,
        replace=g.replace
    )
end


#############################
# SetOperationInstanceQubitNoise
#############################

function toproto(g::SetOperationInstanceQubitNoise, declcache=nothing)
    msg = noisemodel_pb.SetOperationInstanceQubitNoise(
        _to_operation(g.operation, declcache),
        UInt32.(collect(g.qubits)),
        _to_operation(g.noise, declcache),
        g.before,
        g.replace
    )
    return noisemodel_pb.NoiseRule(OneOf(:set_operation_instance_noise, msg))
end

function fromproto(g::noisemodel_pb.SetOperationInstanceQubitNoise, declcache=nothing)
    return SetOperationInstanceQubitNoise(
        fromproto(g.operation, declcache),
        Set(Int.(g.qubits)),
        fromproto(g.noise, declcache);
        before=g.before,
        replace=g.replace
    )
end


#############################
# IdleNoise
#############################

function toproto(g::IdleNoise, declcache=nothing)
    rel = g.relation

    if rel isa Pair
        # Case 1: IdleNoise(x => op)
        variable = rel.first
        operation = rel.second

        pbrelation = noisemodel_pb.SymbolicPattern(
            [toproto(variable)],
            _to_operation(operation, declcache)
        )

    else
        # Case 2: IdleNoise(op)
        operation = rel

        pbrelation = noisemodel_pb.SymbolicPattern(
            [],   # <-- no variables
            _to_operation(operation, declcache)
        )
    end

    return noisemodel_pb.NoiseRule(
        OneOf(:idle_noise, noisemodel_pb.IdleNoise(pbrelation))
    )
end

function fromproto(g::noisemodel_pb.IdleNoise, declcache=nothing)
    vars_pb = g.relation.variables
    operation = fromproto(g.relation.operation, declcache)

    if isempty(vars_pb)
        # IdleNoise(op)
        return IdleNoise(operation)

    elseif length(vars_pb) == 1
        # IdleNoise(x => op)
        variable = fromproto(vars_pb[1])
        return IdleNoise(variable => operation)

    else
        throw(ArgumentError("IdleNoise must have at most 1 variable, got $(length(vars_pb))"))
    end
end


#############################
# SetIdleQubitNoise
#############################

function toproto(g::SetIdleQubitNoise, declcache=nothing)
    rel = g.relation
    qubits_u32 = UInt32.(collect(g.qubits))

    if rel isa Pair
        # SetIdleQubitNoise(x => op)
        variable = rel.first
        operation = rel.second

        pbrelation = noisemodel_pb.SymbolicPattern([toproto(variable)],_to_operation(operation, declcache))
    else
        # SetIdleQubitNoise(op)
        operation = rel
        pbrelation = noisemodel_pb.SymbolicPattern([],_to_operation(operation, declcache))
    end

    pbnoise = noisemodel_pb.SetIdleQubitNoise(pbrelation, qubits_u32)
    return noisemodel_pb.NoiseRule(OneOf(:set_idle_noise, pbnoise))
end

function fromproto(g::noisemodel_pb.SetIdleQubitNoise, declcache=nothing)
    qubits = Set(Int.(g.qubits))
    vars_pb = g.relation.variables
    operation = fromproto(g.relation.operation, declcache)

    if isempty(vars_pb)
        # Case 1: SetIdleQubitNoise(op, qubits)
        return SetIdleQubitNoise(operation, qubits)

    elseif length(vars_pb) == 1
        # Case 2: SetIdleQubitNoise(x => op, qubits)
        variable = fromproto(vars_pb[1])
        return SetIdleQubitNoise(variable => operation, qubits)

    else
        throw(ArgumentError("SetIdleQubitNoise must have 0 or 1 variables, got $(length(vars_pb))"))
    end
end


#############################
# CustomNoiseRule
#############################

function toproto(g::CustomNoiseRule, declcache=nothing)
    for (label, fn) in (("matcher", g.matcher), ("generator", g.generator))
        if Base.isanonymous(fn)
            throw(ArgumentError(
                "CustomNoiseRule cannot be serialized with anonymous callables. "  
            ))
        end
    end
    msg = noisemodel_pb.CustomNoiseRule(
        string(g.matcher),
        string(g.generator),
        Int32(priority(g)),
        g.before,
        g.replace
    )
    return noisemodel_pb.NoiseRule(OneOf(:custom_noise, msg))
end

function fromproto(g::noisemodel_pb.CustomNoiseRule, declcache=nothing)
    return CustomNoiseRule(
        inst -> true,
        inst -> inst;
        priority_val=Int(g.priority),
        before=g.before,
        replace=g.replace
    )
end
