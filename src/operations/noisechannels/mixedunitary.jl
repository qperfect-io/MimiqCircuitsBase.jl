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
    MixedUnitary(p,U)

Custom ``N`` qubit mixed unitary channel specified by a list of
unitary gates and a list of probabilities that add up to 1.

A mixed unitary noise channel is defined by

```math
\mathcal{E}(\rho) = \sum_k p_k U_k \rho U_k^\dagger,
```

where ``0\leq p_k \leq 1`` and ``U_k`` are unitary matrices.
The probabilities must fulfill ``\sum_k p_k = 1``.

If your Kraus matrices are not all proportional to unitaries, use [`Kraus`](@ref) instead.

The Kraus matrices are defined in the computational basis in the usual textbook
order (the first qubit corresponds to the left-most qubit).
For 1 qubit we have ``|0\rangle``, ``|1\rangle``.
For 2 qubits we have ``|00\rangle``, ``|01\rangle``, ``|10\rangle``, ``|11\rangle``.
See also [`GateCustom`](@ref).

!!! note
    Currently only 1 and 2-qubit custom MixedUnitary channels are supported.

See also [`Kraus`](@ref), [`ismixedunitary`](@ref), [`AbstractKrausChannel`](@ref),
and [`RescaledGate`](@ref).

## Arguments

* `p`: Vector of probabilities, must be positive real numbers and add up to 1.
* `U`: Vector of either complex-valued ``2^N \times 2^N`` matrices or unitary gates acting
  on ``N`` qubits. Both can be mixed.

The length of the vectors `p` and `U` must be equal.

## Examples

