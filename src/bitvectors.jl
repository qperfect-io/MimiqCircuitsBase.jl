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

function _helper_bitarr_to_int(arr, ::Type{T}) where {T<:Integer}
    res = zero(T)
    v = one(T)
    for i in eachindex(arr)
        res += v * arr[i]
        v <<= 1
    end
    return res
end

function bitarr_to_int(arr, ::Type{T}) where {T<:Integer}
    # take into account the sign bit (since we just want positive numbers)
    sbit = T <: Unsigned ? 0 : 1
    if length(arr) > sizeof(T) * 8 - sbit
        error("Input array is too long")
    end

    _helper_bitarr_to_int(arr, T)
end

function bitarr_to_int(arr, ::Type{T}) where {T<:BigInt}
    _helper_bitarr_to_int(arr, T)
end

function int_to_bitarr(x::Integer, pad)
    bv = BitVector(undef, pad)
    ax = abs(x)
    for i in Base.OneTo(pad)
        bv[i] = (ax >> (i - 1)) & 1
    end
    return bv
end

function bitarr_to_bytes(bv::BitVector)
    b = UInt8[]
    for i in 1:8:length(bv)
        val = zero(UInt8)
        for j in 0:7
            if i + j > length(bv)
                break
            end
            val += bv[i+j] << j
        end
        push!(b, val)
    end
    return b
end

function bytes_to_bitarr(b::Vector{UInt8})
    bv = BitVector()
    for val in b
        for i in 0:7
            push!(bv, (val >> i) & 1)
        end
    end
    return bv
end

bytes_to_bitarr(b::Vector{UInt8}, n::Int) = bytes_to_bitarr(b)[1:n]
