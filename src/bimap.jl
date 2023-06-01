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

const OPERATIONS = let
    operations = [
        GateX, GateY, GateZ, GateH, GateS, GateSDG,
        GateT, GateTDG, GateSX, GateSXDG, GateID,
        GateP, GateRX, GateRY, GateRZ, GateR,
        GateU1, GateU2, GateU2DG, GateU3, GateU,
        GateCX, GateCY, GateCZ, GateCH, GateSWAP,
        GateISWAP, GateISWAPDG, GateCP, GateCRX, GateCRY,
        GateCRZ, GateCU, GateCCX, GateCSWAP, GateCR, GateRZZ,
        GateRXX, GateRYY, GateXXplusYY, GateXXminusYY, GateCSX,
        GateCSXDG, GateCS, GateCSDG, GateECR, GateDCX, GateDCXDG,
        Barrier
    ]

    BiMap(operations, opname.(operations))
end
