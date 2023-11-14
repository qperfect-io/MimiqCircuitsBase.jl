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

function toproto(s::QCSResults)
    return qcsresults_pb.QCSResults(
        s.simulator,
        s.version,
        s.fidelities,
        s.avggateerrors,
        toproto.(s.cstates),
        toproto.(s.zstates),
        toproto(s.amplitudes),
        s.timings,
    )
end

function toproto(v::Vector{ComplexF64})
    return qcsresults_pb.ComplexVector(toproto.(v))
end

function toproto(v::ComplexF64)
    return qcsresults_pb.ComplexDouble(real(v), imag(v))
end

function toproto(bv::BitVector)
    return qcsresults_pb.BitVector(length(bv), bitarr_to_bytes(bv))
end

function toproto(amplitudes::Dict{BitState,ComplexF64})
    return map(collect(amplitudes)) do (k, v)
        qcsresults_pb.AmplitudeEntry(toproto(k.bits), toproto(v))
    end
end

function fromproto(s::qcsresults_pb.QCSResults)
    return QCSResults(
        s.simulator,
        s.version,
        s.fidelities,
        s.avggateerrors,
        fromproto.(s.cstates),
        fromproto.(s.zstates),
        fromproto(s.amplitudes),
        s.timings,
    )
end

function fromproto(v::qcsresults_pb.ComplexVector)
    return fromproto.(v.data)
end

function fromproto(v::qcsresults_pb.ComplexDouble)
    return ComplexF64(v.real, v.imag)
end

function fromproto(bv::qcsresults_pb.BitVector)
    return bytes_to_bitarr(bv.data, bv.len)
end

function fromproto(amplitudes::Vector{qcsresults_pb.AmplitudeEntry})
    d = Dict{BitState,ComplexF64}()
    for ae in amplitudes
        k, v = ae.key, ae.val
        d[BitState(fromproto(k))] = fromproto(v)
    end
    return d
end
