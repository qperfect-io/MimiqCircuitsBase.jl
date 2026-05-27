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

# ============================================== #
# Abstract Circuit Rule and Shared Infrastructure #
# ============================================== #

"""
    AbstractCircuitRule

Abstract base type for all circuit transformation rules.

Both noise rules ([`AbstractNoiseRule`](@ref)) and loss rules ([`DropRule`](@ref),
[`DecorateRule`](@ref), [`ReplaceRule`](@ref), [`CustomRule`](@ref)) inherit from this type.
"""
abstract type AbstractCircuitRule end

"""
    priority(rule::AbstractCircuitRule) -> Int

Return the priority of a circuit rule. Lower numbers have higher priority.
Default is 100.
"""
priority(::AbstractCircuitRule) = 100

"""
    before(rule::AbstractCircuitRule) -> Bool

Return whether the rule's effect should be applied before the original instruction.
Default is `false` (apply after).
"""
before(::AbstractCircuitRule) = false

"""
    replaces(rule::AbstractCircuitRule) -> Bool

Return whether the rule replaces the original instruction.
Default is `false` (rule adds alongside the original).
"""
replaces(::AbstractCircuitRule) = false

"""
    matches(rule::AbstractCircuitRule, inst::Instruction) -> Bool

Check if a rule matches a given instruction. Must be implemented by concrete subtypes.
"""
function matches(::AbstractCircuitRule, ::Instruction)
    error("matches not implemented for this rule type")
end

"""
    apply_rule(rule::AbstractCircuitRule, inst::Instruction) -> Union{Vector{Instruction}, Nothing}

Apply the rule to an instruction and return the complete output sequence.

Returns `nothing` if the rule does not match. Returns a `Vector{Instruction}`
with the full output (including the original instruction for decoration rules):

- [`DropRule`](@ref): `Instruction[]` (empty — gate is dropped).
- [`ReplaceRule`](@ref): `[replacement_instructions...]` (original removed).
- [`DecorateRule`](@ref): `[inst, decoration...]` or `[decoration..., inst]` depending on [`before`](@ref).
- [`CustomRule`](@ref): delegates to the user-defined generator.

The caller emits the vector as-is. [`before`](@ref) and [`replaces`](@ref) remain
available for introspection but are not checked by application loops.
"""
function apply_rule(::AbstractCircuitRule, ::Instruction)
    error("apply_rule not implemented for this rule type")
end

# ========================== #
# Shared Validation Helpers  #
# ========================== #

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
         operation isa IfStatement ||
         operation isa WhileStatement)
        throw(ArgumentError(
            "Rule target operation must be a gate, measurement, reset, Block, Repeat, IfStatement, or WhileStatement operation."
        ))
    end

    return nothing
end

# ========================= #
# Operation Pattern Matching #
# ========================= #

"""
    _matches_operation_pattern(op_inst::Operation, op_rule::Operation) -> Bool

Check whether an instruction's operation matches a rule's operation pattern.

- If the rule's operation is symbolic (e.g., `GateRXX(θ)`), matches any operation of the same type.
- If the rule's operation is concrete (e.g., `GateCX()`), requires exact equality.
"""
function _matches_operation_pattern(op_inst::Operation, op_rule::Operation)
    typeof(op_inst) != typeof(op_rule) && return false

    if !_is_symbolic_operation_pattern(op_rule)
        return op_inst == op_rule
    end

    return true
end

"""
    _resolve_symbolic_replacement(op_inst::Operation, op_rule::Operation, replacement::Operation) -> Operation

Resolve symbolic parameters in `replacement` by extracting concrete values from `op_inst`
and substituting them according to the pattern in `op_rule`.
"""
function _resolve_symbolic_replacement(op_inst::Operation, op_rule::Operation, replacement::Operation)
    if !_is_symbolic_operation_pattern(op_rule)
        return replacement
    end

    variables = _extract_variables(op_rule)
    if isnothing(variables) || all(isnothing, variables)
        return replacement
    end

    return applyparams(op_inst, variables => replacement)
end

# =================================== #
# Replacement Instruction Builders    #
# =================================== #

