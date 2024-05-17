#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
# See AUTHORS.md for the list of authors.
#


@doc raw"""
    struct GateCustom{N,T} <: AbstractGate{N}

`N` qubit gate specified by a ``2^N \times 2^N`` matrix with elements of type
`T`.

Use this to construct your own gates based on unitary matrices.
Currently only N=1,2 (M=2,4) are recognised.

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
    N = size(U, 1) >> 2 + 1
    fU = float.(U)
    GateCustom{N}(fU)
end

opname(::Type{<:GateCustom}) = "Custom"

inverse(g::GateCustom) = GateCustom(inv(g.U))

matrix(g::GateCustom) = g.U

function _matrix(::Type{GateCustom{N}}, params...) where {N}
    reshape(collect(params), 2^N, 2^N)
end

function unwrappedmatrix(g::GateCustom)
    return unwrapvalue.(g.U)
end

parnames(::GateCustom{N}) where {N} = tuple(1:2^(2N)...)

parnames(::Type{<:GateCustom{N}}) where {N} = tuple(1:2^(2N)...)

getparam(g::GateCustom, i) = g.U[i]

getparams(g::GateCustom) = g.U

function Base.show(io::IO, gate::GateCustom)
    print(io, opname(gate), "(")
    io1 = IOContext(io, :compact => true)
    print(io1, gate.U)
    print(io, ")")
end
