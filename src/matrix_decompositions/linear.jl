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

# Synthesis of linear reversible circuits: circuits of X, CX and SWAP gates.
#
# Such a circuit maps the basis state x to A x ⊕ b over GF(2), for an
# invertible n × n Boolean matrix A and a vector b; row i of A lists the input
# bits whose parity becomes output bit i. A CX with control c and target t adds
# row c to row t, so writing A as a product of such row additions is writing it
# as a CX circuit.

# Row additions (c, t), row t ⊻= row c, applied in order, that bring A to upper
# triangular form with a unit diagonal; A is updated in place.
#
# Patel, Markov and Hayes, Quantum Inf. Comput. 8, 282 (2008): the columns are
# processed in sections of `m`. Rows that agree on the whole section are first
# added to one another, which clears m entries for the price of one operation;
# plain Gaussian elimination then finishes the section. Over the right section
# size this needs O(n² / log n) operations instead of O(n²).
function _pmh_lower!(A::AbstractMatrix{Bool}, m::Int)
    n = size(A, 1)
    ops = Tuple{Int,Int}[]
    function addrow!(c, t)
        for j in 1:n
            A[t, j] ⊻= A[c, j]
        end
        push!(ops, (c, t))
    end

    for s in 1:m:n
        section = s:min(s + m - 1, n)
        # Rows below the section start are already zero left of it, so adding
        # them to each other keeps the earlier sections clear.
        seen = Dict{Vector{Bool},Int}()
        for r in s:n
            pattern = A[r, section]
            any(pattern) || continue
            first = get!(seen, pattern, r)
            first == r || addrow!(first, r)
        end
        for col in section
            if !A[col, col]
                r = findfirst(r -> A[r, col], col+1:n)
                isnothing(r) && throw(ArgumentError("matrix is not invertible over GF(2)"))
                addrow!(col + r, col)
            end
            for r in col+1:n
                A[r, col] && addrow!(col, r)
            end
        end
    end
    return ops
end

# CX gates (control, target) that implement x ↦ A x, for a fixed section size.
#
# The lower pass gives L A = U, with L the product of its row additions, and
# the same pass on Uᵀ gives R Uᵀ = I. Every row addition is its own inverse and
# transposing one swaps its rows, so A = L⁻¹ (Rᵀ)⁻¹: the transposed R
# operations come first in the circuit, then the L operations in reverse.
function _pmh_synthesis(A::AbstractMatrix{Bool}, m::Int)
    U = Matrix{Bool}(A)
    lower = _pmh_lower!(U, m)
    upper = _pmh_lower!(permutedims(U), m)
    return vcat([(t, c) for (c, t) in upper], reverse(lower))
end

@doc raw"""
    _linear_synthesis(A, b) -> (cx, xs)

A circuit on local qubits `1:n` implementing ``x \mapsto A x \oplus b`` over
GF(2): the CX gates `cx`, as `(control, target)` pairs, found by
Patel-Markov-Hayes elimination, trying every section size up to ``\log_2 n``
and keeping the fewest, followed by an X on each qubit in `xs`, where `b` is
set.
"""
function _linear_synthesis(A::AbstractMatrix{Bool}, b::AbstractVector{Bool})
    n = size(A, 1)
    best = nothing
    for m in 1:max(1, ceil(Int, log2(n)))
        ops = _pmh_synthesis(A, m)
        (isnothing(best) || length(ops) < length(best)) && (best = ops)
    end
    return best, findall(b)
end

# (A, b) of a sequence of linear gates on the local qubits `1:n`, each given
# as (kind, qubits) with kind 1 for X, 2 for CX and 3 for SWAP.
function _affinemap(gates, n::Int)
    A = Matrix{Bool}(I, n, n)
    b = falses(n)
    for (kind, qs) in gates
        if kind == 1
            b[qs[1]] ⊻= true
        elseif kind == 2
            c, t = qs
            for j in 1:n
                A[t, j] ⊻= A[c, j]
            end
            b[t] ⊻= b[c]
        elseif kind == 3
            p, q = qs
            for j in 1:n
                A[p, j], A[q, j] = A[q, j], A[p, j]
            end
            b[p], b[q] = b[q], b[p]
        else
            throw(ArgumentError("unknown linear gate kind $kind"))
        end
    end
    return A, b
end
