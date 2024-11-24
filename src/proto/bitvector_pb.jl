# Autogenerated using ProtoBuf.jl v1.0.16 on 2024-10-22T20:04:05.458
# original file: /home/gdmsl/QPerfect/Code/MimiqCircuitsBase.jl/src/proto/bitvector.proto (proto3 syntax)

module bitvector_pb

import ProtoBuf as PB
using ProtoBuf: OneOf
using ProtoBuf.EnumX: @enumx

export BitVector

struct BitVector
    len::Int64
    data::Vector{UInt8}
end
PB.default_values(::Type{BitVector}) = (;len = zero(Int64), data = UInt8[])
PB.field_numbers(::Type{BitVector}) = (;len = 1, data = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:BitVector})
    len = zero(Int64)
    data = UInt8[]
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            len = PB.decode(d, Int64)
        elseif field_number == 2
            data = PB.decode(d, Vector{UInt8})
        else
            PB.skip(d, wire_type)
        end
    end
    return BitVector(len, data)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::BitVector)
    initpos = position(e.io)
    x.len != zero(Int64) && PB.encode(e, 1, x.len)
    !isempty(x.data) && PB.encode(e, 2, x.data)
    return position(e.io) - initpos
end
function PB._encoded_size(x::BitVector)
    encoded_size = 0
    x.len != zero(Int64) && (encoded_size += PB._encoded_size(x.len, 1))
    !isempty(x.data) && (encoded_size += PB._encoded_size(x.data, 2))
    return encoded_size
end
end # module