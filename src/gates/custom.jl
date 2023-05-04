#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
# See AUTHORS.md for the list of authors.
#


@doc raw"""
    struct Gate{N,M,T} <: AbstractGate{N}

`N` qubit gate specified by a `M`×`M` matrix with elements of type `T`.
Use this to construct your own gates based on unitary matrices.
Currently only N=1,2 (M=2,4) are recognised.

MIMIQ uses textbook convention for specifying gates

one qubit gate matrices are defined in the basis |0>, |1>
e.g.,
Z = [1  0; 
     0 -1]  

two qubit gate matrices are defined in the basis |00>, |01>, |10>, |11>
where the left-most qubit is the first to appear in the target list 

e.g.
CNOT = [1 0 0 0; 
        0 1 0 0; 
        0 0 0 1; 
        0 0 1 0]

CircuitGate(Gate(CNOT),1,2) # CNOT gate with control on q1 and target on q2

# Examples
```jldoctest
julia> g = Gate([1 0; 0 1])
Custom([1.0 0.0; 0.0 1.0])

julia> push!(Circuit(), g, 1)
1-qubit circuit with 1 gates:
└── Custom([1.0 0.0; 0.0 1.0]) @ q1
```
"""
struct Gate{N,T<:Number} <: AbstractGate{N}
    U::Matrix{T}
    a::Union{Float64,ComplexF64}
    b::Union{Float64,ComplexF64}
    c::Union{Float64,ComplexF64}
    d::Union{Float64,ComplexF64}

    function Gate{N,T}(U::AbstractMatrix{T}) where {N,T}
        M = 1 << N
        if size(U, 1) != M || size(U, 2) != M
            error("Wrong matrix dimension for a $N qubit gate")
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

function Gate(U::AbstractMatrix{T}) where {T<:Number}
    N = size(U, 1) >> 2 + 1
    Gate{N,float(T)}(float.(U))
end

gatename(::Type{<:Gate}) = "Custom"

inverse(g::Gate) = Gate(adjoint(g.U))

@inline matrix(g::Gate) = g.U

function Base.show(io::IO, gate::Gate)
    print(io, gatename(gate), "(")
    io1 = IOContext(io, :compact => true)
    print(io1, gate.U)
    print(io, ")")
end
