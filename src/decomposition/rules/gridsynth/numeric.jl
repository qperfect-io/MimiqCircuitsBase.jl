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
# Numeric helpers of `_GridSynth`: integer square root and rounding, powers
# of √2, the reference `floorlog`, and real quadratic roots.

# All real arithmetic is BigFloat at the precision set by the caller.
sqrt2() = sqrt(BigFloat(2))

floorsqrt(x::Integer) = x < 0 ? throw(DomainError(x)) : isqrt(x)
floorsqrt(x::Real) = x < 0 ? throw(DomainError(x)) : isqrt(floor(BigInt, x))

rounddiv(x::Integer, y::Integer) = y > 0 ? fld(x + fld(y, 2), y) : fld(x - fld(-y, 2), y)

function pow_sqrt2(k::Integer)
    p = BigFloat(big(1) << (k >> 1))
    return isodd(k) ? p * sqrt2() : p
end

# Kept identical to the reference implementation (including its behaviour for
# x < 1) so that grid points are enumerated in the same order.
function floorlog(x, y)
    x <= 0 && throw(DomainError(x))
    tmp = y
    m = 0
    while x >= tmp || x * tmp < 1
        tmp *= tmp
        m += 1
    end
    pows = typeof(y)[y]
    for _ in 2:m
        push!(pows, pows[end] * pows[end])
    end
    n, r = x >= 1 ? (0, x) : (-1, x * tmp)
    for p in Iterators.reverse(pows)
        n <<= 1
        if r > p
            r /= p
            n += 1
        end
    end
    return n
end

function solve_quadratic(a, b, c)
    if a < 0
        a, b, c = -a, -b, -c
    end
    disc = b^2 - 4 * a * c
    disc < 0 && return nothing
    s1 = -b - sqrt(disc)
    s2 = -b + sqrt(disc)
    if b >= 0
        return (s1 / (2 * a), s2 / (2 * a))
    elseif iszero(c)
        return (zero(a), -b / a)
    else
        return ((2 * c) / s2, (2 * c) / s1)
    end
end
