#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
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

@doc raw"""
    struct GateCustomDiagonal{N} <: AbstractGate{N}

`N` qubit diagonal gate, stored as its ``2^N`` diagonal entries.

Same role as [`GateCustom`](@ref), but for gates that are diagonal in the
computational basis: only the diagonal is kept, so both the memory and the cost
of composing two such gates grow as ``2^N`` instead of ``4^N``.

The entries are ordered as the diagonal of the dense matrix, in the basis
``|0\dots0\rangle, \dots, |1\dots1\rangle`` with the first target qubit as the
most significant bit — the same convention as [`GateCustom`](@ref).

Unitarity requires every entry to be a phase, ``|d_i| = 1``.

## Examples

```jldoctest
julia> g = GateCustomDiagonal([1, -1])
1-qubit CustomDiagonal:
├── 1.0
└── -1.0

julia> matrix(g)
2×2 Matrix{ComplexF64}:
 1.0+0.0im   0.0+0.0im
 0.0+0.0im  -1.0+0.0im

julia> push!(Circuit(), GateCustomDiagonal([1, 1, 1, -1]), 1, 2)
2-qubit circuit with 1 instruction:
└── CustomDiagonal(…) @ q[1:2]
```

See also [`GateCustom`](@ref).
"""
struct GateCustomDiagonal{N} <: AbstractGate{N}
    d::Vector{Complex{Num}}

    function GateCustomDiagonal{N}(d) where {N}
        if N < 1
            error("Cannot define 0-qubit custom diagonal gate")
        end

        M = 1 << N
        if length(d) != M
            throw(ArgumentError("Custom diagonal should have $(M) entries."))
        end

        dd = convert(Vector{Complex{Num}}, collect(d))

        if !any(issymbolic, dd)
            ud = unwrapvalue.(dd)
            if !all(x -> isapprox(abs(x), 1; rtol=1e-8), ud)
                throw(ArgumentError("Custom diagonal not unitary (|dᵢ| ≉ 1)."))
            end
        end

        return new{N}(dd)
    end
end

function GateCustomDiagonal(d::AbstractVector)
    dim = length(d)
    if !isvalidpowerof2(dim)
        throw(ArgumentError("Length of custom diagonal has to be 2^n with n>=1."))
    end
    return GateCustomDiagonal{Int(log2(dim))}(float.(d))
end

opname(::Type{<:GateCustomDiagonal}) = "CustomDiagonal"

inverse(g::GateCustomDiagonal) = GateCustomDiagonal(conj.(g.d))

"""
    diagonal(g::GateCustomDiagonal)

The diagonal entries of `g`, as stored (possibly symbolic).

See also [`unwrappeddiagonal`](@ref).
"""
diagonal(g::GateCustomDiagonal) = g.d

"""
    unwrappeddiagonal(g::GateCustomDiagonal)

The diagonal entries of `g` without the `Symbolics.Num` wrapper. Throws if any
entry is symbolic.

See also [`diagonal`](@ref), [`unwrappedmatrix`](@ref).
"""
unwrappeddiagonal(g::GateCustomDiagonal) = unwrapvalue.(g.d)

# Same numeric/symbolic triage as `matrix(::GateCustom)`: entries that can be
# folded to a number are, everything else stays symbolic.
function _evaluated_diagonal(g::GateCustomDiagonal)
    map(g.d) do p
        v = Symbolics.value(p)

        if !(v isa Num)
            vv = simplify(v)
            vvc = unwrap_const(vv)
            vvc isa Number && return vvc
        end

        if iscall(v)
            vv = Symbolics.value(Symbolics.symbolic_to_float(v))
            vv isa Number && return vv
        end

        return p
    end
end

matrix(g::GateCustomDiagonal) = Matrix(Diagonal(_evaluated_diagonal(g)))

unwrappedmatrix(g::GateCustomDiagonal) = Matrix(Diagonal(unwrappeddiagonal(g)))

