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
# INSTRUCTION BENCHMARKS #
# ====================== #

SUITE["instruction"] = BenchmarkGroup(["Benchmarks for Instruction operations"])

# Creation
SUITE["instruction"]["create"] = BenchmarkGroup()
SUITE["instruction"]["create"]["H"] = @benchmarkable Instruction(GateH(), (1,), (), ())
SUITE["instruction"]["create"]["CX"] = @benchmarkable Instruction(GateCX(), (1, 2), (), ())
SUITE["instruction"]["create"]["RX"] = @benchmarkable Instruction(GateRX(0.5), (1,), (), ())
SUITE["instruction"]["create"]["U3"] = @benchmarkable Instruction(GateU(0.1, 0.2, 0.3), (1,), (), ())
SUITE["instruction"]["create"]["Measure"] = @benchmarkable Instruction(Measure(), (1,), (1,), ())
SUITE["instruction"]["create"]["CCX"] = @benchmarkable Instruction(GateCCX(), (1, 2, 3), (), ())

# Accessors
inst_h = Instruction(GateH(), (1,), (), ())
inst_cx = Instruction(GateCX(), (1, 2), (), ())
inst_rx = Instruction(GateRX(0.5), (1,), (), ())
inst_m = Instruction(Measure(), (1,), (1,), ())
inst_ccx = Instruction(GateCCX(), (1, 2, 3), (), ())

SUITE["instruction"]["access"] = BenchmarkGroup()
SUITE["instruction"]["access"]["getoperation_H"] = @benchmarkable getoperation($inst_h)
SUITE["instruction"]["access"]["getoperation_RX"] = @benchmarkable getoperation($inst_rx)
SUITE["instruction"]["access"]["getqubits_CX"] = @benchmarkable getqubits($inst_cx)
SUITE["instruction"]["access"]["getqubits_CCX"] = @benchmarkable getqubits($inst_ccx)
SUITE["instruction"]["access"]["getbits"] = @benchmarkable getbits($inst_m)
SUITE["instruction"]["access"]["numqubits"] = @benchmarkable numqubits($inst_cx)
