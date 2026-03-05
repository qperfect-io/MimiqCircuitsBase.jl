#
# Copyright © 2025-2026 QPerfect. All Rights Reserved.
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

# ============================== #
# REAL-WORLD WORKFLOW BENCHMARKS #
# ============================== #

SUITE["workflows"] = BenchmarkGroup(["Benchmarks for realistic workflows"])

# VQE-like workflow
SUITE["workflows"]["vqe_setup_4q2l"] = @benchmarkable begin
    c = Circuit()
    # Ansatz
    for q in 1:4
        push!(c, GateRY(0.5), q)
        push!(c, GateRZ(0.3), q)
    end
    for q in 1:3
        push!(c, GateCX(), q, q + 1)
    end
    for q in 1:4
        push!(c, GateRY(0.2), q)
        push!(c, GateRZ(0.1), q)
    end
    push!(c, Measure(), 1:4, 1:4)
    c
end

# QFT + inverse roundtrip
for n in [4, 8, 12]
    SUITE["workflows"]["qft_roundtrip_$n"] = @benchmarkable begin
        c = Circuit()
        push!(c, QFT($n), 1:$n...)
        push!(c, inverse(QFT($n)), 1:$n...)
        decompose(c)
    end
end

# Noisy GHZ
SUITE["workflows"]["noisy_ghz_10"] = @benchmarkable begin
    c = ghz_circuit(10)
    push!(c, Measure(), 1:10, 1:10)
    nm = NoiseModel([
        GateInstanceNoise(GateH(), Depolarizing1(0.001)),
        GateInstanceNoise(GateCX(), Depolarizing2(0.01)),
    ])
    apply_noise_model(c, nm)
end

# Build + decompose + depth
SUITE["workflows"]["build_decompose_depth"] = @benchmarkable begin
    c = qft_circuit(8)
    cd = decompose(c)
    d = depth(cd)
    (cd, d)
end

# Quantum Volume circuit
for n in [4, 6, 8]
    SUITE["workflows"]["qv_$(n)x$n"] = @benchmarkable qv_circuit($n, depth=$n)
end
