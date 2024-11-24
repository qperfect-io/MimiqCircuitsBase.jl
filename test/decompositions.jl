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
using MimiqCircuitsBase

@testset "1q decomposition" begin
    GATES1Q = filter(gtype -> gtype <: AbstractGate{1}, MimiqCircuitsBase.GATES)
    @testset "$(opname(gtype)) decomposition" for gtype in GATES1Q
        gate = gtype(rand(numparams(gtype))...)

        M = mapreduce(*, reverse(decompose(gate)._instructions)) do g
            matrix(getoperation(g))
        end

        @test matrix(gate) ≈ M
    end
end

@testset "2q decomposition" begin
    GATES2Q = filter(gtype -> gtype <: AbstractGate{2}, MimiqCircuitsBase.GATES)

    @testset "$(opname(gtype)) decomposition" for gtype in GATES2Q
        gate = gtype(rand(numparams(gtype))...)

        M = mapreduce(*, reverse(decompose(gate)._instructions)) do g
            if numqubits(g) == 1
                target = getqubit(g, 1)
                if target == 1
                    return kron(matrix(getoperation(g)), Matrix(I, 2, 2))
                end

                if target == 2
                    return kron(Matrix(I, 2, 2), matrix(getoperation(g)))
                end

                error("Invalid target qubit for gate $g.")
            end

            if numqubits(g) == 2
                if getqubits(g) == (1, 2)
                    return matrix(getoperation(g))
                end

                if getqubits(g) == (2, 1)
                    return matrix(GateSWAP()) * matrix(getoperation(g)) * matrix(GateSWAP())
                end

                error("Invalid qubits for gate $g.")
            end

            error("Invalid number of qubits for gate $g.")
        end

        @test matrix(gate) ≈ M
    end
end

@testset "Circuit decomposition" begin
    @testset "$(opname(gtype))" for gtype in MimiqCircuitsBase.GATES
        gate = gtype(rand(numparams(gtype))...)
        circ = push!(Circuit(), gate, 1:numqubits(gate)..., 1:numbits(gate)...)

        decomposed = decompose(circ)

        @test length(decomposed) >= length(circ)

        for inst in decomposed
            @test MimiqCircuitsBase.issupported_default(getoperation(inst))
        end
    end
end
