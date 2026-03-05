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

# ========================= #
# Quantum Fourier Transform #
# ========================= #

"""
    qft_circuit(n; swap::Bool=true) -> Circuit

Quantum Fourier Transform on `n` qubits.

# Arguments
- `n::Int`: Number of qubits
- `swap::Bool=true`: Include final SWAP gates for standard bit ordering
"""
function qft_circuit(n::Int; swap::Bool=true)
    n > 0 || throw(ArgumentError("n must be positive"))

    c = Circuit()

    for j in 1:n
        push!(c, GateH(), j)
        for k in (j+1):n
            push!(c, GateCP(π / 2^(k - j)), k, j)
        end
    end

    # Bit reversal to match standard QFT convention
    if swap
        for i in 1:(n÷2)
            push!(c, GateSWAP(), i, n - i + 1)
        end
    end

    return c
end
