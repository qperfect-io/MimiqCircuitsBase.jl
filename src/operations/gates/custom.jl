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
    struct GateCustom{N,T} <: AbstractGate{N}

`N` qubit gate specified by a ``2^N \times 2^N`` matrix with elements of type
`T`.

Use this to construct your own gates based on unitary matrices.

!!! note
    Only one and two qubits gates are supported.

MIMIQ uses textbook convention for specifying gates.

One qubit gate matrices are defined in the basis ``|0\rangle``, ``|1\rangle``
e.g.,

```math
\operatorname{Z} =
\begin{pmatrix}
    1&0\\
    0&-1
\end{pmatrix}
```

Two qubit gate matrices are defined in the basis ``|00\rangle``,
``|01\rangle``>, ``|10\rangle``, ``|11\rangle`` where the left-most qubit is
the first to appear in the target list
e.g.,

```math
\operatorname{CNOT} =
\begin{pmatrix}
    1&0&0&0\\
    0&1&0&0\\
    0&0&0&1\\
    0&0&1&0
\end{pmatrix}
```

```
julia> CNOT = [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]
4×4 Matrix{Int64}:
 1  0  0  0
 0  1  0  0
 0  0  0  1
 0  0  1  0

julia> # CNOT gate with control on q1 and target on q2

julia> Instruction(GateCustom(CNOT), 1, 2)
GateCustom([1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]) @ q1, q2

# Examples

```jldoctest
julia> g = GateCustom([1 0; 0 1])
Custom([1.0 0.0; 0.0 1.0])

julia> push!(Circuit(), g, 1)
1-qubit circuit with 1 instructions:
└── Custom([1.0 0.0; 0.0 1.0]) @ q1
```
"""
struct GateCustom{N} <: AbstractGate{N}
    U::Matrix{Complex{Num}}

    function GateCustom{N}(U) where {N}
        if N < 1
            error("Cannot define 0-qubit custom gate")
        end
        if N > 2
            error("Custom gates larger than 2 qubits are not supported")
        end

        M = 1 << N
        if ndims(U) != 2 || size(U, 1) != M || size(U, 2) != M
            throw(ArgumentError("Custom matrix should be $(M)×$(M)."))
        end

        # first check if 
        issymbolic = any(U) do x
            if isa(x, Complex{Num})
                return !(Symbolics.value(real(x)) isa Number) || !(Symbolics.value(imag(x)) isa Number)
            end

            if x isa Num
                return !(Symbolics.value(x) isa Number)
            end

            return false
        end

        if !issymbolic && !isapprox(U * adjoint(U), Matrix(I, M, M), rtol=1e-8)
            throw(ArgumentError("Custom matrix not unitary (U⋅adjoint(U) ≉ I)."))
        end

        return new{N}(U)
    end
end

function GateCustom(U::AbstractMatrix)
    dim = size(U, 1)
    if !isvalidpowerof2(dim)
        throw(ArgumentError("Dimension of custom matrix has to be 2^n with n>=1."))
    end
    #N = size(U, 1) >> 2 + 1
    N = Int(log2(dim))
    fU = float.(U)
    GateCustom{N}(fU)
end

opname(::Type{<:GateCustom}) = "Custom"

inverse(g::GateCustom) = GateCustom(inv(g.U))

matrix(g::GateCustom) = g.U

_matrix(::Type{GateCustom{N}}, U...) where {N} = reshape(collect(U), 2^N, 2^N)

function unwrappedmatrix(g::GateCustom)
    return unwrapvalue.(g.U)
end

parnames(::GateCustom{N}) where {N} = tuple(1:2^(2N)...)

parnames(::Type{<:GateCustom{N}}) where {N} = tuple(1:2^(2N)...)

getparam(g::GateCustom, i) = g.U[i]

getparams(g::GateCustom) = g.U

function Base.show(io::IO, gate::GateCustom)
    print(io, "GateCustom", "(")
    io1 = IOContext(io, :compact => get(io, :compact, false), :typeinfo => Array{Symbolics.Num})
    print(io, _decomplex(matrix(gate)))
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", gate::GateCustom{N}) where {N}
    U = _decomplex(matrix(gate))
    if get(io, :compact, false)
        print(io, opname(gate))
        if get(io, :limit, false) && N > 1
            print(io, "(…)")
            return nothing
        end
        print(io, "([")

        if N <= 1
            join(io, map(x -> join(x, " "), eachrow(U)), "; ")
        else
            join(io, U[1:2], " ")
            print(io, " … ")
            join(io, U[end-1:end], " ")
        end
        print(io, "])")
        return nothing
    end

    print(io, numqubits(gate), "-qubit ", opname(gate), ":\n")
    a = axes(U, 1)
    for i in a[1:end-1]
        print("├── ")
        join(io, U[i, :], " ")
        print('\n')
    end
    print("└── ")
    join(io, U[a[end], :], " ")
end
