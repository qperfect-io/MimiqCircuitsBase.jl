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

# ====================== #
# NOISE MODEL BENCHMARKS #
# ====================== #

SUITE["noise"] = BenchmarkGroup(["Benchmarks for noise channels and models"])

# Channel creation
SUITE["noise"]["create"] = BenchmarkGroup()

SUITE["noise"]["create"]["Depolarizing1"] = @benchmarkable Depolarizing1(0.01)
SUITE["noise"]["create"]["Depolarizing2"] = @benchmarkable Depolarizing2(0.01)
SUITE["noise"]["create"]["AmplitudeDamping"] = @benchmarkable AmplitudeDamping(0.01)
# SUITE["noise"]["create"]["PhaseDamping"] = @benchmarkable PhaseDamping(0.01)
SUITE["noise"]["create"]["PauliX"] = @benchmarkable PauliX(0.01)
SUITE["noise"]["create"]["PauliY"] = @benchmarkable PauliY(0.01)
SUITE["noise"]["create"]["PauliZ"] = @benchmarkable PauliZ(0.01)

# Kraus matrices
SUITE["noise"]["kraus"] = BenchmarkGroup()

channels_for_kraus = [
    ("Depolarizing1", Depolarizing1(0.1)),
    ("Depolarizing2", Depolarizing2(0.1)),
    ("AmplitudeDamping", AmplitudeDamping(0.1)),
    #     ("PhaseDamping", PhaseDamping(0.1)),
    #     ("GeneralizedAD", GeneralizedAmplitudeDamping(0.5, 0.1)),
    #     ("ThermalNoise", ThermalNoise(0.1, 0.05)),
]

for (name, channel) in channels_for_kraus
    SUITE["noise"]["kraus"][name] = @benchmarkable krausmatrices($channel)
end

# Noise model application
SUITE["noise"]["apply"] = BenchmarkGroup()

simple_nm = NoiseModel([
    GateInstanceNoise(GateH(), Depolarizing1(0.001)),
    GateInstanceNoise(GateCX(), Depolarizing2(0.01)),
])

full_nm = NoiseModel([
    GateInstanceNoise(GateH(), Depolarizing1(0.001)),
    GateInstanceNoise(GateX(), Depolarizing1(0.001)),
    GateInstanceNoise(GateY(), Depolarizing1(0.001)),
    GateInstanceNoise(GateZ(), Depolarizing1(0.001)),
    GateInstanceNoise(GateRX(θ), Depolarizing1(0.001)),
    GateInstanceNoise(GateRY(θ), Depolarizing1(0.001)),
    GateInstanceNoise(GateRZ(θ), Depolarizing1(0.001)),
    GateInstanceNoise(GateCX(), Depolarizing2(0.01)),
    GateInstanceNoise(GateCZ(), Depolarizing2(0.01)),
])

for n in [20, 50, 100]
    circ = random_circuit(10, n)
    SUITE["noise"]["apply"]["simple_n$n"] = @benchmarkable apply_noise_model($circ, $simple_nm)
    SUITE["noise"]["apply"]["full_n$n"] = @benchmarkable apply_noise_model($circ, $full_nm)
end
