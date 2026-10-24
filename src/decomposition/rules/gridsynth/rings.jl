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
# The rings Z[√2], D[√2], Z[ω] and D[ω], with the √2-conjugation `conj2`,
# norms, Euclidean division and gcd.

# ---------------------------------------------------------------------------
# Z[√2]: a + b√2
# ---------------------------------------------------------------------------

struct ZRootTwo
    a::BigInt
    b::BigInt
end
ZRootTwo(n::Integer) = ZRootTwo(n, 0)

Base.:+(x::ZRootTwo, y::ZRootTwo) = ZRootTwo(x.a + y.a, x.b + y.b)
Base.:+(x::ZRootTwo, n::Integer) = ZRootTwo(x.a + n, x.b)
Base.:-(x::ZRootTwo, y::ZRootTwo) = ZRootTwo(x.a - y.a, x.b - y.b)
Base.:-(x::ZRootTwo) = ZRootTwo(-x.a, -x.b)
Base.:*(x::ZRootTwo, y::ZRootTwo) = ZRootTwo(x.a * y.a + 2 * x.b * y.b, x.a * y.b + x.b * y.a)
Base.:*(x::ZRootTwo, n::Integer) = ZRootTwo(x.a * n, x.b * n)
Base.:(==)(x::ZRootTwo, y::ZRootTwo) = x.a == y.a && x.b == y.b
Base.:(==)(x::ZRootTwo, n::Integer) = x.a == n && iszero(x.b)
Base.iszero(x::ZRootTwo) = iszero(x.a) && iszero(x.b)

# Exact ordering of the real values a + b√2.
function Base.:<(x::ZRootTwo, y::ZRootTwo)
    da = x.a - y.a
    db = x.b - y.b
    if db > 0
        return da < 0 && da^2 > 2 * db^2
    elseif db < 0
        return da < 0 || da^2 < 2 * db^2
    else
        return da < 0
    end
end
Base.:<(x::ZRootTwo, n::Integer) = x < ZRootTwo(n)
Base.:<=(x::ZRootTwo, y::ZRootTwo) = x < y || x == y

conj2(x::ZRootTwo) = ZRootTwo(x.a, -x.b)
znorm(x::ZRootTwo) = x.a^2 - 2 * x.b^2
to_real(x::ZRootTwo) = x.a + sqrt2() * x.b
parity(x::ZRootTwo) = Int(isodd(x.a))

function Base.inv(x::ZRootTwo)
    n = znorm(x)
    n == 1 && return conj2(x)
    n == -1 && return -conj2(x)
    throw(DivideError())
end

function Base.:^(x::ZRootTwo, n::Integer)
    n < 0 && return inv(x)^(-n)
    r = ZRootTwo(1)
    t = x
    while n > 0
        isodd(n) && (r *= t)
        t *= t
        n >>= 1
    end
    return r
end

function zdivrem(x::ZRootTwo, y::ZRootTwo)
    p = x * conj2(y)
    k = znorm(y)
    q = ZRootTwo(rounddiv(p.a, k), rounddiv(p.b, k))
    return q, x - y * q
end
zdiv(x, y) = zdivrem(x, y)[1]
zrem(x, y) = zdivrem(x, y)[2]
zdiv(x::ZRootTwo, n::Integer) = zdiv(x, ZRootTwo(n))
zrem(x::ZRootTwo, n::Integer) = zrem(x, ZRootTwo(n))

similar_(x, y) = iszero(zrem(x, y)) && iszero(zrem(y, x))

function zgcd(a, b)
    while !iszero(b)
        a, b = b, zrem(a, b)
    end
    return a
end

function Base.sqrt(x::ZRootTwo)
    n = znorm(x)
    (n < 0 || x.a < 0) && return nothing
    r = floorsqrt(n)
    a1 = floorsqrt(fld(x.a + r, 2))
    b1 = floorsqrt(fld(x.a - r, 4))
    a2 = floorsqrt(fld(x.a - r, 2))
    b2 = floorsqrt(fld(x.a + r, 4))
    if sign(x.a) * sign(x.b) >= 0
        w1, w2 = ZRootTwo(a1, b1), ZRootTwo(a2, b2)
    else
        w1, w2 = ZRootTwo(a1, -b1), ZRootTwo(a2, -b2)
    end
    x == w1 * w1 && return w1
    x == w2 * w2 && return w2
    return nothing
