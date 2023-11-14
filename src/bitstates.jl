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
    struct BitState

Representation of the quantum state of a quantum register with definite values for each qubit.

## Examples

```julia
julia> BitState(16)
16-qubit BitState with 0 non-zero qubits:
└── |0000000000000000⟩

julia> bs = BitState(16, [1,2,3,4])
16-qubit BitState with 4 non-zero qubits:
├── |1111000000000000⟩
└── non-zero qubits: [1, 2, 3, 4]

julia> bs[10] = 1
1

julia> bs
16-qubit BitState with 5 non-zero qubits:
├── |1111000001000000⟩
└── non-zero qubits: [1, 2, 3, 4, 10]

julia> c = Circuit()
empty circuit

julia> push!(c, GateX(), 8)
8-qubit circuit with 1 instructions:
└── X @ q8

julia> BitState(c, [1,3,5,8])
8-qubit BitState with 4 non-zero qubits:
├── |10101001⟩
└── non-zero qubits: [1, 3, 5, 8]

julia> bitstate_to_integer(bs)
527

julia> typeof(ans)
BigInt

julia> bitstate_to_integer(bs, Int64)
527

julia> typeof(ans)
Int64
```

There are many different ways to get bit states:

```julia
julia> bs = BitState(30, 2344574)
30-qubit BitState with 13 non-zero qubits:
├── |011111100110001111000100000000⟩
└── non-zero qubits: [2, 3, 4, 5, 6, 7, 10, 11, 15, 16, 17, 18, 22]

julia> ones(BitState, 10) # or also trues(BitState, 10)
10-qubit BitState with 10 non-zero qubits:
├── |1111111111⟩
└── non-zero qubits: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

julia> zeros(BitState, 10) # or also falses(BitState, 10)
10-qubit BitState with 0 non-zero qubits:
└── |0000000000⟩

julia> BitState(16) do i
           iseven(i)
       end
16-qubit BitState with 8 non-zero qubits:
├── |0101010101010101⟩
└── non-zero qubits: [2, 4, 6, 8, 10, 12, 14, 16]
```
"""
struct BitState
    bits::BitVector

    function BitState(bits)
        if isempty(bits)
            error("Cannot have a BitState with no qubits")
        end

        new(bits)
    end
end

BitState(nq::Integer) = BitState(zeros(Bool, nq))

BitState(nq::Integer, i::Integer) = BitState(int_to_bitarr(i, nq))

function BitState(nq::Integer, nz)
    bs = BitState(nq)
    bs.bits[nz] .= true
    return bs
end

function BitState(f::Function, nq::Integer)
    bs = BitState(BitVector(undef, nq))
    for i in 1:nq
        bs.bits[i] = f(i)
    end
    bs
end

function BitState(c::Circuit, args...)
    nq = numqubits(c)
    return BitState(nq, args...)
end

BitState(f::Function, c::Circuit) = BitState(f, numqubits(c))

"""
    bitstate_to_integer(bitstate[, T])

Convert a bit state into its corresponding integer.
"""
bitstate_to_integer(bs::BitState, ::Type{T}=BigInt) where {T} = bitarr_to_int(bs.bits, T)

"""
    bitstate_to_index(bitstate)

Convert a bit state into the corresponding index.

This is useful for indexing, for example, a vector of states.
"""
function bitstate_to_index(bs::BitState)
    int = bitarr_to_int(bs.bits, Int64)

    if !(int < typemax(Int64))
        error("System too large to be indexed by 64 bit integers")
    end

    return int + 1
end

function numqubits(bs::BitState)
    return length(bs.bits)
end

"""
    nonzeros(bitstate)

Return the indices of the non-zero qubits in a bit state.
"""
nonzeros(bs::BitState) = findall(x -> x, bs.bits)

function Base.show(io::IO, bs::BitState)
    print(io, string(bs))
end

function Base.show(io::IO, ::MIME"text/plain", bs::BitState)
    _, cols = displaysize(io)

    n = length(bs)
    nextra = 9
    nprint = cols - nextra
    nz = nonzeros(bs)
    lnz = length(nz)

    char = isempty(nz) ? '└' : '├'

    println(io, n, "-qubit BitState with $lnz non-zero qubits:")
    if nprint < n
        print(io, "$(char)── |", join(map(x -> x ? '1' : '0', bs.bits)), "…", "⟩")
    else
        print(io, "$(char)── |", join(map(x -> x ? '1' : '0', bs.bits)), "⟩")
    end

    if !isempty(nz)
        print(io, "\n└── non-zero qubits: [",)

        printed = 22
        print(io, nz[1])
        printed += length(string(nz[1]))

        for x in nz[2:end]
            printed += length(string(x)) + 2

            if printed > cols - 4
                break
            end

            print(io, ", ", x)
        end

        if printed > cols - 4
            print(io, ", …")
        end

        print(io, "]")
    end

    nothing
end

Base.string(bs::BitState) = "bs" * join(map(x -> x ? '1' : '0', bs.bits))

"""
    to01(bitstate[, endianess=:big])