```jldoctests
julia> push!(Circuit(), MixedUnitary([0.9, 0.1], [[1 0; 0 1], [0 1; 1 0]]), 1)
1-qubit circuit with 1 instructions:
└── MixedUnitary((0.9,Custom([1.0 0.0; 0.0 1.0])),(0.1,Custom([0.0 1.0; 1.0 0.0]))) @ q[1]

julia> push!(Circuit(), MixedUnitary([0.8, 0.2], [GateID(), GateRX(0.2)]), 1)
1-qubit circuit with 1 instructions:
└── MixedUnitary((0.8,ID),(0.2,RX(0.2))) @ q[1]

julia> push!(Circuit(), MixedUnitary([0.8, 0.2], [[1 0; 0 1], GateRX(0.2)]), 1)
1-qubit circuit with 1 instructions:
└── MixedUnitary((0.8,Custom([1.0 0.0; 0.0 1.0])),(0.2,RX(0.2))) @ q[1]

julia> @variables x
1-element Vector{Symbolics.Num}:
 x

julia> g= MixedUnitary([0.9, x], [[1 0; 0 1], [0 1; 1 0]])
MixedUnitary((0.9, Custom([1.0 0.0; 0.0 1.0])), (x, Custom([0.0 1.0; 1.0 0.0])))

julia> evaluate(g,Dict(x=>.1))
MixedUnitary((0.9, Custom([1.0 0.0; 0.0 1.0])), (0.1, Custom([0.0 1.0; 1.0 0.0])))

julia> g= MixedUnitary([0.9, 0.1], [[1 0; 0 1], [0 1; 1 x]])
MixedUnitary((0.9, Custom([1 0; 0 1])), (0.1, Custom([0 1; 1 x])))

julia> evaluate(g,Dict(x=>0))
MixedUnitary((0.9, Custom([1 0; 0 1])), (0.1, Custom([0 1; 1 0])))
```
"""
struct MixedUnitary{N} <: AbstractKrausChannel{N}
    p::Vector{Num}
    U::Vector{AbstractGate}

    function MixedUnitary{N}(p::Vector{<:Number}, U::Vector{<:AbstractGate}) where {N}
        if N < 1
            error("Cannot define a 0-qubit custom noise channel")
        end

        if N > 2
            error("Custom noise channels larger than 2 qubits are not supported")
        end

        if length(p) != length(U)
            throw(ArgumentError("Lists of probabilities and unitaries must have the same length."))
        end

        # Helper function to detect symbolic elements in the probability vector
        function contains_symbolic_elements(vector)
            any(x -> !isreal(Symbolics.value(x)), vector)
        end

        # Perform probability sum check if all probabilities are concrete
        if !contains_symbolic_elements(p) && !isapprox(sum(p), 1, rtol=1e-13)
            sump = sum(p)
            throw(ArgumentError("Probabilities should sum to 1. Instead they are $sump"))
        end

        return new{N}(p, U)
    end
end

function evaluate(m::MixedUnitary, d::Dict=Dict())
    # Substitute values in each element of the probability vector `p`
    evaluated_p = [Symbolics.substitute(prob, d) for prob in m.p]

    # Substitute values within each unitary in `U`
    evaluated_U = [
        u isa GateCustom ?
        GateCustom(map(x -> Symbolics.substitute(x, d), u.U)) :
        map(x -> Symbolics.substitute(x, d), getparams(u)) |> (args -> typeof(u)(args...))
        for u in m.U
    ]

    # Return a new MixedUnitary instance with evaluated probabilities and updated unitaries
    return MixedUnitary(evaluated_p, evaluated_U)
end

function MixedUnitary(p::Vector{<:Number}, U::Vector{<:AbstractGate})
    if isempty(p) || isempty(U)
        error("Vectors of probabilities and unitaries cannot be empty")
    end

    N = numqubits(U[1])
    if !all(map(x -> x == N, numqubits.(U)))
        error("Gates acting on different numbers of qubits provided.")
    end

    return MixedUnitary{N}(p, U)
end

function MixedUnitary(p::Vector{<:Number}, U::Vector)
    if isempty(p) || isempty(U)
        error("Vectors of probabilities and unitary matrices cannot be empty")
    end

    Us = map(U) do x
        if x isa AbstractGate
            return x
        elseif x isa AbstractMatrix
            return GateCustom(x)
        else
            throw(ArgumentError("Invalid object of type $(typeof(x)) is not a valid unitary. Use gates or matrices."))
        end
    end

    N = numqubits(Us[1])
    if !all(map(x -> x == N, numqubits.(Us)))
        error("Gates acting on different numbers of qubits provided.")
    end

    return MixedUnitary{N}(p, Us)
end

function MixedUnitary(kraus::Vector{<:RescaledGate})
    MixedUnitary(getscale.(kraus) .^ 2, getoperation.(kraus))
end

opname(::Type{<:MixedUnitary}) = "MixedUnitary"

probabilities(mixedU::MixedUnitary) = mixedU.p

unitarygates(mixedU::MixedUnitary) = mixedU.U

ismixedunitary(::Type{T}) where {T<:MixedUnitary} = true

function krausoperators(mixedU::MixedUnitary)
    gates = unitarygates(mixedU)
    scales = sqrt.(probabilities(mixedU))
    return RescaledGate.(gates, scales)
end

function Base.show(io::IO, mixedu::MixedUnitary)
    print(io, opname(mixedu), "(")
    sep = get(io, :compact, false) ? "," : ", "
    ps = probabilities(mixedu)
    Us = unitarygates(mixedu)
    join(io, Iterators.map(x -> (x[1], repr(x[2]; context=:compact => true)), zip(ps, Us)), sep)
    print(io, ")")
end

function Base.show(io::IO, m::MIME"text/plain", mixedu::MixedUnitary)
    print(io, opname(mixedu), "(")
    sep = get(io, :compact, false) ? "," : ", "
    ps = probabilities(mixedu)
    Us = unitarygates(mixedu)
    join(io, Iterators.map(x -> "($(x[1])$(sep)$(repr(m, x[2]; context=:compact => true)))", zip(ps, Us)), sep)
    print(io, ")")
end
