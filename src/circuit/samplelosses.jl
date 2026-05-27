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
    sample_losses(c::Circuit; rng=Random.default_rng(), lossmodel=LossModel())

Sample qubit-loss events in a circuit and apply loss rules to gates
touching lost qubits.

The function walks through the circuit, tracks which qubits are lost,
and applies the rules from `lossmodel` to determine what happens to
gates that touch lost qubits.

## Parameters
- `rng`: Random number generator used for sampling stochastic `LossErr` events.
- `lossmodel`: A [`LossModel`](@ref) specifying how to handle gates when
  some qubits are lost.

## Behavior
- `LossErr(p)`: if the qubit is not already lost, it is marked lost with
  probability `p`. If lost, a `QubitLoss` is emitted.
- `QubitLoss`: marks the qubit as lost unconditionally.
- `QubitReload`: marks a lost qubit as present again.
- `CheckLoss` and `MeasureCheckLoss`: always kept in the output.
- Gates with **no** lost qubits: pass through unchanged.
- Gates with **all** qubits lost: always dropped (rules not consulted).
- Gates with **some** qubits lost: rules from `lossmodel` are evaluated
  by priority; first match wins. [`DropRule`](@ref) is evaluated before other
  loss rules. Instructions in the rule's output that touch any lost qubit are
  filtered out. If no rule matches, the gate is dropped.

## Examples

```jldoctests
julia> c = Circuit();

julia> push!(c, QubitLoss(), 2);

julia> push!(c, GateCX(), 1, 2);

julia> sample_losses(c)
2-qubit circuit with 1 instruction:
└── QubitLoss @ q[2]

julia> lm = LossModel([ReplaceRule(GateCX() => Depolarizing1(0.2))]);

julia> sample_losses(c; lossmodel=lm)
2-qubit circuit with 2 instructions:
├── QubitLoss @ q[2]
└── Depolarizing(1,0.2) @ q[1]
```
"""
function sample_losses(c::Circuit; rng::AbstractRNG=Random.default_rng(), lossmodel::LossModel=LossModel())
    lost = Dict{Int,Bool}()
    out = Circuit()

    for inst in c
        op = getoperation(inst)
        qs = collect(getqubits(inst))

        # Loss-state-changing operations
        if op isa LossErr
            _process_losserr!(out, op, qs, lost; rng=rng)
            continue
        end

        if op isa QubitLoss
            _process_qubitloss!(out, op, qs, lost)
            continue
        end

        if op isa QubitReload
            _process_qubitreload!(out, op, qs, lost)
            continue
        end

        # Always-kept operations
        if op isa CheckLoss || op isa MeasureCheckLoss
            push!(out, inst)
            continue
        end

        # No lost qubits → pass through
        if !any(q -> get(lost, q, false), qs)
            push!(out, inst)
            continue
        end

        # ALL qubits lost → always drop (rules not consulted)
        if all(q -> get(lost, q, false), qs)
            continue
        end

        # Some-but-not-all lost → evaluate LossModel rules
        _apply_lossmodel_rules!(out, inst, lossmodel, lost; rng=rng)
    end

    return out
end

# ================= #
# LossModel dispatch #
# ================= #

function _apply_lossmodel_rules!(out::Circuit, inst::Instruction, model::LossModel,
    lost::Dict{Int,Bool}; rng)

    for rule in model.rules
        # CustomRule needs loss context — special dispatch
        result = if rule isa CustomRule
            matches(rule, inst) || continue
            _normalize_to_instructions(rule.generator(inst, lost; rng=rng))
        else
            apply_rule(rule, inst)
        end

        isnothing(result) && continue  # no match, try next rule

        # Filter: discard instructions where any target qubit is lost
        filtered = filter(r -> !any(q -> get(lost, q, false), getqubits(r)), result)
        append!(out, filtered)
        return  # first match wins
    end
    # No rule matched → drop (default)
end


# =============== #
# Helper Methods  #
# =============== #

function _process_losserr!(out, op::LossErr, qs, lost; rng)
    q = qs[1]

    # already lost → ignore
    get(lost, q, false) && return

    # evaluate symbolic probability
    p_val = op.p
    if issymbolic(p_val)
        p_val = Symbolics.value(Symbolics.symbolic_to_float(p_val))
        if !(p_val isa Real)
            throw(ArgumentError(
                "LossErr probability must be numeric for sampling. " *
                "Use evaluate() to substitute symbolic parameters first."
            ))
        end
    end

    # sample stochastic loss
    if rand(rng) < p_val
        lost[q] = true
        push!(out, QubitLoss(), q)
    end
end

function _process_qubitloss!(out, op::QubitLoss, qs, lost)
    q = qs[1]
    lost[q] = true
    push!(out, Instruction(op, qs...))
end

function _process_qubitreload!(out, op::QubitReload, qs, lost)
    q = qs[1]

    if get(lost, q, false)
        lost[q] = false
        push!(out, Instruction(op, qs...))
    end
end
