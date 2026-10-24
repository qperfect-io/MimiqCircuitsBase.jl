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
using Test
using MimiqCircuitsBase
using LinearAlgebra
using Random

# The canonical decomposition of a pair measurement must act as the ideal
# projective measurement of the two-qubit Pauli operator, both in its outcome
# probabilities and in the state it leaves behind.

# Applies `mat` to the qubits `qs` of a state stored with one axis per qubit.
# The first target is the most significant index of `mat`, as in `matrix`.
function _pm_apply(psi::Array{ComplexF64}, mat, qs)
    k = length(qs)
    n = ndims(psi)
    t = reshape(ComplexF64.(mat), fill(2, 2k)...)
    # Julia arrays are column-major, so reverse the axes of the gate tensor
    # to match the row-major reading of `mat`.
    t = permutedims(t, vcat(reverse(1:k), reverse(k+1:2k)))
    others = setdiff(1:n, qs)
    p = permutedims(psi, vcat(qs, others))
    p = reshape(reshape(t, 2^k, 2^k) * reshape(p, 2^k, :), fill(2, n)...)
    return permutedims(p, invperm(vcat(qs, others)))
end

# Exact simulation that follows both outcomes of every Z measurement.
# Returns a Dict mapping the outcome bit to (probability, normalized state).
function _pm_branches(c::Circuit, psi)
    branches = [(1.0, psi, -1)]
    for inst in c
        op, qs = getoperation(inst), collect(getqubits(inst))
        new = similar(branches, 0)
        for (p, s, bit) in branches
            if op isa Measure
                for b in 0:1
                    proj = b == 0 ? [1 0; 0 0] : [0 0; 0 1]
                    phi = _pm_apply(s, proj, qs)
                    pb = real(dot(phi, phi))
                    pb > 1e-12 && push!(new, (p * pb, phi / sqrt(pb), b))
                end
            else
                push!(new, (p, _pm_apply(s, ComplexF64.(matrix(op)), qs), bit))
            end
        end
        branches = new
    end
    return Dict(b => (p, s) for (p, s, b) in branches)
end

@testset "Pair measurement decompositions are projective" begin
    paulis = Dict('X' => ComplexF64[0 1; 1 0], 'Y' => ComplexF64[0 -im; im 0],
                  'Z' => ComplexF64[1 0; 0 -1])
    rng = MersenneTwister(1234)
    for (op, P) in ((MeasureXX(), 'X'), (MeasureYY(), 'Y'), (MeasureZZ(), 'Z'))
        pp = kron(paulis[P], paulis[P])
        dec = decompose(push!(Circuit(), op, 1, 2, 1); basis=CanonicalBasis())
        for _ in 1:10
            v = normalize(randn(rng, ComplexF64, 4))
            # Row-major amplitudes of |q1 q2> into a column-major array.
            got = _pm_branches(dec, permutedims(reshape(v, 2, 2)))
            for (b, sign) in ((0, 1), (1, -1))
                # Outcome 0 is the +1 eigenspace, outcome 1 the -1 eigenspace.
                phi = (I + sign * pp) * v / 2
                pb = real(dot(phi, phi))
                p, s = got[b]
                @test p ≈ pb atol = 1e-10
                # Equal up to a global phase.
                @test abs(dot(phi / sqrt(pb), vec(permutedims(s)))) ≈ 1 atol = 1e-10
            end
        end
    end
end
