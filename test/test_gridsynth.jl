#
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

using Test
using MimiqCircuitsBase
using LinearAlgebra
using Random
using Symbolics

# Errors down to 1e-15 over ~150 gates cannot be checked with Float64 gate
# matrices, so the words are multiplied out in BigFloat.
function _gs_bigmatrix(op)
    s = inv(sqrt(big(2)))
    op isa GateH && return Complex{BigFloat}[s s; s -s]
    op isa GateT && return Complex{BigFloat}[1 0; 0 cis(big(π) / 4)]
    op isa GateS && return Complex{BigFloat}[1 0; 0 im]
    op isa GateSDG && return Complex{BigFloat}[1 0; 0 -im]
    op isa GateZ && return Complex{BigFloat}[1 0; 0 -1]
    op isa GateX && return Complex{BigFloat}[0 1; 1 0]
    error("unexpected gate $op")
end

function _gs_circuit_matrix(c::Circuit)
    U = Matrix{Complex{BigFloat}}(I, 2, 2)
    for inst in c
        U = _gs_bigmatrix(getoperation(inst)) * U
    end
    return U
end

# min_φ ‖U − e^{iφ}V‖ in operator norm. For unitaries the optimal phase is the
# argument of tr(V'U); the 2×2 largest singular value has a closed form.
function _gs_phase_distance(U::AbstractMatrix, V::AbstractMatrix)
    φ = angle(tr(V' * U))
    D = U - cis(φ) * V
    size(D) == (2, 2) || return opnorm(D)
    f = sum(abs2, D)
    d = abs2(D[1, 1] * D[2, 2] - D[1, 2] * D[2, 1])
    return sqrt((f + sqrt(max(f^2 - 4d, zero(f)))) / 2)
end

function _gs_error(λ::Float64, c::Circuit)
    return setprecision(BigFloat, 256) do
        θ = big(λ)
        V = Complex{BigFloat}[cis(-θ / 2) 0; 0 cis(θ / 2)]
        Float64(_gs_phase_distance(_gs_circuit_matrix(c), V))
    end
end

_gs_tcount(c) = count(inst -> getoperation(inst) isa Union{GateT,GateTDG}, c)

const _GS_OUTPUT_TYPES = Union{GateH,GateS,GateSDG,GateZ,GateT,GateX}

@testset "GridSynthRewrite" begin
    @testset "constructor" begin
        @test GridSynthRewrite().epsilon == 1e-10
        @test GridSynthRewrite(epsilon=1e-3).epsilon == 1e-3
        @test_throws ArgumentError GridSynthRewrite(epsilon=0)
        @test_throws ArgumentError GridSynthRewrite(epsilon=1)
        @test_throws ArgumentError GridSynthRewrite(epsilon=-1e-3)
        @test_throws ArgumentError GridSynthRewrite(epsilon=NaN)
        @test GridSynthRewrite(epsilon=1e-100).epsilon == 1e-100
        @test_throws ArgumentError GridSynthRewrite(epsilon=9e-101)
        @test_throws ArgumentError GridSynthRewrite(epsilon=5e-324)
        @test GridSynthRewrite(seed=typemax(UInt64)).seed == typemax(UInt64)
        @test_throws ArgumentError GridSynthRewrite(seed=-1)
        @test_throws ArgumentError GridSynthRewrite(seed=big(2)^64)
        @test_throws TypeError GridSynthRewrite(seed=1.7)
    end

    @testset "non-finite angles" begin
        for λ in (NaN, Inf, -Inf)
            @test_throws ArgumentError decompose_step(GateRZ(λ); rule=GridSynthRewrite())
            @test_throws ArgumentError decompose(GateRZ(λ); basis=CliffordTBasis())
        end
    end

    @testset "matches" begin
        rule = GridSynthRewrite()
        @variables θ
        @test matches(rule, GateRZ(0.123))
        @test matches(rule, GateRZ(π))
        @test !matches(rule, GateRZ(θ))
        @test !matches(rule, GateRX(0.1))
        @test !matches(rule, GateRY(0.1))
        @test !matches(rule, GateU(0.1, 0.2, 0.3))
        @test !matches(rule, GateH())
        @test !matches(rule, GateCX())
    end

    @testset "error bound and gate set" begin
        rng = MersenneTwister(1234)
        for ε in (1e-2, 1e-4, 1e-6, 1e-8, 1e-10, 1e-12, 1e-15)
            rule = GridSynthRewrite(epsilon=ε)
            for _ in 1:5
                λ = 4π * (rand(rng) - 0.5)
                c = decompose_step(GateRZ(λ); rule=rule)
                @test _gs_error(λ, c) <= ε
                @test all(inst -> getoperation(inst) isa _GS_OUTPUT_TYPES, c)
                @test all(inst -> getqubits(inst) == (1,), c)
            end
        end
    end

    @testset "large angles" begin
        rule = GridSynthRewrite(epsilon=1e-8)
        for λ in (100.0, -57.3, 1e3)
            @test _gs_error(λ, decompose_step(GateRZ(λ); rule=rule)) <= 1e-8
        end
    end

    @testset "exact angles k·π/4" begin
        rule = GridSynthRewrite(epsilon=1e-10)
        for k in -8:8
            λ = k * π / 4
            c = decompose_step(GateRZ(λ); rule=rule)
            @test _gs_tcount(c) == (isodd(k) ? 1 : 0)
            @test length(c) <= 2
            @test _gs_error(λ, c) <= 1e-10
        end
        @test isempty(decompose_step(GateRZ(0.0); rule=rule))
    end

    @testset "T-count matches pygridsynth" begin
        # T-counts from pygridsynth 1.2.0 (up_to_phase=True) for the same
        # Float64 angles and tolerances.
        reference = [
            (0.1, 1e-3, 35), (1.2345, 1e-3, 33), (3.0, 1e-3, 32), (-2.5, 1e-3, 31),
            (0.1, 1e-5, 55), (2.0, 1e-5, 50), (0.001, 1e-5, 53), (-2.5, 1e-5, 54),
            (0.5, 1e-10, 102), (1.0, 1e-10, 105), (2.0, 1e-10, 101), (-0.7, 1e-10, 105),
            (0.1, 1e-15, 151), (1.0, 1e-15, 150), (1.2345, 1e-15, 155), (3.0, 1e-15, 153),
        ]
        for (λ, ε, expected) in reference
            c = decompose_step(GateRZ(λ); rule=GridSynthRewrite(epsilon=ε))
            @test _gs_tcount(c) == expected
        end
    end

    @testset "T-count scales as 3·log2(1/ε)" begin
        for ε in (1e-4, 1e-8, 1e-12)
            c = decompose_step(GateRZ(0.7); rule=GridSynthRewrite(epsilon=ε))
            @test abs(_gs_tcount(c) - 3 * log2(1 / ε)) <= 12
        end
    end

    @testset "deterministic" begin
        rule = GridSynthRewrite(epsilon=1e-9)
        c1 = decompose_step(GateRZ(0.4321); rule=rule)
        empty!(MimiqCircuitsBase._GRIDSYNTH_CACHE)
        c2 = decompose_step(GateRZ(0.4321); rule=rule)
        @test c1 == c2

        c3 = decompose_step(GateRZ(0.4321); rule=GridSynthRewrite(epsilon=1e-9, seed=7))
        @test _gs_error(0.4321, c3) <= 1e-9
    end

    # Before Julia 1.12 setprecision sets the global BigFloat precision, so
    # concurrent syntheses at different tolerances must not interfere.
    @testset "threads" begin
        jobs = [(λ, ε) for λ in (0.1, 0.7, 1.3, 2.9) for ε in (1e-3, 1e-10, 1e-30)]
        serial = [decompose_step(GateRZ(λ); rule=GridSynthRewrite(epsilon=ε)) for (λ, ε) in jobs]
        empty!(MimiqCircuitsBase._GRIDSYNTH_CACHE)
        tasks = [Threads.@spawn decompose_step(GateRZ(λ); rule=GridSynthRewrite(epsilon=ε))
                 for (λ, ε) in jobs]
        @test fetch.(tasks) == serial
    end

    @testset "target qubit" begin
        c = Circuit()
        decompose_step!(c, GridSynthRewrite(epsilon=1e-3), GateRZ(0.3), (4,), (), ())
        @test !isempty(c)
        @test all(inst -> getqubits(inst) == (4,), c)
    end
end
