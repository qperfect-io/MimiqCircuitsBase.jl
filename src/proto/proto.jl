function saveproto(fname, c::Circuit)
    open(fname, "w") do io
        e = ProtoEncoder(io)
        return encode(e, toproto(c))
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
    open(fname, "w") do io
        e = ProtoEncoder(io)
        return encode(e, toproto(c))
    end
end

function loadproto(fname, ::Type{QCSResults})
    open(fname, "r") do io
        d = ProtoDecoder(io)
        proto = decode(d, qcsresults_pb.QCSResults)
        return fromproto(proto)
    end
end
