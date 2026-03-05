#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

"""
    issymbolic(obj)

Checks whether the circuit contains any symbolic (unevaluated) parameters.

This method examines each instruction in the circuit to determine if any parameter remains
symbolic (i.e., unevaluated). It recursively checks through each instruction and its nested 
operations, if any.
Returns True if any parameter is symbolic (unevaluated), False if all parameters are fully evaluated.

## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, GateH(), 1)
1-qubit circuit with 1 instruction:
└── H @ q[1]

julia> issymbolic(c)
false

julia> @variables x y
2-element Vector{Symbolics.Num}:
 x
 y

julia> push!(c,Control(3,GateP(x+y)),1,2,3,4)
4-qubit circuit with 2 instructions:
├── H @ q[1]
└── C₃P(x + y) @ q[1:3], q[4]

julia> issymbolic(c)
true

```
"""
function issymbolic end

function issymbolic(n::Num)
    v = Symbolics.value(Symbolics.symbolic_to_float(n))
    v isa Number && return false
    return true
end

function issymbolic(n::Complex{Num})
    issymbolic(real(n)) || issymbolic(imag(n))
end

issymbolic(n::Number) = false

issymbolic(::AbstractString) = false

issymbolic(op::Operation) = any(issymbolic, getparams(op))

issymbolic(inst::Instruction) = issymbolic(getoperation(inst))

issymbolic(c::Circuit) = any(issymbolic, c)

# ############################# #
# Parameter Substitution Helper #
# ############################# #

"""
    _extract_variables(gate::Operation) -> Union{Tuple, Nothing}

Extract symbolic variables from a gate's parameters in order.

# Examples

```julia
@variables θ
gate = GateRX(θ)
vars = _extract_variables(gate)  # Returns: (θ,)

@variables a b c
gate = GateU(a, 0.1, c)
vars = _extract_variables(gate)  # Returns: (a, nothing, c)

gate = GateRX(0.4)
vars = _extract_variables(gate)  # Returns: (nothing,)
```
"""
function _extract_variables(gate::Operation)
    vars = map(getparams(gate)) do param
        if SymbolicUtils.issym(Symbolics.value(param))
            return param
        end

        return nothing
    end

    return Tuple(vars)
end

"""
    _validate_rule_gate_params(gate::Operation)

Validate that a rule gate's parameters are either concrete values or single symbolic variables.
Throws an error if any parameter is a complex symbolic expression.
"""
function _validate_rule_gate_params(gate::Operation)
    for (i, param) in enumerate(getparams(gate))
        v = Symbolics.value(param)

        # check for constant number
        if !(v isa Num)
            vv = simplify(v)
            vvc = unwrap_const(vv)
            vvc isa Number && continue
        end

        # check for something that can be evaluated to a number
        if iscall(v)
            vv = Symbolics.value(Symbolics.symbolic_to_float(v))
            vv isa Number && continue
        end

        # check for simple variable
        if SymbolicUtils.issym(v)
            continue
        end

        throw(ArgumentError(
            "Gate parameter $i ($param) must be a concrete value or a single symbolic variable, got: $param"
        ))
    end
end

const OptionalNum = Union{Num,Nothing}

"""
    applyparams(source::Operation, relation::Pair)

Evaluates a relation by extracting parameter values from a source operation and
substituting them into the target expression.

A relation has the form `variables => target` where:
- `variables`: A single symbolic variable or a tuple of symbolic variables (e.g., `θ` or `(a, b, c)`)
- `target`: An operation using these variables (e.g., `Depolarizing1(θ / π)`)

Parameters are matched **by position**: the i-th variable gets the i-th parameter from source.
Variables in the left side must be **simple symbolic variables**, not expressions.

# Arguments
- `source`: Fully evaluated operation with concrete parameters (e.g., `GateRX(0.4)`)
- `relation`: A `Pair` of variables => target (e.g., `θ => Depolarizing1(θ / π)`)

# Returns
The evaluated target operation with all symbolic variables substituted

# Examples

## Single parameter
```julia
@variables θ
source = GateRX(0.4)
relation = θ => Depolarizing1(θ / π)
result = applyparams(source, relation)
# Result: Depolarizing1(0.4 / π) ≈ Depolarizing1(0.127)
```

## Multiple parameters
```julia
@variables a b c
source = GateU(0.5, 0.3, 0.2)
relation = (a, b, c) => Depolarizing1((a^2 + b^2 + c^2) / (3π^2))
result = applyparams(source, relation)
# Result: Depolarizing1((0.5^2 + 0.3^2 + 0.2^2) / (3π^2))
```

## Using subset of parameters
```julia
@variables a b
source = GateU(0.5, 0.3, 0.2)
relation = (a, b) => Depolarizing1(a + b)
result = applyparams(source, relation)
# Result: Depolarizing1(0.8)
# Third parameter (0.2) is ignored
```

## Complex expressions in target
```julia
@variables θ
source = GateRX(π/4)
relation = θ => AmplitudeDamping(sin(θ)^2 * 0.01)
result = applyparams(source, relation)
# Result: AmplitudeDamping(0.005)
```

## Invalid: Expression in variable list
```julia
@variables a b
source = GateU(0.5, 0.3, 0.2)
relation = (a, b + 1) => Depolarizing1(a)
result = applyparams(source, relation)
# Throws: ArgumentError - left side must be simple variables
```

!!! note
    Variables on the left must be simple symbolic variables (not expressions)

!!! note
    Number of variables must not exceed number of source parameters
"""
function applyparams(source::Operation, relation::Pair{T,<:Operation}) where {T<:NTuple}
    # Source must be fully evaluated
    if issymbolic(source)
        throw(ArgumentError("source must be fully evaluated, got symbolic parameters"))
    end

    # Extract variables and target from relation
    variables, target = relation

    # Return early if no variables to substitute
    if isempty(variables)
        return target
    end

    # Validate that each element in vars is a simple symbolic variable (not an expression)
    for (i, var) in enumerate(variables)
        if isnothing(var)
            continue
        end

        if !(SymbolicUtils.issym(Symbolics.value(var)))
            throw(ArgumentError(
                "Element $i of left side must be a simple symbolic variable, got: $var"
            ))
        end
    end

    # Get parameters from source
    source_params = getparams(source)

    # Check that we don't have more variables than source parameters
    if length(variables) > length(source_params)
        throw(ArgumentError(
            "Relation has $(length(variables)) variables but source only has $(length(source_params)) parameters"
        ))
    end

    # Build substitution dictionary by matching parameter positions
    # First variable gets first parameter, second gets second, etc.
    subs = Dict{Any,Any}()
    for (i, var) in enumerate(variables)
        isnothing(var) && continue
        subs[var] = source_params[i]
    end

    # Apply substitutions to target
    return evaluate(target, subs)
end

function applyparams(source::Operation, relation::Pair{T,<:Operation}) where {T<:OptionalNum}
    variables, target = relation
    return applyparams(source, (variables,) => target)
end
