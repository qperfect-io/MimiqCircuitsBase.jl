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

using Test

@testset "RPauli Gate" begin
    # 1-qubit Pauli rotations
    pstrings = ["I", "X", "Y", "Z"]
    par = π
    for ps in pstrings
        g = RPauli(ps, par)
        @test size(matrix(g)) == (2, 2)
        @test matrix(g) ≈ exp(-0.5im * par * matrix(PauliString(ps)))
    end

    # 2-qubit Pauli rotations
    pstrings2 = ["XX", "YY", "ZZ", "XY", "YX", "IZ", "ZI"]
    for ps in pstrings2
        g = RPauli(ps, 2)
        @test size(matrix(g)) == (4, 4)
        @test matrix(g) ≈ exp(-1im * matrix(PauliString(ps)))
    end

    # 4-qubit check
    ps4 = pauli"IXYZ"
    g4 = RPauli(ps4, 1)
    @test size(matrix(g4)) == (16, 16)
    @test matrix(g4) ≈ exp(-0.5im * matrix(ps4))

    # Identity rotation
    gid = RPauli(pauli"III", 0.1234)
    @test matrix(gid) ≈ exp(-im * 0.1234 / 2) * Matrix(I, (8, 8))

    # Inverse: matrix(g)^dagger ≈ matrix(RPauli(s, -param))
    s = pauli"XYZ"
    g = RPauli(s, par)
    invg = RPauli(s, -par)
    @test matrix(g)' ≈ matrix(invg)

    # Decompose
    p = "IXYZ"
    g = RPauli(p, π)
    c = decompose_step(g)

    cmanual = Circuit()
    push!(cmanual, GateH(), 2)
    push!(cmanual, GateHYZ(), 3)
    push!(cmanual, GateRNZ(3, π), 2, 3, 4)
    push!(cmanual, GateHYZ(), 3)
    push!(cmanual, GateH(), 2)

    @test length(c) == length(cmanual)
    @test length(c) > 0
    @test eltype(c) == Instruction

    # Error on invalid Pauli string
    @test_throws ArgumentError RPauli("IXYZK", π)
end
