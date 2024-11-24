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
    Delay(t)

1-qubit delay gate

This gate is equivalent to a GateID gate, except that it is parametrized by
a time parameter `t`. The parameter does not affect the action of the gate. The only
purpose of this gate is to act as a placeholder to indicate idle noise, in
which case the parameter `t` can later be used to further specify the noise properties.

The gate can be created by calling `Delay(t)` where `t` is a number.

See also [`GateID`](@ref).

## Matrix representation

```math
\operatorname{Delay}(t) =
\begin{pmatrix}
    1 & 0 \\
    0 & 1
\end{pmatrix}
```

## Examples

```jldoctests
julia> c = push!(Circuit(), Delay(0.1), 1)
1-qubit circuit with 1 instructions:
└── Delay(0.1) @ q[1]

```

## Decomposition

```jldoctests
julia> decompose(Delay(0.2))
1-qubit circuit with 1 instructions:
└── ID @ q[1]

```
"""
struct Delay <: AbstractGate{1}
    t::Num
end

opname(::Type{Delay}) = "Delay"

@generated _matrix(::Type{Delay}, _) = _matrix(GateID)

@generated inverse(::Delay) = error("Cannot invert a Delay gate.")

@generated _power(::Delay, _) = error("Cannot raise a Delay gate to a power.")

qregsizes(::Delay) = (1,)

function decompose!(circ::Circuit, ::Delay, qreg, _, _)
    push!(circ, GateID(), qreg)
    return circ
end
