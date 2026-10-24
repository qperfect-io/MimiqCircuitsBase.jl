#
# Copyright © 2026 QPerfect. All Rights Reserved.
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

# Two-qubit KAK (Cartan) decomposition and minimal-CX synthesis.
#
# Every U ∈ U(4) can be written as
#
#     U = e^{iφ} (A1 ⊗ A2) exp(i(a XX + b YY + c ZZ)) (B1 ⊗ B2)
#
# and the number of CX gates U needs is read off (a, b, c) alone. The magic
# basis is what makes this computable: in it, SU(2) ⊗ SU(2) is exactly SO(4),
# so the local factors become real orthogonal matrices around a diagonal core.

const _MAGIC = ComplexF64[1 0 0 im; 0 im 1 0; 0 im -1 0; 1 0 0 -im] / sqrt(2)

const _KAK_X = ComplexF64[0 1; 1 0]
const _KAK_Y = ComplexF64[0 -im; im 0]
const _KAK_Z = ComplexF64[1 0; 0 -1]
const _KAK_I = ComplexF64[1 0; 0 1]

# The magic basis vectors are Bell states, so each is an eigenvector of XX, YY
# and ZZ. Row j holds (1, ⟨XX⟩, ⟨YY⟩, ⟨ZZ⟩) of vector j: the phases of the
# diagonal core are this matrix times (φ, a, b, c).
const _KAK_SIGNS = let
    S = ones(4, 4)
    for j in 1:4, (k, P) in enumerate((_KAK_X, _KAK_Y, _KAK_Z))
        v = _MAGIC[:, j]
        S[j, k+1] = real(v' * kron(P, P) * v)
    end
    S
end

# Eigenvectors of a real symmetric matrix, as the columns of an orthogonal
# matrix, by cyclic Jacobi rotations. Written out rather than calling LAPACK so
# that the result does not depend on the LAPACK build.
function _jacobi_eigvecs(S::AbstractMatrix{Float64})
    A = Matrix{Float64}(S)
    n = size(A, 1)
    V = Matrix{Float64}(I, n, n)
    for _ in 1:50
        off = 0.0
        for i in 1:n, j in 1:n
            i != j && (off += A[i, j]^2)
        end
        off <= 1e-30 && break
        for p in 1:n-1, q in p+1:n
            A[p, q] == 0 && continue
            # The rotation that zeroes A[p, q] (Numerical Recipes, §11.1).
            θ = (A[q, q] - A[p, p]) / (2 * A[p, q])
            t = (θ >= 0 ? 1.0 : -1.0) / (abs(θ) + sqrt(θ^2 + 1))
            c = 1 / sqrt(t^2 + 1)
            s = t * c
            for k in 1:n
                akp, akq = A[k, p], A[k, q]
                A[k, p], A[k, q] = c * akp - s * akq, s * akp + c * akq
            end
            for k in 1:n
                apk, aqk = A[p, k], A[q, k]
                A[p, k], A[q, k] = c * apk - s * aqk, s * apk + c * aqk
            end
            for k in 1:n
                vkp, vkq = V[k, p], V[k, q]
                V[k, p], V[k, q] = c * vkp - s * vkq, s * vkp + c * vkq
            end
        end
    end
    return V
end

# Orthogonal P with Pᵀ M P diagonal, for a complex symmetric unitary M. Its real
# and imaginary parts are commuting real symmetric matrices, so a generic real
# combination of them has the common eigenvectors. "Generic" can fail on
# degenerate spectra, hence the retries over a fixed list of combinations.
function _simultaneous_real_diagonalization(M::AbstractMatrix)
    for k in 0:19
        t = 0.3 + 1.1 * k
        P = _jacobi_eigvecs(cos(t) * real(M) + sin(t) * imag(M))
        D = transpose(P) * M * P
        norm(D - Diagonal(diag(D))) < 1e-10 && return P
    end
    throw(ArgumentError("matrix is not a symmetric unitary"))
end

# (A, B) with kron(A, B) == K for a 4×4 matrix K of tensor-product form. With
# K[(i,j),(k,l)] = A[i,k] B[j,l], fixing (j, l) at the largest entry gives A up
# to a factor, and fixing (i, k) there gives B up to the inverse factor.
function _kron_factor(K::AbstractMatrix)
    r, c = Tuple(argmax(abs.(K)))
    i0, j0 = divrem(r - 1, 2)
    k0, l0 = divrem(c - 1, 2)
    A = ComplexF64[K[2i+j0+1, 2k+l0+1] for i in 0:1, k in 0:1]
    B = ComplexF64[K[2i0+j+1, 2k0+l+1] for j in 0:1, l in 0:1] / K[r, c]
    # Split the scale so that both factors are unitary.
    α = sqrt(det(A))
    return A / α, B * α
end

@doc raw"""
    _kak_decomposition(U) -> (φ, (A1, A2), (a, b, c), (B1, B2))

Decompose a 4×4 unitary as
``U = e^{iφ} (A_1 ⊗ A_2) \exp(i(a XX + b YY + c ZZ)) (B_1 ⊗ B_2)``,
with ``A_1`` acting on the first (most significant) qubit.
"""
function _kak_decomposition(U::AbstractMatrix)
    U = ComplexF64.(U)
    φ = angle(det(U)) / 4
    Up = _MAGIC' * (U * cis(-φ)) * _MAGIC

    P = _simultaneous_real_diagonalization(transpose(Up) * Up)
    det(P) < 0 && (P[:, 1] .*= -1)

    # Up = K1 D Pᵀ with D the square root of Pᵀ Upᵀ Up P. Choosing the roots
    # with det(D) = 1 is what puts K1 in SO(4) rather than O(4).
    d = angle.(diag(transpose(P) * transpose(Up) * Up * P)) ./ 2
    cos(sum(d)) < 0 && (d[1] += π)
    K1 = real(Up * P * Diagonal(cis.(-d)))

    A1, A2 = _kron_factor(_MAGIC * K1 * _MAGIC')
    B1, B2 = _kron_factor(_MAGIC * transpose(P) * _MAGIC')
    ψ, a, b, c = _KAK_SIGNS \ d
    return φ + ψ, (A1, A2), (a, b, c), (B1, B2)
end

# A gate of a synthesized block: (code, parameters, local qubits), with the
# codes of `_GateCode` in circuit/simplify/table.jl.
const _KAKGate = Tuple{Any,Vector{Float64},Vector{Int}}

# exp(i(aXX + bYY + cZZ)) with its coordinates already placed where each
# template expects them, as gates on local qubits 1 and 2. Correct up to a
# global phase, which the caller restores.
function _kak_core(k::Int, (a, b, c))
    if k == 0
        return _KAKGate[]
    elseif k == 1
        # exp(iπ/4 ZZ) is CZ up to Z-rotations, and CZ is CX up to Hadamards.
        return _KAKGate[
            (_CODE_H, [], [2]), (_CODE_CX, [], [1, 2]), (_CODE_H, [], [2]),
            (_CODE_RZ, [-π / 2], [1]), (_CODE_RZ, [-π / 2], [2]),
        ]
    elseif k == 2
        # CX turns X1 into XX and Z2 into ZZ, so b must be zero.
        return _KAKGate[
            (_CODE_CX, [], [1, 2]),
            (_CODE_RX, [-2a], [1]), (_CODE_RZ, [-2c], [2]),
            (_CODE_CX, [], [1, 2]),
        ]
    else
        # Vatan and Williams, Phys. Rev. A 69, 032315 (2004), Fig. 6.
        return _KAKGate[
            (_CODE_RZ, [π / 2], [2]),
            (_CODE_CX, [], [2, 1]),
            (_CODE_RZ, [-π / 2 - 2c], [1]), (_CODE_RY, [-π / 2 - 2a], [2]),
            (_CODE_CX, [], [1, 2]),
            (_CODE_RY, [π / 2 + 2b], [2]),
            (_CODE_CX, [], [2, 1]),
            (_CODE_RZ, [-π / 2], [1]),
        ]
    end
end

# Clifford W with (W⊗W) exp(i(aXX+bYY+cZZ)) (W⊗W)† swapping two coordinates.
# W maps each Pauli to ± another, and the signs square away on P⊗P.
const _KAK_SWAPS = Dict(
    (1, 2) => ComplexF64[1 0; 0 im],                       # S: X ↔ Y
    (1, 3) => ComplexF64[1 1; 1 -1] / sqrt(2),             # H: X ↔ Z
    (2, 3) => ComplexF64[1 -im; -im 1] / sqrt(2),          # RX(π/2): Y ↔ Z
)

@doc raw"""
    _kak_synthesis(U; atol=1e-9) -> (ncx, gates)

Synthesize a 4×4 unitary `U` acting on local qubits 1 and 2 with the fewest CX
gates, between zero and three, as `(code, parameters, qubits)` triples.
Single-qubit gates are emitted as `GateU`, and the global phase of `U` is
reproduced exactly.
"""
function _kak_synthesis(U::AbstractMatrix; atol=1e-9)
    _, (A1, A2), coords, (B1, B2) = _kak_decomposition(U)
    coords = collect(coords)
    paulis = (_KAK_X, _KAK_Y, _KAK_Z)

    # exp(i x PP) shifted by kπ/2 is exp(i x PP) times i^k (P⊗P)^k, which is
    # local: reduce each coordinate to [-π/4, π/4] and fold the rest into B.
    for (j, P) in enumerate(paulis)
        k = round(Int, coords[j] / (π / 2))
        coords[j] -= k * π / 2
        isodd(k) && ((B1, B2) = (P * B1, P * B2))
    end

    iszero_(x) = abs(x) < atol
    nzero = count(iszero_, coords)
    nquarter = count(x -> abs(abs(x) - π / 4) < atol, coords)
    k = nzero == 3 ? 0 : (nzero == 2 && nquarter == 1) ? 1 : nzero >= 1 ? 2 : 3

    # Bring the coordinate each template cares about into its slot: the
    # quarter turn to ZZ for one CX, the zero to YY for two.
    target, wanted = k == 1 ? (3, findfirst(x -> !iszero_(x), coords)) :
                     k == 2 ? (2, findfirst(iszero_, coords)) : (0, 0)
    if target != 0 && wanted != target
        W = _KAK_SWAPS[minmax(wanted, target)]
        coords[wanted], coords[target] = coords[target], coords[wanted]
        A1, A2 = A1 * W', A2 * W'
        B1, B2 = W * B1, W * B2
    end
    # A one-CX core must be exactly exp(+iπ/4 ZZ); the negative quarter turn
    # differs from it by the local ZZ.
    if k == 1 && coords[3] < 0
        coords[3] += π / 2
        B1, B2 = _KAK_Z * B1, _KAK_Z * B2
    end

    _ugate(M, q) = (_CODE_U, collect(Float64, _zyz_decomposition(M)), [q])
    gates = _KAKGate[_ugate(B1, 1), _ugate(B2, 2)]
    append!(gates, _kak_core(k, coords))
    push!(gates, _ugate(A1, 1), _ugate(A2, 2))

    # Every step above holds only up to a global phase: measure it and put it
    # in the last single-qubit gate, so the result is exact.
    V = _foldmatrices([_embedmatrix(_codematrix(code, params), qs, 2) for (code, params, qs) in gates],
        2, ComplexF64)
    i = argmax(abs.(V))
    χ = angle(U[i] / V[i])
    norm(U - cis(χ) * V) < 1e-8 || error("two-qubit synthesis failed to reproduce the unitary")
    gates[end][2][4] += χ
    return k, gates
end
