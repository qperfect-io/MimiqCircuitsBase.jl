#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
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
    Circuit([instructions])

Representation of a quantum circuit as a vector of instructions applied to the qubits.

The circuit can be initialized with an optional vector of instructions.

A Circuit can be manipulated as either a list of inctructions or as a direct acyclic graph (DAG) of instructions.

See [`OPERATIONS`](@ref), [`GATES`](@ref), or [`GENERALIZED`](@ref) for the list
of operations to add to circuits.

## Examples

Operation can be added one by one to a circuit with the
`push!(circuit, operation, targets...)` function

```jldoctests
julia> c = LinearCircuit()
empty circuit

julia> push!(c, GateH(), 1)
1-qubit circuit with 1 instruction:
└── H @ q[1]

julia> push!(c, GateCX(), 1, 2)
2-qubit circuit with 2 instructions:
├── H @ q[1]
└── CX @ q[1], q[2]

julia> push!(c, GateRX(π / 4), 1)
2-qubit circuit with 3 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
└── RX(π/4) @ q[1]

julia> push!(c, Barrier(2), 1, 3)
3-qubit circuit with 4 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── RX(π/4) @ q[1]
└── Barrier @ q[1,3]

julia> push!(c, Measure(), 1, 1)
3-qubit, 1-bit circuit with 5 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── RX(π/4) @ q[1]
├── Barrier @ q[1,3]
└── M @ q[1], c[1]

```

Targets are not restricted to be single values, but also vectors.
In this case a single `push!` will add multiple operations.

```jldoctests
julia> push!(LinearCircuit(), GateCCX(), 1, 2:4, 4:10)
6-qubit circuit with 3 instructions:
├── C₂X @ q[1:2], q[4]
├── C₂X @ q[1,3], q[5]
└── C₂X @ q[1,4], q[6]
```

is equivalent to

```
for (i, j) in zip(2:4, 4:10)
    push!(c, GateCX(), 1, i)
end
```

Notice how the range `4:10` is not fully used, since `2:4` is shorter.

"""
mutable struct Circuit <: AbstractDAGCircuit{Instruction}
    _graph::SimpleDiGraph
    _instructions::Vector{Instruction}
    _nq::Int
    _nb::Int
    _nz::Int
    _circuit_cache_valid::Bool
    _graph_cache_valid::Bool
end

# Constructors
Circuit(insts::Vector{<:Instruction}) = Circuit(SimpleDiGraph(0), convert(Vector{Instruction}, insts), numqbz(insts)..., true, false)
Circuit(insts::AbstractVector) = Circuit(convert(Vector{Instruction}, insts))
Circuit() = Circuit(SimpleDiGraph(0), Instruction[], 0, 0, 0, true, true)
Circuit(c::AbstractCircuit{Instruction}) = Circuit(SimpleDiGraph(0), deepcopy(instructions(c)), numqubits(c), numbits(c), numzvars(c), true, false)

# caching system
set_circuit_cache_valid!(c::Circuit, val::Bool) = c._circuit_cache_valid = val
is_circuit_cache_valid(c::Circuit) = c._circuit_cache_valid
set_graph_cache_valid!(c::Circuit, val::Bool) = c._graph_cache_valid = val
is_graph_cache_valid(c::Circuit) = c._graph_cache_valid

function cache_resources!(c::Circuit, nq::Integer, nb::Integer, nz::Integer)
    c._nq = nq
    c._nb = nb
    c._nz = nz
end
cache_graph!(c::Circuit, val::AbstractGraph) = c._graph = val

# main properties
# Getter setter
instructions(c::Circuit) = c._instructions
graph(c::Circuit) = c._graph

@doc raw"""
    numqbz(insts::Vector{<:Instruction})
    numqbz(c::AbstractCircuit) -> Int

Compute the highest index of qubit targets, bit targets and zvar targets in the given vector of instructions or circuit.


## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, Measure(), 1:2, 1:2)
2-qubit, 2-bit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[2], c[2]

julia> numqbz(c)
(2, 2, 0)

```
"""
function numqbz(insts::Vector{<:Instruction})
    isempty(insts) && return (0, 0, 0)

    max_qubits = 0
    max_bits = 0
    max_zvars = 0

    for inst in insts
        nb_qubits = maximum(getqubits(inst), init=0)
        nb_bits = maximum(getbits(inst), init=0)
        nb_zvars = maximum(getztargets(inst), init=0)
        if nb_qubits > max_qubits
            max_qubits = nb_qubits
        end
        if nb_bits > max_bits
            max_bits = nb_bits
        end
        if nb_zvars > max_zvars
            max_zvars = nb_zvars
        end
    end

    return max_qubits, max_bits, max_zvars
end

@doc raw"""
    numqubits(insts::Vector{<:Instruction})
    numqubits(c::Circuit) -> Int

Compute the highest index of q-targets in the given vector of instructions or circuit.


## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, Measure(), 1:2, 1:2)
2-qubit, 2-bit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[2], c[2]

julia> numqubits(c)
2

```
"""
function numqubits(insts::Vector{<:Instruction})
    isempty(insts) && return 0
    return maximum(Iterators.map(g -> maximum(getqubits(g), init=0), insts))
end
function numqubits(c::Circuit)
    _ensure_circuit_cache!(c)
    return c._nq
end

@doc raw"""
    numbits(insts::Vector{<:Instruction})
    numbits(c::Circuit) -> Int

Compute the highest index of c-targets in the given circuit.


## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, Measure(), 1:2, 1:2)
2-qubit, 2-bit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[2], c[2]

julia> numbits(c)
2

```
"""
function numbits(insts::Vector{<:Instruction})
    isempty(insts) && return 0
    return maximum(Iterators.map(g -> maximum(getbits(g), init=0), insts))
end
function numbits(c::Circuit)
    _ensure_circuit_cache!(c)
    return c._nb
end

@doc raw"""
    numzvars(insts::Vector{<:Instruction})
    numzvars(c::Circuit) -> Int

Compute the highest index of z-targets in the given circuit.

## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, Amplitude(bs"01"), 1:2)
2-vars circuit with 2 instructions:
├── Amplitude(bs"01") @ z[1]
└── Amplitude(bs"01") @ z[2]

julia> numzvars(c)
2

```
"""
function numzvars(insts::Vector{<:Instruction})
    isempty(insts) && return 0
    return maximum(Iterators.map(g -> maximum(getztargets(g), init=0), insts))
end
function numzvars(c::Circuit)
    _ensure_circuit_cache!(c)
    return c._nz
end


# Circuit interface
Base.getindex(c::Circuit, i::Integer) = getindex(c._instructions, i)
Base.getindex(c::Circuit, i) = Circuit(getindex(c._instructions, i))

