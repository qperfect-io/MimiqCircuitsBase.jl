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

@doc raw"""
    PolynomialOracle(xregsize, yregsize, a, b, c, d)
    PolynomialOracle(a, b, c, d) # lazy

Quantum oracle for a polynomial function of two registers.

Applies a ``\pi`` phase shift to any basis state which satifies
``a xy + bx + cy + d == 0``, where ``\ket{x}`` and ``\ket{y}`` are the states of
the two registers.

## Examples

```jldoctest
julia> c = push!(Circuit(), PolynomialOracle(5,5,1,2,3,4), 1:10...)
10-qubit circuit with 1 instruction:
└── PolynomialOracle(1,2,3,4) @ q[1:5], q[6:10]

julia> push!(c, inverse(PolynomialOracle(5,5,1,2,3,4)), 1:10...)
10-qubit circuit with 2 instructions:
├── PolynomialOracle(1,2,3,4) @ q[1:5], q[6:10]
└── PolynomialOracle(1,2,3,4) @ q[1:5], q[6:10]
```

!!! note
    Decomposes into one multi-controlled Z per solution, so large circuits are
    only practical when there are few solutions. Symbolic coefficients must be
    evaluated before decomposing.
"""
struct PolynomialOracle{NX,NY,N} <: AbstractGate{N}
    a::Num
    b::Num
    c::Num
    d::Num

    function PolynomialOracle{NX,NY,N}(a, b, c, d) where {NX,NY,N}
        if NX + NY != N
            throw(OperationError(PolynomialOracle, "Expected NX + NY == N, got $(NX) + $(NY) == $N."))
        end

        if !(NX isa Integer) || !(NY isa Integer) || !(N isa Integer)
            throw(OperationError(PolynomialOracle, "NX, NY, N, must be integers."))
        end

        if NX < 0 || NY < 0
            throw(OperationError(PolynomialOracle, "Number of qubits must be positive"))
        end

        if N < 1
            throw(OperationError(PolynomialOracle, "At least one register must have a size > 0"))
        end

        new{NX,NY,N}(a, b, c, d)
    end
end

function PolynomialOracle(nx, ny, a, b, c, d)
    PolynomialOracle{nx,ny,nx + ny}(a, b, c, d)
end

function PolynomialOracle(a, b, c, d)
    LazyExpr(PolynomialOracle, LazyArg(), LazyArg(), a, b, c, d)
end

opname(::Type{<:PolynomialOracle}) = "PolynomialOracle"

isunitary(::Type{<:PolynomialOracle}) = true

qregsizes(::PolynomialOracle{NX,NY,N}) where {NX,NY,N} = (NX, NY)

inverse(s::PolynomialOracle{NX,NY,N}) where {NX,NY,N} = s

# TODO: change when ID is generalized
_power(s::PolynomialOracle{NX,NY,N}, pwr) where {NX,NY,N} = _power_idempotent(s, control(N - 1, GateID()), pwr)

matches(::CanonicalRewrite, ::PolynomialOracle) = true

# One multi-controlled Z per solution of f(x, y) == 0, with the same convention
# as the simulators: each register is little-endian (its first qubit is the least
# significant bit) and a state is a solution when round(Int, f) == 0. For each
# value of the smaller register f is linear in the other one, so the solutions
# are found without looping over all 2^N basis states.
function decompose_step!(circ, ::CanonicalRewrite, op::PolynomialOracle{NX,NY,N}, qubits, _, _) where {NX,NY,N}
    a, b, c, d = unwrapvalue.((op.a, op.b, op.c, op.d))  # throws UndefinedValue if symbolic

    xq, yq = collect(qubits[1:NX]), collect(qubits[NX+1:N])
    f(x, y) = round(Int, a * x * y + b * x + c * y + d) == 0
    small, large = NX <= NY ? (xq, yq) : (yq, xq)
    xy(u, v) = NX <= NY ? (u, v) : (v, u)

    for u in 0:(1<<length(small))-1
        # f(u, v) = s * v + t, zero after rounding when s * v + t ∈ [-1/2, 1/2]
        s = NX <= NY ? a * u + c : a * u + b
        t = NX <= NY ? b * u + d : c * u + d
        if iszero(s)
            f(xy(u, 0)...) && _flipstate!(circ, small, u, qubits)
            continue
        end
        lo, hi = minmax((-0.5 - t) / s, (0.5 - t) / s)
        vmax = (1 << length(large)) - 1
        lo, hi = clamp(floor(lo) - 1, 0, vmax + 1), clamp(ceil(hi) + 1, -1, vmax)
        for v in Int(lo):Int(hi)
            f(xy(u, v)...) && _flipstate!(circ, [small; large], u + v << length(small), qubits)
        end
    end
    # Solutions may leave the higher register untouched; preserve the oracle's width.
    numqubits(circ) < maximum(qubits) && push!(circ, GateID(), maximum(qubits))
    return circ
end

# Phase -1 on the basis states where the qubits `qs` hold the little-endian value `val`.
function _flipstate!(circ, qs, val, qubits)
    isempty(qs) && return push!(circ, GateU(0, 0, 0, π), qubits[1])  # every state flips
    zeros = [q for (i, q) in enumerate(qs) if iszero(val >> (i - 1) & 1)]
    foreach(q -> push!(circ, GateX(), q), zeros)
    push!(circ, length(qs) == 1 ? GateZ() : Control(length(qs) - 1, GateZ()), qs...)
    foreach(q -> push!(circ, GateX(), q), zeros)
    return circ
end
