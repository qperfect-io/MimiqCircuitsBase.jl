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

# ========== #
# Priorities #
# ========== #
const PRIORITY_USER_OVERRIDE = 0
const PRIORITY_EXACT_OPERATION = 40
const PRIORITY_EXACT_READOUT = 50
const PRIORITY_SET_OPERATION = 60
const PRIORITY_SET_READOUT = 70
const PRIORITY_GLOBAL_OPERATION = 80
const PRIORITY_GLOBAL_READOUT = 90
const PRIORITY_SET_IDLE = 190
const PRIORITY_IDLE = 200


# ====================================== #
# Abstract Types and Core Infrastructure #
# ====================================== #

"""
    AbstractNoiseRule

Abstract base type for all noise rules in the noise model.
Each concrete noise rule defines when and how noise should be applied to circuit instructions.
"""
abstract type AbstractNoiseRule end

"""
    priority(rule::AbstractNoiseRule) -> Int

Return the priority of a noise rule. Lower numbers have higher priority.
Default priority is 100. Override this method to change rule priority.
"""
priority(::AbstractNoiseRule) = 100

"""
    before(rule::AbstractNoiseRule) -> Bool

Return whether the noise should be applied before the operation.
Default is false (apply after). Override for specific rule types.
"""
before(::AbstractNoiseRule) = false

"""
    replaces(rule::AbstractNoiseRule) -> Bool

Return whether the noise instruction replaces the original instruction.
Default is false (noise is added alongside). Override for specific rule types.
"""
replaces(::AbstractNoiseRule) = false

"""
    matches(rule::AbstractNoiseRule, inst::Instruction) -> Bool

Check if a noise rule matches a given instruction.

# Arguments
- `rule`: The noise rule to check
- `inst`: The instruction to potentially add noise to

# Returns
`true` if the rule applies to this instruction, `false` otherwise
"""
function matches(rule::AbstractNoiseRule, inst::Instruction)
    error("matches not implemented for $(typeof(rule))")
end

"""
    apply_rule(rule::AbstractNoiseRule, inst::Instruction) -> Union{Instruction, Nothing}

Generate a noise instruction based on the rule and the matched instruction.

Returns `nothing` if the rule does not match the instruction. This allows the noise
application loop to try multiple rules without needing separate match checks.

# Arguments
- `rule`: The noise rule to apply
- `inst`: The instruction that the rule should be applied to

# Returns
- A new `Instruction` representing the noise to be added, or
- `nothing` if the rule does not match the instruction
"""
function apply_rule(rule::AbstractNoiseRule, inst::Instruction)
    error("apply_rule not implemented for $(typeof(rule))")
end

# validate target operation types for operation-instance rules
_is_reset(operation::Operation) =
    operation isa Reset ||
    operation isa ResetX ||
    operation isa ResetY ||
    operation isa ResetZ

_supports_symbolic_operation_pattern(operation::Operation) =
    operation isa AbstractGate ||
    operation isa AbstractMeasurement ||
    _is_reset(operation)

_is_symbolic_operation_pattern(operation::Operation) =
    _supports_symbolic_operation_pattern(operation) && issymbolic(operation)

function _validate_rule_operation_target(operation::Operation)
    if !(operation isa AbstractGate ||
         operation isa AbstractMeasurement ||
         _is_reset(operation) ||
         operation isa Block ||
         operation isa Repeat ||
         operation isa IfStatement)
        throw(ArgumentError(
            "Rule target operation must be a gate, measurement, reset, Block, Repeat, or IfStatement operation."
        ))
    end

    return nothing
end

# ######################### #
# Concrete Noise Rule Types #
# ######################### #

# ============= #
# Readout Rules #
# ============= #

"""
    GlobalReadoutNoise <: AbstractNoiseRule

Apply readout noise to all measurement operations in the circuit.

# Fields
- `noise::ReadoutErr`: The readout error to apply

# Examples
```jldoctests
rule = GlobalReadoutNoise(ReadoutErr([0.01, 0.02]))
```
"""
struct GlobalReadoutNoise <: AbstractNoiseRule
    noise::ReadoutErr
end

# Lower priority than qubit-specific
priority(::GlobalReadoutNoise) = PRIORITY_GLOBAL_READOUT

function matches(rule::GlobalReadoutNoise, inst::Instruction)
    return getoperation(inst) isa AbstractMeasurement
end

function apply_rule(rule::GlobalReadoutNoise, inst::Instruction)
    if !matches(rule, inst)
        return nothing
    end
    return Instruction(rule.noise, getbits(inst)...)
end

"""
    ExactQubitReadoutNoise <: AbstractNoiseRule

Apply readout noise only to measurements on specific qubits in exact order.

# Fields
- `qubits::Vector{Int}`: Exact sequence of qubits (order matters)
- `noise::ReadoutErr`: The readout error to apply

# Examples
```jldoctests
# Only matches Measure on qubits [1, 2] in that exact order

julia> rule = ExactQubitReadoutNoise([1, 2], ReadoutErr(0.01, 0.02))
ExactQubitReadoutNoise([1, 2], ReadoutErr(0.01, 0.02))

# Different from [2, 1]
julia> rule2 = ExactQubitReadoutNoise([2, 1], ReadoutErr(0.02, 0.03))
ExactQubitReadoutNoise([2, 1], ReadoutErr(0.02, 0.03))
```
"""
struct ExactQubitReadoutNoise <: AbstractNoiseRule
    qubits::Vector{Int}
    noise::ReadoutErr

    function ExactQubitReadoutNoise(qubits, noise::ReadoutErr)
        if length(unique(qubits)) != length(qubits)
            throw(ArgumentError("Qubit list must not contain repetitions"))
        end
        if isempty(qubits)
            throw(ArgumentError("Qubit list must not be empty"))
        end
        new(collect(qubits), noise)
    end
end

priority(::ExactQubitReadoutNoise) = PRIORITY_EXACT_READOUT

function matches(rule::ExactQubitReadoutNoise, inst::Instruction)
    if !(getoperation(inst) isa AbstractMeasurement)
        return false
    end

    # qubits must match exactly in order
    return collect(getqubits(inst)) == rule.qubits
end

function apply_rule(rule::ExactQubitReadoutNoise, inst::Instruction)
    if !matches(rule, inst)
        return nothing
    end
    return Instruction(rule.noise, getbits(inst)...)
end

