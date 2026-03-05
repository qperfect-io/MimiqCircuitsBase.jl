#
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

function matrix(inst::Instruction{1,0,0,<:AbstractGate})
    return matrix(getoperation(inst))
end

function matrix(inst::Instruction{2,0,0,<:AbstractGate})
    M = copy(matrix(getoperation(inst)))
    if !issorted(getqubits(inst))
        Base.swaprows!(M, 2, 3)
        Base.swapcols!(M, 2, 3)
    end
    return M
end

function matrix(inst::Instruction{N,0,0,<:AbstractGate}) where {N}
    matrix(inst, N)
end

function matrix(inst::Instruction{N,0,0,<:AbstractGate}, L) where {N}
    op = getoperation(inst)
    M = matrix(op)
    qubits = getqubits(inst)

    # NOTE: copying here becasue singleton gates behaviour
    if numparams(op) == 0
        return _reorder_qubits_matrix!(Matrix(deepcopy(M)), qubits, L)
    end

    return _reorder_qubits_matrix!(Matrix(M), qubits, L)
end

function matrix(insts::Vector{<:Instruction})
    N = numqubits(insts)

    iter = Iterators.map(insts) do inst
        matrix(inst, N)
    end

    return foldl(*, Iterators.reverse(iter); init=Matrix{Complex{Num}}(I, 2^N, 2^N))
end
