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
# This file is part of the Julia port of pygridsynth 1.2.0
# (https://github.com/quantum-programming/pygridsynth), distributed under the
# MIT License:
#
#     Copyright (c) 2024-2025 Shun Yamamoto and Nobuyuki Yoshioka
#
#     Permission is hereby granted, free of charge, to any person obtaining a
#     copy of this software and associated documentation files (the
#     "Software"), to deal in the Software without restriction, including
#     without limitation the rights to use, copy, modify, merge, publish,
#     distribute, sublicense, and/or sell copies of the Software, and to
#     permit persons to whom the Software is furnished to do so, subject to
#     the following conditions:
#
#     The above copyright notice and this permission notice shall be included
#     in all copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Exact synthesis of U = [z  -w†ωⁿ; w  z†ωⁿ] over D[ω] (Kliuchnikov–Maslov–
# Mosca) and Matsumoto–Amano normal form.

struct DOmegaUnitary
    z::DOmega
    w::DOmega
    n::Int
end

function DOmegaUnitary(z::DOmega, w::DOmega, n::Integer, k::Union{Nothing,Integer})
    if k === nothing
        z, w = _align(z, w)
    else
        z, w = renew_denomexp(z, k), renew_denomexp(w, k)
    end
    return DOmegaUnitary(z, w, Int(n & 7))
end
unitary(z, w, n) = DOmegaUnitary(z, w, n, nothing)

Base.:(==)(U::DOmegaUnitary, V::DOmegaUnitary) = U.z == V.z && U.w == V.w && U.n == V.n
denomexp(U::DOmegaUnitary) = U.w.k
renew_denomexp(U::DOmegaUnitary, k) = DOmegaUnitary(U.z, U.w, U.n, k)

mul_T_inv(U) = unitary(U.z, mul_by_omega_inv(U.w), U.n - 1)
mul_T_power(U, m) = (m &= 7; unitary(U.z, mul_by_omega_power(U.w, m), U.n + m))
mul_S_power(U, m) = (m &= 3; unitary(U.z, mul_by_omega_power(U.w, 2m), U.n + 2m))
mul_H(U) = unitary(mul_by_inv_sqrt2(U.z + U.w), mul_by_inv_sqrt2(U.z - U.w), U.n + 4)
mul_HT_power(U, m) = mul_H(mul_T_power(U, m))
mul_X(U) = unitary(U.w, U.z, U.n + 4)
function mul_W_power(U, m)
    m &= 7
    return unitary(mul_by_omega_power(U.z, m), mul_by_omega_power(U.w, m), U.n + 2m)
end

const BIT_SHIFT = (0, 0, 1, 0, 2, 0, 1, 3, 3, 3, 0, 2, 2, 1, 0, 0)
const BIT_COUNT = (0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4)
const T_POWER_AND_H = ("H", "TH", "SH", "TSH")

# One step of exact synthesis: peel a (T^m H) prefix off U, lowering the
# denominator exponent.
function reduce_denomexp_step(U::DOmegaUnitary)
    rz = residue(U.z)
    rw = residue(U.w)
    rsq = residue(U.z.u * conj(U.z.u))
    m = BIT_SHIFT[rw+1] - BIT_SHIFT[rz+1]
    m < 0 && (m += 4)
    k = denomexp(U)
    if rsq == 0b0000
        return T_POWER_AND_H[1], renew_denomexp(mul_HT_power(U, 0), k - 1)
    elseif rsq == 0b1010
        return T_POWER_AND_H[m+1], renew_denomexp(mul_HT_power(U, -m), k - 1)
    elseif rsq == 0b0001
        V = mul_HT_power(U, -m)
        if BIT_COUNT[rz+1] == BIT_COUNT[rw+1]
            V = renew_denomexp(V, k - 1)
        end
        return T_POWER_AND_H[m+1], V
    end
    throw(ErrorException("invalid residue in exact synthesis"))
end

# Clifford group element E^a X^b S^c ω^d (Matsumoto–Amano).
struct Clifford
    a::Int
    b::Int
    c::Int
    d::Int
    Clifford(a, b, c, d) = new(mod(a, 3), b & 1, c & 3, d & 7)
end

const CONJ2_TABLE = ((0, 0), (0, 0), (1, 0), (3, 2), (2, 0), (2, 4), (3, 0), (1, 6))
const CONJ3_TABLE = (
    (0, 0, 0, 0), (0, 0, 1, 0), (0, 0, 2, 0), (0, 0, 3, 0),
    (0, 1, 0, 0), (0, 1, 1, 0), (0, 1, 2, 0), (0, 1, 3, 0),
    (1, 0, 0, 0), (2, 0, 3, 6), (1, 1, 2, 2), (2, 1, 3, 6),
    (1, 0, 2, 0), (2, 1, 1, 0), (1, 1, 0, 6), (2, 0, 1, 4),
    (2, 0, 0, 0), (1, 1, 3, 4), (2, 1, 0, 0), (1, 0, 1, 2),
    (2, 1, 2, 2), (1, 1, 1, 0), (2, 0, 2, 6), (1, 0, 3, 2),
)
const CINV_TABLE = (
    (0, 0, 0, 0), (0, 0, 3, 0), (0, 0, 2, 0), (0, 0, 1, 0),
    (0, 1, 0, 0), (0, 1, 1, 6), (0, 1, 2, 4), (0, 1, 3, 2),
    (2, 0, 0, 0), (1, 0, 1, 2), (2, 1, 0, 0), (1, 1, 3, 4),
    (2, 1, 1, 2), (1, 1, 1, 6), (2, 0, 2, 2), (1, 0, 3, 4),
    (1, 0, 0, 0), (2, 1, 3, 6), (1, 1, 2, 2), (2, 0, 3, 6),
    (1, 0, 2, 0), (2, 1, 1, 6), (1, 1, 0, 2), (2, 0, 1, 6),
)
# Axis: 0 = I, 1 = H, 2 = SH
const TCONJ_TABLE = ((0, 0, 0), (0, 1, 7), (1, 3, 3), (1, 2, 0), (2, 0, 5), (2, 1, 4))