"""
    SetQubitReadoutNoise <: AbstractNoiseRule

Apply readout noise to measurements if all qubits are in the specified set.

# Fields
- `qubits::Set{Int}`: Set of qubit indices where noise should be applied
- `noise::ReadoutErr`: The readout error to apply

# Examples
```jldoctests
# Matches any measurement where all qubits are in {1, 3, 5}
julia> rule = SetQubitReadoutNoise([1, 3, 5], ReadoutErr(0.01, 0.02))
SetQubitReadoutNoise(Set([5, 3, 1]), ReadoutErr(0.01, 0.02))
```
"""
struct SetQubitReadoutNoise <: AbstractNoiseRule
    qubits::Set{Int}
    noise::ReadoutErr

    function SetQubitReadoutNoise(qubits, noise::ReadoutErr)
        if length(unique(qubits)) != length(qubits)
            throw(ArgumentError("Qubit list must not contain repetitions"))
        end
        if isempty(qubits)
            throw(ArgumentError("Qubit list must not be empty"))
        end
        new(Set(qubits), noise)
    end
end

# Lower priority than exact match
priority(::SetQubitReadoutNoise) = PRIORITY_SET_READOUT

function matches(rule::SetQubitReadoutNoise, inst::Instruction)
    if !(getoperation(inst) isa AbstractMeasurement)
        return false
    end

    # all instruction qubits must be in the rule's qubit set
    return all(q -> q in rule.qubits, getqubits(inst))
end

function apply_rule(rule::SetQubitReadoutNoise, inst::Instruction)
    if !matches(rule, inst)
        return nothing
    end
    return Instruction(rule.noise, getbits(inst)...)
end

# ================================ #
# Operation instance matching noise #
# ================================ #

"""
    OperationInstanceNoise <: AbstractNoiseRule

Apply noise to operations matching a specific operation pattern.

The operation pattern can have symbolic parameters (e.g., `GateRX(a)`) which will be
matched positionally against concrete operation instances. When a match occurs, the
symbolic variables are substituted with the concrete parameter values in the noise.

# Fields
- `operation::Operation`: The operation pattern to match (may have symbolic parameters)
- `noise::Union{AbstractKrausChannel,AbstractGate}`: The noise to apply (may use symbolic variables)
- `before::Bool`: If true, apply noise before the operation (default: false)
- `replace::Bool`: If true, replace the matched operation with the noise operation (default: false)

# Examples

## Concrete operation matching
```jldoctests
julia> rule = OperationInstanceNoise(GateRX(π/2), AmplitudeDamping(0.001))
OperationInstanceNoise(GateRX(π/2), AmplitudeDamping(0.001), false, false)
```

## Symbolic operation matching with parameter-dependent noise
```jldoctests

julia> @variables a
1-element Vector{Symbolics.Num}:
 a

# Matches any GateRX, applies noise that depends on the rotation angle

julia> rule = OperationInstanceNoise(GateRX(a), Depolarizing1(a / π))
OperationInstanceNoise(GateRX(a), Depolarizing(1, a / π), false, false)

# When GateRX(0.4) is encountered, applies Depolarizing1(0.4 / π)
```

## Multi-parameter symbolic matching
```jldoctests
julia> @variables θ φ
2-element Vector{Symbolics.Num}:
 θ
 φ

julia> rule = OperationInstanceNoise(GateU(θ, φ, 0), Depolarizing1((θ^2 + φ^2) / (2π^2)))
OperationInstanceNoise(GateU(θ, φ, 0, 0π), Depolarizing(1, (θ^2 + φ^2) / 19.739208802178716), false, false)
```

## Compact relation syntax
```jldoctests

julia> @variables a
1-element Vector{Symbolics.Num}:
 a

julia> rule = OperationInstanceNoise(GateRX(a) => Depolarizing1(a + 2))
OperationInstanceNoise(GateRX(a), Depolarizing(1, 2 + a), false, false)
```

## Measurement noise with Pauli channels (apply before measurement)
```jldoctests
julia> rule = OperationInstanceNoise(Measure(), PauliX(0.02); before=true)
OperationInstanceNoise(Measure(), PauliX(0.02), true, false)
```

## Reset noise
```jldoctests
julia> rule = OperationInstanceNoise(Reset(), Depolarizing1(0.01))
OperationInstanceNoise(Reset(), Depolarizing(1, 0.01), false, false)
```

## Replace matched operation
```jldoctests
julia> rule = OperationInstanceNoise(GateH(), AmplitudeDamping(0.001); replace=true)
OperationInstanceNoise(GateH(), AmplitudeDamping(0.001), false, true)
```
"""
struct OperationInstanceNoise <: AbstractNoiseRule
    operation::Operation
    noise::Union{AbstractKrausChannel,AbstractGate}
    before::Bool
    replace::Bool

    function OperationInstanceNoise(operation::Operation, noise::Union{AbstractKrausChannel,AbstractGate};
        before::Bool=false, replace::Bool=false)

        _validate_rule_operation_target(operation)

        # Validate symbolic parameters only for operations that support symbolic matching.
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end

        if numqubits(operation) != numqubits(noise)
            throw(ArgumentError("Noise operation must act on the same number of qubits as the operation instance"))
        end
        if before && replace
            throw(ArgumentError("Cannot set both before=true and replace=true"))
        end
        new(operation, noise, before, replace)
    end

    # Compact constructor: OperationInstanceNoise(GateRX(a) => Depolarizing1(a + 2))
    function OperationInstanceNoise(relation::Pair; before::Bool=false, replace::Bool=false)
        operation, noise = relation
        OperationInstanceNoise(operation, noise; before=before, replace=replace)
    end
end

# Higher priority than set-based
priority(::OperationInstanceNoise) = PRIORITY_GLOBAL_OPERATION

before(rule::OperationInstanceNoise) = rule.before

replaces(rule::OperationInstanceNoise) = rule.replace

function matches(rule::OperationInstanceNoise, inst::Instruction)
    op_inst = getoperation(inst)
    op_rule = rule.operation

    # Must be same type
    if typeof(op_inst) != typeof(op_rule)
        return false
    end

    # Non-symbolic patterns (including Block/Repeat) require exact operation match.
    if !_is_symbolic_operation_pattern(op_rule)
        return op_inst == op_rule
    end

    # Type matches and rule is symbolic - match.
    return true
end

function apply_rule(rule::OperationInstanceNoise, inst::Instruction)
    # Check if rule matches
    if !matches(rule, inst)
        return nothing
    end

    op_inst = getoperation(inst)

    # Non-symbolic patterns (including Block/Repeat) use static noise.
    if !_is_symbolic_operation_pattern(rule.operation)
        noise = rule.noise
    else
        # Symbolic patterns substitute parameters from the matched instruction.
        variables = _extract_variables(rule.operation)
        if isnothing(variables)
            noise = rule.noise
        else
            noise = applyparams(op_inst, variables => rule.noise)
        end
    end

    return Instruction(noise, getqubits(inst)...)
end

