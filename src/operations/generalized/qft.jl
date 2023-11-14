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
    QFT(n[; norev=false])

Quantum Fourier transform.

Performs the quantum Fourier transform on a register of `n` qubits.

Optionally the `reverse` keyword argument can be set to false to avoid reversing
the order of the qubits at the end of the circuit.

The inverse quantum Fourier transform is simply given `inverse(qft)`.

It implements the unitary transformation.

```math
\frac{1}{2^{n/2}} \sum_{x=0}^{2^n-1} \sum_{y=0}^{2^n-1} e^{2\pi i \frac{xy}{2^n}} \ket{y}\bra{x}
```

## Examples

```jldoctests
julia> c = push!(Circuit(), QFT(10), 1:10...)
10-qubit circuit with 1 instructions:
└── QFT @ q[1,2,3,4,5,6,7,8,9,10]

julia> push!(c, inverse(QFT(10)), 1:10...)
10-qubit circuit with 2 instructions:
├── QFT @ q[1,2,3,4,5,6,7,8,9,10]
└── QFT† @ q1, q2, q3, q4, q5, q6, q7, q8, q9, q10
```
"""
struct QFT{N,NOREV} <: AbstractGate{N} end

function QFT(numqubits::Int; norev=false)
    QFT{numqubits,norev}()
end

# constructor to allow the syntax
# push!(circuit, QFT, register)
function QFT(::Type{Instruction}, reg)
    g = QFT(length(reg))
    return Instruction(g, Tuple(reg), ())
end

# constructor to allow the syntax
# push!(circuit, QFT(), register)
QFT(; kwargs...) = reg -> Instruction(QFT(length(reg); kwargs...), Tuple(reg), ())

opname(::Type{<:QFT}) = "QFT"

qregsizes(::QFT{N}) where {N} = (N,)

function decompose!(circ::Circuit, ::QFT{N,NOREV}, qtargets, _) where {N,NOREV}
    qreg = NOREV ? qtargets : reverse(qtargets)

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

function Base.show(io::IO, qft::QFT{N,NOREV}) where {N,NOREV}
    print(io, opname(qft))

    if NOREV
        print(io, "(norev)")
    end
end