"""
    _build_replacement_instructions(replacement, op_pattern, inst) -> Vector{Instruction}

Build output instructions from a replacement specification, remapping to the actual
qubits of `inst`. Supports three forms:

1. `Vector{Instruction}` on canonical qubits → remapped to actual qubits.
2. `Operation` with `numqubits == numqubits(matched)` → single instruction on all qubits.
3. `Operation` with `numqubits == 1` → broadcast to each qubit individually.
"""
function _build_replacement_instructions(repl::Operation, op_pattern::Operation, inst::Instruction)
    op_inst = getoperation(inst)
    qs = getqubits(inst)
    repl_resolved = _resolve_symbolic_replacement(op_inst, op_pattern, repl)

    if numqubits(repl_resolved) == length(qs)
        return Instruction[Instruction(repl_resolved, qs...)]
    else
        # numqubits == 1, validated at construction
        return Instruction[Instruction(repl_resolved, q) for q in qs]
    end
end

function _build_replacement_instructions(repls::Vector{Instruction}, ::Operation, inst::Instruction)
    qs = getqubits(inst)
    qubit_map = Dict(i => qs[i] for i in eachindex(qs))
    return Instruction[
        Instruction(getoperation(r), Tuple(qubit_map[q] for q in getqubits(r))...)
        for r in repls
    ]
end

function _validate_replacement_qubits(operation::Operation, replacement::Operation)
    nq_op = numqubits(operation)
    nq_repl = numqubits(replacement)
    if nq_repl != nq_op && nq_repl != 1
        throw(ArgumentError(
            "Replacement must have the same number of qubits as the operation ($nq_op) " *
            "or exactly 1 qubit (broadcast). Got $nq_repl."
        ))
    end
end

# ====================== #
# Concrete Rule Types     #
# ====================== #

"""
    DropRule([operation])

A circuit rule that drops (removes) matched instructions.

When used in a [`LossModel`](@ref), drops gates touching lost qubits.

# Arguments
- `operation`: Operation pattern to match (e.g., `GateCX()`, `GateRXX(θ)`).
  If omitted, matches any operation (catch-all).

# Examples
```jldoctests
julia> DropRule(GateCX())
DropRule(GateCX())

julia> DropRule()
DropRule(*)
```
"""
struct DropRule <: AbstractCircuitRule
    operation::Union{Operation,Nothing}

    function DropRule(op::Operation)
        _validate_rule_operation_target(op)
        if _supports_symbolic_operation_pattern(op)
            _validate_rule_gate_params(op)
        end
        new(op)
    end

    DropRule() = new(nothing)
end

priority(::DropRule) = 0

function matches(rule::DropRule, inst::Instruction)
    isnothing(rule.operation) && return true
    return _matches_operation_pattern(getoperation(inst), rule.operation)
end

replaces(::DropRule) = true

function apply_rule(rule::DropRule, inst::Instruction)
    matches(rule, inst) || return nothing
    return Instruction[]
end

function Base.show(io::IO, rule::DropRule)
    if isnothing(rule.operation)
        print(io, "DropRule(*)")
    else
        print(io, "DropRule(", rule.operation, ")")
    end
end

"""
    DecorateRule(operation, decoration; before=false)

A circuit rule that **keeps** the original instruction and adds a decoration
(noise channel, gate, or vector of instructions) before or after it.

The decoration can be:
- An `Operation` with the same qubit count as the matched gate → applied on all qubits.
- A 1-qubit `Operation` → broadcast to each qubit individually.
- A `Vector{Instruction}` on canonical qubits `(1, 2, ...)` → remapped to actual qubits.

When used in a [`LossModel`](@ref), instructions targeting only lost qubits
are automatically filtered out.

# Arguments
- `operation`: Operation pattern to match.
- `decoration`: What to add (Operation or Vector{Instruction}).
- `before`: If `true`, insert decoration before the original (default: `false`).

# Examples
```jldoctests
julia> DecorateRule(GateCX(), Depolarizing1(0.01))
DecorateRule(GateCX(), Depolarizing(1, 0.01), after)

julia> DecorateRule(GateCX(), Depolarizing1(0.01); before=true)
DecorateRule(GateCX(), Depolarizing(1, 0.01), before)
```
"""
struct DecorateRule <: AbstractCircuitRule
    operation::Operation
    decoration::Union{Operation,Vector{Instruction}}
    before::Bool

    function DecorateRule(operation::Operation, decoration::Operation; before::Bool=false)
        _validate_rule_operation_target(operation)
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end
        _validate_replacement_qubits(operation, decoration)
        new(operation, decoration, before)
    end

    function DecorateRule(operation::Operation, decoration::AbstractVector{<:Instruction}; before::Bool=false)
        _validate_rule_operation_target(operation)
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end
        new(operation, collect(Instruction, decoration), before)
    end

    function DecorateRule(relation::Pair; before::Bool=false)
        operation, decoration = relation
        DecorateRule(operation, decoration; before=before)
    end
