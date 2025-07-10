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


@testset "listvars vs getparams" begin
    # Flatten nested parameters
    function flattenparams(p)
        out = Any[]
        for x in p
            if x isa Tuple || x isa AbstractVector
                append!(out, flattenparams(x))
            else
                push!(out, x)
            end
        end
        return out
    end

    # Test for symbolic inclusion safely
    contains_param(p, params) = any(q -> Symbolics.isequal(p, q), params)

    @testset "Symbolic only" begin
        @variables x y
        c = Circuit()
        push!(c, GateXXplusYY(x, y), 1, 2)

        flat = flattenparams(getparams(c))
        vars = listvars(c)

        @test Set(vars) == Set(flat)
        @test all(v -> contains_param(v, flat), [x, y])
    end

    @testset "Symbolic and numeric" begin
        @variables x y z
        c = Circuit()
        push!(c, GateXXplusYY(x, y + 2), 1, 2)
        push!(c, GateRX(1.0), 1)
        push!(c, GateRY(z), 2)

        flat = flattenparams(getparams(c))
        vars = listvars(c)

        @test Set(vars) == Set([x, y, z])
        @test all(v -> contains_param(v, flat), [x, y + 2, z])
        @test any(q -> Symbolics.isequal(q, 1.0), flat)
        @test all(p -> !Symbolics.isequal(p, 1.0), vars)
        @test Set(vars) != Set(flat)
    end
end

