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

# Parameters

* `gates::Vector{Instruction}` vector of quantum instructions (see [`Instruction`](@ref))

# Example iteration

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
* Custom gate (currently only for 1 and 2 qubit gates): [`Gate`](@ref)
    
"""
struct Circuit
    instructions::Vector{Instruction}
end

Circuit() = Circuit(Instruction[])

@inline Base.iterate(c::Circuit) = iterate(c.instructions)
@inline Base.iterate(c::Circuit, state) = iterate(c.instructions, state)
@inline Base.length(c::Circuit) = length(c.instructions)
@inline Base.isempty(c::Circuit) = isempty(c.instructions)
@inline Base.getindex(c::Circuit, i) = getindex(c.instructions, i)
Base.eltype(::Circuit) = Instruction

@inline function Base.push!(c::Circuit, g::Instruction)
    push!(c.instructions, g)
    return c
end

@inline function Base.append!(c::Circuit, c2::Circuit)
    append!(c.instructions, c2.instructions)
    return c
end

@inline Base.push!(c::Circuit, c2::Circuit) = Base.append!(c, c2)

function Base.push!(c::Circuit, g::Gate{N}, qtargets...) where {N}
    push!(c, Instruction(g, qtargets...))
end

@inline function Base.push!(c::Circuit, b::Barrier, qtargets...)
    push!(c, Instruction(b, qtargets...))
end

function Base.push!(c::Circuit, ::Type{Barrier}, qtargets...)
    push!(c, Instruction(Barrier(), qtargets...))
end

function numqubits(c::Circuit)
    isempty(c) && return 0
    maxtarget_iter = Iterators.map(c) do g
        targets = getqubits(g)
        isempty(targets) && return 0
        return maximum(targets)
    end
    return maximum(maxtarget_iter)
end

function numbits(c::Circuit)
    isempty(c) && return 0
    maxtarget_iter = Iterators.map(c) do g
        targets = getbits(g)
        isempty(targets) && return 0
        return maximum(targets)
    end
    return maximum(maxtarget_iter)
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
        println(io, "$(numqubits(c))-qubit circuit with $(n) gates:")

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
            print(io, "$(numqubits(c))-qubit circuit with $(length(c)) gates")
        end
    end

    nothing
end