end

const LAMBDA = ZRootTwo(1, 1)

# ---------------------------------------------------------------------------
# D[√2]: α / √2^k with α ∈ Z[√2]
# ---------------------------------------------------------------------------

struct DRootTwo
    alpha::ZRootTwo
    k::Int
end
DRootTwo(n::Integer) = DRootTwo(ZRootTwo(n), 0)

function mul_by_sqrt2_power(x::DRootTwo, d::Integer)
    a, b = x.alpha.a, x.alpha.b
    if d >= 0
        alpha = x.alpha * (big(1) << (d >> 1))
        isodd(d) && (alpha *= ZRootTwo(0, 1))
        return DRootTwo(alpha, x.k)
    end
    h = (-d) >> 1
    if iseven(-d)
        bit = (big(1) << h) - 1
        (iszero(a & bit) && iszero(b & bit)) || throw(ArgumentError("not divisible"))
        return DRootTwo(ZRootTwo(a >> h, b >> h), x.k)
    else
        bit = (big(1) << h) - 1
        bit2 = (big(1) << (h + 1)) - 1
        (iszero(a & bit2) && iszero(b & bit)) || throw(ArgumentError("not divisible"))
        return DRootTwo(ZRootTwo(b >> h, a >> (h + 1)), x.k)
    end
end

renew_denomexp(x::DRootTwo, k::Integer) = DRootTwo(mul_by_sqrt2_power(x, k - x.k).alpha, k)

function _align(x, y)
    x.k < y.k && return renew_denomexp(x, y.k), y
    x.k > y.k && return x, renew_denomexp(y, x.k)
    return x, y
end

function Base.:+(x::DRootTwo, y::DRootTwo)
    x, y = _align(x, y)
    return DRootTwo(x.alpha + y.alpha, x.k)
end
Base.:-(x::DRootTwo) = DRootTwo(-x.alpha, x.k)
Base.:-(x::DRootTwo, y::DRootTwo) = x + (-y)
Base.:*(x::DRootTwo, y::DRootTwo) = DRootTwo(x.alpha * y.alpha, x.k + y.k)
function Base.:(==)(x::DRootTwo, y::DRootTwo)
    x, y = _align(x, y)
    return x.alpha == y.alpha
end
function Base.:<(x::DRootTwo, y::DRootTwo)
    x, y = _align(x, y)
    return x.alpha < y.alpha
end
Base.:<=(x::DRootTwo, y::DRootTwo) = x < y || x == y
Base.:<=(x::DRootTwo, y::ZRootTwo) = x <= DRootTwo(y, 0)

parity(x::DRootTwo) = parity(x.alpha)
to_real(x::DRootTwo) = to_real(x.alpha) / pow_sqrt2(x.k)
conj2(x::DRootTwo) = DRootTwo(isodd(x.k) ? -conj2(x.alpha) : conj2(x.alpha), x.k)
power_of_inv_sqrt2(k::Integer) = DRootTwo(ZRootTwo(1), k)

function renewing_denomexp(x::DRootTwo, d::Integer)
    d > x.k && throw(ArgumentError("exponent too large"))
    return DRootTwo(x.alpha, x.k - d)
end

# ---------------------------------------------------------------------------
# Z[ω]: aω³ + bω² + cω + d
# ---------------------------------------------------------------------------

struct ZOmega
    a::BigInt
    b::BigInt
    c::BigInt
    d::BigInt
end
ZOmega(n::Integer) = ZOmega(0, 0, 0, n)
ZOmega(x::ZRootTwo) = ZOmega(-x.b, 0, x.b, x.a)