Converts a BitState into a string of 0 and 1 characters.
Optionally endianess can be specified, which can be either `:big` or `:little`.

## Examples

```jldoctests
julia> to01(bs"10011")
"10011"

julia> to01(bs"10011"; endianess=:big)
"10011"

julia> to01(bs"10011"; endianess=:little)
"11001"
```
"""
function to01(bs::BitState; endianess::Symbol=:big)
    if endianess == :big
        return join(map(x -> x ? '1' : '0', bs.bits))
    end

    if endianess == :little
        return join(map(x -> x ? '1' : '0', reverse(bs.bits)))
    end

    throw(ArgumentError("No such endianess: $endianess. Must be :big or :little"))
end

function Base.parse(::Type{BitState}, s::AbstractString)
    m = match(r"^bs([01]+)$", s)
    if !isnothing(m)
        return BitState(map(x -> parse(Bool, x), collect(m.captures[1])))
    else
        throw(ArgumentError("Invalid bit state string"))
    end
end

Base.:(==)(lhs::BitState, rhs::BitState) = lhs.bits == rhs.bits

Base.isequal(lhs::BitState, rhs::BitState) = isequal(lhs.bits, rhs.bits)

Base.hash(bs::BitState) = hash(bs.bits)

"""
    macro bs_str(s)

Convert a string into a bit state.

## Examples

```jldoctests
julia> bs"101011"
6-qubit BitState with 4 non-zero qubits:
├── |101011⟩
└── non-zero qubits: [1, 3, 5, 6]
```
"""
macro bs_str(s)
    return :(parse(BitState, "bs" * $s))
end

"""
    bits(bitstate)

Get the underlying bit array of a bit state.
"""
bits(bs::BitState) = bs.bits

# Base overrides
Base.length(bs::BitState) = length(bs.bits)
Base.keys(bs::BitState) = keys(bs.bits)
Base.size(bs::BitState) = size(bs.bits)
Base.eachindex(bs::BitState) = eachindex(bs.bits)
Base.firstindex(bs::BitState) = firstindex(bs.bits)
Base.lastindex(bs::BitState) = lastindex(bs.bits)
Base.axes(bs::BitState, d) = axes(bs.bits, d)
Base.getindex(bs::BitState, i::Integer) = bs.bits[i]
Base.getindex(bs::BitState, i) = BitState(bs.bits[i])
Base.setindex!(bs::BitState, i, val) = setindex!(bs.bits, i, val)
Base.iterate(bs::BitState) = iterate(bs.bits)
Base.iterate(bs::BitState, state) = iterate(bs.bits, state)
Base.isempty(bs::BitState) = isempty(bs.bits)
Base.trues(::Type{BitState}, nq::Integer) = BitState(trues(nq))
Base.ones(::Type{BitState}, nq::Integer) = trues(BitState, nq)
Base.falses(::Type{BitState}, nq::Integer) = BitState(falses(nq))
Base.zeros(::Type{BitState}, nq::Integer) = falses(BitState, nq)

# Bitwise operators

Base.:~(bs::BitState) = BitState(~bs.bits)

Base.:&(lhs::BitState, rhs::BitState) = BitState(lhs.bits & rhs.bits)

Base.:|(lhs::BitState, rhs::BitState) = BitState(lhs.bits | rhs.bits)

Base.:⊻(lhs::BitState, rhs::BitState) = BitState(lhs.bits ⊻ rhs.bits)

Base.:<<(bs::BitState, n::Integer) = BitState(Bool.(circshift(bs.bits, n)))

Base.:>>(bs::BitState, n::Integer) = BitState(Bool.(circshift(bs.bits, -n)))

# concatenation

Base.vcat(lhs::BitState, rhs::BitState) = BitState(vcat(lhs.bits, rhs.bits))

Base.repeat(bs::BitState, args...; kwargs...) = BitState(repeat(bs.bits, args...; kwargs...))
