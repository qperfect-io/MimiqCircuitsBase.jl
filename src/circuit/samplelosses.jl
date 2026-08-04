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

@doc raw"""
    sample_losses(c::Circuit; rng=Random.default_rng())

Resolve the random qubit-loss events in a circuit.

Each [`Loss`](@ref)`(p)` is drawn: with probability `p` it becomes a certain
loss `Loss(1.0)`, otherwise it is removed. Every other operation, including the
deterministic loss bookkeeping (`Reload`, `Check`, `MeasureCheck`), is kept
unchanged. The result is therefore deterministic but still expressed with loss
operations; use [`lower_losses`](@ref) to turn it into a runnable, loss-free
circuit.

## Examples

```jldoctests
julia> c = push!(Circuit(), Loss(), 2);

julia> sample_losses(c)
2-qubit circuit with 1 instruction:
└── Loss(1.0) @ q[2]
```
"""
function sample_losses(c::Circuit; rng::AbstractRNG=Random.default_rng())
    out = Circuit()
    for inst in c
        op = getoperation(inst)
        if op isa Loss
            q = getqubit(inst, 1)
            if _loss_fires(op, rng)
                push!(out, Loss(1.0), q)
            end
        else
            push!(out, inst)
        end
    end
    return out
end

@doc raw"""
    lower_losses(c::Circuit; rng=Random.default_rng(), lossmodel=LossModel())

Lower a circuit with loss operations into an equivalent circuit that uses only
primitives (`Reset`, `Measure`, `SetBit0`, `SetBit1`) and therefore runs on any
backend.

This is the deterministic half of loss resolution. It expects the random
`Loss(p)` events to be resolved already (see [`sample_losses`](@ref)) and treats
any remaining `Loss`, whatever its probability, as a certain loss. For the full
pipeline that samples then lowers, use [`resolve_losses`](@ref).

It tracks which qubits are lost and rewrites every loss operation:

- `Loss`: marks the qubit lost and emits a passive [`Lost`](@ref) marker.
- `Reload`: emits a [`Reset`](@ref) and a [`Reloaded`](@ref) marker, and marks
  the qubit present again.
- `Check`: emits `SetBit1` if the qubit is present, `SetBit0` if it is lost.
- `MeasureCheck`: present, a `Measure` plus `SetBit1`; lost, `SetBit0` on both
  bits.
- `Measure` on a lost qubit: emits `SetBit0`, so a lost qubit reads 0.
- Gates with no lost qubits pass through; gates with all qubits lost are
  dropped; gates with some qubits lost are handled by the [`LossModel`](@ref)
  rules, with instructions touching a lost qubit filtered out.

The returned circuit contains no loss operations.

## Examples

```jldoctests
julia> c = Circuit();

julia> push!(c, Loss(), 1);

julia> push!(c, GateX(), 1);

julia> push!(c, Check(), 1, 1);

julia> lower_losses(c)
1-qubit, 1-bit circuit with 2 instructions:
├── Lost @ q[1]
└── c[1] = 0
```
"""
function lower_losses(c::Circuit; rng::AbstractRNG=Random.default_rng(),
    lossmodel::LossModel=LossModel())
    lost = Dict{Int,Bool}()
    out = Circuit()

    for inst in c
        op = getoperation(inst)
        qs = collect(getqubits(inst))

        if op isa Loss
            q = qs[1]
            get(lost, q, false) && continue
            lost[q] = true
            push!(out, Lost(), q)
            continue
        end

        if op isa Reload
            q = qs[1]
            push!(out, Reset(), q)
            push!(out, Reloaded(), q)
            lost[q] = false
            continue
        end

        if op isa Check
            q = qs[1]
            b = getbit(inst, 1)
            push!(out, get(lost, q, false) ? SetBit0() : SetBit1(), b)
            continue
        end

        if op isa MeasureCheck
            q = qs[1]
            mbit = getbit(inst, 1)
            sbit = getbit(inst, 2)
            if get(lost, q, false)
                push!(out, SetBit0(), mbit)
                push!(out, SetBit0(), sbit)
            else
                push!(out, Measure(), q, mbit)
                push!(out, SetBit1(), sbit)
            end
            continue
        end

        # a single-qubit measurement on a lost qubit reads 0
        if op isa AbstractMeasurement{1} && get(lost, qs[1], false)
            push!(out, SetBit0(), getbit(inst, 1))
            continue
        end

        # no lost qubits → pass through
        if !any(q -> get(lost, q, false), qs)
            push!(out, inst)
            continue
        end

        # all qubits lost → drop
        if all(q -> get(lost, q, false), qs)
            continue
        end

        # some-but-not-all lost → evaluate LossModel rules
        _apply_lossmodel_rules!(out, inst, lossmodel, lost; rng=rng)
    end

    return out