"""
    ExactOperationInstanceQubitNoise <: AbstractNoiseRule

Apply noise to a specific operation pattern only when it acts on specific qubits in exact order.

The operation pattern can have symbolic parameters (see [`OperationInstanceNoise`](@ref)).

# Fields
- `operation::Operation`: The operation pattern to match (may have symbolic parameters)
- `qubits::Vector{Int}`: Exact sequence of qubits (order matters)
- `noise::Union{AbstractKrausChannel,AbstractGate}`: The noise to apply (may use symbolic variables)
- `before::Bool`: If true, apply noise before the operation (default: false)
- `replace::Bool`: If true, replace the matched operation with the noise operation (default: false)

# Examples
```jldoctests
@variables a
# Only matches GateRX on qubit 1, with angle-dependent noise

julia> rule = ExactOperationInstanceQubitNoise(GateRX(a), [1], AmplitudeDamping(a / π))
ExactOperationInstanceQubitNoise(GateRX(a), [1], AmplitudeDamping(a / π), false, false)

# Compact syntax
julia> rule = ExactOperationInstanceQubitNoise(GateRX(a) => AmplitudeDamping(a / π), qubits=[1])
ExactOperationInstanceQubitNoise(GateRX(a), [1], AmplitudeDamping(a / π), false, false)
```
"""
struct ExactOperationInstanceQubitNoise <: AbstractNoiseRule
    operation::Operation
    qubits::Vector{Int}
    noise::Union{AbstractKrausChannel,AbstractGate}
    before::Bool
    replace::Bool

    function ExactOperationInstanceQubitNoise(operation::Operation, qubits, noise::Union{AbstractKrausChannel,AbstractGate};
        before::Bool=false, replace::Bool=false)

        _validate_rule_operation_target(operation)

        # Validate symbolic parameters only for operations that support symbolic matching.
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end

        if numqubits(operation) != numqubits(noise)
            throw(ArgumentError("Noise operation must act on the same number of qubits as the operation instance"))
        end
        if length(unique(qubits)) != length(qubits)
            throw(ArgumentError("Qubit list must not contain repetitions"))
        end
        if length(qubits) != numqubits(operation)
            throw(ArgumentError("Qubit list length must match the number of qubits the operation acts on"))
        end
        if before && replace
            throw(ArgumentError("Cannot set both before=true and replace=true"))
        end
        new(operation, collect(qubits), noise, before, replace)
    end

    # Compact constructor
    function ExactOperationInstanceQubitNoise(relation::Pair; qubits, before::Bool=false, replace::Bool=false)
        operation, noise = relation
        ExactOperationInstanceQubitNoise(operation, qubits, noise; before=before, replace=replace)
    end
end

# Highest priority for most specific
priority(::ExactOperationInstanceQubitNoise) = PRIORITY_EXACT_OPERATION

before(rule::ExactOperationInstanceQubitNoise) = rule.before

replaces(rule::ExactOperationInstanceQubitNoise) = rule.replace

function matches(rule::ExactOperationInstanceQubitNoise, inst::Instruction)
    op_inst = getoperation(inst)
    op_rule = rule.operation

    # Must be same type
    if typeof(op_inst) != typeof(op_rule)
        return false
    end

    # Qubits must match exactly in order
    if collect(getqubits(inst)) != rule.qubits
        return false
    end

    # Non-symbolic patterns (including Block/Repeat) require exact operation match.
    if !_is_symbolic_operation_pattern(op_rule)
        return op_inst == op_rule
    end

    return true
end

function apply_rule(rule::ExactOperationInstanceQubitNoise, inst::Instruction)
    # Check if rule matches
    if !matches(rule, inst)
        return nothing
    end

    op_inst = getoperation(inst)

    # Non-symbolic patterns (including Block/Repeat) use static noise.
    if !_is_symbolic_operation_pattern(rule.operation)
        noise = rule.noise
    else
        # Symbolic patterns substitute parameters from the matched instruction.
        variables = _extract_variables(rule.operation)
        if isnothing(variables)
            noise = rule.noise
        else
            noise = applyparams(op_inst, variables => rule.noise)
        end
    end

    return Instruction(noise, getqubits(inst)...)
end

"""
    SetOperationInstanceQubitNoise <: AbstractNoiseRule

Apply noise to a specific operation pattern when all its qubits are in a specified set.

The operation pattern can have symbolic parameters (see [`OperationInstanceNoise`](@ref)).

# Fields
- `operation::Operation`: The operation pattern to match (may have symbolic parameters)
- `qubits::Set{Int}`: Set of qubit indices where noise should be applied
- `noise::Union{AbstractKrausChannel,AbstractGate}`: The noise to apply (may use symbolic variables)
- `before::Bool`: If true, apply noise before the operation (default: false)
- `replace::Bool`: If true, replace the matched operation with the noise operation (default: false)

# Examples
```jldoctests
@variables a
# Matches GateRX on any qubits in {1, 2, 3} with angle-dependent noise

julia> rule = SetOperationInstanceQubitNoise(GateRX(a), [1, 2, 3], PhaseAmplitudeDamping(1, 1, a / (2π)))
SetOperationInstanceQubitNoise(GateRX(a), Set([2, 3, 1]), PhaseAmplitudeDamping(1, 1, a / 6.283185307179586), false, false)

# Compact syntax
julia> rule = SetOperationInstanceQubitNoise(GateRX(a) => PhaseAmplitudeDamping(1, 1, a / (2π)), qubits=[1, 2, 3])
SetOperationInstanceQubitNoise(GateRX(a), Set([2, 3, 1]), PhaseAmplitudeDamping(1, 1, a / 6.283185307179586), false, false)
```
"""
struct SetOperationInstanceQubitNoise <: AbstractNoiseRule
    operation::Operation
    qubits::Set{Int}
    noise::Union{AbstractKrausChannel,AbstractGate}
    before::Bool
    replace::Bool

    function SetOperationInstanceQubitNoise(operation::Operation, qubits, noise::Union{AbstractKrausChannel,AbstractGate};
        before::Bool=false, replace::Bool=false)

        _validate_rule_operation_target(operation)

        # Validate symbolic parameters only for operations that support symbolic matching.
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end

        if length(qubits) < numqubits(operation)
            throw(ArgumentError("Qubit set must contain at least as many qubits as the operation acts on"))
        end
        if length(unique(qubits)) != length(qubits)
            throw(ArgumentError("Qubit set must not contain repetitions"))
        end
        if numqubits(operation) != numqubits(noise)
            throw(ArgumentError("Noise operation must act on the same number of qubits as the operation instance"))
        end
        if before && replace
            throw(ArgumentError("Cannot set both before=true and replace=true"))
        end
        new(operation, Set(qubits), noise, before, replace)
    end

    # Compact constructor
    function SetOperationInstanceQubitNoise(relation::Pair; qubits, before::Bool=false, replace::Bool=false)
        operation, noise = relation
        SetOperationInstanceQubitNoise(operation, qubits, noise; before=before, replace=replace)
    end