function Base.:*(x::Clifford, y::Clifford)
    a1, b1, c1, d1 = CONJ3_TABLE[(y.a<<3|x.b<<2|x.c)+1]
    c2, d2 = CONJ2_TABLE[(c1<<1|y.b)+1]
    return Clifford(x.a + a1, b1 + y.b, c2 + y.c, d2 + d1 + x.d + y.d)
end

function Base.inv(x::Clifford)
    a1, b1, c1, d1 = CINV_TABLE[(x.a<<3|x.b<<2|x.c)+1]
    return Clifford(a1, b1, c1, d1 - x.d)
end

const CLIFFORD_I = Clifford(0, 0, 0, 0)
const CLIFFORD_X = Clifford(0, 1, 0, 0)
const CLIFFORD_H = Clifford(1, 0, 1, 5)
const CLIFFORD_S = Clifford(0, 0, 1, 0)
const CLIFFORD_W = Clifford(0, 0, 0, 1)
const CLIFFORD_SH = CLIFFORD_S * CLIFFORD_H
const CLIFFORD_HS = CLIFFORD_H * CLIFFORD_S
const CLIFFORD_SHS = CLIFFORD_S * CLIFFORD_H * CLIFFORD_S

function clifford_from_char(g::Char)
    g == 'H' && return CLIFFORD_H
    g == 'S' && return CLIFFORD_S
    g == 'X' && return CLIFFORD_X
    g == 'W' && return CLIFFORD_W
    throw(ArgumentError("not a Clifford generator: $g"))
end

function decompose_coset(x::Clifford)
    x.a == 0 && return 0, x
    x.a == 1 && return 1, inv(CLIFFORD_H) * x
    return 2, inv(CLIFFORD_SH) * x
end

function decompose_tconj(x::Clifford)
    axis, c1, d1 = TCONJ_TABLE[(x.a<<1|x.b)+1]
    return axis, Clifford(0, x.b, c1 + x.c, d1 + x.d)
end

# Global phases (W = ω) are dropped: the caller only needs U up to phase.
function clifford_chars(x::Clifford)
    axis, c = decompose_coset(x)
    out = Char[]
    axis == 1 && push!(out, 'H')
    axis == 2 && append!(out, ('S', 'H'))
    for _ in 1:c.b
        push!(out, 'X')
    end
    for _ in 1:c.c
        push!(out, 'S')
    end
    return out
end

# Syllables: 1 = T, 2 = HT, 3 = SHT
function normal_form(gates::Vector{Char})
    syl = Int[]
    c = CLIFFORD_I
    for g in gates
        if g == 'T'
            axis, newc = decompose_tconj(c)
            if axis == 0
                if isempty(syl)
                    push!(syl, 1)
                elseif syl[end] == 1
                    pop!(syl)
                    c = CLIFFORD_S * newc
                elseif syl[end] == 2
                    pop!(syl)
                    c = CLIFFORD_HS * newc
                else
                    pop!(syl)
                    c = CLIFFORD_SHS * newc
                end
            else
                push!(syl, axis == 1 ? 2 : 3)
                c = newc
            end
        else
            c *= clifford_from_char(g)
        end
    end
    out = Char[]
    for s in syl
        s == 2 && push!(out, 'H')
        s == 3 && append!(out, ('S', 'H'))
        push!(out, 'T')
    end
    append!(out, clifford_chars(c))
    return out
end

function decompose_domega_unitary(U::DOmegaUnitary)
    gates = Char[]
    while denomexp(U) > 0
        g, U = reduce_denomexp_step(U)
        append!(gates, g)
    end
    if isodd(U.n)
        push!(gates, 'T')
        U = mul_T_inv(U)
    end
    if U.z == 0
        push!(gates, 'X')
        U = mul_X(U)
    end
    for m in 0:7
        if U.z == OMEGA_POWER[m+1]
            U = mul_W_power(U, -m)
            break
        end
    end
    mS = U.n >> 1
    for _ in 1:mS
        push!(gates, 'S')
    end
    U = mul_S_power(U, -mS)
    U == unitary(DOmega(1), DOmega(0), 0) || throw(ErrorException("exact synthesis failed"))
    return normal_form(gates)
end
