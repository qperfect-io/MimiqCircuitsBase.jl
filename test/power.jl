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

@testset "GateU" begin
    rng = MersenneTwister(1234)

    for _ in 1:100
        pwr = 100 * (rand() - 0.4)
        g = GateU(rand() * 4π, rand() * 2π, rand() * 2π, rand() * 2π)

        @test matrix(g)^pwr ≈ matrix(power(g, pwr))
    end

    # Diagonal GateU (θ = 0): the phase lives in λ, which used to be dropped when
    # sin(θ/2) ≈ 0, so power returned the identity. Regression for the Shor
    # modular-arithmetic decomposition bug (√ of GateU(0,0,π,0) must be
    # GateU(0,0,π/2,0), not the identity).
    for g in (
        GateU(0, 0, π, 0),
        GateU(0, 0, π / 2, 0),
        GateU(0, 0, 2π / 3, 0),
        GateU(0, π / 5, π / 7, 0),
    )
        for pwr in (1 // 2, 1 // 3, -1 // 2, 2, 0.37)
            @test matrix(g)^pwr ≈ matrix(power(g, pwr))
        end
    end
end
