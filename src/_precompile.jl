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

function _precompile_()
    for gate_t in MimiqCircuitsBase.GATES
        @debug "Precompiling $gate_t"

        nq = numqubits(gate_t)
        np = numparams(gate_t)

        precompile(gate_t, ntuple(_ -> Float64, nq))
        precompile(gate_t, ntuple(_ -> Int64, nq))

        precompile(numqubits, (gate_t,))
        precompile(numbits, (gate_t,))

        precompile(Base.push!, (Circuit, gate_t, Vararg{Int,nq}))

        precompile(matrix, (gate_t,))
        precompile(_matrix, (Type{gate_t}, ntuple(_ -> Float64, np)...))
        precompile(_matrix, (Type{gate_t}, ntuple(_ -> Int64, np)...))

        for power in (1 // 4, 1 // 2, 0.25, 0.5, 2, 3)
            precompile(power, (gate_t, Int64))
            precompile(power, (gate_t, Float64))
            precompile(power, (gate_t, typeof(1 // 2)))
            precompile(matrix, (Power{power,nq,gate_t},))
            precompile(_matrix, (Type{Power{power,nq,gate_t}}, ntuple(_ -> Float64, np)...))
            precompile(_matrix, (Type{Power{power,nq,gate_t}}, ntuple(_ -> Int64, np)...))
        end

        precompile(matrix, (Inverse{nq,gate_t},))
        precompile(_matrix, (Type{Inverse{nq,gate_t}}, ntuple(_ -> Float64, np)...))
        precompile(_matrix, (Type{Inverse{nq,gate_t}}, ntuple(_ -> Int64, np)...))

        precompile(control, (Int, gate_t))

        precompile(decompose, (gate_t,))
    end
end