Base.:+(x::ZOmega, y::ZOmega) = ZOmega(x.a + y.a, x.b + y.b, x.c + y.c, x.d + y.d)
Base.:-(x::ZOmega, y::ZOmega) = ZOmega(x.a - y.a, x.b - y.b, x.c - y.c, x.d - y.d)
Base.:-(x::ZOmega) = ZOmega(-x.a, -x.b, -x.c, -x.d)
Base.:+(x::ZOmega, n::Integer) = x + ZOmega(n)
Base.:+(n::Integer, x::ZOmega) = x + ZOmega(n)
function Base.:*(x::ZOmega, y::ZOmega)
    # ω⁴ = -1
    d = x.d * y.d - x.c * y.a - x.b * y.b - x.a * y.c
    c = x.d * y.c + x.c * y.d - x.b * y.a - x.a * y.b
    b = x.d * y.b + x.c * y.c + x.b * y.d - x.a * y.a
    a = x.d * y.a + x.c * y.b + x.b * y.c + x.a * y.d
    return ZOmega(a, b, c, d)
end
Base.:*(x::ZOmega, n::Integer) = ZOmega(x.a * n, x.b * n, x.c * n, x.d * n)
Base.:*(x::ZOmega, y::ZRootTwo) = x * ZOmega(y)
Base.:*(y::ZRootTwo, x::ZOmega) = ZOmega(y) * x
Base.:(==)(x::ZOmega, y::ZOmega) = x.a == y.a && x.b == y.b && x.c == y.c && x.d == y.d
Base.:(==)(x::ZOmega, n::Integer) = x == ZOmega(n)
Base.iszero(x::ZOmega) = x == 0

function Base.:^(x::ZOmega, n::Integer)
    n < 0 && throw(DomainError(n))
    r = ZOmega(1)
    t = x
    while n > 0
        isodd(n) && (r *= t)
        t *= t
        n >>= 1
    end
    return r
end

Base.conj(x::ZOmega) = ZOmega(-x.c, -x.b, -x.a, x.d)
conj2(x::ZOmega) = ZOmega(-x.a, x.b, -x.c, x.d)
function znorm(x::ZOmega)
    s = x.a^2 + x.b^2 + x.c^2 + x.d^2
    t = x.a * x.b + x.b * x.c + x.c * x.d - x.d * x.a
    return s^2 - 2 * t^2
end
Base.real(x::ZOmega) = x.d + sqrt2() * (x.c - x.a) / 2
Base.imag(x::ZOmega) = x.b + sqrt2() * (x.c + x.a) / 2
residue(x::ZOmega) = Int((x.a & 1) << 3 | (x.b & 1) << 2 | (x.c & 1) << 1 | (x.d & 1))

mul_by_omega(x::ZOmega) = ZOmega(x.b, x.c, x.d, -x.a)
mul_by_omega_inv(x::ZOmega) = ZOmega(-x.d, x.a, x.b, x.c)
function mul_by_omega_power(x::ZOmega, n::Integer)
    n &= 7
    for _ in 1:n
        x = mul_by_omega(x)
    end
    return x
end

function zdivrem(x::ZOmega, y::ZOmega)
    p = x * conj(y) * conj2(conj(y)) * conj2(y)
    k = znorm(y)
    q = ZOmega(rounddiv(p.a, k), rounddiv(p.b, k), rounddiv(p.c, k), rounddiv(p.d, k))
    return q, x - y * q
end

function ZRootTwo(x::ZOmega)
    (iszero(x.b) && x.a == -x.c) || throw(ArgumentError("$x is not in Z[√2]"))
    return ZRootTwo(x.d, x.c)
end

const OMEGA_POWER = [mul_by_omega_power(ZOmega(1), m) for m in 0:7]

# ---------------------------------------------------------------------------
# D[ω]: u / √2^k with u ∈ Z[ω]
# ---------------------------------------------------------------------------

struct DOmega
    u::ZOmega
    k::Int
end
DOmega(n::Integer) = DOmega(ZOmega(n), 0)
DOmega(x::DRootTwo) = DOmega(ZOmega(x.alpha), x.k)
DRootTwo(x::DOmega) = DRootTwo(ZRootTwo(x.u), x.k)

function from_droottwo_vector(x::DRootTwo, y::DRootTwo, k::Integer)
    return renew_denomexp(DOmega(x) + DOmega(y) * ZOmega(0, 1, 0, 0), k)
