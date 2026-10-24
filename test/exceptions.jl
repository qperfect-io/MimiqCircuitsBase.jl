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

using MimiqCircuitsBase
using Test
using Symbolics

using MimiqCircuitsBase: OperationError, UndefinedValue, DecompositionError

@testset "OperationError" begin
    @test_throws OperationError QFT(0)
    e = try
        QFT(0)
    catch err
        err
    end
    @test sprint(showerror, e) == "QFT: Number of qubits must be ≥ 1."
end

@testset "UndefinedValue" begin
    @variables θ
    @test_throws UndefinedValue MimiqCircuitsBase.unwrappedprobabilities(PauliX(θ))
    @test sprint(showerror, UndefinedValue(θ)) == "Undefined value θ."
end

@testset "DecompositionError" begin
    c = push!(Circuit(), AmplitudeDamping(0.1), 1)
    @test_throws DecompositionError decompose(c; basis=QASMBasis())
    @test sprint(showerror, DecompositionError("bad")) == "Error during decomposition: bad"
end
