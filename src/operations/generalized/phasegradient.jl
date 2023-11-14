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

@doc raw"""
    PhaseGradient(n)

A phase gradient gate applies a phase shift to a quantum register of `n` qubits,
where each computational basis state ``\ket{k}`` experiences a phase
proportional to its integer value ``k``:

```math
\operatorname{PhaseGradient} =
\sum{k=0}^{n-1} \mathrm{e}^{i \frac{2 \pi}{N} k} \ket{k}\bra{k}
```
"""
struct PhaseGradient{N} <: AbstractGate{N} end

function PhaseGradient(numqubits::Int)
    PhaseGradient{numqubits}()
end

# constructor to allow the syntax
# push!(circuit, PhaseGate, register)
function PhaseGradient(::Type{Instruction}, reg)
    g = PhaseGradient(length(reg))
    return Instruction(g, Tuple(reg), ())
end

# constructor to allow the syntax
PhaseGradient() = reg -> Instruction(PhaseGradient(length(reg)), Tuple(reg), ())

opname(::Type{<:PhaseGradient}) = "PhaseGradient"

qregsizes(::PhaseGradient{N}) where {N} = (N,)

function _phasegradientpow_decompose!(circ, P, N, qtargets)
    for i in N:-1:1
        # exp(2π / 2^i) on qubit i
        phase = P * π / 2.0^(i - 1)
        push!(circ, GateP(phase), qtargets[i])
    end
    return circ
end

# standard decomposition
decompose!(circ::Circuit, ::PhaseGradient{N}, qtargets, _) where {N} = _phasegradientpow_decompose!(circ, 1, N, qtargets)

# specialization for power
decompose!(circ::Circuit, ::Power{P,N,PhaseGradient{N}}, qtargets, _) where {P,N} = _phasegradientpow_decompose!(circ, P, N, qtargets)
