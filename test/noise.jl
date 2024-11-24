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

#TODO: test specific matrices of noise channels

@testset "Noise channels definition" begin
    @test isdefined(MimiqCircuitsBase, :AbstractKrausChannel)
    @test isdefined(MimiqCircuitsBase, :Kraus)
    @test isdefined(MimiqCircuitsBase, :MixedUnitary)
    @test isdefined(MimiqCircuitsBase, :PauliNoise)
    @test isdefined(MimiqCircuitsBase, :AmplitudeDamping)
    @test isdefined(MimiqCircuitsBase, :GeneralizedAmplitudeDamping)
    @test isdefined(MimiqCircuitsBase, :PhaseAmplitudeDamping)
    @test isdefined(MimiqCircuitsBase, :ThermalNoise)
    @test isdefined(MimiqCircuitsBase, :Depolarizing)
    @test isdefined(MimiqCircuitsBase, :Reset)
    @test isdefined(MimiqCircuitsBase, :ResetX)
    @test isdefined(MimiqCircuitsBase, :ResetY)
    @test isdefined(MimiqCircuitsBase, :ResetZ)
    @test isdefined(MimiqCircuitsBase, :ProjectiveNoise)
end

@testset "Mixed Unitary assignment" begin
    # Non mixed unitary channels
    @test !ismixedunitary(AbstractKrausChannel)
    @test !ismixedunitary(Kraus)
    @test !ismixedunitary(AmplitudeDamping)
    @test !ismixedunitary(GeneralizedAmplitudeDamping)
    @test !ismixedunitary(PhaseAmplitudeDamping)
    @test !ismixedunitary(ThermalNoise)
    @test !ismixedunitary(ProjectiveNoiseX)
    @test !ismixedunitary(ProjectiveNoiseY)
    @test !ismixedunitary(ProjectiveNoiseZ)

    # Mixed unitary channels
    @test ismixedunitary(MixedUnitary)
    @test ismixedunitary(PauliNoise)
    @test ismixedunitary(Depolarizing)
end

@testset "Kraus channel" begin
    p = rand()

    Emats = [[1 0; 0 sqrt(1 - p)], [0 sqrt(p); 0 0]]
    kch = Kraus(Emats)

    for (k, Ek) in enumerate(krausmatrices(kch))
        @test Ek == Emats[k]
    end

    # Wrong Kraus: Not normalized
    Emats = [[1 0; 0 sqrt(1 - p)], [0 sqrt(p); 1 0]]
    @test_throws "List of Kraus matrices should fulfill" Kraus(Emats)

    # Wrong Kraus: dimension
    Emats = [[1 0 0; 0 sqrt(1 - p) 0; 0 0 1], [0 sqrt(p) 0; 0 0 0; 0 0 0]]
    @test_throws ArgumentError Kraus(Emats)
end

@testset "Mixed Unitary channel" begin
    probs2, probs4 = rand(2), rand(4)
    probs2 ./= sum(probs2)
    probs4 ./= sum(probs4)

    Umats2 = [randunitary(2), randunitary(2)]
    much2 = MixedUnitary(probs2, Umats2)

    Umats4 = [randunitary(4), randunitary(4), randunitary(4), randunitary(4)]
    much4 = MixedUnitary(probs4, Umats4)

    for (k, Uk) in enumerate(unitarymatrices(much2))
        @test Uk == Umats2[k]
    end

    for (k, Uk) in enumerate(unitarymatrices(much4))
        @test Uk == Umats4[k]
    end

    # Wrong MixedUnitary: not unitary
    Umats_wrong = [randunitary(2), [1 0; 1 -1]]
    @test_throws "Custom matrix not unitary" MixedUnitary(probs2, Umats_wrong)

    # Wrong MixedUnitary: not normalized
    probs_wrong = probs2 .* 0.5
    @test_throws "Probabilities should sum to 1." MixedUnitary(probs_wrong, Umats2)

    # Wrong MixedUnitary: dimension
    Umats_wrong = [[1 0 0; 0 1 0; 0 0 0], [1 0 0; 0 -1 0; 0 0 0]]
    @test_throws ArgumentError MixedUnitary(probs2, Umats_wrong)
end

@testset "PauliNoise channel" begin
    probs2, probs4 = rand(2), rand(4)
    probs2 ./= sum(probs2)
    probs4 ./= sum(probs4)

    ops_str = ["I", "X"]
    pauliN = PauliNoise(probs2, ops_str)
    for (k, Uk) in enumerate(unitarymatrices(pauliN))
        @test Uk == matrix(PauliString(ops_str[k]))
    end

    ops_str = ["II", "XX", "YY", "ZX"]
    pauliN = PauliNoise(probs4, ops_str)
    for (k, Uk) in enumerate(unitarymatrices(pauliN))
        @test Uk == matrix(PauliString(ops_str[k]))
    end

    # Wrong PauliNoise: non-Pauli
    ops_str = ["I", "K"]
    @test_throws "Pauli string can only contain I, X, Y, or Z" PauliNoise(probs2, ops_str)

    # Wrong PauliNoise: dimensions
    ops_str = ["I", "XX"]
    @test_throws "Pauli strings must all be of the same length." PauliNoise(probs2, ops_str)

    # Wrong PauliNoise: non-matching lengths
    ops_str = ["II", "XX"]
    @test_throws "probabilities and Paulis must have the same length" PauliNoise(probs4, ops_str)
end

