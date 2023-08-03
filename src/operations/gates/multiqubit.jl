#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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

"""
    struct GateCCX <: Gate{3}

C₂X (or C₂NOT) 3-qubits gate. Where the first two qubits are used as controls.
"""
struct GateCCX <: Gate{3} end

opname(::Type{GateCCX}) = "CCX"

inverse(g::GateCCX) = g

@generated matrix(::GateCCX) = ctrl(ctrl(matrix(GateX())))

"""
    struct GateCSWAP <: Gate{3} end

3-qubits control SWAP gate where the first qubit is the control.
"""
struct GateCSWAP <: Gate{3} end

opname(::Type{GateCSWAP}) = "CSWAP"

inverse(g::GateCSWAP) = g

@generated matrix(::GateCSWAP) = ctrl(matrix(GateSWAP()))
