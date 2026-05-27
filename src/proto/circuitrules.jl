#
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
# CircuitRule wrapper (oneof)
#############################

function fromproto(rule::circuitrules_pb.CircuitRule, declcache=nothing)
    inner = rule.kind.value
    return fromproto(inner, declcache)
end

#############################
# LossModel
#############################

function toproto(g::LossModel, declcache=nothing)
    rules = map(r -> toproto(r, declcache), g.rules)
    return circuitrules_pb.LossModel(g.name, rules)
end

function fromproto(g::circuitrules_pb.LossModel, declcache=nothing)
    rules = map(r -> fromproto(r, declcache), g.rules)
    return LossModel(rules; name=g.name)
end

#############################
# DropRule
#############################

function toproto(g::DropRule, declcache=nothing)
    op = isnothing(g.operation) ? nothing : _to_operation(g.operation, declcache)
    msg = circuitrules_pb.DropRuleMsg(op)
    return circuitrules_pb.CircuitRule(OneOf(:drop_rule, msg))
end

function fromproto(g::circuitrules_pb.DropRuleMsg, declcache=nothing)
    if isnothing(g.operation)
        return DropRule()
    else
        return DropRule(fromproto(g.operation, declcache))
    end
end

#############################
# DecorateRule
#############################

function toproto(g::DecorateRule, declcache=nothing)
    msg = circuitrules_pb.DecorateRuleMsg(
        _to_operation(g.operation, declcache),
        _to_operation(g.decoration, declcache),
        g.before,
    )
    return circuitrules_pb.CircuitRule(OneOf(:decorate_rule, msg))
end

function fromproto(g::circuitrules_pb.DecorateRuleMsg, declcache=nothing)
    return DecorateRule(
        fromproto(g.operation, declcache),
        fromproto(g.decoration, declcache);
        before=g.before,
    )
end

#############################
# ReplaceRule
#############################

function toproto(g::ReplaceRule, declcache=nothing)
    msg = circuitrules_pb.ReplaceRuleMsg(
        _to_operation(g.operation, declcache),
        _to_operation(g.replacement, declcache),
    )
    return circuitrules_pb.CircuitRule(OneOf(:replace_rule, msg))
end

function fromproto(g::circuitrules_pb.ReplaceRuleMsg, declcache=nothing)
    return ReplaceRule(
        fromproto(g.operation, declcache),
        fromproto(g.replacement, declcache),
    )
end
