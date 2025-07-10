#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
    saveproto(fname, h::Hamiltonian)

Serialize a `Circuit`, a `QCSResults`, or a `Hamiltonian`, object to a
ProtoBuf file.
"""
function saveproto end

"""
    loadproto(fname, Circuit)
    loadproto(fname, QCSResults)

Deserialize a `Circuit`, a `QCSResults`, or a `Hamiltonian` object from a
ProtoBuf file.
"""
function loadproto end

for (T, PT) in [(Circuit, circuit_pb.Circuit), (QCSResults, qcsresults_pb.QCSResults), (Hamiltonian, hamiltonian_pb.Hamiltonian)]
    eval(quote
        function saveproto(io::IO, c::$T)
            iobuffer = IOBuffer()
            e = ProtoEncoder(iobuffer)
            encode(e, toproto(c))
            write(io, take!(iobuffer))
        end
        function loadproto(io::IO, ::Type{$T})
            d = ProtoDecoder(io)
            proto = decode(d, $(PT))
            return fromproto(proto)
        end
    end)
end

function saveproto(fname, c)
    open(fname, "w") do io
        saveproto(io, c)
    end
end

function loadproto(fname, T::Type)
    open(fname, "r") do io
        loadproto(io, T)
    end
end
