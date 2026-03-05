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

# ================================= #
# PROTOBUF SERIALIZATION BENCHMARKS #
# ================================= #

SUITE["proto"] = BenchmarkGroup(["Benchmarks for protobuf serialization"])

for n in [10, 50, 100]
    circ = random_circuit(10, n)

    SUITE["proto"]["to_n$n"] = @benchmarkable MimiqCircuitsBase.toproto($circ)

    proto = MimiqCircuitsBase.toproto(circ)
    SUITE["proto"]["from_n$n"] = @benchmarkable MimiqCircuitsBase.fromproto($proto)
end

# Gate serialization
SUITE["proto"]["gate"] = BenchmarkGroup()

proto_gates = [
    ("H", GateH()),
    ("RX", GateRX(0.5)),
    ("U3", GateU(0.1, 0.2, 0.3)),
    ("CX", GateCX()),
    ("CCX", GateCCX()),
]

for (name, gate) in proto_gates
    SUITE["proto"]["gate"]["to_$name"] = @benchmarkable MimiqCircuitsBase.toproto($gate)

    proto = MimiqCircuitsBase.toproto(gate)
    SUITE["proto"]["gate"]["from_$name"] = @benchmarkable MimiqCircuitsBase.fromproto($proto)
end
