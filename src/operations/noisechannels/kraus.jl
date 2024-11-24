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

See also [`MixedUnitary`](@ref), [`AbstractKrausChannel`](@ref).

## Arguments

* `E`: Vector of ``2^N \times 2^N`` complex matrices or ``N`` qubit operators.
  Both can be mixed.

## Examples

```jldoctests
julia> push!(Circuit(), Kraus([[1 0; 0 sqrt(0.9)], [0 sqrt(0.1); 0 0]]), 1)
1-qubit circuit with 1 instructions:
└── Kraus(Operator([1.0 0.0; 0.0 0.948683]), Operator([0.0 0.316228; 0.0 0.0])) @ q[1]

julia> push!(Circuit(), Kraus([Projector0(), Projector1()]), 1)
1-qubit circuit with 1 instructions:
└── Kraus(Projector0(1), Projector1(1)) @ q[1]

julia> push!(Circuit(), Kraus([[1 0; 0 0], Projector1()]), 1)
1-qubit circuit with 1 instructions:
└── Kraus(Operator([1.0 0.0; 0.0 0.0]), Projector1(1)) @ q[1]

julia> @variables x
1-element Vector{Symbolics.Num}:
 x

julia> g = Kraus([Projector0(), Projector1(x)])
Kraus(Projector0(1), Projector1(x))

julia> evaluate(g,Dict(x=>1))
Kraus(Projector0(1), Projector1(1))

julia> g = Kraus([[1 0; 0 sqrt(0.9)], [0 sqrt(0.1); 0 x]])
Kraus(Operator([1.0 0.0; 0.0 0.948683]), Operator([0 0.316228; 0 x]))

julia> evaluate(g,Dict(x=>0))
Kraus(Operator([1.0 0.0; 0.0 0.948683]), Operator([0 0.316228; 0 0]))
```
"""
struct Kraus{N} <: AbstractKrausChannel{N}
    E::Vector{AbstractOperator}

    function Kraus{N}(E::Vector{<:AbstractOperator}) where {N}
        if N < 1
            error("Cannot define a 0-qubit custom noise channel")
        end
        if N > 2
            error("Custom noise channels larger than 2 qubits are not supported")
        end

        M = 1 << N

        # Helper function to detect symbolic elements in a matrix
        function contains_symbolic_elements(matrix)
            any(x -> !isreal(Symbolics.value(x)), matrix)
        end

        # Check if all matrices are non-symbolic, and apply normalization if so
        if !any(contains_symbolic_elements(matrix) for matrix in matrix.(E))
            # Perform normalization check only for purely numeric matrices
            ksum = sum(adjoint(Ek) * Ek for Ek in matrix.(E))
            if !isapprox(ksum, Matrix(I, M, M), rtol=1e-12)
                throw(ArgumentError("List of Kraus matrices should fulfill ``\\sum_k E_k^\\dagger E_k = I``."))
            end
        end

        return new{N}(E)
    end
end

function evaluate(k::Kraus, d::Dict=Dict())
    evaluated_E = [
        x isa Operator ?
        Operator(map(y -> Symbolics.substitute(y, d), x.O)) :  # For matrix-based operators
        x isa AbstractOperator ?
        map(y -> Symbolics.substitute(y, d), getparams(x)) |> (args -> typeof(x)(args...)) :
        x  # Leave other operators unchanged
        for x in k.E
    ]

    # Return a new Kraus instance with evaluated operators
    return Kraus(evaluated_E)
end


function Kraus(E::Vector{<:AbstractOperator})
    if isempty(E)
        error("Vector of Kraus matrices cannot be empty")
    end

    N = numqubits(E[1])
    if !all(map(x -> x == N, numqubits.(E)))
        error("Operators acting on different numbers of qubits provided.")
    end

    return Kraus{N}(E)
end

function Kraus(E::Vector)
    if isempty(E)
        error("Vector of Kraus matrices cannot be empty")
    end

    Es = map(E) do x
        if x isa AbstractOperator
            return x
        elseif x isa AbstractMatrix
            return Operator(x)
        else
            throw(ArgumentError("Invalid object of type $(typeof(x)) is not a valid operator. Use operators or matrices."))
        end
    end

    N = numqubits(Es[1])
    if !all(map(x -> x == N, numqubits.(Es)))
        error("Operators acting on different numbers of qubits provided.")
    end

    return Kraus{N}(Es)
end

opname(::Type{<:Kraus}) = "Kraus"

krausoperators(kraus::Kraus) = kraus.E

function Base.show(io::IO, kraus::Kraus)
    print(io, opname(kraus), "(")

    io1 = IOContext(io, :compact => true)

    print(io1, kraus.E[1])
    for matrix in kraus.E[2:end]
        print(io1, ", ")
        print(io1, matrix)
    end

    print(io, ")")
end
