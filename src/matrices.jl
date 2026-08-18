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

pmatrix(λ) = [1 0; 0 cis(λ)]

pmatrixpi(λ) = [1 0; 0 cispi(λ)]

gphase(λ) = cis(λ)

gphasepi(λ) = cispi(λ)

function umatrix(θ, ϕ, λ, γ=0.0)
    sinθ2, cosθ2 = sincos(θ / 2)
    return [cis(γ)*cosθ2 -cis(λ + γ)*sinθ2; cis(ϕ + γ)*sinθ2 cis(ϕ + λ + γ)*cosθ2]
end

function umatrixpi(θ, ϕ, λ, γ=0.0)
    sinθ2, cosθ2 = sincospi(θ / 2)
    return [
        cispi(γ)*cosθ2 -cispi(λ + γ)*sinθ2
        cispi(ϕ + γ)*sinθ2 cispi(ϕ + λ + γ)*cosθ2
    ]
end

function _swapcrosses!(M::Matrix, n, m)
    M[:, n], M[:, m] = M[:, m], M[:, n]
    M[n, :], M[m, :] = M[m, :], M[n, :]
    return M
end

# Permutation of the `2^nq` basis indices induced by permuting index *bits* by
# `qperm`. The map is linear over the bits, so the image of an index is the sum
# of the images of its set bits: evaluating it on the `nq` basis indices costs
# `nq` `BitString` round-trips instead of `2^nq`. The images form a bijection on
# `0:2^nq-1`, so the permutation we want is their inverse — a scatter, not a
# `sortperm`. Both round-trips stay on `BitString` so the endianness convention
# is read from there rather than re-derived here.
function _index_permutation(qperm, nq)
    n = 1 << nq
    w = [bitstring_to_integer(BitString(nq, 1 << (k - 1))[qperm], Int) for k in 1:nq]

    perm = Vector{Int}(undef, n)
    @inbounds for i in 0:(n-1)
        s = 0
        for k in 1:nq
            ((i >> (k - 1)) & 1) == 1 && (s += w[k])
        end
        perm[s+1] = i + 1
    end
    return perm
end

function _reorder_qubits_matrix!(M::Matrix, qubits, nq=maximum(qubits))
    fullqubits = [collect(qubits); [qu for qu in 1:nq if qu ∉ qubits]]
    nqempty = nq - length(qubits)

    fullM = kron(M, Matrix(I, 2^nqempty, 2^nqempty))

    if issorted(fullqubits)
        return fullM
    end

    qperm = nq .+ 1 .- reverse(sortperm(collect(fullqubits)))

    perm = _index_permutation(qperm, nq)
    Base.permuterows!(fullM, perm)
    Base.permutecols!(fullM, perm)

    return fullM
end