end

# Lower priority than exact match
priority(::SetOperationInstanceQubitNoise) = PRIORITY_SET_OPERATION

before(rule::SetOperationInstanceQubitNoise) = rule.before

replaces(rule::SetOperationInstanceQubitNoise) = rule.replace

function matches(rule::SetOperationInstanceQubitNoise, inst::Instruction)
    op_inst = getoperation(inst)
    op_rule = rule.operation

    # Must be same type
    if typeof(op_inst) != typeof(op_rule)
        return false
    end

    # All instruction qubits must be in the rule's qubit set
    if !all(q -> q in rule.qubits, getqubits(inst))
        return false
    end

    # Non-symbolic patterns (including Block/Repeat) require exact operation match.
    if !_is_symbolic_operation_pattern(op_rule)
        return op_inst == op_rule
    end

    return true
end

function apply_rule(rule::SetOperationInstanceQubitNoise, inst::Instruction)
    # Check if rule matches
    if !matches(rule, inst)
        return nothing
    end

    op_inst = getoperation(inst)

    # Non-symbolic patterns (including Block/Repeat) use static noise.
    if !_is_symbolic_operation_pattern(rule.operation)
        noise = rule.noise
    else
        # Symbolic patterns substitute parameters from the matched instruction.
        variables = _extract_variables(rule.operation)
        if isnothing(variables)
            noise = rule.noise
        else
            noise = applyparams(op_inst, variables => rule.noise)
        end
    end

    return Instruction(noise, getqubits(inst)...)
end

# ========== #
# Idle Noise #
# ========== #

"""
    IdleNoise <: AbstractNoiseRule

Apply noise to qubits that are idle (not involved in any operation) at a given time step.

The noise can depend on the idle time using a relation with a symbolic time variable.

# Fields
- `relation::Union{Pair, Operation}`: Either a relation `time_var => noise(time_var)` or constant noise

# Examples

## Constant idle noise
```jldoctests
julia> IdleNoise(AmplitudeDamping(0.0001))
IdleNoise(AmplitudeDamping(0.0001))
```

## Time-dependent idle noise
```jldoctests
julia> @variables t
1-element Vector{Symbolics.Num}:
 t

julia> IdleNoise(t => AmplitudeDamping(t / 1000))
IdleNoise(t => AmplitudeDamping(t / 1000))

julia> IdleNoise(t => AmplitudeDamping(1 - exp(-t / t^2)))
IdleNoise(t => AmplitudeDamping(1 - exp(-1 / t)))
```
"""
struct IdleNoise <: AbstractNoiseRule
    relation::Union{Pair,Operation}

    function IdleNoise(relation::Union{Pair{<:OptionalNum,<:Operation},Operation})
        # Validate relation if it's a Pair
        if relation isa Pair
            variable, target = relation

            if !(SymbolicUtils.issym(Symbolics.value(variable)))
                throw(ArgumentError(
                    "Left-side element of relation must be a simple symbolic variable, got: $variable"
                ))
            end
        end

        new(relation)
    end
end

# Lowest priority - only applies when nothing else does
priority(::IdleNoise) = PRIORITY_IDLE

replaces(::IdleNoise) = true

function matches(rule::IdleNoise, inst::Instruction)
    return getoperation(inst) isa Delay
end

function apply_rule(rule::IdleNoise, inst::Instruction)
    if !matches(rule, inst)
        return nothing
    end

    delay = getoperation(inst)

    # If relation is just a constant operation, use it directly
    if rule.relation isa Operation
        return Instruction(rule.relation, getqubits(inst)...)
    end

    # Otherwise it's a Pair - extract variables and use applyparams
    variable, target = rule.relation

    # Apply the relation
    noise = applyparams(delay, variable => target)

    return Instruction(noise, getqubits(inst)...)
end


"""
    SetIdleQubitNoise <: AbstractNoiseRule

Apply noise to idle qubits that are in a specified set.

The noise can depend on the idle time using a relation with a symbolic time variable.

# Fields
- `relation::Union{Pair, Operation}`: Either a relation `time_var => noise(time_var)` or constant noise
- `qubits::Set{Int}`: Set of qubit indices where noise should be applied

# Examples

## Constant idle noise
```jldoctests
SetIdleQubitNoise(AmplitudeDamping(0.0001), [1,2,3])
```

## Time-dependent idle noise
```jldoctests
julia> @variables t
1-element Vector{Symbolics.Num}:
 t

julia> SetIdleQubitNoise(t => AmplitudeDamping(t / 1000), [1,2,3])
SetIdleQubitNoise(t => AmplitudeDamping(t / 1000), Set([2, 3, 1]))
```
"""
struct SetIdleQubitNoise <: AbstractNoiseRule
    relation::Union{Pair,Operation}
    qubits::Set{Int}

    function SetIdleQubitNoise(relation::Union{Pair{<:OptionalNum,<:Operation},Operation}, qubits)
        # Validate relation if it's a Pair
        if relation isa Pair
            variable, target = relation

            if !(SymbolicUtils.issym(Symbolics.value(variable)))
                throw(ArgumentError(
                    "Left-side element of relation must be a simple symbolic variable, got: $variable"
                ))
            end
        end

        if isempty(qubits)
            throw(ArgumentError("Qubit set must not be empty"))
        end

        new(relation, Set(qubits))
    end
end

priority(::SetIdleQubitNoise) = PRIORITY_SET_IDLE

replaces(::SetIdleQubitNoise) = true

function matches(rule::SetIdleQubitNoise, inst::Instruction)
    if !(getoperation(inst) isa Delay)
        return false
    end

    # all instruction qubits must be in the rule's qubit set
    return all(q -> q in rule.qubits, getqubits(inst))
end

function apply_rule(rule::SetIdleQubitNoise, inst::Instruction)
    if !matches(rule, inst)
        return nothing
    end

    delay = getoperation(inst)

    # If relation is just a constant operation, use it directly
    if rule.relation isa Operation
        return Instruction(rule.relation, getqubits(inst)...)
    end

    # Otherwise it's a Pair - extract variables and use applyparams
    variable, target = rule.relation

    # Apply the relation
    noise = applyparams(delay, variable => target)

    return Instruction(noise, getqubits(inst)...)
end

# ============ #
# Custom Noise #
# ============ #

