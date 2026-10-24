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

@doc raw"""
    PrepareStateT()

Prepare one qubit in the magic state
``T\ket{+} = (\ket{0} + e^{i\pi/4}\ket{1})/\sqrt{2}``, whatever
its previous state.

A magic state is the resource consumed by a ``\pi/8`` Pauli rotation when
the rotation is carried out with Pauli product measurements (see
[`pauli_based_computation`](@ref)). Fault-tolerant architectures produce these
states separately, by distillation, so a dedicated operation lets them be
counted and scheduled.

The operation is a Kraus channel with operators ``T\ket{+}\bra{0}`` and
``T\ket{+}\bra{1}``, and is equivalent to `Reset`, `GateH`, `GateT`. It cannot
be inverted.

See also [`Reset`](@ref), [`ResetX`](@ref), [`MeasurePauli`](@ref).

## Examples

```jldoctest
julia> c = push!(Circuit(), PrepareStateT(), 1)
1-qubit circuit with 1 instruction:
└── PrepareStateT @ q[1]
```

The canonical decomposition resets the qubit to ``\ket{0}``, then applies
`H` and `T`:

```jldoctest
julia> decompose_step(PrepareStateT())
1-qubit circuit with 3 instructions:
├── Reset @ q[1]
├── H @ q[1]
└── T @ q[1]
```
"""
struct PrepareStateT <: AbstractKrausChannel{1} end

inverse(::PrepareStateT) = error("Cannot invert PrepareStateT operations")

opname(::Type{<:PrepareStateT}) = "PrepareStateT"

krausmatrices(op::PrepareStateT) = [matrix(kraus) for kraus in krausoperators(op)]

# T|+⟩⟨0| and T|+⟩⟨1|: whatever the input, the output is T|+⟩.
function krausoperators(::PrepareStateT)
    m = [1, cis(π / 4)] ./ sqrt(2)
    return [Operator(m * [1 0]), Operator(m * [0 1])]
end

matches(::CanonicalRewrite, ::PrepareStateT) = true

function decompose_step!(builder, ::CanonicalRewrite, ::PrepareStateT, qtargets, _, _)
    q = qtargets[1]
    push!(builder, Reset(), q)
    push!(builder, GateH(), q)
    push!(builder, GateT(), q)
    return builder
end

function Base.show(io::IO, ::PrepareStateT)
    print(io, opname(PrepareStateT))
end

Base.@deprecate_binding PrepareMagic PrepareStateT
