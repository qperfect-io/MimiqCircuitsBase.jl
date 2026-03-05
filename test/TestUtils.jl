
module TestUtils

using Test
using Random
using LinearAlgebra
using Symbolics
using MimiqCircuitsBase

export areequal, randunitary, saveloadproto, testsaveloadproto

areequal(a, b) = a == b
areequal(a::T, b::T) where {T<:AbstractAnnotation} = getnotes(a) == getnotes(b)
function areequal(a::Num, b::Num)
    if issymbolic(a) != issymbolic(b)
        return false
    end
    if !issymbolic(a)
        return a == b
    end
    return string(simplify(a)) == string(simplify(b))
end
function areequal(a::T, b::T) where {T<:AbstractOperator}
    all(x -> areequal(x[1], x[2]), zip(getparams(a), getparams(b)))
end
areequal(a::GateCustom{N}, b::GateCustom{N}) where {N} = all(areequal.(matrix(a), matrix(b)))
areequal(a::Operator{N}, b::Operator{N}) where {N} = all(areequal.(matrix(a), matrix(b)))
areequal(a::Instruction{N,M,T}, b::Instruction{N,M,T}) where {N,M,T} = areequal(getoperation(a), getoperation(b)) && getqubits(a) == getqubits(b) && getbits(a) == getbits(b)
areequal(a::Circuit, b::Circuit) = all(x -> areequal(first(x), last(x)), zip(a._instructions, b._instructions))
areequal(a::IfStatement, b::IfStatement) = areequal(getoperation(a), getoperation(b)) && getbitstring(a) == getbitstring(b)
areequal(a::Repeat, b::Repeat) = areequal(getoperation(a), getoperation(b)) && numrepeats(a) == numrepeats(b)
areequal(a::HamiltonianTerm, b::HamiltonianTerm) = areequal(a.coefficient, b.coefficient) && areequal(a.operation, b.operation) && a.qubits == b.qubits
areequal(a::Hamiltonian, b::Hamiltonian) = all(x -> areequal(first(x), last(x)), zip(a.terms, b.terms))
areequal(a::Block, b::Block) = all(x -> areequal(first(x), last(x)), zip(a._instructions, b._instructions))

function randunitary(n::Integer)
    mat = rand(ComplexF64, n, n)
    exp(im .* (mat .+ adjoint(mat)))
end

function saveloadproto(c::T) where {T}
    mktemp() do fname, _
        saveproto(fname, c)
        return loadproto(fname, T)
    end
end

function testsaveloadproto(c)
    newc = saveloadproto(c)
    @test areequal(c, newc)
end

end # module
