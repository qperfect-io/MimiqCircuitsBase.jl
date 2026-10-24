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
# Regions: intervals, upright rectangles, ellipses and ellipse pairs, and
# the two convex sets of the problem, the ε-region and the unit disk.

struct Interval
    l::BigFloat
    r::BigFloat
end

Base.:+(I::Interval, x::Real) = Interval(I.l + x, I.r + x)
Base.:-(I::Interval, x::Real) = Interval(I.l - x, I.r - x)
Base.:-(I::Interval) = Interval(-I.r, -I.l)
Base.:*(I::Interval, x::Real) = x >= 0 ? Interval(I.l * x, I.r * x) : Interval(I.r * x, I.l * x)
Base.:/(I::Interval, x::Real) = x > 0 ? Interval(I.l / x, I.r / x) : Interval(I.r / x, I.l / x)
width(I::Interval) = I.r - I.l
fatten(I::Interval, e) = Interval(I.l - e, I.r + e)
within(I::Interval, x) = I.l <= x <= I.r

struct Rectangle
    x::Interval
    y::Interval
end

# The ellipse {v : (v - p)ᵀ D (v - p) ≤ 1} with D = [a b; b d].
struct Ellipse
    a::BigFloat
    b::BigFloat
    d::BigFloat
    px::BigFloat
    py::BigFloat
end

sqrt_det(E::Ellipse) = sqrt(E.d * E.a - E.b^2)
skew(E::Ellipse) = E.b^2
bias(E::Ellipse) = E.d / E.a

function bbox(E::Ellipse)
    s = sqrt_det(E)
    w = sqrt(E.d) / s
    h = sqrt(E.a) / s
    return Rectangle(Interval(E.px - w, E.px + w), Interval(E.py - h, E.py + h))
end

function normalize(E::Ellipse)
    s = sqrt_det(E)
    t = sqrt(s)
    return Ellipse(E.a / s, E.b / s, E.d / s, E.px * t, E.py * t)
end

function Base.:*(g::GridOp, E::Ellipse)
    m00, m01, m10, m11 = to_matrix(inv(g))
    a = E.a * m00 * m00 + 2 * E.b * m00 * m10 + E.d * m10 * m10
    b = E.a * m00 * m01 + E.b * (m00 * m11 + m01 * m10) + E.d * m10 * m11
    d = E.a * m01 * m01 + 2 * E.b * m11 * m01 + E.d * m11 * m11
    n00, n01, n10, n11 = to_matrix(g)
    return Ellipse(a, b, d, n00 * E.px + n01 * E.py, n10 * E.px + n11 * E.py)
end

struct EllipsePair
    A::Ellipse
    B::Ellipse
end

skew(P::EllipsePair) = skew(P.A) + skew(P.B)
bias(P::EllipsePair) = bias(P.B) / bias(P.A)
Base.:*(g::GridOp, P::EllipsePair) = EllipsePair(g * P.A, conj2(g) * P.B)

"""
Convex region of candidate top-left entries u for target angle θ: the part of
the disk |u|² ≤ scale lying in the ε-cap around e^{-iθ/2} (Ross–Selinger §7).
"""
struct EpsilonRegion
    scale::ZRootTwo
    d::BigFloat
    zx::BigFloat
    zy::BigFloat
    ellipse::Ellipse
end

function EpsilonRegion(theta::BigFloat, epsilon::BigFloat, scale::ZRootTwo=ZRootTwo(1))
    s = to_real(scale)
    d = sqrt(1 - epsilon^2 / 4) * sqrt(s)
    zx = cos(-theta / 2)
    zy = sin(-theta / 2)
    # D = R(z) · diag(64/ε⁴, 4/ε²)/scale · R(z)ᵀ
    s1 = 64 * (1 / epsilon)^4 / s
    s2 = 4 * (1 / epsilon)^2 / s
    ea = s1 * zx * zx + s2 * zy * zy
    eb = zx * zy * (s1 - s2)
    ed = s1 * zy * zy + s2 * zx * zx
    return EpsilonRegion(scale, d, zx, zy, Ellipse(ea, eb, ed, d * zx, d * zy))
end

function inside(S::EpsilonRegion, u::DOmega)
    return DRootTwo(conj(u) * u) <= S.scale && S.zx * real(u) + S.zy * imag(u) >= S.d
end

function intersect(S::EpsilonRegion, u0::DOmega, v::DOmega)
    a = conj(v) * v
    b = 2 * conj(v) * u0
    c = conj(u0) * u0 - S.scale
    vz = S.zx * real(v) + S.zy * imag(v)
    rhs = S.d - S.zx * real(u0) - S.zy * imag(u0)
    t = solve_quadratic(real(a), real(b), real(c))
    t === nothing && return nothing
    t0, t1 = t
    if vz > 0
        t2 = rhs / vz
        return t0 > t2 ? (t0, t1) : (t2, t1)
    elseif vz < 0
        t2 = rhs / vz
        return t1 < t2 ? (t0, t1) : (t0, t2)
    else
        return rhs <= 0 ? (t0, t1) : nothing
    end
end

struct UnitDisk
    scale::ZRootTwo
    ellipse::Ellipse
end

function UnitDisk(scale::ZRootTwo=ZRootTwo(1))
    sinv = 1 / to_real(scale)
    return UnitDisk(scale, Ellipse(sinv, zero(sinv), sinv, zero(sinv), zero(sinv)))
end

inside(S::UnitDisk, u::DOmega) = DRootTwo(conj(u) * u) <= S.scale

function intersect(S::UnitDisk, u0::DOmega, v::DOmega)
    a = conj(v) * v
    b = 2 * conj(v) * u0
    c = conj(u0) * u0 - S.scale
    return solve_quadratic(real(a), real(b), real(c))
end