end

function mul_by_inv_sqrt2(x::DOmega)
    u = x.u
    (iseven(u.b + u.d) && iseven(u.c + u.a)) || throw(ArgumentError("not divisible"))
    return DOmega(ZOmega((u.b - u.d) >> 1, (u.c + u.a) >> 1, (u.b + u.d) >> 1, (u.c - u.a) >> 1), x.k)
end

function mul_by_sqrt2_power(x::DOmega, d::Integer)
    u = x.u
    if d >= 0
        v = u * (big(1) << (d >> 1))
        isodd(d) && (v *= ZOmega(-1, 0, 1, 0))
        return DOmega(v, x.k)
    end
    d == -1 && return mul_by_inv_sqrt2(x)
    h = (-d) >> 1
    if iseven(-d)
        bit = (big(1) << h) - 1
        (iszero(u.a & bit) && iszero(u.b & bit) && iszero(u.c & bit) && iszero(u.d & bit)) ||
            throw(ArgumentError("not divisible"))
        return DOmega(ZOmega(u.a >> h, u.b >> h, u.c >> h, u.d >> h), x.k)
    else
        bit = (big(1) << (h + 1)) - 1
        p, q, r, s = u.b - u.d, u.c + u.a, u.b + u.d, u.c - u.a
        (iszero(p & bit) && iszero(q & bit) && iszero(r & bit) && iszero(s & bit)) ||
            throw(ArgumentError("not divisible"))
        return DOmega(ZOmega(p >> (h + 1), q >> (h + 1), r >> (h + 1), s >> (h + 1)), x.k)
    end
end

renew_denomexp(x::DOmega, k::Integer) = DOmega(mul_by_sqrt2_power(x, k - x.k).u, k)

_tz(n::BigInt, k) = iszero(n) ? k : trailing_zeros(n)

function reduce_denomexp(x::DOmega)
    u = x.u
    r = min(_tz(u.a, x.k), _tz(u.b, x.k), _tz(u.c, x.k), _tz(u.d, x.k))
    newk = x.k - 2 * r
    bit = (big(1) << (r + 1)) - 1
    if iszero((u.c + u.a) & bit) && iszero((u.b + u.d) & bit)
        newk -= 1
    end
    return renew_denomexp(x, max(newk, 0))
end

function Base.:+(x::DOmega, y::DOmega)
    x, y = _align(x, y)
    return DOmega(x.u + y.u, x.k)
end
Base.:-(x::DOmega) = DOmega(-x.u, x.k)
Base.:-(x::DOmega, y::DOmega) = x + (-y)
Base.:-(x::DOmega, y::ZRootTwo) = x - DOmega(ZOmega(y), 0)
Base.:*(x::DOmega, y::DOmega) = DOmega(x.u * y.u, x.k + y.k)
Base.:*(x::DOmega, y::ZOmega) = DOmega(x.u * y, x.k)
Base.:*(n::Integer, x::DOmega) = DOmega(x.u * n, x.k)
function Base.:(==)(x::DOmega, y::DOmega)
    x, y = _align(x, y)
    return x.u == y.u
end
Base.:(==)(x::DOmega, y::ZOmega) = x == DOmega(y, 0)
Base.:(==)(x::DOmega, n::Integer) = x == DOmega(n)

mul_by_omega(x::DOmega) = DOmega(mul_by_omega(x.u), x.k)
mul_by_omega_inv(x::DOmega) = DOmega(mul_by_omega_inv(x.u), x.k)
mul_by_omega_power(x::DOmega, n::Integer) = DOmega(mul_by_omega_power(x.u, n), x.k)
residue(x::DOmega) = residue(x.u)
Base.real(x::DOmega) = real(x.u) / pow_sqrt2(x.k)
Base.imag(x::DOmega) = imag(x.u) / pow_sqrt2(x.k)
Base.conj(x::DOmega) = DOmega(conj(x.u), x.k)
conj2(x::DOmega) = DOmega(isodd(x.k) ? -conj2(x.u) : conj2(x.u), x.k)
