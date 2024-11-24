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
    BitString(numbits)

Representation of the state of a register of bits.
Can also represent the state of a register of qubits with defined values for
each qubit (0 or 1).

## Examples

```jldoctests
julia> BitString(16)
16-bits BitString with integer value 0:
  00000000 00000000

julia> bs = BitString(16, [1,2,3,4])
16-bits BitString with integer value 15:
  11110000 00000000

julia> bs[10] = 1
1

julia> bs
16-bits BitString with integer value 527:
  11110000 01000000

julia> bitstring_to_integer(bs)
527

julia> typeof(ans)
BigInt

julia> bitstring_to_integer(bs, Int)
527

julia> typeof(ans)
Int64
```

There are many different ways to get bit states:

```jldoctests
julia> bs = BitString(30, 2344574)
30-bits BitString with integer value 2344574:
  01111110 01100011 11000100 000000

julia> ones(BitString, 10) # or also trues(BitString, 10)
10-bits BitString with integer value 1023:
  11111111 11

julia> zeros(BitString, 10) # or also falses(BitString, 10)
10-bits BitString with integer value 0:
  00000000 00

julia> BitString(16) do i
           iseven(i)
       end
16-bits BitString with integer value 43690:
  01010101 01010101
```
"""
struct BitString
    bits::BitVector

    function BitString(bits)
        new(bits)
    end
end

BitString(nq::Integer) = BitString(zeros(Bool, nq))

BitString(nq::Integer, i::Integer) = BitString(int_to_bitarr(i, nq))

function BitString(nq::Integer, nz)
    bs = BitString(nq)
    bs.bits[nz] .= true
    return bs
end

function BitString(f::Function, nq::Integer)
    bs = BitString(BitVector(undef, nq))
    for i in 1:nq
        bs.bits[i] = f(i)
    end
    bs
end

BitString(s::String) = parse(BitString, s)

"""
    bitstring_to_integer(bitstring[, T])

Convert a bitstring into its corresponding integer.
"""
bitstring_to_integer(bs::BitString, T::Type=BigInt) = bitarr_to_int(bs.bits, T)

"""
    bitstring_to_index(bitstring)

Convert a bitstring into the corresponding index.

This is useful for indexing, for example, a vector of states.
"""
function bitstring_to_index(bs::BitString)
    int = bitarr_to_int(bs.bits, Int64)

    if !(int < typemax(Int64))
        error("System too large to be indexed by 64 bit integers")
    end

    return int + 1
end

numbits(bs::BitString) = length(bs.bits)
numqubits(bs::BitString) = numbits(bs)

"""
    nonzeros(bitstring)

Return the indices of the non-zero qubits in a bit state.
"""
nonzeros(bs::BitString) = findall(x -> x, bs.bits)

function Base.show(io::IO, bs::BitString)
    print(io, "bs\"")
    for b in bs.bits
        print(io, Int(b))
    end
    print(io, "\"")
    nothing
end

function Base.show(io::IO, ::MIME"text/plain", bs::BitString)
    # try to catch the case of an array
    if !isnothing(get(io, :typeinfo, nothing))
        return print(io, bs)
    end

    n = length(bs)
    rows, cols = displaysize()
    tab = "  "
    arows = rows - 3
    acols = cols - 2
    print(io, "$(n)-bits $(typeof(bs)) with integer value $(bitstring_to_integer(bs))")
    n8 = ceil(Int, n / 8)
    if acols - n8 >= n
        println(io, ":")
        print(io, "  ")
        for i in 1:n8-1
            for j in 1:8
                print(io, Int(bs[(i-1)*8+j]))
            end
            print(io, " ")
        end
        for j in 1:8
            index = (n8 - 1) * 8 + j
            if index > n
                break
            end
            print(io, Int(bs[index]))
        end
        print(io, "\n")

    elseif arows > 4
        println(io, ":")
        if arows >= n8
            for i in 1:n8-1
                print(io, tab)
                for j in 1:8
                    print(io, Int(bs[(i-1)*8+j]))
                end
                print(io, '\n')
            end
            print(io, tab)
            for j in 1:8
                index = (n8 - 1) * 8 + j
                if index > n
                    break
                end
                print(io, Int(bs[index]))
            end
        else
            aarows = div(arows, 2) - 1

            for i in 1:aarows
                print(io, tab)
                for j in 1:8
                    print(io, Int(bs[(i-1)*8+j]))
                end
                print(io, '\n')
            end

            println(io, tab, "...")

            for i in (n8-aarows+1):n8-1
                print(io, tab)
                for j in 1:8
                    print(io, Int(bs[(i-1)*8+j]))
                end
                print(io, '\n')
            end
            print(io, tab)
            for j in 1:8
                index = (n8 - 1) * 8 + j
                if index > n
                    break
                end
                print(io, Int(bs[index]))
            end
        end
    end

    nothing
end

Base.string(bs::BitString) = "bs" * join(map(x -> x ? '1' : '0', bs.bits))

"""
    to01(bitstring[, endianess=:big])

