#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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

See [`OPERATIONS`](@ref), [`GATES`](@ref), or [`GENERALIZED`](@ref) for the list
of operations to add to circuits.

## Examples

Operation can be added one by one to a circuit with the
`push!(circuit, operation, targets...)` function

```jldoctests
julia> c = Circuit()
empty circuit


julia> push!(c, GateH(), 1)
1-qubit circuit with 1 instructions:
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
3-qubit circuit with 5 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── RX(π/4) @ q[1]
├── Barrier @ q[1,3]
└── M @ q[1], c[1]

```

Targets are not restricted to be single values, but also vectors.
In this case a single `push!` will add multiple operations.

```jldoctests
julia> push!(Circuit(), GateCCX(), 1, 2:4, 4:10)
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

## Display

To display a a LaTeX representation of the circuit, we can just use Quantikz.jl

```julia
using Quantikz
c = Circuit()
...
displaycircuit(c)
```

or

```julia
savecircuit(c, "circuit.pdf")
```
"""
struct Circuit
    _instructions::Vector{Instruction}
end

Circuit() = Circuit(Instruction[])

Base.iterate(c::Circuit) = iterate(c._instructions)
Base.iterate(c::Circuit, state) = iterate(c._instructions, state)
Base.firstindex(c::Circuit) = firstindex(c._instructions)
Base.lastindex(c::Circuit) = lastindex(c._instructions)
Base.length(c::Circuit) = length(c._instructions)
Base.isempty(c::Circuit) = isempty(c._instructions)
Base.getindex(c::Circuit, i::Integer) = getindex(c._instructions, i)
Base.getindex(c::Circuit, i) = Circuit(getindex(c._instructions, i))
Base.eltype(::Circuit) = Instruction

"""
    push!(circuit::Circuit, instruction::Instruction)

Add an instruction to the circuit.

## Arguments
- `circuit::Circuit`: The quantum circuit to which the instruction will be added.
- `instruction::Instruction`: The instruction to add.

## Examples

```jldoctests
julia> c=Circuit()
empty circuit

julia> push!(c, Instruction(GateX(),1)) 
1-qubit circuit with 1 instructions:
└── X @ q[1]

julia> push!(c, Instruction(GateCX(),1, 2))
2-qubit circuit with 2 instructions:
├── X @ q[1]
└── CX @ q[1], q[2]
```
"""
function Base.push!(c::Circuit, g::Instruction)
    push!(c._instructions, g)
    return c
end

"""
    append!(circuit1::Circuit, circuit2::Circuit)

Append all instructions from `circuit2` to `circuit1`.

## Arguments
- `circuit1::Circuit`: The target circuit to which instructions will be appended.
- `circuit2::Circuit`: The circuit whose instructions will be appended.

## Examples

```jldoctests
julia> c=Circuit()
empty circuit

julia> push!(c, GateX(), 1:4)         # Applies X to all 4 targets
4-qubit circuit with 4 instructions:
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> c1 = Circuit()
empty circuit

julia> push!(c1, GateH(), 1:4)
4-qubit circuit with 4 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
└── H @ q[4]

julia> append!(c,c1)
4-qubit circuit with 8 instructions:
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
├── X @ q[4]
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
└── H @ q[4]
"""
function Base.append!(c::Circuit, other::Circuit)
    append!(c._instructions, other._instructions)
    return c
end

"""
    insert!(circuit::Circuit, index::Integer, instruction::Instruction)

Insert an instruction into the circuit at the specified index.

## Arguments
- `circuit::Circuit`: The quantum circuit where the instruction will be inserted.
- `index::Integer`: The position at which the instruction will be inserted.
- `instruction::Instruction`: The instruction to insert.

## Examples

