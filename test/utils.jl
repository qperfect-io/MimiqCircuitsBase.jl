using Random
using LinearAlgebra

areequal(a, b) = a == b
areequal(a::GateCustom, b::GateCustom) = matrix(a) == matrix(b)
areequal(a::T, b::T) where {T<:ParametricGate} = all(p -> getfield(a, p) == getfield(b, p), parnames(a))
areequal(a::Instruction{N,M,T}, b::Instruction{N,M,T}) where {N,M,T} = areequal(getoperation(a), getoperation(b)) && getqubits(a) == getqubits(b) && getbits(a) == getbits(b)
areequal(a::Circuit, b::Circuit) = all(x -> areequal(first(x), last(x)), zip(a.instructions, b.instructions))
areequal(a::IfStatement, b::IfStatement) = areequal(a.op, b.op) && a.val == b.val

function randunitary(n::Integer)
    mat = rand(ComplexF64, n, n)
    exp(im .* (mat .+ adjoint(mat)))
end

