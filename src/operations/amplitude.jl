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
    Amplitude(bs::BitString)

Operation to get amplitude of a state vector element.

The operation gets the quantum state's amplitude (which is a complex number)
corresponding to the state defined by the  bitstring `bs` in the computational
basis and stores it in a z-register.

See [`BitString`](@ref).

## Examples

When defining a circuit, only the z-register to store the result needs to be specified.

```jldoctests
julia> Amplitude(BitString("001"))
Amplitude(bs"001")

julia> c = push!(Circuit(),Amplitude(BitString("001")), 1)
0-qubit circuit with 1 instructions:
└── Amplitude(bs"001") @ z[1]

```
"""
struct Amplitude <: Operation{0,0,1}
    bs::BitString
end

opname(::Type{<:Amplitude}) = "Amplitude"

qregsizes(::Amplitude) = ()

cregsizes(::Amplitude) = ()

zregsizes(::Amplitude) = (1,)

inverse(g::Amplitude) = g

isunitary(::Type{<:Amplitude}) = true

getbitstring(c::Amplitude) = c.bs

function Base.show(io::IO, op::Amplitude)
    print(io, opname(Amplitude), "(", op.bs, ")")
end

function Base.show(io::IO, ::MIME"text/plain", op::Amplitude)
    print(io, opname(Amplitude), "(", op.bs, ")")
end