Converts a BitString into a string of 0 and 1 characters.
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
function to01(bs::BitString; endianess::Symbol=:big)
    if endianess == :big
        return join(map(x -> x ? '1' : '0', bs.bits))
    end

    if endianess == :little
        return join(map(x -> x ? '1' : '0', reverse(bs.bits)))
    end

    throw(ArgumentError("No such endianess: $endianess. Must be :big or :little"))
end

function Base.parse(::Type{BitString}, s::AbstractString)
    m = match(r"^(?:bs)?([01]+)$", s)
    if !isnothing(m)
        return BitString(map(x -> parse(Bool, x), collect(m.captures[1])))
    else
        throw(ArgumentError("Invalid bit state string: expected 'bs' prefix or plain binary string"))
    end
end

Base.:(==)(lhs::BitString, rhs::BitString) = lhs.bits == rhs.bits

Base.isequal(lhs::BitString, rhs::BitString) = isequal(lhs.bits, rhs.bits)

Base.hash(bs::BitString) = hash(bs.bits)

"""
    macro bs_str(s)

Convert a string into a bit state.

## Examples

```jldoctests
julia> bs"101011"
6-bits BitString with integer value 53:
  101011
```
"""
macro bs_str(s)
    return :(parse(BitString, $s))
end

"""
    tobits(bitstring)

Get the underlying BitVector of a bit state.
"""
tobits(bs::BitString) = bs.bits

# Base overrides
Base.length(bs::BitString) = length(bs.bits)
Base.keys(bs::BitString) = keys(bs.bits)
Base.size(bs::BitString) = size(bs.bits)
Base.eachindex(bs::BitString) = eachindex(bs.bits)
Base.firstindex(bs::BitString) = firstindex(bs.bits)
Base.lastindex(bs::BitString) = lastindex(bs.bits)
Base.axes(bs::BitString, d) = axes(bs.bits, d)
Base.getindex(bs::BitString, i::Integer) = bs.bits[i]
Base.getindex(bs::BitString, i) = BitString(bs.bits[i])
Base.setindex!(bs::BitString, i, val) = setindex!(bs.bits, i, val)
Base.iterate(bs::BitString) = iterate(bs.bits)
Base.iterate(bs::BitString, state) = iterate(bs.bits, state)
Base.isempty(bs::BitString) = isempty(bs.bits)
Base.trues(::Type{BitString}, nq::Integer) = BitString(trues(nq))
Base.ones(::Type{BitString}, nq::Integer) = trues(BitString, nq)
Base.falses(::Type{BitString}, nq::Integer) = BitString(falses(nq))
Base.zeros(::Type{BitString}, nq::Integer) = falses(BitString, nq)

# Bitwise operators

Base.:~(bs::BitString) = BitString(map(b -> !b, bs.bits))

Base.:&(lhs::BitString, rhs::BitString) = BitString(lhs.bits .& rhs.bits)

Base.:|(lhs::BitString, rhs::BitString) = BitString(lhs.bits .| rhs.bits)

Base.:⊻(lhs::BitString, rhs::BitString) = BitString(lhs.bits .⊻ rhs.bits)

Base.:<<(bs::BitString, n::Integer) = BitString(Bool.(circshift(bs.bits, -n)))

Base.:>>(bs::BitString, n::Integer) = BitString(Bool.(circshift(bs.bits, n)))

# concatenation

Base.vcat(lhs::BitString, rhs::BitString) = BitString(vcat(lhs.bits, rhs.bits))

Base.repeat(bs::BitString, args...; kwargs...) = BitString(repeat(bs.bits, args...; kwargs...))

Base.convert(::Type{BitString}, bs::BitVector) = BitString(bs)
