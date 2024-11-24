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
using Test

@testset "PauliString gate" begin
    @test isdefined(MimiqCircuitsBase, :PauliString)

    # N=1
    pstrings = ["I", "X", "Y", "Z"]
    pmats = matrix.([GateID(), GateX(), GateY(), GateZ()])
    for k in eachindex(pstrings)
        @test matrix(PauliString(pstrings[k])) == pmats[k]
    end

    # N=2
    pstrings2 = [join([s1, s2]) for s1 in pstrings, s2 in pstrings]
    pmats2 = [kron(M1, M2) for M1 in pmats, M2 in pmats]
    for k in eachindex(pstrings2)
        @test matrix(PauliString(pstrings2[k])) == pmats2[k]
    end

    # N=4
    @test matrix(PauliString("IXYZ")) == reduce(kron, pmats)

    # Inverse
    for k in eachindex(pstrings)
        @test inverse(PauliString(pstrings[k])) == PauliString(pstrings[k])
    end
    for k in eachindex(pstrings2)
        @test inverse(PauliString(pstrings2[k])) == PauliString(pstrings2[k])
    end

    # Decompose
    pauli = PauliString("IXYZ")
    dec = decompose(pauli)

    c = Circuit()
    push!(c, GateID(), 1)
    push!(c, GateX(), 2)
    push!(c, GateY(), 3)
    push!(c, GateZ(), 4)

    @test all(c .== dec)

    # Wrong Pauli strings
    @test_throws "Pauli string can only contain I, X, Y, or Z" PauliString("IXXYZA")
end

