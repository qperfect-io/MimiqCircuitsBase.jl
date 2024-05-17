function saveproto(fname, c::Circuit)
    iobuffer = IOBuffer()
    e = ProtoEncoder(iobuffer)
    encode(e, toproto(c))

    open(fname, "w") do io
        write(io, take!(iobuffer))
    end
end

function loadproto(fname, ::Type{Circuit})
    open(fname, "r") do io
        d = ProtoDecoder(io)
        proto = decode(d, circuit_pb.Circuit)
        return fromproto(proto)
    end
end

function saveproto(fname, c::QCSResults)
    iobuffer = IOBuffer()
    e = ProtoEncoder(iobuffer)
    encode(e, toproto(c))

    open(fname, "w") do io
        write(io, take!(iobuffer))
    end
end

function loadproto(fname, ::Type{QCSResults})
    open(fname, "r") do io
        d = ProtoDecoder(io)
        proto = decode(d, qcsresults_pb.QCSResults)
        return fromproto(proto)
    end
end