end

function matches(rule::DecorateRule, inst::Instruction)
    return _matches_operation_pattern(getoperation(inst), rule.operation)
end

before(rule::DecorateRule) = rule.before
replaces(::DecorateRule) = false

function apply_rule(rule::DecorateRule, inst::Instruction)
    matches(rule, inst) || return nothing
    dec_insts = _build_replacement_instructions(rule.decoration, rule.operation, inst)
    return rule.before ? vcat(dec_insts, Instruction[inst]) : vcat(Instruction[inst], dec_insts)
end

function Base.show(io::IO, rule::DecorateRule)
    pos = rule.before ? "before" : "after"
    print(io, "DecorateRule(", rule.operation, ", ", rule.decoration, ", ", pos, ")")
end

"""
    ReplaceRule(operation, replacement)

A circuit rule that **replaces** the original instruction with replacement
instructions.

The replacement can be:
- An `Operation` with the same qubit count as the matched gate → single instruction on all qubits.
- A 1-qubit `Operation` → broadcast to each qubit individually.
- A `Vector{Instruction}` on canonical qubits `(1, 2, ...)` → remapped to actual qubits.

When used in a [`LossModel`](@ref), instructions targeting only lost qubits
are automatically filtered out. The broadcast form naturally handles per-qubit
loss filtering.

# Arguments
- `operation`: Operation pattern to match.
- `replacement`: What to substitute (Operation or Vector{Instruction}).

# Examples
```jldoctests
julia> ReplaceRule(GateCX(), Depolarizing1(0.2))
ReplaceRule(GateCX() => Depolarizing(1, 0.2))

julia> ReplaceRule(GateCX() => Depolarizing1(0.2))
ReplaceRule(GateCX() => Depolarizing(1, 0.2))
```
"""
struct ReplaceRule <: AbstractCircuitRule
    operation::Operation
    replacement::Union{Operation,Vector{Instruction}}

    function ReplaceRule(operation::Operation, replacement::Operation)
        _validate_rule_operation_target(operation)
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end
        _validate_replacement_qubits(operation, replacement)
        new(operation, replacement)
    end

    function ReplaceRule(operation::Operation, replacement::AbstractVector{<:Instruction})
        _validate_rule_operation_target(operation)
        if _supports_symbolic_operation_pattern(operation)
            _validate_rule_gate_params(operation)
        end
        new(operation, collect(Instruction, replacement))
    end

    function ReplaceRule(relation::Pair)
        operation, replacement = relation
        ReplaceRule(operation, replacement)
    end
end

function matches(rule::ReplaceRule, inst::Instruction)
    return _matches_operation_pattern(getoperation(inst), rule.operation)
end

replaces(::ReplaceRule) = true

function apply_rule(rule::ReplaceRule, inst::Instruction)
    matches(rule, inst) || return nothing
    return _build_replacement_instructions(rule.replacement, rule.operation, inst)
end

function Base.show(io::IO, rule::ReplaceRule)
    print(io, "ReplaceRule(", rule.operation, " => ", rule.replacement, ")")
end

"""
    CustomRule(matcher, generator)

A circuit rule with user-defined matching and generation logic.

# Arguments
- `matcher`: Function `(inst::Instruction) -> Bool` that determines whether the rule applies.
- `generator`: Function `(inst::Instruction, lost::Dict{Int,Bool}; rng) -> result` where
  result is `nothing` (drop), an `Instruction`, or a `Vector{Instruction}`.

# Notes
- Not serializable (same limitation as `CustomNoiseRule`).
- The `generator` receives the `lost` qubit map and `rng` as keyword arguments
  when used in [`sample_losses`](@ref).

# Examples
```julia
rule = CustomRule(
    inst -> getoperation(inst) isa GateSWAP,
    (inst, lost; rng=nothing) -> nothing  # drop all SWAPs
)
```
"""
struct CustomRule <: AbstractCircuitRule
    matcher::Function
    generator::Function
