#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
# See AUTHORS.md for the list of authors.
#


@doc raw"""
    struct GateCustom{N,T} <: Gate{N}

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
1-qubit circuit with 1 gates:
└── Custom([1.0 0.0; 0.0 1.0]) @ q1
```
"""
struct GateCustom{N,T<:Number} <: Gate{N}
    U::Matrix{T}
    a::Union{Float64,ComplexF64}
    b::Union{Float64,ComplexF64}
    c::Union{Float64,ComplexF64}
    d::Union{Float64,ComplexF64}

    function GateCustom{N,T}(U::AbstractMatrix{T}) where {N,T}
        M = 1 << N
        if size(U, 1) != M || size(U, 2) != M
            error("Wrong matrix dimension for a $N qubit gate")
        end

        if !(U * adjoint(U) ≈ Matrix(I, M, M))
            @warn "Custom gate matrix U is not unitary." U
        end

        return new{N,T}(
            U,
            _decomplex(U[1, 1]),
            _decomplex(U[2, 1]),
            _decomplex(U[1, 2]),
            _decomplex(U[2, 2]),
        )
    end
end

function GateCustom(U::AbstractMatrix{T}) where {T<:Number}
    N = size(U, 1) >> 2 + 1
    GateCustom{N,float(T)}(float.(U))
end

opname(::Type{<:GateCustom}) = "Custom"

inverse(g::GateCustom) = Gate(adjoint(g.U))

@inline matrix(g::GateCustom) = g.U

function Base.show(io::IO, gate::GateCustom)
    print(io, opname(gate), "(")
    io1 = IOContext(io, :compact => true)
    print(io1, gate.U)
    print(io, ")")
end