@testset "Depolarizing channel" begin
    # N=1
    depol = Depolarizing(1, 0.5)
    umats = unitarymatrices(depol)

    pmats = matrix.([GateID(), GateX(), GateY(), GateZ()])
    for k in eachindex(umats)
        @test umats[k] == pmats[k]
    end

    # N=2
    depol = Depolarizing(2, 0.3)
    umats = unitarymatrices(depol)

    pmats2 = [kron(M1, M2) for M1 in pmats, M2 in pmats]
    for k in eachindex(umats)
        @test umats[k] == pmats2[k]
    end

    # Wrong Depolarizing: p value
    p = 2
    @test_throws "Probability p needs to be between 0 and 1." Depolarizing(1, p)
    p = -0.1
    @test_throws "Probability p needs to be between 0 and 1." Depolarizing(1, p)
end

@testset "Amplitude Damping" begin
    gam = rand()

    ad = AmplitudeDamping(gam)
    kmats = krausmatrices(ad)

    @test kmats[1] == [1 0; 0 sqrt(1 - gam)]
    @test kmats[2] == [0 sqrt(gam); 0 0]

    ksum = sum(adjoint(Ek) * Ek for Ek in kmats)
    @test isapprox(ksum, Matrix(I, 2, 2), rtol=1e-8)

    @test_throws ArgumentError AmplitudeDamping(2.0)
    @test_throws ArgumentError AmplitudeDamping(-0.1)
end

@testset "Generalized Amplitude Damping" begin
    p, gam = rand(), rand()

    gad = GeneralizedAmplitudeDamping(p, gam)
    kmats = krausmatrices(gad)

    # Expected matrices
    @test kmats[1] == sqrt(p) .* [1 0; 0 sqrt(1 - gam)]
    @test kmats[2] == sqrt(1 - p) .* [sqrt(1 - gam) 0; 0 1]
    @test kmats[3] == sqrt(p) .* [0 sqrt(gam); 0 0]
    @test kmats[4] == sqrt(1 - p) .* [0 0; sqrt(gam) 0]

    # Normalization of Kraus
    ksum = sum(adjoint(Ek) * Ek for Ek in kmats)
    @test isapprox(ksum, Matrix(I, 2, 2), rtol=1e-8)

    # Test invalid gamma and p values
    @test_throws ArgumentError GeneralizedAmplitudeDamping(1.1, gam)  # p > 1
    @test_throws ArgumentError GeneralizedAmplitudeDamping(-0.1, gam) # p < 0
    @test_throws ArgumentError GeneralizedAmplitudeDamping(p, 1.1)    # gamma > 1
    @test_throws ArgumentError GeneralizedAmplitudeDamping(p, -0.1)   # gamma < 0
end

@testset "Phase Amplitude Damping" begin
    p, gamma, beta = rand(), rand(), rand()

    pad = PhaseAmplitudeDamping(p, gamma, beta)
    kmats = krausmatrices(pad)

    K = sqrt(1 - gamma) * (1 - 2 * beta) / (1 - gamma * p)
    pref1 = sqrt(1 - gamma * p)
    pref2 = sqrt(1 - gamma * (1 - p) - (1 - gamma * p) * K^2)
    pref3 = sqrt(gamma * p)
    pref4 = sqrt(gamma * (1 - p))

    # Expected matrices
    @test kmats[1] == pref1 .* [K 0; 0 1]
    @test kmats[2] == pref2 .* [1 0; 0 0]
    @test kmats[3] == pref3 .* [0 1; 0 0]
    @test kmats[4] == pref4 .* [0 0; 1 0]

    # Normalization of Kraus
    ksum = sum(adjoint(Ek) * Ek for Ek in kmats)
    @test isapprox(ksum, Matrix(I, 2, 2), rtol=1e-8)

    # Test invalid parameter values
    @test_throws ArgumentError PhaseAmplitudeDamping(p, 2.0, beta)  # gamma > 1
    @test_throws ArgumentError PhaseAmplitudeDamping(p, -0.1, beta) # gamma < 0
    @test_throws ArgumentError PhaseAmplitudeDamping(1.1, gamma, beta) # p > 1
    @test_throws ArgumentError PhaseAmplitudeDamping(-0.1, gamma, beta) # p < 0
    @test_throws ArgumentError PhaseAmplitudeDamping(p, gamma, 1.1) # beta > 1
    @test_throws ArgumentError PhaseAmplitudeDamping(p, gamma, -0.1) # beta < 0
end

@testset "Thermal Noise" begin
    T2 = rand()
    T1 = 2 * T2 + rand()
    time = rand()
    ne = rand()

    Gamma1 = 1 / T1
    Gamma2 = 1 / T2
    p = 1 - ne
    gamma = 1 - exp(-Gamma1 * time)
    beta = 0.5 * (1 - exp(-(Gamma2 - Gamma1 / 2) * time))

    tn = ThermalNoise(T1, T2, time, ne)
    pad = PhaseAmplitudeDamping(p, gamma, beta)

    kmattn = krausmatrices(tn)
    kmatpad = krausmatrices(pad)

    # Expected matrices same as PhaseAmplitudeDamping
    for k in eachindex(kmattn)
        @test isapprox(kmattn[k], kmatpad[k], rtol=1e-8)
    end

    # Wrong parameters
    T1 = -0.1
    @test_throws "Value of T1 must be >= 0" ThermalNoise(T1, T2, time, ne)

    T1 = rand()
    T2 = 2 * T1 + rand()
    @test_throws "Value of T2 must fulfill" ThermalNoise(T1, T2, time, ne)

    T2 = rand()
    T1 = 2 * T2 + rand()
    time = -1
    @test_throws "time must be a positive parameter." ThermalNoise(T1, T2, time, ne)

    time = rand()
    ne = 2
    @test_throws "Value of ne must be between 0 and 1" ThermalNoise(T1, T2, time, ne)
    ne = -0.1
    @test_throws "Value of ne must be between 0 and 1" ThermalNoise(T1, T2, time, ne)

end
