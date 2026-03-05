#
# Copyright © 2026 QPerfect. All Rights Reserved.
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
    AbstractCircuit{T}

This abstract type is the base of Any Circuit representation in MIMIQ.
It can be seen as a wrapper for list of Instructions, but it also includes a graph representation of this list.
The structure of the graph is up to the inheriting struct to decide & implement.

This class alos directly implements the functions needed to add Instructions to the list, the different getter and setter for the children struct properties
as well as the caching system for the properties of the circuit.
"""


abstract type AbstractCircuit{T} <: AbstractGraph{Int} end

# Getter and setter expected by the children class
function set_circuit_cache_valid! end
function is_circuit_cache_valid end
function set_graph_cache_valid! end
function is_graph_cache_valid end


function instructions end

function cache_graph! end
function graph end

function numqubits end
function numbits end
function numzvars end
function cache_resources! end

@inline function _invalidate_cache!(c::AbstractCircuit{T}) where {T}
    set_circuit_cache_valid!(c, false)
    set_graph_cache_valid!(c, false)
    return nothing
end

function _ensure_circuit_cache!(c::AbstractCircuit{T}) where {T}
    if !is_circuit_cache_valid(c)
        cache_resources!(c, numqbz(instructions(c))...)
        set_circuit_cache_valid!(c, true)
    end
end

function _ensure_graph_cache!(c::AbstractCircuit{T}) where {T}
    if !is_graph_cache_valid(c)
        cache_graph!(c, _build_graph(c))
        set_graph_cache_valid!(c, true)
    end
end

function _ensure_cache!(c::AbstractCircuit{T}) where {T}
    _ensure_circuit_cache!(c)
    _ensure_graph_cache!(c)
end

Base.iterate(c::AbstractCircuit{T}) where {T} = iterate(instructions(c))
Base.iterate(c::AbstractCircuit{T}, state) where {T} = iterate(instructions(c), state)
Base.firstindex(c::AbstractCircuit{T}) where {T} = firstindex(instructions(c))
Base.lastindex(c::AbstractCircuit{T}) where {T} = lastindex(instructions(c))
Base.length(c::AbstractCircuit{T}) where {T} = length(instructions(c))
Base.isempty(c::AbstractCircuit{T}) where {T} = isempty(instructions(c))
Base.getindex(c::AbstractCircuit{T}, i::Integer) where {T} = getindex(instructions(c), i)
Base.getindex(c::AbstractCircuit{T}, i) where {T} = getindex(instructions(c), i)
Base.eltype(c::AbstractCircuit{T}) where {T} = eltype(instructions(c))
Base.keys(c::AbstractCircuit{T}) where {T} = keys(instructions(c))

"""
    push!(circuit::AbstractCircuit{T}, instruction::T)

Add an instruction to the circuit.

## Arguments
- `circuit::AbstractCircuit{T}`: The quantum circuit to which the instruction will be added.
- `instruction::T`: The instruction to add.

## Examples

```jldoctests
julia> c=Circuit()
empty circuit

julia> push!(c, Instruction(GateX(),1)) 
1-qubit circuit with 1 instruction:
└── X @ q[1]

julia> push!(c, Instruction(GateCX(),1, 2))
2-qubit circuit with 2 instructions:
├── X @ q[1]
└── CX @ q[1], q[2]
```
"""
function Base.push!(c::AbstractCircuit{T}, g::T) where {T}
    push!(instructions(c), g)
    _invalidate_cache!(c)
    return c
end

"""
    append!(circuit1::AbstractCircuit{T}, circuit2::AbstractCircuit{T})

Append all instructions from `circuit2` to `circuit1`.

## Arguments
- `circuit1::AbstractCircuit{T}`: The target circuit to which instructions will be appended.
- `circuit2::AbstractCircuit{T}`: The circuit whose instructions will be appended.

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
function Base.append!(c::AbstractCircuit{T}, other::AbstractCircuit{T}) where {T}
    append!(instructions(c), instructions(other))
    _invalidate_cache!(c)
    return c
end

function Base.append!(c::AbstractCircuit{T}, insts::Vector{<:T}) where {T}
    append!(instructions(c), insts)
    _invalidate_cache!(c)
    return c
end

"""
    insert!(circuit::AbstractCircuit{T}, index::Integer, instruction::T)

Insert an instruction into the circuit at the specified index.

## Arguments
- `circuit::AbstractCircuit{T}`: The quantum circuit where the instruction will be inserted.
- `index::Integer`: The position at which the instruction will be inserted.
- `instruction::T`: The instruction to insert.

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
function Base.insert!(c::AbstractCircuit{T}, index, g::T) where {T}
    insert!(instructions(c), index, g)
    _invalidate_cache!(c)
    return c
end

"""
    insert!(circuit1::AbstractCircuit{T}, index::Integer, circuit2::AbstractCircuit{T})