_matrix(::Type{GateCustomDiagonal{N}}, d...) where {N} = Matrix(Diagonal(collect(d)))

parnames(::GateCustomDiagonal{N}) where {N} = tuple(1:2^N...)

parnames(::Type{<:GateCustomDiagonal{N}}) where {N} = tuple(1:2^N...)

getparam(g::GateCustomDiagonal, i) = g.d[i]

getparams(g::GateCustomDiagonal) = g.d

function Base.show(io::IO, gate::GateCustomDiagonal)
    print(io, "GateCustomDiagonal", "(")
    io1 = IOContext(io, :compact => get(io, :compact, false), :typeinfo => Array{Symbolics.Num})
    print(io1, map(_decomplex, _evaluated_diagonal(gate)))
    print(io1, ")")
end

function Base.show(io::IO, ::MIME"text/plain", gate::GateCustomDiagonal{N}) where {N}
    d = map(_decomplex, _evaluated_diagonal(gate))
    if get(io, :compact, false)
        print(io, opname(gate))
        if get(io, :limit, false) && N > 1
            print(io, "(…)")
            return nothing
        end
        print(io, "([")
        if N <= 1
            join(io, d, ", ")
        else
            join(io, d[1:2], ", ")
            print(io, " … ")
            join(io, d[end-1:end], ", ")
        end
        print(io, "])")
        return nothing
    end

    print(io, numqubits(gate), "-qubit ", opname(gate), ":\n")
    for i in 1:length(d)-1
        print(io, "├── ", d[i], '\n')
    end
    print(io, "└── ", d[end])
end

matches(::CanonicalRewrite, ::GateCustomDiagonal{N}) where {N} = true

# In-place fast Walsh–Hadamard transform.
function _fwht!(a)
    n = length(a)
    h = 1
    while h < n
        for i in 1:(2h):n, j in i:(i+h-1)
            x, y = a[j], a[j+h]
            a[j] = x + y
            a[j+h] = x - y
        end
        h *= 2
    end
    return a
end

# Expand the phases in the Walsh basis: with ``φ(x) = Σ_S α_S (-1)^{|x ∩ S|}``,
# the gate is ``e^{i α_∅} ∏_{S ≠ ∅} \exp(i α_S Z_S)``, and each parity term is
# one `GateRNZ` on the qubits of `S` (a `GateRZ` when `S` is a single qubit).
#
# Not routed through `GateCustom`: that would build a `4^N`-entry matrix for a
# gate that needs `2^N`, and QSD would then spend a multiple of that many gates
# rediscovering a structure this expansion writes down directly.
function decompose_step!(builder, ::CanonicalRewrite, g::GateCustomDiagonal{N}, qtargets, _, _) where {N}
    α = _fwht!(angle.(unwrappeddiagonal(g))) ./ (1 << N)

    for S in 1:((1 << N) - 1)
        abs(α[S+1]) < 1e-14 && continue
        # bit `N - p` of the mask selects the p-th target, matching the
        # most-significant-first order of the diagonal itself
        qs = [qtargets[p] for p in 1:N if !iszero((S >> (N - p)) & 1)]
        if length(qs) == 1
            push!(builder, GateRZ(-2 * α[S+1]), qs[1])
        else
            push!(builder, GateRNZ(length(qs), -2 * α[S+1]), qs...)
        end
    end

    # α_∅ is the global phase left over
    abs(α[1]) < 1e-14 || push!(builder, GateU(0, 0, 0, α[1]), qtargets[1])

    return builder
end

function Base.:(==)(left::GateCustomDiagonal, right::GateCustomDiagonal)
    typeof(left) == typeof(right) || return false

    for (l, r) in zip(_evaluated_diagonal(left), _evaluated_diagonal(right))
        issymbolic(l) == issymbolic(r) || return false

        if issymbolic(l) && issymbolic(r)
            l === r || return false
        end

        isequal(l, r) || return false
    end

    return true
end