"""
    CustomNoiseRule <: AbstractNoiseRule

Apply noise based on a custom matching function.

# Fields
- `matcher::Function`: Function (inst) -> Bool
- `generator::Function`: Function (inst) -> Instruction
- `priority_val::Int`: Priority for this rule (default: $PRIORITY_USER_OVERRIDE)
- `before::Bool`: If true, apply noise before the matched instruction
- `replace::Bool`: If true, noise replaces the original instruction

# Examples
```jldoctests
# Add noise to all 2-qubit operations

julia> rule = CustomNoiseRule(
           inst -> numqubits(getoperation(inst)) == 2,
           inst -> Instruction(Depolarizing2(0.01), getqubits(inst)...)
       )
CustomNoiseRule(var"#3#5"(), var"#4#6"(), 0, false, false)
```
"""
struct CustomNoiseRule <: AbstractNoiseRule
    matcher::Function
    generator::Function
    priority_val::Int
    before::Bool
    replace::Bool

    function CustomNoiseRule(matcher::Function, generator::Function; priority_val::Int=PRIORITY_USER_OVERRIDE, before::Bool=false, replace::Bool=false)
        new(matcher, generator, priority_val, before, replace)
    end
end

priority(rule::CustomNoiseRule) = rule.priority_val

before(rule::CustomNoiseRule) = rule.before

replaces(rule::CustomNoiseRule) = rule.replace

matches(rule::CustomNoiseRule, inst::Instruction) = rule.matcher(inst)

apply_rule(rule::CustomNoiseRule, inst::Instruction) = rule.matcher(inst) ? rule.generator(inst) : nothing

# =========== #
# Noise Model #
# =========== #

"""
    NoiseModel

A collection of noise rules that define how noise is applied to a quantum circuit.

# Fields
- `rules::Vector{AbstractNoiseRule}`: List of noise rules in the model
- `name::String`: Optional name for the noise model

# Priority Order (lower number = higher priority)
- [`CustomNoiseRule`](@ref): configurable (default $PRIORITY_USER_OVERRIDE)
- [`ExactOperationInstanceQubitNoise`](@ref): $PRIORITY_EXACT_OPERATION
- [`ExactQubitReadoutNoise`](@ref): $PRIORITY_EXACT_READOUT
- [`SetOperationInstanceQubitNoise`](@ref): $PRIORITY_SET_OPERATION
- [`SetQubitReadoutNoise`](@ref): $PRIORITY_SET_READOUT
- [`OperationInstanceNoise`](@ref): $PRIORITY_GLOBAL_OPERATION
- [`GlobalReadoutNoise`](@ref): $PRIORITY_GLOBAL_READOUT
- [`SetIdleQubitNoise`](@ref): $PRIORITY_SET_IDLE
- [`IdleNoise`](@ref): $PRIORITY_IDLE



# Examples

## Using symbolic parameters for angle-dependent noise
```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> model = NoiseModel([
           # Noise that scales with rotation angle
           OperationInstanceNoise(GateRX(θ), Depolarizing1(θ / π)),
           OperationInstanceNoise(GateRY(θ), Depolarizing1(θ / π)),

           # Different noise for different qubit pairs
           ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing2(0.01)),
           ExactOperationInstanceQubitNoise(GateCX(), [2, 1], Depolarizing2(0.02)),

           # General fallbacks
           GlobalReadoutNoise(ReadoutErr(0.01, 0.02)),
           IdleNoise(AmplitudeDamping(0.0001))
       ], name="Angle-Dependent Noise Model")

NoiseModel(AbstractNoiseRule[ExactOperationInstanceQubitNoise(GateCX(), [1, 2], Depolarizing(2, 0.01), false, false), ExactOperationInstanceQubitNoise(GateCX(), [2, 1], Depolarizing(2, 0.02), false, false), OperationInstanceNoise(GateRX(θ), Depolarizing(1, θ / π), false, false), OperationInstanceNoise(GateRY(θ), Depolarizing(1, θ / π), false, false), GlobalReadoutNoise(ReadoutErr(0.01, 0.02)), IdleNoise(AmplitudeDamping(0.0001))], "Angle-Dependent Noise Model")
```

## Using symbolic parameters with complex expressions
```jldoctests
@variables α β
model = NoiseModel([
    # Two-parameter operation with combined noise
    OperationInstanceNoise(GateU(α, β, 0), Depolarizing1((α^2 + β^2) / (2π^2))),
], name="Complex Parameter Noise")
```
"""
struct NoiseModel
    rules::Vector{AbstractNoiseRule}
    name::String

    function NoiseModel(rules::Vector{<:AbstractNoiseRule}; name::String="")
        # Sort rules by priority (lower number = higher priority)
        sorted_rules = sort(rules, by=priority)
        new(sorted_rules, name)
    end
end

# Convenience constructor for single rule
NoiseModel(rule::AbstractNoiseRule; name::String="") = NoiseModel([rule], name=name)

# Convenience constructor for no rules
NoiseModel(; name::String="") = NoiseModel(AbstractNoiseRule[], name=name)

"""
    add_rule!(model::NoiseModel, rule::AbstractNoiseRule)

Add a new rule to the noise model. Rules are automatically sorted by priority.
"""
function add_rule!(model::NoiseModel, rule::AbstractNoiseRule)
    push!(model.rules, rule)
    sort!(model.rules, by=priority)
    return model
end

_canonical_targets(op::Operation) = (
    Tuple(1:numqubits(op)),
    Tuple(1:numbits(op)),
    Tuple(1:numzvars(op))
)

function _collapse_local_instructions_to_operation(instructions::Vector{Instruction}, op::Operation)
    qcanon, bcanon, zcanon = _canonical_targets(op)

    if length(instructions) == 1 &&
       getqubits(instructions[1]) == qcanon &&
       getbits(instructions[1]) == bcanon &&
       getztargets(instructions[1]) == zcanon
        return getoperation(instructions[1])
    end

    return Block(numqubits(op), numbits(op), numzvars(op), instructions)
end

function _apply_rules_to_instruction(inst::Instruction, model::NoiseModel)
    for rule in model.rules
        noise = apply_rule(rule, inst)
        if !isnothing(noise)
            if replaces(rule)
                return Instruction[noise], true
            elseif before(rule)
                return Instruction[noise, inst], true
            else
                return Instruction[inst, noise], true
            end
        end
    end

    return Instruction[inst], false
end

_rewrite_nested_operation(op::Operation, ::NoiseModel, ::IdDict{Any,Nothing}) = op

