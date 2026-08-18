#
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

function matrix(inst::Instruction{1,0,0,<:AbstractGate})
    return matrix(getoperation(inst))
end

function matrix(inst::Instruction{2,0,0,<:AbstractGate})
    M = copy(matrix(getoperation(inst)))
    if !issorted(getqubits(inst))
        Base.swaprows!(M, 2, 3)
        Base.swapcols!(M, 2, 3)
    end
    return M
end

function matrix(inst::Instruction{N,0,0,<:AbstractGate}) where {N}
    matrix(inst, N)
end

function matrix(inst::Instruction{N,0,0,<:AbstractGate}, L) where {N}
    op = getoperation(inst)
    M = matrix(op)
    qubits = getqubits(inst)

    # NOTE: copying here becasue singleton gates behaviour
    if numparams(op) == 0
        return _reorder_qubits_matrix!(Matrix(deepcopy(M)), qubits, L)
    end

    return _reorder_qubits_matrix!(Matrix(M), qubits, L)
end

# Whether a gate-matrix element type carries symbolic expressions. Gate matrices
# span `Int64`, `Float64`, `ComplexF64`, `Num` (`GateRY` with a symbolic angle)
# and `Complex{Num}`; note that Symbolics leaves `promote_type(ComplexF64, Num)`
# ambiguous, so these types must be classified rather than promoted.
_issymbolictype(::Type{T}) where {T} = T <: Num || T <: Complex{<:Num}

# Product of already-embedded factors in circuit order (later gate on the left),
# all converted to `T` up front so every step is one BLAS call.
function _foldmatrices(Ms, N, ::Type{T}) where {T}
    factors = [convert(Matrix{T}, M) for M in Ms]
    return foldl(*, Iterators.reverse(factors); init=Matrix{T}(I, 2^N, 2^N))
end

function matrix(insts::Vector{<:Instruction})
    N = numqubits(insts)

    Ms = map(inst -> matrix(inst, N), insts)

    # Always `Matrix{Complex{Num}}`, as before: making the element type depend on
    # whether any gate happens to be symbolic would make the return type a
    # function of the argument's *value*, and every caller type-unstable with it.
    #
    # A numeric circuit still gets the fast path — the product runs in
    # `ComplexF64` and is converted once at the end, rather than putting every
    # intermediate through SymbolicUtils. Callers that want the numeric matrix
    # itself, and can establish that nothing is symbolic, should fold with
    # `_foldmatrices(..., ComplexF64)` directly; `fuse` does.
    if !isempty(Ms) && !any(M -> _issymbolictype(eltype(M)), Ms)
        return convert(Matrix{Complex{Num}}, _foldmatrices(Ms, N, ComplexF64))
    end

    return _foldmatrices(Ms, N, Complex{Num})
end
