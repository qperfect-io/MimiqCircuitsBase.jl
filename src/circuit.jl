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
└── H @ q1

julia> push!(c, GateCX(), 1, 2)
2-qubit circuit with 2 instructions:
├── H @ q1
└── CX @ q1, q2

julia> push!(c, GateRX(π / 4), 1)
2-qubit circuit with 3 instructions:
├── H @ q1
├── CX @ q1, q2
└── RX(π/4) @ q1

julia> push!(c, Barrier, 1, 3)
3-qubit circuit with 4 instructions:
├── H @ q1
├── CX @ q1, q2
├── RX(π/4) @ q1
└── Barrier @ q1, q3

julia> push!(c, Measure(), 1, 1)
3-qubit circuit with 5 instructions:
├── H @ q1
├── CX @ q1, q2
├── RX(π/4) @ q1
├── Barrier @ q1, q3
└── Measure @ q1, c1

```

Targets are not restricted to be single values, but also vectors.
In this case a single `push!` will add multiple operations.

```jldoctests
julia> push!(Circuit(), GateCCX(), 1, 2:4, 4:10)
6-qubit circuit with 3 instructions:
├── C₂X @ q1, q2, q4
├── C₂X @ q1, q3, q5
└── C₂X @ q1, q4, q6
```

is equivalent to

```
for (i, j) in zip(2:4, 4:10)
    push!(c, GateCX(), 1, i)
end
```

Notice how the range `4:10` is not fully used, since `2:4` is shorter.

Some operations behave a bit differently. See also: [`Barrier`](@ref) and [`Measure`](@ref)

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

function Base.push!(c::Circuit, g::Instruction)
    push!(c._instructions, g)
    return c
end

function Base.append!(c::Circuit, other::Circuit)
    append!(c._instructions, other._instructions)
    return c
end

function Base.insert!(c::Circuit, index, g::Instruction)
    insert!(c._instructions, index, g)
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

    # PERF: this is a double pass the qubit/bit targets, but it is probably
    # the only way of doing it.
    for tgs in shortestzip(targets...)
        if length(unique(tgs)) != length(tgs)
            throw(ArgumentError("Target $(type)s must be the different"))
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

    for tgs in shortestzip(targets...)
        qts = tgs[1:N]
        cts = tgs[end-M+1:end]
        push!(c, Instruction(g, qts..., cts...; checks=false))
    end

    return c
end

# If the we are trying to push a type, then probably we would like to call
# its constructor before, since the type is dependent on the targets.
# A call could result to multiple instructions (e.g. passing registers instead of )
function Base.push!(c::Circuit, ::Type{T}, targets...) where {T<:Operation}
    if numparams(T) == 0
        push!(c, T(), targets...)
    else
        push!(c, T(Instruction, targets...))
    end
end

# same for a function
Base.push!(c::Circuit, f::Function, targets...) = push!(c, f(targets...))

function Base.insert!(c::Circuit, i::Integer, g::Operation{N,M}, targets::Vararg{Integer,L}) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    insert!(c, i, Instruction(g, targets[1:N], targets[end-M+1:end]))
end

# same as for push!
function Base.insert!(c::Circuit, i::Integer, ::Type{T}, targets...) where {T<:Operation}
    if numparams(T) == 0
        insert!(c, i, T(), targets...)
    else
        insert!(c, i, T(Instruction, targets...))
    end
end

# same as for push!
Base.insert!(c::Circuit, i::Integer, f::Function, targets...) = insert!(c, i, f(targets...))

function numqubits(insts::Vector{<:Instruction})
    isempty(insts) && return 0
    return maximum(Iterators.map(g -> maximum(getqubits(g), init=0), insts))
end

numqubits(c::Circuit) = numqubits(c._instructions)

function numbits(c::Circuit)
    isempty(c) && return 0
    return maximum(Iterators.map(g -> maximum(getbits(g), init=0), c))
end

function inverse(c::Circuit)
    gates = map(inverse, reverse(c._instructions))
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
            for g in c._instructions[1:end-1]
                println(io, "├── ", g)
            end
            print(io, "└── ", c._instructions[end])
        else
            chunksize = div(rows - 6, 2)

            for g in c._instructions[1:chunksize]
                println(io, "├── ", g)
            end

            println(io, "⋮   ⋮")

            for g in c._instructions[end-chunksize:end-1]
                println(io, "├── ", g)
            end

            print(io, "└── ", c._instructions[end])
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


