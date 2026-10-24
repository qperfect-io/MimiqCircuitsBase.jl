#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

using Test
using Symbolics
using MimiqCircuitsBase: _displaynum

@testset "_displaynum" begin
    compact = IOContext(IOBuffer(), :compact => true)
    full = IOContext(IOBuffer(), :compact => false)
    @variables θ

    # numbers that compact printing keeps exact are left alone
    @test _displaynum(compact, 0.5) == "0.5"
    @test _displaynum(compact, 1.0) == "1.0"
    @test _displaynum(compact, 0.25) == "0.25"
    @test _displaynum(compact, -0.0) == "-0.0"
    @test _displaynum(compact, 1.0e-5) == "1.0e-5"
    @test _displaynum(compact, 0.1f0) == "0.1"
    @test _displaynum(compact, 2) == "2"
    @test _displaynum(compact, -3) == "-3"
    @test _displaynum(compact, 1 // 3) == "1//3"
    @test _displaynum(compact, NaN) == "NaN"
    @test _displaynum(compact, Inf) == "Inf"
    @test _displaynum(compact, -Inf) == "-Inf"

    # shortened numbers are marked
    @test _displaynum(compact, 0.7853981633974483) == "0.785398…"
    @test _displaynum(compact, -0.7853981633974483) == "-0.785398…"
    @test _displaynum(compact, 1.23456789e-5) == "1.23457e-5…"

    # complex numbers are marked part by part
    @test _displaynum(compact, 1.0 + 2.0im) == "1.0+2.0im"
    @test _displaynum(compact, 0.123456789 + 0.5im) == "0.123457…+0.5im"
    @test _displaynum(compact, 1.0 - 0.123456789im) == "1.0-0.123457…im"
    @test _displaynum(compact, complex(1.0, NaN)) == "1.0+NaN*im"
    @test _displaynum(compact, complex(0.5, -Inf)) == "0.5-Inf*im"

    # numeric `Num`s behave like the number they hold
    @test _displaynum(compact, Num(0.5)) == "0.5"
    @test _displaynum(compact, Num(0.123456789)) == "0.123457…"
    @test _displaynum(compact, Complex{Num}(0.5, -0.25)) == "0.5 - 0.25im"
    @test _displaynum(compact, Complex{Num}(0.5, -0.123456789)) == "0.5 - 0.123457…im"
    @test _displaynum(compact, Complex{Num}(0.123456789, 0)) == "0.123457…"

    # symbolic expressions print as they always did
    @test _displaynum(compact, θ / 4) == sprint(print, θ / 4; context=compact)
    @test _displaynum(compact, π / 4 * θ) == sprint(print, π / 4 * θ; context=compact)

    # without :compact nothing is shortened, so nothing is marked
    @test _displaynum(full, 0.7853981633974483) == "0.7853981633974483"
    @test _displaynum(full, 0.123456789 + 0.5im) == "0.123456789 + 0.5im"

    # exact values print exactly as Base prints them
    for x in (0.5, -2.0, 1.0 + 0.5im, 0.25 - 1.0im, Num(3), Complex{Num}(0, 0.5))
        @test _displaynum(compact, x) == sprint(print, x; context=compact)
    end
end

@testset "Shortened numbers in listings" begin
    c = Circuit()
    push!(c, GateRX(π / 4), 1)
    push!(c, GateRX(0.5), 1)
    push!(c, Depolarizing1(0.5), 1)
    push!(c, Depolarizing1(0.0123456789), 1)
    push!(c, Power(GateX(), 0.123456789), 1)
    push!(c, Loss(0.123456789), 1)
    push!(c, Kraus([[1 0; 0 sqrt(0.9)], [0 sqrt(0.1); 0 0]]), 1)

    listing = sprint(show, MIME"text/plain"(), c)
    @test occursin("RX(π/4) @ q[1]", listing)
    @test occursin("RX(0.5) @ q[1]", listing)
    @test occursin("Depolarizing(1,0.5) @ q[1]", listing)
    @test occursin("Depolarizing(1,0.0123457…) @ q[1]", listing)
    @test occursin("X^0.123457… @ q[1]", listing)
    @test occursin("Loss(0.123457…) @ q[1]", listing)
    @test occursin("Kraus(Operator([1.0 0.0; 0.0 0.948683…]), Operator([0.0 0.316228…; 0.0 0.0])) @ q[1]", listing)

    @test repr("text/plain", RescaledGate(GateX(), 0.123456789); context=:compact => true) == "0.123457…*X"

    # full-precision output is unchanged
    @test repr(Depolarizing1(0.0123456789)) == "Depolarizing(1, 0.0123456789)"
    @test repr(Loss(0.123456789)) == "Loss(0.123456789)"

    # the drawing uses the same text, so boxes grow by the one-character mark
    drawing = mktemp() do path, f
        redirect_stdout(() -> draw(push!(Circuit(), Loss(0.123456789), 1)), f)
        flush(f)
        read(path, String)
    end
    @test occursin("┤Loss(0.123457…)├", drawing)
    @test occursin("┌" * "─"^15 * "┐", drawing)
end

@testset "draw packs independent instructions into shared columns" begin
    c = push!(Circuit(), GateH(), 1:3)
    push!(c, Measure(), 1:2, 1:2)

    drawing = mktemp() do path, f
        redirect_stdout(() -> draw(c), f)
        flush(f)
        read(path, String)
    end
    lines = split(drawing, '\n')
    column(gate) = [length(l[1:first(findfirst(gate, l))]) for l in lines if occursin(gate, l)]

    # the three H gates act on different qubits, so they share one column
    hcols = column("┤H├")
    @test length(hcols) == 3 && allequal(hcols)

    # both measurements write to c, so they are drawn one after the other
    mcols = column("┤M├")
    @test length(mcols) == 2 && !allequal(mcols)
end

@testset "draw aligns runs of one broadcast push!" begin
    c = push!(Circuit(), GateH(), 1:4)
    push!(c, GateCX(), 1:2:8, 2:2:8)

    drawing = mktemp() do path, f
        redirect_stdout(() -> draw(c), f)
        flush(f)
        read(path, String)
    end

    # one push! of CX gates is drawn as one layer, although q[5]..q[8] are free
    # in the first column
    xcols = [length(l[1:first(findfirst("┤X├", l))]) for l in split(drawing, '\n') if occursin("┤X├", l)]
    @test length(xcols) == 4 && allequal(xcols)
end

@testset "draw(c; compact=false) gives every instruction its own column" begin
    c = push!(Circuit(), GateH(), 1:3)

    drawing = mktemp() do path, f
        redirect_stdout(() -> draw(c; compact=false), f)
        flush(f)
        read(path, String)
    end

    hcols = [length(l[1:first(findfirst("┤H├", l))]) for l in split(drawing, '\n') if occursin("┤H├", l)]
    @test length(hcols) == 3 && allunique(hcols)
end
