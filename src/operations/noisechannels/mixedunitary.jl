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
1-qubit circuit with 1 instruction:
└── MixedUnitary((0.9,Custom([1.0 0.0; 0.0 1.0])),(0.1,Custom([0.0 1.0; 1.0 0.0]))) @ q[1]

julia> push!(Circuit(), MixedUnitary([0.8, 0.2], [GateID(), GateRX(0.2)]), 1)
1-qubit circuit with 1 instruction:
└── MixedUnitary((0.8,ID),(0.2,RX(0.2))) @ q[1]

julia> push!(Circuit(), MixedUnitary([0.8, 0.2], [[1 0; 0 1], GateRX(0.2)]), 1)
1-qubit circuit with 1 instruction:
└── MixedUnitary((0.8,Custom([1.0 0.0; 0.0 1.0])),(0.2,RX(0.2))) @ q[1]

julia> @variables x
1-element Vector{Symbolics.Num}:
 x

julia> g= MixedUnitary([0.9, x], [[1 0; 0 1], [0 1; 1 0]])
MixedUnitary((0.9, Custom([1.0 0.0; 0.0 1.0])), (x, Custom([0.0 1.0; 1.0 0.0])))

julia> evaluate(g,Dict(x=>.1))
MixedUnitary((0.9, Custom([1.0 0.0; 0.0 1.0])), (0.1, Custom([0.0 1.0; 1.0 0.0])))

julia> g= MixedUnitary([0.9, 0.1], [[1 0; 0 1], [0 1; 1 x]])
ERROR: MimiqCircuitsBase.UndefinedValue(x)
Stacktrace:
  [1] unwrapvalue(g::Symbolics.Num)
    @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/utils.jl:159
  [2] _broadcast_getindex_evalf
    @ ./broadcast.jl:699 [inlined]
  [3] _broadcast_getindex
    @ ./broadcast.jl:672 [inlined]
  [4] _getindex
    @ ./broadcast.jl:620 [inlined]
  [5] getindex
    @ ./broadcast.jl:616 [inlined]
  [6] copyto_nonleaf!(dest::Matrix{Int64}, bc::Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{2}, Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}, typeof(MimiqCircuitsBase.unwrapvalue), Tuple{Base.Broadcast.Extruded{Matrix{Symbolics.Num}, Tuple{Bool, Bool}, Tuple{Int64, Int64}}}}, iter::CartesianIndices{2, Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}}, state::CartesianIndex{2}, count::Int64)
    @ Base.Broadcast ./broadcast.jl:1104
  [7] copy
    @ ./broadcast.jl:941 [inlined]
  [8] materialize
    @ ./broadcast.jl:894 [inlined]
  [9] GateCustom{1}(U::Matrix{Symbolics.Num})
    @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/gates/custom.jl:106
 [10] GateCustom(U::Matrix{Symbolics.Num})
    @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/gates/custom.jl:123
 [11] #MixedUnitary##2
    @ ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/noisechannels/mixedunitary.jl:205 [inlined]
 [12] iterate
    @ ./generator.jl:48 [inlined]
 [13] collect_to!(dest::Vector{GateCustom{1}}, itr::Base.Generator{Vector{Matrix{Symbolics.Num}}, MimiqCircuitsBase.var"#MixedUnitary##2#MixedUnitary##3"}, offs::Int64, st::Int64)
    @ Base ./array.jl:848
 [14] collect_to_with_first!(dest::Vector{GateCustom{1}}, v1::GateCustom{1}, itr::Base.Generator{Vector{Matrix{Symbolics.Num}}, MimiqCircuitsBase.var"#MixedUnitary##2#MixedUnitary##3"}, st::Int64)
    @ Base ./array.jl:826
 [15] _collect(c::Vector{Matrix{Symbolics.Num}}, itr::Base.Generator{Vector{Matrix{Symbolics.Num}}, MimiqCircuitsBase.var"#MixedUnitary##2#MixedUnitary##3"}, ::Base.EltypeUnknown, isz::Base.HasShape{1})
    @ Base ./array.jl:820
 [16] collect_similar
    @ ./array.jl:732 [inlined]
 [17] map
    @ ./abstractarray.jl:3372 [inlined]
 [18] MixedUnitary(p::Vector{Float64}, U::Vector{Matrix{Symbolics.Num}})
    @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/noisechannels/mixedunitary.jl:201
 [19] top-level scope
    @ none:1

julia> evaluate(g,Dict(x=>0))
ERROR: ArgumentError: Probabilities should sum to 1. Instead they are 0.9
Stacktrace:
 [1] MixedUnitary{1}(p::Vector{Symbolics.Num}, U::Vector{GateCustom{1}})
   @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/noisechannels/mixedunitary.jl:160
 [2] MixedUnitary(p::Vector{Symbolics.Num}, U::Vector{GateCustom{1}})
   @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/noisechannels/mixedunitary.jl:193
 [3] evaluate(m::MixedUnitary{1}, d::Dict{Symbolics.Num, Int64})
   @ MimiqCircuitsBase ~/QPerfect/Code/MimiqCircuitsBase.jl/src/operations/noisechannels/mixedunitary.jl:180
 [4] top-level scope
   @ none:1
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
            any(x -> issymbolic(x), vector)
        end

        # Perform probability sum check if all probabilities are concrete
        if !contains_symbolic_elements(p) && !isapprox(sum(unwrapvalue.(p)), 1, rtol=1e-13)
            sump = sum(p)
            throw(ArgumentError("Probabilities should sum to 1. Instead they are $sump"))
        end

        return new{N}(p, U)
    end
end

function evaluate(m::MixedUnitary, d::Dict=Dict())
    # Substitute values in each element of the probability vector `p`
    evaluated_p = map(m.p) do prob
        value = Symbolics.substitute(prob, d)
        issymbolic(value) ? value : unwrapvalue(value)
    end

    # Substitute values within each unitary in `U`
    evaluated_U = [
        u isa GateCustom ?
        GateCustom(map(u.U) do x
            value = Symbolics.substitute(x, d)
            issymbolic(value) ? value : unwrapvalue(value)
        end) :
        map(getparams(u)) do x
            value = Symbolics.substitute(x, d)
            issymbolic(value) ? value : unwrapvalue(value)
        end |> (args -> typeof(u)(args...))
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

function Base.:(==)(left::MixedUnitary, right::MixedUnitary)
    typeof(left) == typeof(right) || return false

    # check the probabilities
    for (pl, pr) in zip(probabilities(left), probabilities(right))
        # one symbolic one not
        issymbolic(pl) == issymbolic(pr) || return false

        # both symbolic
        if issymbolic(pl) && issymbolic(pr)
            pl === pr || return false
        end

        # both are not symbolic
        isequal(pl, pr) || return false
    end

    unitarygates(left) == unitarygates(right) || return false

    return true
end