end

function matches(rule::CustomRule, inst::Instruction)
    return rule.matcher(inst)
end

replaces(::CustomRule) = true

function apply_rule(rule::CustomRule, inst::Instruction)
    matches(rule, inst) || return nothing
    result = rule.generator(inst, Dict{Int,Bool}(); rng=nothing)
    return _normalize_to_instructions(result)
end

_normalize_to_instructions(::Nothing) = Instruction[]
_normalize_to_instructions(inst::Instruction) = Instruction[inst]
_normalize_to_instructions(insts::AbstractVector{<:Instruction}) = collect(Instruction, insts)
_normalize_to_instructions(c::AbstractCircuit{Instruction}) = collect(Instruction, c)

function Base.show(io::IO, ::CustomRule)
    print(io, "CustomRule(<callable>)")
end

# ============ #
# Loss Model   #
# ============ #

"""
    LossModel([rules]; name="")

A model that specifies how to handle gates when some (but not all) of their
target qubits are lost during [`sample_losses`](@ref).

Rules are evaluated by priority (lower value first), then by insertion order
within the same priority. [`DropRule`](@ref) is evaluated before other loss
rules so it can exclude special cases from broader salvage rules. If multiple
rules of the same priority match, the first one wins.

If no rule matches, the gate is **dropped** by default.

When **all** qubits of a gate are lost, the gate is always dropped regardless
of rules. When **no** qubits are lost, the gate passes through unchanged.

# Arguments
- `rules`: A vector of [`AbstractCircuitRule`](@ref) (default: empty = drop everything).
- `name`: Optional name for the model.

# Examples
```jldoctests
julia> LossModel()
LossModel (unnamed, 0 rules)

julia> LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2)), DropRule(GateSWAP())])
LossModel (unnamed, 2 rules)
├── DropRule(GateSWAP())
└── ReplaceRule(GateCX() => Depolarizing(1, 0.2))
```
"""
struct LossModel
    rules::Vector{AbstractCircuitRule}
    name::String

    function LossModel(rules::AbstractVector{<:AbstractCircuitRule}=AbstractCircuitRule[]; name::String="")
        sorted_rules = collect(AbstractCircuitRule, rules)
        _sort_loss_model_rules!(sorted_rules)
        new(sorted_rules, name)
    end
end

function _sort_loss_model_rules!(rules::Vector{AbstractCircuitRule})
    perm = sortperm(eachindex(rules); by=i -> (priority(rules[i]), i))
    rules[:] = rules[perm]
    return rules
end

function Base.show(io::IO, model::LossModel)
    n = isempty(model.name) ? "unnamed" : model.name
    print(io, "LossModel (", n, ", ", length(model.rules), " rules)")
end

function Base.show(io::IO, ::MIME"text/plain", model::LossModel)
    n = isempty(model.name) ? "unnamed" : model.name
    println(io, "LossModel (", n, ", ", length(model.rules), " rules)")
    for (i, rule) in enumerate(model.rules)
        prefix = i == length(model.rules) ? "└── " : "├── "
        println(io, prefix, rule)
    end
end

# ========================== #
# LossModel Mutation Methods #
# ========================== #

"""
    add_rule!(model::LossModel, rule::AbstractCircuitRule)

Add a rule to the loss model. Rules are kept ordered by priority (lower value
means higher priority). Within the same priority, insertion order is preserved.

Returns the model for chaining.
"""
function add_rule!(model::LossModel, rule::AbstractCircuitRule)
    push!(model.rules, rule)
    _sort_loss_model_rules!(model.rules)
    return model
end

