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

@testset "Circuit" begin
    @variables λ

    @circuit c begin
        # basic gate
        push!(c, GateX(), 1)

        # parametric
        push!(c, GateRX(λ), 1)

        # parametric with value
        push!(c, GateRX(π / 2), 1)

        # controlled
        push!(c, GateCX(), 1, 2)
        push!(c, GateCRX(λ), 2, 1)
        push!(c, GateCRX(1.23), 2, 1)

        # power
        push!(c, GateSX(), 1)

        # inverse
        push!(c, GateSXDG(), 3)

        # controlled-inverse
        push!(c, GateCSXDG(), 121, 3)

        # powers with non-rational powers
        push!(c, Power(GateX(), 1.23), 1)
        push!(c, Power(GateSWAP(), 1.23), 1, 2)

        # multi-controlled
        push!(c, GateCCX(), 1, 2, 3)
        push!(c, GateC3X(), 1, 2, 3, 4)
        push!(c, Control(5, GateSWAP()), 1:7...)

        # non-unitary
        push!(c, Measure(), 1, 1)
        push!(c, Reset(), 121)

        # barrier
        push!(c, Barrier(3), 1, 2, 121)

        # algorithm
        push!(c, QFT(4), 1:4...)
        push!(c, PhaseGradient(4), 1:4...)
        push!(c, Diffusion(4), 1:4...)
        push!(c, PolynomialOracle(2, 2, 1, 2, 3, 4), 1:2..., 3:4...)

        # gate declaration
        decl = @gatedecl ansatz(θ) = begin
            insts = Instruction[]
            push!(insts, Instruction(GateX(), 1))
            push!(insts, Instruction(GateRX(θ), 2))
            return insts
        end

        push!(c, decl(λ), 1, 2)
    end

    fname, _ = mktemp()

    saveproto(fname, c)
    newc = loadproto(fname, Circuit)

    @test length(newc) == length(c)

    for i in 1:length(c)
        inst = c[i]
        ninst = newc[i]
        @test typeof(getoperation(inst)) == typeof(getoperation(ninst))
        @test typeof(getqubits(inst)) == typeof(getqubits(ninst))
        @test typeof(getbits(inst)) == typeof(getbits(ninst))
    end
end


