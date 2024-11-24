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
using Random

MIXEDUNITARYCHANNELS = AbstractKrausChannel[]
KRAUSCHANNELS = AbstractKrausChannel[]

# Custom 1 qubit MixedUnitary
p = 0.4
U1 = [1 0; 0 1]
U2 = [1 0; 0 -1]
push!(MIXEDUNITARYCHANNELS, MixedUnitary([1 - p, p], [U1, U2]))

# Custom 2 qubit MixedUnitary
ps = [0.2, 0.3, 0.3, 0.2]
U1 = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1]
U2 = [1 0 0 0; 0 1 0 0; 0 0 -1 0; 0 0 0 -1]
U3 = [0 0 1 0; 0 0 0 1; 1 0 0 0; 0 1 0 0]
U4 = [1 0 0 0; 0 -1 0 0; 0 0 1 0; 0 0 0 -1]
push!(MIXEDUNITARYCHANNELS, MixedUnitary(ps, [U1, U2, U3, U4]))

# Pauli channel 1 qubit
ps = [0.25, 0.15, 0.4, 0.2]
pstrs = ["I", "X", "Y", "Z"]
push!(MIXEDUNITARYCHANNELS, PauliNoise(ps, pstrs))

# Pauli channel 2 qubits
ps = [0.3, 0.2, 0.2, 0.3]
pstrs = ["II", "XZ", "YY", "IX"]
push!(MIXEDUNITARYCHANNELS, PauliNoise(ps, pstrs))

# Depolarizing channel 1 qubit
nq = 1
p = 0.66
push!(MIXEDUNITARYCHANNELS, Depolarizing(nq, p))

# Depolarizing channel 2 qubit
nq = 2
p = 0.78
push!(MIXEDUNITARYCHANNELS, Depolarizing(nq, p))

# Define Kraus channels
push!(KRAUSCHANNELS, AmplitudeDamping(0.3))
push!(KRAUSCHANNELS, GeneralizedAmplitudeDamping(0.4, 0.6))
push!(KRAUSCHANNELS, Depolarizing(1, 0.5))
push!(KRAUSCHANNELS, Reset())

@testset "Sample Mixed Unitaries" begin
    rng = MersenneTwister(42)

    c = Circuit()
    for much in MIXEDUNITARYCHANNELS
        push!(c, much, rand(rng, 1:10, numqubits(much))...)
    end

    for kch in KRAUSCHANNELS
        push!(c, kch, rand(rng, 1:10, numqubits(kch))...)
    end

    push!(c, GateH(), 7)
    push!(c, GateCX(), 1, 2)
    push!(c, Reset(), 4)

    for much in MIXEDUNITARYCHANNELS
        push!(c, much, rand(rng, 1:10, numqubits(much))...)
        push!(c, Measure(), rand(rng, 1:10), rand(rng, 1:10))
    end

    csampled = sample_mixedunitaries(c; rng=rng, ids=true)

    for k in 1:length(c)
        op = getoperation(c[k])
        if op isa AbstractKrausChannel && ismixedunitary(op)
            opsampled = getoperation(csampled[k])
            ugates = unitarygates(op)

            @test (opsampled in ugates
                   ||
                   (typeof(opsampled) in typeof.(ugates) &&
                    any(map(u -> all(getparams(opsampled) .== getparams(u)), ugates))))
            @test getqubits(c[k]) == getqubits(csampled[k])
        else
            @test c[k] == csampled[k]
        end
    end
end


@testset "Add noise functions" begin
    rng = MersenneTwister(42)

    c = Circuit()
    push!(c, GateH(), 1:3)
    push!(c, Reset(), [2, 3, 6])
    push!(c, GateCX(), 1, 2:4)
    push!(c, GateCX(), [1, 2, 3], [4, 5, 6])
    push!(c, Measure(), 1:3, 1:3)

    add_noise!(c, GateH(), Depolarizing1(0.1); before=true, parallel=true)
    add_noise!(c, GateH(), AmplitudeDamping(0.1); before=false, parallel=false)
    add_noise!(c, Reset(), ProjectiveNoise("X"); before=false, parallel=true)
    add_noise!(c, GateCX(), Depolarizing2(0.1); before=false, parallel=true)
    add_noise!(c, Measure(), GeneralizedAmplitudeDamping(0.1, 0.2); before=false, parallel=true)
    add_noise!(c, Measure(), PauliX(0.1); before=true, parallel=false)

    cmanual = Circuit()
    push!(cmanual, Depolarizing1(0.1), 1:3)
    for k in 1:3
        push!(cmanual, GateH(), k)
        push!(cmanual, AmplitudeDamping(0.1), k)
    end

    push!(cmanual, Reset(), [2, 3, 6])
    push!(cmanual, ProjectiveNoise("X"), [2, 3, 6])

    for k in 2:4
        push!(cmanual, GateCX(), 1, k)
        push!(cmanual, Depolarizing2(0.1), 1, k)
    end
    push!(cmanual, GateCX(), [1, 2, 3], [4, 5, 6])
    push!(cmanual, Depolarizing2(0.1), [1, 2, 3], [4, 5, 6])

    for k in 1:3
        push!(cmanual, PauliX(0.1), k)
        push!(cmanual, Measure(), k, k)
    end
    push!(cmanual, GeneralizedAmplitudeDamping(0.1, 0.2), 1:3)

    @test all(c .== cmanual)
end
