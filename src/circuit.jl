#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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
    struct Circuit

Representation of a quantum circuit as a vector of gates applied to the qubits.

## Parameters

* `gates::Vector{Instruction}` vector of quantum instructions (see [`Instruction`](@ref))

## Example iteration

```
circuit = Circuit()
# add gates to circuit

for (; operation, targets) in circuit
    # do something with the gate and its targets
    # e.g.
end
```
(here the iteration parameters should be called `operation` and `targets` to
proper destructure a `Instruction`)

## Gate types
* Single qubit gates (basic): [`GateX`](@ref), [`GateY`](@ref), [`GateZ`](@ref), [`GateH`](@ref), [`GateS`](@ref), [`GateSDG`](@ref), [`GateT`](@ref), [`GateTDG`](@ref), [`GateSX`](@ref), [`GateSXDG`](@ref), [`GateID`](@ref)
* Single qubit gates (parametric): [`GateRX`](@ref), [`GateRY`](@ref), [`GateRZ`](@ref), [`GateP`](@ref), [`GateR`](@ref), [`GateU`](@ref)
* Two qubit gates (basic): [`GateCX`](@ref), [`GateCY`](@ref), [`GateCZ`](@ref), [`GateCH`](@ref), [`GateSWAP`](@ref), [`GateISWAP`](@ref), [`GateISWAPDG`](@ref)
* Two qubit gates (parametric): [`GateCP`](@ref), [`GateCRX`](@ref), [`GateCRY`](@ref), [`GateCRZ`](@ref), [`GateCU`](@ref)
* Custom gate (currently only for 1 and 2 qubit gates): [`GateCustom`](@ref)

## Special operations
* [`Barrier`](@ref), [`Reset`](@ref), [`Measure`](@ref)
"""
struct Circuit
    instructions::Vector{Instruction}
end

Circuit() = Circuit(Instruction[])

Base.iterate(c::Circuit) = iterate(c.instructions)
Base.iterate(c::Circuit, state) = iterate(c.instructions, state)
Base.firstindex(c::Circuit) = firstindex(c.instructions)
Base.lastindex(c::Circuit) = lastindex(c.instructions)
Base.length(c::Circuit) = length(c.instructions)
Base.isempty(c::Circuit) = isempty(c.instructions)
Base.getindex(c::Circuit, i::Integer) = getindex(c.instructions, i)
Base.getindex(c::Circuit, i) = Circuit(getindex(c.instructions, i))
Base.eltype(::Circuit) = Instruction

function Base.push!(c::Circuit, g::Instruction)
    push!(c.instructions, g)
    return c
end

function Base.append!(c::Circuit, c2::Circuit)
    append!(c.instructions, c2.instructions)
    return c
end

function Base.insert!(c::Circuit, index::Integer, g::Instruction)
    insert!(c.instructions, index, g)
    return c
end

function _checkpushtargets(targets, N, type="qubit")
    L = length(targets)

    if length(targets) != N
        throw(ArgumentError("Wrong number of targets: given $L total for $N-$type operation"))
    end

    if any(x -> any(y -> y <= 0, x), targets)
        throw(ArgumentError("Target $(type)s must be positive and >=1"))
    end

    for i in 1:N
        for j in (i+1):N
            if !isdisjoint(targets[i], targets[j])
                throw(ArgumentError("Target $(type)s must be different"))
            end
        end
    end

    nothing
end

# allows for `push!(c, GateCX(), [1, 2], 3)` syntax to add `CX @ q1, q3` and
# `CX @ q2, q3`. Also works for `push!(c, GateX(), 1:4)` for applying H to all
# of 4 targets.
function Base.push!(c::Circuit, g::Operation{N,M}, targets::Vararg{Any,L}) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    _checkpushtargets(targets[1:N], N, "qubit")
    _checkpushtargets(targets[end-M+1:end], M, "bit")

    for tgs in Iterators.product(targets...)
        qts = tgs[1:N]
        cts = tgs[end-M+1:end]
        push!(c, Instruction(g, qts..., cts...; checks=false))
    end

    return c
end

function Base.insert!(c::Circuit, i::Integer, g::Operation{N,M}, targets::Vararg{Integer,L}) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    insert!(c, i, Instruction(g, targets[1:N], targets[end-M+1:end]))
end

function numqubits(c::Circuit)
    isempty(c) && return 0
    return maximum(Iterators.map(g -> maximum(getqubits(g), init=0), c))
end

function numbits(c::Circuit)
    isempty(c) && return 0
    return maximum(Iterators.map(g -> maximum(getbits(g), init=0), c))
end

function inverse(c::Circuit)
    gates = map(inverse, reverse(c.instructions))
    return Circuit(gates)
end

function Base.show(io::IO, c::Circuit)
    compact = get(io, :compact, false)
    rows, _ = displaysize(io)
    n = length(c)
    if !compact && !isempty(c)
        println(io, "$(numqubits(c))-qubit circuit with $(n) instructions:")

        if rows - 4 <= 0
            print(io, "└── ...")
        elseif rows - 4 >= n
            for g in c.instructions[1:end-1]
                println(io, "├── ", g)
            end
            print(io, "└── ", c.instructions[end])
        else
            chunksize = div(rows - 6, 2)

            for g in c.instructions[1:chunksize]
                println(io, "├── ", g)
            end

            println(io, "⋮   ⋮")

            for g in c.instructions[end-chunksize:end-1]
                println(io, "├── ", g)
            end

            print(io, "└── ", c.instructions[end])
        end
    else
        if isempty(c)
            print(io, "empty circuit")
        else
            print(io, "$(numqubits(c))-qubit circuit with $(length(c)) instructions")
        end
    end

    nothing
end