```jldoctests
julia> c=Circuit()
empty circuit

julia> c=Circuit()
empty circuit

julia> push!(c, GateX(), 1:4)
4-qubit circuit with 4 instructions:
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> insert!(c, 2, Instruction(GateH(), 1))
4-qubit circuit with 5 instructions:
├── X @ q[1]
├── H @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]
"""
function Base.insert!(c::Circuit, index, g::Instruction)
    insert!(c._instructions, index, g)
    return c
end

"""
    insert!(circuit1::Circuit, index::Integer, circuit2::Circuit)

Insert all instructions from `circuit2` into `circuit1` at the specified index.

## Arguments
- `circuit1::Circuit`: The target circuit where instructions will be inserted.
- `index::Integer`: The position at which the instructions from `circuit2` will be inserted.
- `circuit2::Circuit`: The circuit whose instructions will be inserted.

## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, GateX(), 1:4)
4-qubit circuit with 4 instructions:
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> c1 = Circuit()
empty circuit

julia> push!(c1, GateH(), 1:4)
4-qubit circuit with 4 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
└── H @ q[4]

julia> insert!(c,1,c1)
4-qubit circuit with 8 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── H @ q[4]
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> 
"""
function Base.insert!(c::Circuit, index::Int, g::Circuit)
    for inst in g._instructions
        insert!(c, index, inst)
        index += 1
    end
    return c
end

function specify_operations(c::Circuit)
    counts = Dict{String,Int}()
    for i in c._instructions
        nq = length(i.qtargets)
        nb = length(i.ctargets)

        if nb > 0
            qubit_key = nq > 1 ? "$(nq)_qubits" : "1_qubit"
            bit_key = nb > 1 ? "$(nb)_bits" : "1_bit"
            key = "$qubit_key & $bit_key"
        else
            key = nq > 1 ? "$(nq)_qubits" : "1_qubit"
        end

        counts[key] = get(counts, key, 0) + 1
    end

    total_operations = sum(values(counts))
    println("Total number of operations: $total_operations")

    count_items = collect(counts)
    for (idx, (key, count)) in enumerate(count_items)
        if idx == length(count_items)
            println("└── $count x $key")
        else
            println("├── $count x $key")
        end
    end
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
2-qubit circuit with 2 instructions:
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

numqubits(c::Circuit) = numqubits(c._instructions)

@doc raw"""
    numbits(insts::Vector{<:Instruction})
    numbits(c::Circuit) -> Int

Compute the highest index of c-targets in the given circuit.


## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, Measure(), 1:2, 1:2)
2-qubit circuit with 2 instructions:
├── M @ q[1], c[1]
└── M @ q[2], c[2]

julia> numbits(c)
2

```
"""
function numbits(c::Circuit)
    isempty(c) && return 0
    return maximum(Iterators.map(g -> maximum(getbits(g), init=0), c))
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
0-qubit circuit with 2 instructions:
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

numzvars(c::Circuit) = numzvars(c._instructions)

function inverse(c::Circuit)
    gates = map(inverse, reverse(c._instructions))
    return Circuit(gates)
end

function Base.show(io::IO, c::Circuit)
    if isempty(c)
        print(io, "Circuit()")
        return nothing
    end

    sep = get(io, :compact, false) ? "," : ", "

    print(io, "Circuit([")
    print(io, c[1])

    if length(c) > 1
        for inst in c[2:end]
            print(io, sep, inst)
        end
    end

    print(io, "])")

    return nothing
end

function Base.show(io::IO, m::MIME"text/plain", c::Circuit)
    compact = get(io, :compact, false)
    rows, _ = displaysize(io)
    n = length(c)
    if !compact && !isempty(c)
        println(io, "$(numqubits(c))-qubit circuit with $(n) instructions:")

        if rows - 4 <= 0
            print(io, "└── ...")
        elseif rows - 4 >= n
            for g in c._instructions[1:end-1]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end
            print(io, "└── ")
            show(io, m, c._instructions[end])
        else
            chunksize = div(rows - 6, 2)

            for g in c._instructions[1:chunksize]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end

            println(io, "⋮   ⋮")

            for g in c._instructions[end-chunksize:end-1]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end

            print(io, "└── ")
            show(io, m, c._instructions[end])
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
