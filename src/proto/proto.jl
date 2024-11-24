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
    saveproto(fname, c::Circuit)
    saveproto(fname, c::QCSResults)

Serialize a `Circuit` or a `QCSResults` object to a ProtoBuf file.
"""
function saveproto end

function saveproto(fname, c::Circuit)
    iobuffer = IOBuffer()
    e = ProtoEncoder(iobuffer)
    encode(e, toproto(c))

    open(fname, "w") do io
        write(io, take!(iobuffer))
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

"""
    loadproto(fname, Circuit)
    loadproto(fname, QCSResults)

Deserialize a `Circuit` or a `QCSResults` object from a ProtoBuf file.
"""
function loadproto end

function loadproto(fname, ::Type{Circuit})
    open(fname, "r") do io
        d = ProtoDecoder(io)
        proto = decode(d, circuit_pb.Circuit)
        return fromproto(proto)
    end
end

function loadproto(fname, ::Type{QCSResults})
    open(fname, "r") do io
        d = ProtoDecoder(io)
        proto = decode(d, qcsresults_pb.QCSResults)
        return fromproto(proto)
    end
end
