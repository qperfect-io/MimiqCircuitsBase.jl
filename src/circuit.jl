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
using Base: typename
    struct CircuitGate{N,T<:AbstractGate{N}}

Element of a quantum circuit, representing a `N`-qubit gate applied to `N` targets

# Parameters

* `gate::T` actual gate represented
* `targets::NTuple{N, Int64}` tuple of target indices specifying on which
  qubits the gate is applied
"""
struct CircuitGate{N,T<:AbstractGate{N}}
    gate::T
    targets::NTuple{N,Int64}
end

function CircuitGate(gate::AbstractGate{N}, targets...) where {N}
    if length(targets) != N
        throw(ArgumentError("Wrong number of target for $N-qubit gate"))
    end

    if any(x -> x <= 0, targets)
        throw(ArgumentError("Targets must be positive and >=1"))
    end

    CircuitGate{N,typeof(gate)}(gate, targets)
end

"""
    gettarget(circuit_gate, i)

Returns the i-th target qubit of a circuit gate.
"""
gettarget(g::CircuitGate, i) = g.targets[i]

"""
    gettargets(circuit_gate)

Returns the targets of a circuit gate.
"""
gettargets(g::CircuitGate) = g.targets

"""
    getgate(circuit_gate)

Returns the quantum gate associated to the given circuit gate.
"""
getgate(g::CircuitGate) = g.gate

@inline matrix(g::CircuitGate) = matrix(g.gate)
@inline numqubits(::Type{CircuitGate{N,T}}) where {N,T} = N
@inline numqubits(::CircuitGate{N,T}) where {N,T} = N

inverse(c::CircuitGate) = CircuitGate(inverse(c.gate), c.targets...)

function Base.show(io::IO, g::CircuitGate)
    compact = get(io, :compact, false)

    if compact
        print(io, g.gate, "@")
        join(io, map(x -> "q$x", g.targets), ",")
    else
        print(io, g.gate, " @ ")
        join(io, map(x -> "q$x", g.targets), ", ")
    end
end

"""
    struct Circuit

Representation of a quantum circuit as a vector of gates applied to the qubits.

# Parameters

* `gates::Vector{CircuitGate}` vector of gates (see [`CircuitGate`](@ref))

# Example iteration

```
circuit = Circuit()
# add gates to circuit

for (; gate, targets) in circuit
    # do something with the gate and its targets
    # e.g.
end
```
(here the iteration parameters should be called `gate` and `targets` to
proper destructure a `CircuitGate`)

## Gate types
* Single qubit gates (basic): [`GateX`](@ref), [`GateY`](@ref), [`GateZ`](@ref), [`GateH`](@ref), [`GateS`](@ref), [`GateSDG`](@ref), [`GateT`](@ref), [`GateTDG`](@ref), [`GateSX`](@ref), [`GateSXDG`](@ref), [`GateID`](@ref)
* Single qubit gates (parametric): [`GateRX`](@ref), [`GateRY`](@ref), [`GateRZ`](@ref), [`GateP`](@ref), [`GateR`](@ref), [`GateU`](@ref)
* Two qubit gates (basic): [`GateCX`](@ref), [`GateCY`](@ref), [`GateCZ`](@ref), [`GateCH`](@ref), [`GateSWAP`](@ref), [`GateISWAP`](@ref), [`GateISWAPDG`](@ref)
* Two qubit gates (parametric): [`GateCP`](@ref), [`GateCRX`](@ref), [`GateCRY`](@ref), [`GateCRZ`](@ref), [`GateCU`](@ref)
* Custom gate (currently only for 1 and 2 qubit gates): [`Gate`](@ref)
    
"""
struct Circuit
    gates::Vector{CircuitGate}
end

Circuit() = Circuit(CircuitGate[])

@inline Base.iterate(c::Circuit) = iterate(c.gates)
@inline Base.iterate(c::Circuit, state) = iterate(c.gates, state)
@inline Base.length(c::Circuit) = length(c.gates)
@inline Base.isempty(c::Circuit) = isempty(c.gates)
@inline Base.getindex(c::Circuit, i) = getindex(c.gates, i)

@inline function Base.push!(c::Circuit, g)
    push!(c.gates, g)
    return c
end

@inline function Base.append!(c::Circuit, c2::Circuit)
    append!(c.gates, c2.gates)
    return c
end

@inline Base.push!(c::Circuit, c2::Circuit) = Base.append!(c, c2)

function Base.push!(c::Circuit, g::AbstractGate{N}, targets...) where {N}
    push!(c, CircuitGate(g, targets...))
end

function numqubits(c::Circuit)
    isempty(c) && return 0
    return maximum(map(g -> maximum(gettargets(g)), c))
end

function inverse(c::Circuit)
    gates = map(inverse, reverse(c.gates))
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
            for g in c.gates[1:end-1]
                println(io, "├── ", g)
            end
            print(io, "└── ", c.gates[end])
        else
            chunksize = div(rows - 6, 2)

            for g in c.gates[1:chunksize]
                println(io, "├── ", g)
            end

            println(io, "⋮   ⋮")

            for g in c.gates[end-chunksize:end-1]
                println(io, "├── ", g)
            end

            print(io, "└── ", c.gates[end])
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

