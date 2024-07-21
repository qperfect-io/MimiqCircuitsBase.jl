"""
    saveproto(fname, c::Circuit)
    saveproto(fname, c::QCSResults)
    loadproto(fname, ::typeof(Circuit))
    loadproto(fname, ::typeof(QCSResults))

Save and load a quantum circuit or QCSResults to/from a protocol buffer file.

## saveproto

The `saveproto` function saves a given object, such as a `Circuit` or `QCSResults`, to a protocol buffer file.


## loadproto

The `loadproto` function loads a specified type of object from a protocol buffer file.

## Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, GateX(), 1)
1-qubit circuit with 1 instructions:
└── X @ q[1]

julia> push!(c, GateXXplusYY(1.0, 4), 1, 2:5)
5-qubit circuit with 5 instructions:
├── X @ q[1]
├── XXplusYY(1.0, 4) @ q[1:2]
├── XXplusYY(1.0, 4) @ q[1,3]
├── XXplusYY(1.0, 4) @ q[1,4]
└── XXplusYY(1.0, 4) @ q[1,5]

julia> mktemp() do path, io
           saveproto(path, c)
           println( saveproto(path, c))
           loaded_circuit = loadproto(path, Circuit)
           println(loaded_circuit)
       end
135
5-qubit circuit with 5 instructions:
├── X @ q[1]
├── XXplusYY(1.0, 4) @ q[1:2]
├── XXplusYY(1.0, 4) @ q[1,3]
├── XXplusYY(1.0, 4) @ q[1,4]
└── XXplusYY(1.0, 4) @ q[1,5]
```

!!! note
    This example uses a temporary file to demonstrate the save and load functionality.
    You can save your file with any name at any location using:

        saveproto("example.pb", c)

        loadproto("example.pb", typeof(c))
"""
function saveproto(fname, c::Circuit)
    iobuffer = IOBuffer()
    e = ProtoEncoder(iobuffer)
    encode(e, toproto(c))

    open(fname, "w") do io
        write(io, take!(iobuffer))
    end
end

"""

See [`saveproto`](@ref), for the Examples

"""
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