Insert all instructions from `circuit2` into `circuit1` at the specified index.

## Arguments
- `circuit1::AbstractCircuit{T}`: The target circuit where instructions will be inserted.
- `index::Integer`: The position at which the instructions from `circuit2` will be inserted.
- `circuit2::AbstractCircuit{T}`: The circuit whose instructions will be inserted.

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
function Base.insert!(c::AbstractCircuit{T}, index::Int, g::AbstractCircuit{T}) where {T}
    for inst in instructions(g)
        insert!(c, index, inst)
        index += 1
    end
    # no need to invalidate, insert!(c, index, inst) called above does it
    return c
end

"""
    deleteat!(circuit::AbstractCircuit{T}, index::Integer)
    deleteat!(circuit::AbstractCircuit{T}, inds)

Remove the instruction(s) at the given index(es).

## Arguments
- `circuit::AbstractCircuit{T}`: The target circuit.
- `index`: The index or collection of indices to remove.

## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, GateX(), 1:3)
3-qubit circuit with 3 instructions:
├── X @ q[1]
├── X @ q[2]
└── X @ q[3]

julia> deleteat!(c, 2)
3-qubit circuit with 2 instructions:
├── X @ q[1]
└── X @ q[3]
```
"""
function Base.deleteat!(c::AbstractCircuit{T}, i::Integer) where {T}
    deleteat!(instructions(c), i)
    _invalidate_cache!(c)
    return c
end

function Base.deleteat!(c::AbstractCircuit{T}, inds) where {T}
    deleteat!(instructions(c), inds)
    _invalidate_cache!(c)
    return c
end

function Base.splice!(c::AbstractCircuit{T}, index::Integer, replacement::Vector{T}=T[]) where {T}
    res = splice!(instructions(c), index, replacement)
    _invalidate_cache!(c)
    return res
end

function Base.splice!(c::AbstractCircuit{T}, range::AbstractUnitRange{<:Integer}, replacement::Vector{T}=T[]) where {T}
    res = splice!(instructions(c), range, replacement)
    _invalidate_cache!(c)
    return res
end

function specify_operations(c::AbstractCircuit{T}) where {T}
    counts = Dict{String,Int}()
    for i in instructions(c)
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

function numqbz(c::AbstractCircuit{T}) where {T}
    _ensure_circuit_cache!(c)
    return numqubits(c), numbits(c), numzvars(c)
end

function getparams(c::AbstractCircuit{T}) where {T}
    return reduce(vcat, getparams.(instructions(c)))
end

function listvars(c::AbstractCircuit{T}) where {T}
    return unique(reduce(vcat, listvars.(instructions(c)); init=Symbolics.Num[]))
end

function inverse(c::AbstractCircuit{T}) where {T}
    gates = map(inverse, reverse(instructions(c)))
    # New circuit, cache invalid (initially 0s and false by default constructor with vector)
    return Circuit(gates)
end

function Base.show(io::IO, c::AbstractCircuit{T}) where {T}
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

function _print_instcontainer_header_numbers(io::IO, c)
    nq = numqubits(c)
    nc = numbits(c)
    nz = numzvars(c)
    oneprinted = false
    if nq != 0
        print(io, "$nq-qubit")
        oneprinted = true
    end
    if nc != 0
        if oneprinted
            print(io, ", ")
        end
        print(io, "$nc-bit")
        oneprinted = true
    end
    if nz != 0
        if oneprinted
            print(io, ", ")
        end
        print(io, "$nz-vars")
        oneprinted = true
    end
    if oneprinted
        print(io, " ")
    end
end

function _print_instcontainer_header(io::IO, c::AbstractCircuit{T}) where {T}
    if isempty(c)
        print(io, "empty circuit")
    else
        _print_instcontainer_header_numbers(io, c)
        print(io, "circuit with $(length(c))")
        if length(c) == 1
            print(io, " instruction")
        else
            print(io, " instructions")
        end
    end
end

_show_instruction(io::IO, m::MIME, inst; _...) = show(io, m, inst)

function _show_instructions(io::IO, m::MIME, c)
    rows = first(displaysize(io))
    indent = get(io, :indent, 0)
    last = get(io, :last, false)

    indentstr = last ? "    "^indent : "│   "^indent
    n = length(c)

    if isempty(c)
        return nothing
    end

    if rows - 4 <= 0
        print(io, indentstr, "└── ...")
    elseif rows - 4 >= n
        for g in c[1:end-1]
            print(io, indentstr, "├── ")
            _show_instruction(io, m, g)
            print(io, '\n')
        end
        print(io, indentstr, "└── ")
        _show_instruction(io, m, c[end], last=true)
    else
        chunksize = div(rows - 6, 2)

        for g in c[1:chunksize]
            print(io, indentstr, "├── ")
            _show_instruction(io, m, g)
            print(io, '\n')
        end

        println(io, indentstr, "⋮   ⋮")

        for g in c[end-chunksize:end-1]
            print(io, indentstr, "├── ")
            _show_instruction(io, m, g)
            print(io, '\n')
        end

        print(io, indentstr, "└── ")
        _show_instruction(io, m, c[end])
    end
