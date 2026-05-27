#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

function _check_custom_kraus_qubit_count(N::Integer)
    if N < 1
        error("Cannot define a 0-qubit custom noise channel")
    end
    if N > 2
        error("Custom noise channels larger than 2 qubits are not supported")
    end
    return nothing
end

function _check_kraus_completeness(
    E::Vector{<:AbstractOperator}, N::Integer, channel_name::AbstractString,
)
    any(issymbolic, E) && return nothing
    M = 1 << N
    ksum = sum(adjoint(Ek) * Ek for Ek in unwrappedmatrix.(E))
    if !isapprox(ksum, Matrix(I, M, M), rtol=1e-12)
        throw(ArgumentError("List of $channel_name matrices should fulfill ``\\sum_k E_k^\\dagger E_k = I``."))
    end
    return nothing
end

function _evaluate_kraus_operators(E::Vector{<:AbstractOperator}, d::Dict)
    return [
        x isa Operator ?
        Operator(map(x.O) do y
            value = Symbolics.substitute(y, d)
            issymbolic(value) ? value : unwrapvalue(value)
        end) :
        x isa LossyOperator ?
        LossyOperator(map(x.O) do y
            value = Symbolics.substitute(y, d)
            issymbolic(value) ? value : unwrapvalue(value)
        end, x.lossy) :
        x isa AbstractOperator ?
        map(getparams(x)) do y
            value = Symbolics.substitute(y, d)
            issymbolic(value) ? value : unwrapvalue(value)
        end |> (args -> typeof(x)(args...)) :
        x
        for x in E
    ]
end

function _coerce_kraus_input(E::AbstractVector)
    isempty(E) && error("Vector of Kraus matrices cannot be empty")
    return AbstractOperator[
        x isa AbstractOperator ? x :
        x isa AbstractMatrix ? Operator(x) :
        throw(ArgumentError("Invalid object of type $(typeof(x)) is not a valid operator. Use operators or matrices."))
        for x in E
    ]
end

function _kraus_uniform_numqubits(E::AbstractVector{<:AbstractOperator})
    isempty(E) && error("Vector of Kraus matrices cannot be empty")
    N = numqubits(E[1])
    if !all(x -> numqubits(x) == N, E)
        error("Operators acting on different numbers of qubits provided.")
    end
    return N
end

function _show_kraus_channel(io::IO, kraus)
    print(io, opname(kraus), "(")
    io1 = IOContext(io, :compact => true)
    print(io1, kraus.E[1])
    for op in @view kraus.E[2:end]
        print(io1, ", ")
        print(io1, op)
    end
    print(io, ")")
end

@doc raw"""
    Kraus(E)

Custom ``N`` qubit Kraus channel specified by a list of Kraus operators.

A Kraus channel is defined by

```math
\mathcal{E}(\rho) = \sum_k E_k \rho E_k^\dagger,
```

where ``E_k`` are Kraus operators that need to fulfill ``\sum_k E_k^\dagger E_k = I``.

If the Kraus operators are all proportional to unitaries, use [`MixedUnitary`](@ref) instead.

The Kraus matrices are defined in the computational basis in the usual textbook
order (the first qubit corresponds to the left-most qubit).
For 1 qubit we have ``|0\rangle``, ``|1\rangle``.
For 2 qubits we have ``|00\rangle``, ``|01\rangle``, ``|10\rangle``, ``|11\rangle``.
See also [`GateCustom`](@ref).

!!! note
    Currently only 1 and 2-qubit custom Kraus channels are supported.

A `Kraus` channel becomes loss-aware simply by including one or more
[`LossyOperator`](@ref) branches in `E`; in that case [`hasloss`](@ref) returns
`true` and [`lossoperators`](@ref) / [`survivaloperators`](@ref) /
[`losseffect`](@ref) describe its leakage structure.

See also [`MixedUnitary`](@ref), [`AbstractKrausChannel`](@ref),
[`LossyOperator`](@ref).

## Arguments

* `E`: Vector of ``2^N \times 2^N`` complex matrices or ``N`` qubit operators.
  Both can be mixed. Including [`LossyOperator`](@ref) branches makes the
  channel loss-aware.

## Examples

```jldoctests
julia> push!(Circuit(), Kraus([[1 0; 0 sqrt(0.9)], [0 sqrt(0.1); 0 0]]), 1)
1-qubit circuit with 1 instruction:
└── Kraus(Operator([1.0 0.0; 0.0 0.948683]), Operator([0.0 0.316228; 0.0 0.0])) @ q[1]

julia> push!(Circuit(), Kraus([Projector0(), Projector1()]), 1)
1-qubit circuit with 1 instruction:
└── Kraus(Projector0(1), Projector1(1)) @ q[1]

julia> push!(Circuit(), Kraus([[1 0; 0 0], Projector1()]), 1)
1-qubit circuit with 1 instruction:
└── Kraus(Operator([1.0 0.0; 0.0 0.0]), Projector1(1)) @ q[1]

julia> @variables x
1-element Vector{Symbolics.Num}:
 x

julia> g = Kraus([Projector0(), Projector1(x)])
Kraus(Projector0(1), Projector1(x))

julia> evaluate(g,Dict(x=>1))
Kraus(Projector0(1), Projector1(1))

julia> g = Kraus([[1 0; 0 sqrt(0.9)], [0 sqrt(0.1); 0 x]])
Kraus(Operator([1.0 0.0; 0.0 0.948683]), Operator(Real[0 0.316228; 0 x]))

julia> evaluate(g,Dict(x=>0))
Kraus(Operator([1.0 0.0; 0.0 0.948683]), Operator([0.0 0.316228; 0.0 0.0]))
```
"""
struct Kraus{N} <: AbstractKrausChannel{N}
    E::Vector{AbstractOperator}

    function Kraus{N}(E::Vector{<:AbstractOperator}) where {N}
        _check_custom_kraus_qubit_count(N)
        _check_kraus_completeness(E, N, "Kraus")
        return new{N}(E)
    end