end

@doc raw"""
    resolve_losses(c::Circuit; rng=Random.default_rng(), lossmodel=LossModel())

Fully resolve loss in a circuit into a runnable, loss-free circuit.

This is the entry point to reach for in the common case. It runs the two steps
of loss resolution back to back: [`sample_losses`](@ref) draws the random
`Loss(p)` events, then [`lower_losses`](@ref) rewrites the result into
primitives. The returned circuit contains no loss operations and runs on any
backend.

## Choosing a function

Loss resolution is split into two stages so each can be used on its own:

1. [`sample_losses`](@ref) is the **random** stage. It draws every `Loss(p)`,
   keeping it as a certain `Loss(1.0)` or dropping it, and leaves everything
   else (including `Reload`, `Check`, `MeasureCheck`) untouched. The output is
   still a loss circuit, just with the randomness fixed. Call it on its own to
   inspect or post-process one sampled loss pattern before lowering, or to draw
   many patterns from the same circuit.
2. [`lower_losses`](@ref) is the **deterministic** stage. It rewrites the loss
   bookkeeping into `Reset`/`Measure`/`SetBit0`/`SetBit1` and applies the
   [`LossModel`](@ref) rules to gates on lost qubits. It treats any remaining
   `Loss` as certain, so it is meaningful only after the probabilities are
   resolved. Call it on its own when the losses are already deterministic (for
   example a hand-written circuit using `Loss()`, or the output of
   `sample_losses`).

`resolve_losses` is `lower_losses ∘ sample_losses`; prefer it unless you need
one stage in isolation. For a targeted "what if I lose exactly these sites"
study, see [`sample_loss_scenario`](@ref).

## Examples

```jldoctests
julia> c = Circuit();

julia> push!(c, Loss(), 1);

julia> push!(c, GateX(), 1);

julia> push!(c, Check(), 1, 1);

julia> resolve_losses(c)
1-qubit, 1-bit circuit with 2 instructions:
├── Lost @ q[1]
└── c[1] = 0
```
"""
function resolve_losses(c::Circuit; rng::AbstractRNG=Random.default_rng(),
    lossmodel::LossModel=LossModel())
    return lower_losses(sample_losses(c; rng=rng); rng=rng, lossmodel=lossmodel)
end

