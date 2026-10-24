#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
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

using MimiqCircuitsBase: toproto, fromproto, circuit_pb
using ProtoBuf: ProtoEncoder, ProtoDecoder, encode, decode

function _argbytes(x)
    io = IOBuffer()
    encode(ProtoEncoder(io), toproto(x))
    return bytes2hex(take!(io))
end

_argfromhex(h) = fromproto(decode(ProtoDecoder(IOBuffer(hex2bytes(h))), circuit_pb.Arg))

function _roundtrip(c)
    io = IOBuffer()
    encode(ProtoEncoder(io), toproto(c))
    seekstart(io)
    return fromproto(decode(ProtoDecoder(io), circuit_pb.Circuit))
end

@testset "Exact symbolic arguments" begin
    @variables x
    P = Num(π)

    @testset "round trip $(e)" for e in (
        P / 4, -P / 4, 2P / 3, P / 2, 3P / 2, 7P / 8, P, P^2, x * P / 4, x / 2 + P / 3,
        Num(ℯ) / 2, (1 // 4) * P, 0.5P, Num(1 // 4), Num(0.5), Num(3), x, -x,
    )
        c = push!(Circuit(), GateRX(e), 1)
        @test _roundtrip(c) == c
    end

    @testset "plain numbers stay plain" begin
        @test toproto(Num(0.5)).arg.name == :argvalue_value
        @test toproto(Num(3)).arg.name == :argvalue_value
    end

    # The same vectors are pinned in the Python test suite
    # (tests/test_proto_symbolic.py): both languages must write these bytes and
    # read them back to the expression.
    vectors = [
        (P / 4, "1a0c08021202200012040a020804"),
        (-P / 4, "1a21080112191a170802120d0a0b08ffffffffffffffffff0112040a02080412022000"),
        (2P / 3, "1a18080112101a0e080212040a02080212040a02080312022000"),
        (7P / 8, "1a18080112101a0e080212040a02080712040a02080812022000"),
        (x * P / 4, "1a1f0801120512030a017812101a0e080212040a02080112040a02080412022000"),
        (
            x / 2 + P / 3,
            "1a23120e1a0c08021202200012040a02080312111a0f0802120512030a017812040a020802",
        ),
        (Num(1 // 4), "1a0e080212040a02080112040a020804"),
        (Num(0.5), "0a0911000000000000e03f"),
        (Num(3), "0a020803"),
    ]
    @testset "byte vector $(e)" for (e, h) in vectors
        @test _argbytes(e) == h
        @test isequal(_argfromhex(h), e)
    end

    @testset "older payloads" begin
        # `MUL(0.25, PI)`, written by earlier Python encoders.
        v = _argfromhex("1a130801120b0a0911000000000000d03f12022000")
        @test Symbolics.value(Symbolics.symbolic_to_float(v)) ≈ π / 4
        # A plain double, written by earlier Julia encoders.
        @test isequal(_argfromhex("0a0911182d4454fb21e93f"), Num(π / 4))
    end
end