end

evaluate(k::Kraus, d::Dict=Dict()) = Kraus(_evaluate_kraus_operators(k.E, d))

Kraus(E::Vector{<:AbstractOperator}) = Kraus{_kraus_uniform_numqubits(E)}(E)

function Kraus(E::Vector)
    Es = _coerce_kraus_input(E)
    return Kraus{_kraus_uniform_numqubits(Es)}(Es)
end

opname(::Type{<:Kraus}) = "Kraus"

krausoperators(kraus::Kraus) = kraus.E

Base.show(io::IO, kraus::Kraus) = _show_kraus_channel(io, kraus)

function Base.:(==)(left::Kraus, right::Kraus)
    typeof(left) == typeof(right) || return false
    return krausoperators(left) == krausoperators(right)
end

"""
    hasloss(kraus)

Return `true` if `kraus` contains any [`LossyOperator`](@ref) branch.
"""
hasloss(kraus::AbstractKrausChannel) = any(op -> op isa LossyOperator, krausoperators(kraus))

"""
    lossoperators(kraus)

Return the [`LossyOperator`](@ref) branches of a Kraus channel.
"""
lossoperators(kraus::AbstractKrausChannel) = filter(op -> op isa LossyOperator, krausoperators(kraus))

"""
    survivaloperators(kraus)

Return the non-[`LossyOperator`](@ref) branches of a Kraus channel.
"""
survivaloperators(kraus::AbstractKrausChannel) = filter(op -> !(op isa LossyOperator), krausoperators(kraus))

@doc raw"""
    losseffect(kraus)

Compute the loss-probability operator ``\Lambda = \sum_k L_k^\dagger L_k``
over all [`LossyOperator`](@ref)-tagged branches ``L_k`` of `kraus`.

``\Lambda`` is a positive semidefinite matrix whose diagonal entries are the
loss probabilities from each computational basis state: ``\langle i|\Lambda|i\rangle``
is the probability that state ``|i\rangle`` leaks out of the computational
subspace. For a general state ``|\psi\rangle``, the total loss probability is
``\langle\psi|\Lambda|\psi\rangle``.

Note that ``\Lambda`` contains **probabilities**, not amplitudes. The
[`LossyOperator`](@ref) matrices hold amplitudes, so their entries are the
square roots of the corresponding loss probabilities (e.g. an amplitude of
``\sqrt{0.1}`` gives a loss probability of ``0.1``).

The survival and lossy operators together satisfy
``\sum_k S_k^\dagger S_k + \Lambda = I``, where ``S_k`` are the non-lossy
branches.

If the channel has no lossy operators, the zero matrix is returned.

See also [`Kraus`](@ref), [`lossoperators`](@ref), [`survivaloperators`](@ref).

## Examples

```jldoctests
julia> g = Kraus([[1 0; 0 sqrt(0.9)], LossyOperator([0 sqrt(0.1); 0 0])]);

julia> losseffect(g)
1-qubit Operator:
├── 0.0 0.0
└── 0.0 0.1
```

The result shows that ``|0\rangle`` has zero loss probability and ``|1\rangle``
has 10% loss probability. For a state ``\alpha|0\rangle + \beta|1\rangle`` the
total loss probability is ``0.1|\beta|^2``.
"""
function losseffect(kraus::AbstractKrausChannel; tol::Real=1e-12)
    M = 1 << numqubits(kraus)
    loss_ops = lossoperators(kraus)
    isempty(loss_ops) && return Operator(zeros(ComplexF64, M, M))

    effect = matrix(opsquared(loss_ops[1]))
    for op in loss_ops[2:end]
        effect += matrix(opsquared(op))
    end

    if !any(issymbolic, effect)
        effect = map(x -> abs(x) < tol ? zero(x) : x, effect)
    end

    return Operator(Matrix(effect))
end
