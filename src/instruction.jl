#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    AbstractInstruction

Abstract super type for all the instrcutions.

An instruction applies one or more operations to a set of qubits and classical
bits.

## Methods

[`getqubit`](@ref), [`getqubits`](@ref), [`getbits`](@ref), [`getbit`](@ref)
[`inverse`](@ref), [`opname`](@ref), [`numqubits`](@ref), [`numbits`](@ref)

## See also

[`Instruction`](@ref), [`Operation`](@ref)
"""
abstract type AbstractInstruction end

"""
    getqubit(instruction, i)

`i`-th target qubit of an instruction.

## Examples

```jldoctests
julia> inst = Instruction(GateCX(), 1, 3)
CX @ q[1], q[3]

julia> getqubit(inst, 2)
3

```

## See also

[`getqubits`](@ref), [`getbit`](@ref), [`getbits`](@ref)
"""
function getqubit end

"""
    getqubits(instruction)

Tuple of quantum bits which the instruction is applied to.

```jldoctests
julia> inst = Instruction(GateCX(), 1, 3)
CX @ q[1], q[3]

julia> getqubits(inst)
(1, 3)

```

## See also

[`getqubit`](@ref), [`getbits`](@ref), [`getbit`](@ref)
"""
function getqubits end

"""
    getbit(instruction, i)

`i`-th target classical bit of an instruction.

## Examples

```jldoctests
julia> inst = Instruction(Measure(), 1, 3)
Measure @ q[1], c[3]

julia> getbit(inst, 1)
3

```

## See also

[`getbits`](@ref), [`getqubit`](@ref), [`getqubits`](@ref),
"""
function getbit end

"""
    getbits(instruction)

Tuple of the classical bits which the instruction is applied to.

## Examples

```jldoctests
julia> inst = Instruction(Measure(), 1, 3)
Measure @ q[1], c[3]

julia> getbits(inst)
(3,)

```

## See also

[`getbit`](@ref), [`getqubits`](@ref), [`getqubit`](@ref)
"""
function getbits end

function _checktargets(targets, N, type="qubit")
    L = length(targets)

    if length(targets) != N
        throw(ArgumentError("Wrong number of targets: given $L for $N-$type operation"))
    end

    if any(x -> x <= 0, targets)
        throw(ArgumentError("Target $(type)s must be positive and >=1"))
    end

    if !allunique(targets)
        throw(ArgumentError("Target $(type)s cannot be repeated"))
    end

    nothing
end

"""
    Instruction(op, qtargets, ctargets) <: AbstractInstruction

Representation of an operation applied to specific qubit and bit targets.

## Example

```jldoctests
julia> Instruction(GateX(), (1,), ())
X @ q[1]

julia> Instruction(GateCX(), (1,2), ())
CX @ q[1], q[2]

julia> Instruction(Measure(), (3,), (3,))
Measure @ q[3], c[3]

```

## See also

[`AbstractInstruction`](@ref), [`Operation`](@ref)
"""
struct Instruction{N,M,T<:Operation{N,M}} <: AbstractInstruction
    op::T
    qtargets::NTuple{N,Int64}
    ctargets::NTuple{M,Int64}

    function Instruction(op::T, qtargets::NTuple{N,<:Integer}, ctargets::NTuple{M,<:Integer}; checks=true) where {N,M,T<:Operation{N,M}}
        if checks
            _checktargets(qtargets, N, "qubit")
            _checktargets(ctargets, M, "bit")
        end

        new{N,M,T}(op, qtargets, ctargets)
    end
end

"""
    Instruction(op, targets...)

Constructors an instruction from an operation and a list of targets.

By convention, if `op` is an `N`-qubit and `M`-bit operations, then the first
`N` targets are used as qubits and the last `M` as bits.

## Examples

```jldoctests
julia> Instruction(GateX(), 1)
X @ q[1]

julia> Instruction(GateCX(), 1,2)
CX @ q[1], q[2]

julia> Instruction(Measure(), 3, 3)
Measure @ q[3], c[3]

```
"""
function Instruction(op::Operation{N,M}, targets::Vararg{Integer,L}; kwargs...) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    qtargets = targets[1:N]
    ctargets = targets[end-M+1:end]

    Instruction(op, qtargets, ctargets; kwargs...)
end

isunitary(::Type{Instruction{N,M,T}}) where {N,M,T} = isunitary(T)

numqubits(::Type{Instruction{N,M}}) where {N,M} = N
numqubits(::Instruction{N,M}) where {N,M} = N

numbits(::Type{Instruction{N,M}}) where {N,M} = M
numbits(::Instruction{N,M}) where {N,M} = M

getqubit(inst::AbstractInstruction, i) = getqubits(inst)[i]
getqubits(inst::Instruction) = inst.qtargets

getbit(inst::AbstractInstruction, i) = getbits(inst)[i]
getbits(inst::Instruction) = inst.ctargets

getoperation(g::Instruction) = g.op

opname(g::Instruction) = opname(g.op)

inverse(c::Instruction) = Instruction(inverse(getoperation(c)), getqubits(c)...)

function _partition(arr, indices)
    vec = collect(arr)
    partitions = [vec[1:indices[1]]]
    for i in 2:length(indices)
        push!(partitions, vec[indices[i-1]+1:indices[i]])
    end
    return partitions
end

_string_with_square(arr, sep) = return "[$(join(arr, sep))]"

function _findunitrange(arr)
    if length(arr) < 2
        return arr
    end

    narr = []
    rangestart = arr[1]
    rangestop = arr[1]

    for v in arr[2:end]
        if v == rangestop + 1
            rangestop = v
        elseif rangestart == rangestop
            push!(narr, rangestart)
            rangestart = v
            rangestop = v
        else
            push!(narr, rangestart:rangestop)
            rangestart = v
            rangestop = v
        end
    end

    if rangestart == rangestop
        push!(narr, rangestart)
    else
        push!(narr, rangestart:rangestop)
    end

    return narr
end

function Base.show(io::IO, g::Instruction)
    compact = get(io, :compact, false)

    op = getoperation(g)

    print(io, op)

    nq = numqubits(g)
    nb = numbits(g)

    if nq != 0 || nb != 0
        space = compact ? "" : " "
        print(io, "$space@$space")

        # group the qubits
        if nq != 0
            ps = _partition(getqubits(g), cumsum(qregsizes(op)))
            join(io, map(x -> "q" * _string_with_square(_findunitrange(x), ","), ps), ",$space")
        end

        if nq != 0 && nb != 0
            print(io, ",$space")
        end

        # group the cbits
        if nb != 0
            ps = _partition(getbits(g), cumsum(cregsizes(op)))
            join(io, map(x -> "c" * _string_with_square(_findunitrange(x), ","), ps), ",$space")
        end
    end
end