@doc raw"""
    sample_loss_scenario(c::Circuit, loss_indices; p=1.0, rng=Random.default_rng(), lossmodel=LossModel())

Build a deterministic "what if" loss scenario from a circuit containing
[`Loss`](@ref) instructions.

The selected `Loss` instructions, in circuit order, are forced to `Loss(p)`
while every other `Loss` is forced to `Loss(0.0)`. The result is then resolved
with [`resolve_losses`](@ref), so the returned circuit shows the effect of
losing exactly those sites.

# Examples
```jldoctests
julia> c = Circuit();

julia> push!(c, Loss(0.2), 1);

julia> push!(c, GateCX(), 1, 2);

julia> push!(c, Loss(0.4), 2);

julia> sample_loss_scenario(c, [2])
2-qubit circuit with 2 instructions:
├── CX @ q[1], q[2]
└── Lost @ q[2]
```
"""
function sample_loss_scenario(c::Circuit, loss_indices; p::Real=1.0,
    rng::AbstractRNG=Random.default_rng(), lossmodel::LossModel=LossModel())
    forced_indices = _normalize_loss_indices(loss_indices)
    0.0 <= p <= 1.0 || throw(ArgumentError("Probability p must be between 0 and 1, got $p."))

    scenario = Circuit()
    current_index = 0

    for inst in c
        op = getoperation(inst)
        if op isa Loss
            current_index += 1
            forced_op = Loss(current_index in forced_indices ? p : 0.0)
            push!(scenario, Instruction(forced_op, getqubits(inst), getbits(inst), getztargets(inst)))
        else
            push!(scenario, inst)
        end
    end

    if current_index == 0
        throw(ArgumentError("Circuit does not contain any Loss instructions."))
    end

    invalid_indices = sort!(collect(filter(i -> i > current_index, forced_indices)))
    if !isempty(invalid_indices)
        throw(ArgumentError(
            "Loss index/indices $(invalid_indices) out of range for a circuit with $current_index Loss instruction(s)."
        ))
    end

    return resolve_losses(scenario; rng=rng, lossmodel=lossmodel)
end

sample_loss_scenario(c::Circuit, loss_index::Integer; p::Real=1.0,
    rng::AbstractRNG=Random.default_rng(), lossmodel::LossModel=LossModel()) =
    sample_loss_scenario(c, (loss_index,); p=p, rng=rng, lossmodel=lossmodel)

function _normalize_loss_indices(loss_indices)
    indices = Set{Int}()
    for idx in loss_indices
        idx >= 1 || throw(ArgumentError("Loss indices must be >= 1, got $idx."))
        push!(indices, Int(idx))
    end
    return indices
end

# Draw whether a `Loss(p)` fires. A certain loss (p == 1) always fires.
function _loss_fires(op::Loss, rng)
    p_val = op.p
    if issymbolic(p_val)
        p_val = Symbolics.value(Symbolics.symbolic_to_float(p_val))
        if !(p_val isa Real)
            throw(ArgumentError(
                "Loss probability must be numeric for sampling. " *
                "Use evaluate() to substitute symbolic parameters first."
            ))
        end
    end
    return p_val >= 1.0 || rand(rng) < p_val
end

# ================= #
# LossModel dispatch #
# ================= #

@doc raw"""
    lossmodel_rewrite(inst::Instruction, lost::Dict{Int,Bool}, model::LossModel; rng)

Decide how a single instruction that touches both lost and present qubits is
rewritten under a [`LossModel`](@ref), returning the instructions to emit in its
place (an empty vector when the instruction is dropped).

This is the per-instruction decision core shared by the offline
[`lower_losses`](@ref) and the online runtime-loss driver: both feed it the same
`lost` map (qubit → lost?) and apply whatever it returns. Rules are tried in
order, the first matching rule wins, and any emitted instruction still touching a
lost qubit is filtered out. When no rule matches, the instruction is dropped.
"""
function lossmodel_rewrite(inst::Instruction, lost::Dict{Int,Bool}, model::LossModel; rng)
    for rule in model.rules
        # CustomRule needs the loss context, so it gets a special dispatch
        result = if rule isa CustomRule
            matches(rule, inst) || continue
            _normalize_to_instructions(rule.generator(inst, lost; rng=rng))
        else
            apply_rule(rule, inst)
        end

        isnothing(result) && continue  # no match, try next rule

        # discard instructions where any target qubit is lost; first match wins
        return filter(r -> !any(q -> get(lost, q, false), getqubits(r)), result)
    end
    # No rule matched → drop (default)
    return Instruction[]
end

_apply_lossmodel_rules!(out::Circuit, inst::Instruction, model::LossModel,
    lost::Dict{Int,Bool}; rng) =
    append!(out, lossmodel_rewrite(inst, lost, model; rng=rng))
