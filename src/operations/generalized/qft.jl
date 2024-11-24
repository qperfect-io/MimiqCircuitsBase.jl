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

@doc raw"""
    QFT(n)

Quantum Fourier transform.

Performs the quantum Fourier transform on a register of `n` qubits.

The inverse quantum Fourier transform is simply given `inverse(qft)`.

It implements the unitary transformation.

```math
\frac{1}{2^{n/2}} \sum_{x=0}^{2^n-1} \sum_{y=0}^{2^n-1} e^{2\pi i \frac{xy}{2^n}} \ket{y}\bra{x}
```

## Examples

```jldoctests
julia> c = push!(Circuit(), QFT(10), 1:10...)
10-qubit circuit with 1 instructions:
└── QFT @ q[1:10]

julia> push!(c, inverse(QFT(10)), 1:10...)
10-qubit circuit with 2 instructions:
├── QFT @ q[1:10]
└── QFT† @ q[1:10]
```
"""
struct QFT{N} <: AbstractGate{N}
    function QFT{N}() where {N}
        if !(N isa Integer)
            throw(OperationError(QFT, "Number of qubits must be an integer."))
        end

        if N < 1
            throw(OperationError(QFT, "Number of qubits must be ≥ 1."))
        end

        new{N}()
    end
end

function QFT(numqubits::Int)
    QFT{numqubits}()
end

QFT() = LazyExpr(QFT, LazyArg())

opname(::Type{<:QFT}) = "QFT"

qregsizes(::QFT{N}) where {N} = (N,)

function decompose!(circ::Circuit, ::QFT{N}, qubits, _, _) where {N}
    qreg = reverse(qubits)

    push!(circ, GateH(), qreg[1])

    for i in 2:N
        # should we use the phase gradient gate instead?
        # not yet, it is very slow
        # push!(circ, Control(PhaseGradient(i - 1)^(1 // 2)), qreg[i:-1:1]...)
        # or
        #decompose!(circ, Control(PhaseGradient(i - 1)^(1 // 2)), qreg[i:-1:1], ())

        for j in 1:i-1
            angle = π / 2.0^(i - j)
            push!(circ, GateCP(angle), qreg[i], qreg[j])
        end

        push!(circ, GateH(), qreg[i])
    end

    return circ
end
