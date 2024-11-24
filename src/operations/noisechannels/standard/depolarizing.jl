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
    Depolarizing(N,p)

``N`` qubit depolarizing noise channel.

The Kraus operators for the depolarizing channel are given by

```math
E_1 = \sqrt{1-p} I_N, \quad E_i = \sqrt{p/(4^N-1)} P_i
```

where ``p\in [0,1]`` is a probability, and ``P_i` is an ``N``-qubit Pauli string
operator, i.e. a tensor product of one-qubit Pauli operators (see [`Paulistring`](@ref)).
There is exactly one Kraus operator ``E_{i>1}`` for each distinct combination of
Pauli operators ``P_i``, except for the ``N``-qubit identity
``I_N = I\otimes I \otimes I \otimes...``

For example, for one qubit we have 3 operators ``P_i \in \{X,Y,Z\}``,
and for two qubits we have 15 operators ``P_i \in \{ I\otimes X, I\otimes Y,
I\otimes Z, X\otimes I, Y\otimes I, Z\otimes I, X\otimes X, X\otimes Y, X\otimes Z,
Y\otimes X, Y\otimes Y, Y\otimes Z, Z\otimes X, Z\otimes Y, Z\otimes Z \}``.
Use [`unitarygates`](@ref) to see this.

This channel is a mixed unitary channel, see [`ismixedunitary`](@ref),
and is a special case of [`PauliNoise`](@ref).

See also [`PauliString`](@ref) and [`PauliNoise`](@ref).

## Arguments

* `N`: Number of qubits.
* `p`: Probability of error, i.e. of not applying identity.

## Examples

Depolarizing channels can be defined for any ``N``:

```jldoctests
julia> push!(Circuit(), Depolarizing(1, 0.1), 1)
1-qubit circuit with 1 instructions:
└── Depolarizing(1,0.1) @ q[1]

julia> push!(Circuit(), Depolarizing(5, 0.1), 1, 2, 3, 4, 5)
5-qubit circuit with 1 instructions:
└── Depolarizing(5,0.1) @ q[1:5]
```

For one and two qubits you can use the shorthand notation:

```jldoctests
julia> push!(Circuit(), Depolarizing1(0.1), 1)
1-qubit circuit with 1 instructions:
└── Depolarizing(1,0.1) @ q[1]

julia> push!(Circuit(), Depolarizing2(0.1), 1, 2)
2-qubit circuit with 1 instructions:
└── Depolarizing(2,0.1) @ q[1:2]
```

"""
struct Depolarizing{N} <: AbstractKrausChannel{N}
    p::Num
end

function Depolarizing(N::Int, p)
    if N < 1
        error("Cannot define a 0-qubit depolarizing noise channel")
    end

    if !(p isa Symbolics.Num) && (p < 0 || p > 1)
        throw(ArgumentError("Probability p needs to be between 0 and 1."))
    end

    return Depolarizing{N}(p)
end

opname(::Type{<:Depolarizing{N}}) where {N} = "Depolarizing"

function evaluate(depol::Depolarizing, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(depol.p, d)
    concrete_value =  Symbolics.value(evaluated_p)
    
    if (concrete_value isa Real)
        if (concrete_value < 0 || concrete_value > 1)
            throw(ArgumentError("Probability p needs to be between 0 and 1 after evaluation."))
        end

        return Depolarizing{typeof(depol).parameters[1]}(concrete_value)

    elseif evaluated_p isa Symbolics.Num

        return Depolarizing{typeof(depol).parameters[1]}(evaluated_p)
    end
end

function probabilities(depol::Depolarizing{N}) where {N}
    return vcat([1 - depol.p], repeat([depol.p / (4^N - 1)], 4^N - 1))
end

function unitarygates(::Depolarizing{1})
    # NOTE: The first element must be the identity, the order of the rest doesn't matter
    return [GateID(), GateX(), GateY(), GateZ()]
end

function unitarygates(::Depolarizing{N}) where {N}
    # NOTE: The first element must be the identity, the order of the rest doesn't matter
    paulis = ['I', 'X', 'Y', 'Z']
    combinations = Iterators.product(fill(paulis, N)...)
    return vec([PauliString(join(comb)) for comb in combinations])
end

ismixedunitary(::Type{T}) where {T<:Depolarizing} = true

function Base.show(io::IO, depol::Depolarizing{N}) where {N}
    sep = get(io, :compact, false) ? "," : ", "
    print(io, opname(depol), "(", N, sep, depol.p, ")")
    return nothing
end

@doc raw"""
    Depolarizing1(p) Doc TODO
"""
const Depolarizing1 = Depolarizing{1}
@doc raw"""
    Depolarizing2(p) Doc TODO
"""
const Depolarizing2 = Depolarizing{2}