end

function Base.show(io::IO, m::MIME"text/plain", c::AbstractCircuit{T}) where {T}
    compact = get(io, :compact, false)

    if !compact && !isempty(c)
        _print_instcontainer_header(io, c)
        print(io, ":\n")

        _show_instructions(io, m, c)
    else
        if isempty(c)
            print(io, "empty circuit")
        else
            _print_instcontainer_header(io, c)
        end
    end

    nothing
end

Base.copy(c::AbstractCircuit{T}) where {T} = Circuit(copy(instructions(c)), numqubits(c), numbits(c), numzvars(c), is_circuit_cache_valid(c))

function Base.:(==)(c1::AbstractCircuit{T}, c2::AbstractCircuit{T}) where {T}
    length(c1) == length(c2) || return false
    instructions(c1) == instructions(c2) || return false
    return true
end

matrix(c::AbstractCircuit{T}) where {T} = matrix(instructions(c))


# Graphs functions

function _build_graph(circuit::AbstractCircuit{T}) where {T}
    error("Abstract type not implemented: To manipulate the graph representing the circuit the struct inheriting from AbstractCircuit{T} must implement the method _build_graph") # see Circuit._build_graph for an example
end

# Graphs.jl interface
function Graphs.nv(g::AbstractCircuit{T}) where {T}
    _ensure_graph_cache!(g)
    return nv(graph(g))
end
function Graphs.ne(g::AbstractCircuit{T}) where {T}
    _ensure_graph_cache!(g)
    return ne(graph(g))
end
function Graphs.edges(g::AbstractCircuit{T}) where {T}
    _ensure_graph_cache!(g)
    return edges(graph(g))
end
function Graphs.vertices(g::AbstractCircuit{T}) where {T}
    _ensure_graph_cache!(g)
    return vertices(graph(g))
end
function Graphs.inneighbors(g::AbstractCircuit{T}, v) where {T}
    _ensure_graph_cache!(g)
    return inneighbors(graph(g), v)
end
function Graphs.outneighbors(g::AbstractCircuit{T}, v) where {T}
    _ensure_graph_cache!(g)
    return outneighbors(graph(g), v)
end
Graphs.is_directed(::Type{<:AbstractCircuit{T}}) where {T} = true
Graphs.is_directed(g::AbstractCircuit{T}) where {T} = true
Graphs.zero(::Type{AbstractCircuit{T}}) where {T} = AbstractCircuit{T}(SimpleDiGraph(0), T[], 0, 0, 0, false) where {T}
function Graphs.has_edge(g::AbstractCircuit{T}, s, d) where {T}
    _ensure_graph_cache!(g)
    return has_edge(graph(g), s, d)
end
function Graphs.has_vertex(g::AbstractCircuit{T}, v) where {T}
    _ensure_graph_cache!(g)
    return has_vertex(graph(g), v)
end


"""
    abstract type AbstractDAGCircuit{T} <: AbstractCircuit{T} end

Abstract type for all the struct that needs to implement a DAG representation for their circuits.
It simply serves as a middle man/type providing the method to build the DAG from the list of instructions.
"""
abstract type AbstractDAGCircuit{T} <: AbstractCircuit{T} end


function _build_graph(circuit::AbstractDAGCircuit{T}) where {T}
    n = length(circuit)
    g = SimpleDiGraph(n)

    last_op_q = Dict{Int,Int}()
    last_op_c = Dict{Int,Int}()
    last_op_z = Dict{Int,Int}()

    for (i, inst) in enumerate(circuit)
        # Check dependencies for qubits
        for q in getqubits(inst)
            if haskey(last_op_q, q)
                prev = last_op_q[q]
                add_edge!(g, prev, i)
            end
            last_op_q[q] = i
        end

        # Check dependencies for bits
        for b in getbits(inst)
            if haskey(last_op_c, b)
                prev = last_op_c[b]
                add_edge!(g, prev, i)
            end
            last_op_c[b] = i
        end

        # Check dependencies for z-targets
        for z in getztargets(inst)
            if haskey(last_op_z, z)
                prev = last_op_z[z]
                add_edge!(g, prev, i)
            end
            last_op_z[z] = i
        end
    end
    return g
end