#
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""
    decompose_step(operation; rule=CanonicalRewrite())::Circuit
    decompose_step(instruction; rule=CanonicalRewrite())::Circuit
    decompose_step(circuit; rule=CanonicalRewrite())::Circuit

    decompose_step(instructions; rule=CanonicalRewrite())::Vector{Instruction}

Perform a single step of decomposition for the given object.

Returns a `Circuit` or `Vector{Instruction}` containing the decomposed
instructions.

Unlike [`decompose`](@ref), this function acts non-recursively and treats
blocks or other container-like operations as opaque.
"""
function decompose_step end

# decompose an operation directly
function decompose_step(op::Operation{N,M,L}; rule::RewriteRule=CanonicalRewrite()) where {N,M,L}
    c = Circuit()
    decompose_step!(c, rule, op, 1:N, 1:M, 1:L)
    return c
end

# decompose an instruction directly
function decompose_step(inst::Instruction; rule::RewriteRule=CanonicalRewrite())
    c = Circuit()
    decompose_step!(c, rule, getoperation(inst), getqubits(inst), getbits(inst), getztargets(inst))
    return c
end

# perform a single step decomposition on each instruction of a circuit 
function decompose_step(c::Circuit; rule::RewriteRule=CanonicalRewrite())
    cc = Circuit()
    for inst in c
        if matches(rule, getoperation(inst))
            decompose_step!(cc, rule, getoperation(inst), getqubits(inst), getbits(inst), getztargets(inst))
        else
            push!(cc, inst)
        end
    end
    return cc
end

# perform a single step decomposition on each instruction of a vector of instructions
function decompose_step(c::Vector{Instruction}; rule::RewriteRule=CanonicalRewrite())
    cc = Vector{Instruction}()
    for inst in c
        if matches(rule, getoperation(inst))
            decompose_step!(cc, rule, getoperation(inst), getqubits(inst), getbits(inst), getztargets(inst))
        else
            push!(cc, inst)
        end
    end
    return cc
end

"""
    decompose_step!(container, operation; rule=CanonicalRewrite())
    decompose_step!(container, instruction; rule=CanonicalRewrite())
    decompose_step!(container, circuit; rule=CanonicalRewrite())

Perform a single step of decomposition for the given object and appending the
result to `container`.

    decompose_step!(builder, rule, op, qtargets, ctargets, ztargets)

Is the low-level interface that must be implemented by rewrite rules.

Unlike [`decompose`](@ref), this function acts non-recursively and treats
blocks or other container-like operations as opaque.

See also [`decompose_step`](@ref).
"""
function decompose_step! end

function decompose_step!(c, inst::Instruction; rule::DecompositionBasis=CanonicalRewrite())
    decompose_step!(c, rule, getoperation(inst), getqubits(inst), getbits(inst), getztargets(inst))
    return c
end

function decompose_step!(c, map::Circuit; rule::DecompositionBasis=CanonicalRewrite())
    for inst in map
        if matches(rule, getoperation(inst))
            decompose_step!(c, inst; rule=rule)
        else
            push!(c, inst)
        end
    end
    return c
end

function decompose_step!(c, op::Operation{N,M,L}; rule::DecompositionBasis=CanonicalRewrite()) where {N,M,L}
    decompose_step!(c, rule, op, 1:N, 1:M, 1:L)
    return c
end