function _rewrite_nested_operation(op::Block, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    noisy_instructions = _apply_noise_to_instructions(op._instructions, model, active_decls)

    if noisy_instructions == op._instructions
        return op
    end

    return Block(numqubits(op), numbits(op), numzvars(op), noisy_instructions)
end

function _rewrite_nested_operation(op::IfStatement, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    inner = getoperation(op)
    qcanon, bcanon, zcanon = _canonical_targets(inner)
    inner_inst = Instruction(inner, qcanon, bcanon, zcanon)

    noisy_inner = _apply_noise_to_instruction(inner_inst, model, active_decls)
    rewritten_inner = _collapse_local_instructions_to_operation(noisy_inner, inner)

    if rewritten_inner === inner
        return op
    end

    return IfStatement(rewritten_inner, getbitstring(op))
end

function _rewrite_nested_operation(op::Parallel, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    inner = getoperation(op)
    nq = numqubits(inner)
    nb = numbits(inner)
    nz = numzvars(inner)

    repeated_instructions = Instruction[]
    for rep in 1:numrepeats(op)
        qtargets = Tuple(nq * (rep - 1) .+ (1:nq))
        btargets = Tuple(nb * (rep - 1) .+ (1:nb))
        ztargets = Tuple(nz * (rep - 1) .+ (1:nz))
        push!(repeated_instructions, Instruction(inner, qtargets, btargets, ztargets))
    end

    noisy_instructions = _apply_noise_to_instructions(repeated_instructions, model, active_decls)

    if noisy_instructions == repeated_instructions
        return op
    end

    return Block(numqubits(op), numbits(op), numzvars(op), noisy_instructions)
end

function _rewrite_nested_operation(op::Repeat, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    inner = getoperation(op)
    qcanon, bcanon, zcanon = _canonical_targets(inner)

    repeated_instructions = Instruction[]
    for _ in 1:numrepeats(op)
        push!(repeated_instructions, Instruction(inner, qcanon, bcanon, zcanon))
    end

    noisy_instructions = _apply_noise_to_instructions(repeated_instructions, model, active_decls)

    if noisy_instructions == repeated_instructions
        return op
    end

    return Block(numqubits(op), numbits(op), numzvars(op), noisy_instructions)
end

function _rewrite_nested_operation(op::GateCall, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    decl = op._decl

    # Prevent infinite recursion for self-referential declarations.
    if haskey(active_decls, decl)
        return op
    end

    active_decls[decl] = nothing
    try
        substitutions = Dict(zip(decl._arguments, op._args))
        expanded_instructions = Instruction[]
        for inst in decl._instructions
            expanded_op = evaluate(getoperation(inst), substitutions)
            push!(expanded_instructions, Instruction(expanded_op, getqubits(inst), getbits(inst), getztargets(inst)))
        end

        noisy_instructions = _apply_noise_to_instructions(expanded_instructions, model, active_decls)

        if noisy_instructions == expanded_instructions
            return op
        end

        return Block(numqubits(op), numbits(op), numzvars(op), noisy_instructions)
    finally
        delete!(active_decls, decl)
    end
end

function _apply_noise_to_instruction(inst::Instruction, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    rewritten_instructions, matched = _apply_rules_to_instruction(inst, model)
    if matched
        return rewritten_instructions
    end

    op = getoperation(inst)
    rewritten_op = _rewrite_nested_operation(op, model, active_decls)

    if rewritten_op === op
        return rewritten_instructions
    end

    return Instruction[Instruction(rewritten_op, getqubits(inst), getbits(inst), getztargets(inst))]
end

function _apply_noise_to_instructions(instructions::Vector{<:Instruction}, model::NoiseModel, active_decls::IdDict{Any,Nothing})
    noisy_instructions = Instruction[]

    for inst in instructions
        append!(noisy_instructions, _apply_noise_to_instruction(inst, model, active_decls))
    end

    return noisy_instructions
end

"""
    apply_noise_model(circuit::Circuit, model::NoiseModel) -> Circuit

Apply a noise model to a circuit, creating a new noisy circuit.

For each instruction in the circuit, the rules are tried in priority order until
one applies. The `apply_rule` function returns `nothing` for non-matching rules,
allowing efficient rule search without redundant matching checks.

Wrapper operations are processed recursively (`Block`, `IfStatement`, `Parallel`,
`Repeat`, and `GateCall`). Nested wrappers are also traversed recursively.

# Arguments
- `circuit`: The original circuit
- `model`: The noise model to apply

# Returns
A new circuit with noise applied according to the model

# Examples
```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> c = Circuit()
empty circuit

julia> push!(c, GateRX(0.4), 1)
1-qubit circuit with 1 instruction:
└── RX(0.4) @ q[1]

julia> push!(c, GateRX(0.8), 2)
2-qubit circuit with 2 instructions:
├── RX(0.4) @ q[1]
└── RX(0.8) @ q[2]

julia> push!(c, Measure(), 1:2, 1:2)
2-qubit, 2-bit circuit with 4 instructions:
├── RX(0.4) @ q[1]
├── RX(0.8) @ q[2]+
├── M @ q[1], c[1]
└── M @ q[2], c[2]


julia> model = NoiseModel([
           OperationInstanceNoise(GateRX(θ), Depolarizing1(θ / π)),
           GlobalReadoutNoise(ReadoutErr(0.01, 0.02))
       ])
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(GateRX(θ), Depolarizing(1, θ / π), false, false), GlobalReadoutNoise(ReadoutErr(0.01, 0.02))], "")

julia> noisy_circuit = apply_noise_model(c, model)
2-qubit, 2-bit circuit with 8 instructions:
├── RX(0.4) @ q[1]
├── Depolarizing(1,0.127324) @ q[1]
├── RX(0.8) @ q[2]
├── Depolarizing(1,0.254648) @ q[2]
├── M @ q[1], c[1]
├── RErr(0.01, 0.02) @ c[1]
├── M @ q[2], c[2]
└── RErr(0.01, 0.02) @ c[2]
# Result:
# - GateRX(0.4) followed by Depolarizing1(0.4 / π) ≈ Depolarizing1(0.127)
# - GateRX(0.8) followed by Depolarizing1(0.8 / π) ≈ Depolarizing1(0.255)
# - Measurements followed by ReadoutErr(0.01, 0.02)
```

## Recursive wrapper behavior (`Block`, `GateCall`, `Parallel`, `Repeat`, `IfStatement`)
```jldoctests

julia> model = NoiseModel([OperationInstanceNoise(GateH(), AmplitudeDamping(0.01))])
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(GateH(), AmplitudeDamping(0.01), false, false)], "")

# Block
julia> c_block = Circuit()
empty circuit

julia> push!(c_block, Block(1, 0, 0, [Instruction(GateH(), (1,), (), ())]), 1)
1-qubit circuit with 1 instruction:
└── block 2y91k9t1raigi @ q[1]

julia> n_block = apply_noise_model(c_block, model)
1-qubit circuit with 1 instruction:
└── block 1gbh70af4yogd @ q[1]

julia> n_block|>decompose_step
1-qubit circuit with 2 instructions:
├── H @ q[1]
└── AmplitudeDamping(0.01) @ q[1]


# GateCall
julia> decl = GateDecl(:local_h, (), [Instruction(GateH(), (1,), (), ())])
gate local_h() =
└── H @ q[1]

julia> c_gatecall = Circuit()
empty circuit

julia> push!(c_gatecall, GateCall(decl), 1)
1-qubit circuit with 1 instruction:
└── local_h @ q[1]

julia> n_gatecall = apply_noise_model(c_gatecall, model)
1-qubit circuit with 1 instruction:
└── block 32mk75z1nxr64 @ q[1]

julia> n_gatecall|>decompose_step
1-qubit circuit with 2 instructions:
├── H @ q[1]
└── AmplitudeDamping(0.01) @ q[1]

# Parallel
julia> c_parallel = Circuit()
empty circuit

julia> push!(c_parallel, Parallel(2, GateH()), 1, 2)
2-qubit circuit with 1 instruction:
└── ⨷ ² H @ q[1], q[2]

julia> n_parallel = apply_noise_model(c_parallel, model)
2-qubit circuit with 1 instruction:
└── block 2ee4nt7tqqx9l @ q[1:2]

julia> n_parallel|>decompose_step
2-qubit circuit with 4 instructions:
├── H @ q[1]
├── AmplitudeDamping(0.01) @ q[1]
├── H @ q[2]
└── AmplitudeDamping(0.01) @ q[2]

# Repeat
julia> c_repeat = Circuit()
empty circuit

julia> push!(c_repeat, Repeat(2, GateH()), 1)
1-qubit circuit with 1 instruction:
└── ∏² H @ q[1]

julia> n_repeat = apply_noise_model(c_repeat, model)
1-qubit circuit with 1 instruction:
└── block 33yafv6sg3yxg @ q[1]

julia> n_repeat|>decompose_step
1-qubit circuit with 4 instructions:
├── H @ q[1]
├── AmplitudeDamping(0.01) @ q[1]
├── H @ q[1]
└── AmplitudeDamping(0.01) @ q[1]

# IfStatement
julia> c_if = Circuit()
empty circuit

julia> push!(c_if, IfStatement(GateH(), BitString("1")), 1, 1)
1-qubit, 1-bit circuit with 1 instruction:
└── IF(c==1) H @ q[1], condition[1]

julia> n_if = apply_noise_model(c_if, model)
1-qubit, 1-bit circuit with 1 instruction:
└── IF(c==1) block 2mvmsxvfbxhb2 @ q[1], condition[1]

julia> n_if|>decompose_step
1-qubit, 1-bit circuit with 2 instructions:
├── IF(c==1) H @ q[1], condition[1]
└── IF(c==1) AmplitudeDamping(0.01) @ q[1], condition[1]
```
"""
function apply_noise_model(circuit::Circuit, model::NoiseModel)
    active_decls = IdDict{Any,Nothing}()
    noisy_instructions = _apply_noise_to_instructions(circuit._instructions, model, active_decls)
    return Circuit(noisy_instructions)
end

"""
    apply_noise_model!(circuit::Circuit, model::NoiseModel)

Apply a noise model to a circuit in-place.

This is a convenience function that replaces the circuit with its noisy version.

# Arguments
- `circuit`: The circuit to modify
- `model`: The noise model to apply

# Returns
The modified circuit
"""
function apply_noise_model!(circuit::Circuit, model::NoiseModel)
    active_decls = IdDict{Any,Nothing}()
    circuit._instructions = _apply_noise_to_instructions(circuit._instructions, model, active_decls)
    _invalidate_cache!(circuit)
    return circuit
end

# ======================== #
# Noise Model Construction #
# ======================== #

"""
    add_readout_noise!(model, noise[; qubits=nothing[, exact=false]])

Add a readout noise rule to a noise model.

This function simplifies the process of adding different types of readout noise.

# Arguments
- `model`: The `NoiseModel` to which the rule will be added
- `noise`: The `ReadoutErr` to apply
- `qubits`: (Optional) A collection of qubit indices. If not provided, the noise is global
- `exact`: (Optional) If `true` and `qubits` is provided, the noise will only apply to measurements on the exact sequence of qubits. Defaults to `false`

# Behavior
- If `qubits` is `nothing`, a `GlobalReadoutNoise` rule is added
- If `qubits` is provided and `exact` is `false`, a `SetQubitReadoutNoise` rule is added
- If `qubits` is provided and `exact` is `true`, an `ExactQubitReadoutNoise` rule is added

# Examples
```jldoctests
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

# Global readout noise
julia> add_readout_noise!(model, ReadoutErr(0.01, 0.02))
NoiseModel(AbstractNoiseRule[GlobalReadoutNoise(ReadoutErr(0.01, 0.02))], "")

# Readout noise on a specific set of qubits
julia> add_readout_noise!(model, ReadoutErr(0.03, 0.04), qubits=[1, 3])
NoiseModel(AbstractNoiseRule[SetQubitReadoutNoise(Set([3, 1]), ReadoutErr(0.03, 0.04)), GlobalReadoutNoise(ReadoutErr(0.01, 0.02))], "")

# Readout noise for an exact qubit order
julia> add_readout_noise!(model, ReadoutErr(0.05, 0.06), qubits=[2, 1], exact=true)
NoiseModel(AbstractNoiseRule[ExactQubitReadoutNoise([2, 1], ReadoutErr(0.05, 0.06)), SetQubitReadoutNoise(Set([3, 1]), ReadoutErr(0.03, 0.04)), GlobalReadoutNoise(ReadoutErr(0.01, 0.02))], "")
```
"""
function add_readout_noise!(model::NoiseModel, noise::ReadoutErr;
    qubits=nothing, exact::Bool=false)
    if isnothing(qubits)
        rule = GlobalReadoutNoise(noise)
    elseif exact
        rule = ExactQubitReadoutNoise(collect(qubits), noise)
    else
        rule = SetQubitReadoutNoise(Set(qubits), noise)
    end
    add_rule!(model, rule)
end

"""
    add_operation_noise!(model, operation, noise[; qubits=nothing[, exact=false[, before=false[, replace=false]]]])

Add an operation-instance noise rule to a noise model.

This function adds noise to operation instances. The `operation` parameter can be either:
1. A concrete operation (e.g., `GateRX(π/2)` or `Reset()`) - matches only that exact operation
2. A symbolic operation (e.g., `GateRX(a)` where `a` is a symbolic variable) - matches any operation
   of that type and substitutes parameter values into the noise expression

# Arguments
- `model`: The `NoiseModel` to which the rule will be added
- `operation`: The operation instance to target (concrete or symbolic)
- `noise`: The noise to apply (may contain symbolic expressions using variables from `operation`)
- `qubits`: (Optional) A collection of qubit indices to restrict the noise to
- `exact`: (Optional) If true and qubits is provided, the noise will only apply to operations on the exact sequence of qubits. Defaults to false
- `before`: (Optional) If true, the noise is applied before the matched operation. Defaults to false
- `replace`: (Optional) If true, the matched operation is replaced by the noise operation. Defaults to false

# Examples

## Concrete operation matching
```jldoctests
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

# Apply noise only to RX(π/2) operations

julia> add_operation_noise!(model, GateRX(π/2), AmplitudeDamping(0.001))
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(GateRX(π/2), AmplitudeDamping(0.001), false, false)], "")
```

## Symbolic operation matching with angle-dependent noise
```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

# Apply noise to all RX operations, with noise strength proportional to angle

julia> add_operation_noise!(model, GateRX(θ), Depolarizing1(θ / π))
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(GateRX(θ), Depolarizing(1, θ / π), false, false)], "")

# When GateRX(0.4) is encountered, Depolarizing1(0.4 / π) ≈ Depolarizing1(0.127) is applied
# When GateRX(1.2) is encountered, Depolarizing1(1.2 / π) ≈ Depolarizing1(0.382) is applied
```

## Symbolic multi-parameter operations
```jldoctests
julia> @variables α β
2-element Vector{Symbolics.Num}:
 α
 β

# Noise depends on both parameters

julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

julia> add_operation_noise!(model, GateU(α, β, 0), Depolarizing1((α^2 + β^2) / (2π^2)))
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(GateU(α, β, 0, 0π), Depolarizing(1, (α^2 + β^2) / 19.739208802178716), false, false)], "")
```

## Qubit-specific symbolic noise
```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

# Only on specific qubits
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

julia> add_operation_noise!(model, GateRX(θ), Depolarizing1(θ / π), qubits=[1, 2, 3], exact=false)
NoiseModel(AbstractNoiseRule[SetOperationInstanceQubitNoise(GateRX(θ), Set([2, 3, 1]), Depolarizing(1, θ / π), false, false)], "")

# Only on exact qubit order
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

julia> add_operation_noise!(model, GateRX(θ), Depolarizing1(θ / π), qubits=[1], exact=true)
NoiseModel(AbstractNoiseRule[ExactOperationInstanceQubitNoise(GateRX(θ), [1], Depolarizing(1, θ / π), false, false)], "")
```

## Measurement noise with Pauli channels
```jldoctests
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

julia> add_operation_noise!(model, Measure(), PauliX(0.02); before=true)
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(Measure(), PauliX(0.02), true, false)], "")
```

## Reset noise
```jldoctests
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

julia> add_operation_noise!(model, Reset(), Depolarizing1(0.01))
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(Reset, Depolarizing(1, 0.01), false, false)], "")
```

## Replace matched operation
```jldoctests
julia> model = NoiseModel()
NoiseModel(AbstractNoiseRule[], "")

julia> add_operation_noise!(model, GateH(), AmplitudeDamping(0.001); replace=true)
NoiseModel(AbstractNoiseRule[OperationInstanceNoise(GateH(), AmplitudeDamping(0.001), false, true)], "")
```
"""
function add_operation_noise!(model::NoiseModel,
    operation::Operation,
    noise::Union{AbstractKrausChannel,AbstractGate};
    qubits=nothing, exact::Bool=false, before::Bool=false, replace::Bool=false)

    _validate_rule_operation_target(operation)

    # Operation Instance Noise (with optional symbolic parameters)
    if isnothing(qubits)
        rule = OperationInstanceNoise(operation, noise; before=before, replace=replace)
    elseif exact
        rule = ExactOperationInstanceQubitNoise(operation, qubits, noise; before=before, replace=replace)
    else
        rule = SetOperationInstanceQubitNoise(operation, qubits, noise; before=before, replace=replace)
    end

    add_rule!(model, rule)
end
"""
    add_idle_noise!(model, noise[; qubits=nothing])

Add idle noise to a noise model.

# Arguments
- `model`: The `NoiseModel` to which the rule will be added
- `noise`: Either a constant noise operation or a relation `time_var => noise(time_var)`
- `qubits`: (Optional) A collection of qubit indices to restrict the noise to
"""
function add_idle_noise!(model::NoiseModel,
    noise::Union{Pair{<:OptionalNum,<:Operation},Operation};
    qubits=nothing)

    if isnothing(qubits)
        rule = IdleNoise(noise)
    else
        rule = SetIdleQubitNoise(noise, qubits)
    end

    add_rule!(model, rule)
end

# ================= #
# Utility Functions #
# ================= #

"""
    describe(model::NoiseModel)

Print a human-readable description of the noise model.
"""
function describe(model::NoiseModel)
    if !isempty(model.name)
        println("NoiseModel: $(model.name)")
    else
        println("NoiseModel")
    end
    println("="^50)

    for (i, rule) in enumerate(model.rules)
        println("Rule $i (priority $(priority(rule))): $(typeof(rule))")

        if rule isa GlobalReadoutNoise
            println("  → Applies $(rule.noise) to all measurements")
        elseif rule isa ExactQubitReadoutNoise
            println("  → Applies $(rule.noise) to measurements on qubits $(rule.qubits) (exact order)")
        elseif rule isa SetQubitReadoutNoise
            println("  → Applies $(rule.noise) to measurements on qubits in $(sort(collect(rule.qubits)))")
        elseif rule isa OperationInstanceNoise
            println("  → Applies $(rule.noise) to $(rule.operation) instances")
        elseif rule isa ExactOperationInstanceQubitNoise
            println("  → Applies $(rule.noise) to $(rule.operation) on qubits $(rule.qubits) (exact order)")
        elseif rule isa SetOperationInstanceQubitNoise
            println("  → Applies $(rule.noise) to $(rule.operation) on qubits in $(sort(collect(rule.qubits)))")
        elseif rule isa IdleNoise
            if rule.relation isa Pair
                println("  → Applies $(rule.relation.second) to all idle qubits using relation $(rule.relation.first) => ...")
            else
                println("  → Applies $(rule.relation) to all idle qubits")
            end
        elseif rule isa SetIdleQubitNoise
            if rule.relation isa Pair
                println("  → Applies $(rule.relation.second) to idle qubits $(sort(collect(rule.qubits))) using relation $(rule.relation.first) => ...")
            else
                println("  → Applies $(rule.relation) to idle qubits $(sort(collect(rule.qubits)))")
            end
        elseif rule isa CustomNoiseRule
            println("  → Custom rule with user-defined matcher and generator")
        end

        if hasproperty(rule, :before) && rule.before
            println("    (applied BEFORE the operation)")
        end
        if hasproperty(rule, :replace) && rule.replace
            println("    (REPLACES the matched operation)")
        end
    end
end