"""
    add_drop!(model::LossModel[, operation])

Add a [`DropRule`](@ref) to the loss model.

`DropRule` has higher priority than other loss rules, so it can be used to
exclude special cases before broader replacement or decoration rules are
applied.

# Arguments
- `operation`: Operation pattern to match (e.g., `GateCX()`). If omitted, matches any operation (catch-all).

# Examples
```jldoctests
julia> model = LossModel();

julia> add_replace!(model, GateCX() => Depolarizing1(0.2))
LossModel (unnamed, 1 rules)
└── ReplaceRule(GateCX() => Depolarizing(1, 0.2))


julia> add_drop!(model, GateSWAP())
LossModel (unnamed, 2 rules)
├── DropRule(GateSWAP())
└── ReplaceRule(GateCX() => Depolarizing(1, 0.2))
```
"""
function add_drop!(model::LossModel)
    add_rule!(model, DropRule())
end

function add_drop!(model::LossModel, operation::Operation)
    add_rule!(model, DropRule(operation))
end

"""
    add_replace!(model::LossModel, operation, replacement)
    add_replace!(model::LossModel, operation => replacement)

Add a [`ReplaceRule`](@ref) to the loss model. When a gate matching `operation`
touches lost qubits, it is replaced with `replacement` on the surviving qubits.

Supports symbolic parameters: `add_replace!(model, GateRXX(θ) => Depolarizing1(θ/π))`.

# Examples
```jldoctests
julia> model = LossModel();

julia> add_replace!(model, GateCX() => Depolarizing1(0.2))
LossModel (unnamed, 1 rules)
└── ReplaceRule(GateCX() => Depolarizing(1, 0.2))


julia> add_replace!(model, GateCZ(), Depolarizing1(0.1))
LossModel (unnamed, 2 rules)
├── ReplaceRule(GateCX() => Depolarizing(1, 0.2))
└── ReplaceRule(GateCZ() => Depolarizing(1, 0.1))
```
"""
function add_replace!(model::LossModel, operation::Operation,
    replacement::Union{AbstractKrausChannel,AbstractGate})
    add_rule!(model, ReplaceRule(operation, replacement))
end

function add_replace!(model::LossModel, relation::Pair)
    add_rule!(model, ReplaceRule(relation))
end

"""
    add_decorate!(model::LossModel, operation, decoration; before=false)
    add_decorate!(model::LossModel, operation => decoration; before=false)

Add a [`DecorateRule`](@ref) to the loss model. When a gate matching `operation`
touches lost qubits, the original gate is kept and `decoration` is added on the
surviving qubits (after by default, or before if `before=true`).

# Examples
```jldoctests
julia> model = LossModel();

julia> add_decorate!(model, GateCX(), Depolarizing1(0.01))
LossModel (unnamed, 1 rules)
└── DecorateRule(GateCX(), Depolarizing(1, 0.01), after)


julia> add_decorate!(model, GateCZ() => Depolarizing1(0.01); before=true)
LossModel (unnamed, 2 rules)
├── DecorateRule(GateCX(), Depolarizing(1, 0.01), after)
└── DecorateRule(GateCZ(), Depolarizing(1, 0.01), before)
```
"""
function add_decorate!(model::LossModel, operation::Operation,
    decoration::Union{AbstractKrausChannel,AbstractGate}; before::Bool=false)
    add_rule!(model, DecorateRule(operation, decoration; before=before))
end

function add_decorate!(model::LossModel, relation::Pair; before::Bool=false)
    add_rule!(model, DecorateRule(relation; before=before))
end

"""
    describe(model::LossModel)

Print a human-readable description of the loss model and its rules.
"""
function describe(model::LossModel)
    if !isempty(model.name)
        println("LossModel: $(model.name)")
    else
        println("LossModel")
    end
    println("="^50)

    if isempty(model.rules)
        println("  (no rules — all gates on lost qubits will be dropped)")
        return
    end

    for (i, rule) in enumerate(model.rules)
        println("Rule $i: $(typeof(rule).name.name)")

        if rule isa DropRule
            if isnothing(rule.operation)
                println("  → Drop any gate touching lost qubits")
            else
                println("  → Drop $(rule.operation) when touching lost qubits")
            end
        elseif rule isa ReplaceRule
            println("  → Replace $(rule.operation) with $(rule.replacement) on surviving qubits")
        elseif rule isa DecorateRule
            pos = rule.before ? "before" : "after"
            println("  → Keep $(rule.operation), add $(rule.decoration) $pos on surviving qubits")
        elseif rule isa CustomRule
            println("  → Custom rule (callable)")
        end
    end
end
