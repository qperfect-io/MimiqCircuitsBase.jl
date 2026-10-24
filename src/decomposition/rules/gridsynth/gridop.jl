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
# Grid operators: 2×2 matrices [u0 u1] acting on Z[ω] viewed as a lattice,
# and the constant operators used by the Step Lemma.

struct GridOp
    u0::ZOmega
    u1::ZOmega
end

const OP_I = GridOp(ZOmega(0, 0, 0, 1), ZOmega(0, 1, 0, 0))

function Base.:*(g::GridOp, x::ZOmega)
    a0, b0, c0, d0 = g.u0.a, g.u0.b, g.u0.c, g.u0.d
    a1, b1, c1, d1 = g.u1.a, g.u1.b, g.u1.c, g.u1.d
    nd = d0 * x.d + d1 * x.b + fld(c1 - a1 + c0 - a0, 2) * x.c + fld(c1 - a1 - c0 + a0, 2) * x.a
    nc = c0 * x.d + c1 * x.b + fld(b1 + d1 + b0 + d0, 2) * x.c + fld(b1 + d1 - b0 - d0, 2) * x.a
    nb = b0 * x.d + b1 * x.b + fld(c1 + a1 + c0 + a0, 2) * x.c + fld(c1 + a1 - c0 - a0, 2) * x.a
    na = a0 * x.d + a1 * x.b + fld(b1 - d1 + b0 - d0, 2) * x.c + fld(b1 - d1 - b0 + d0, 2) * x.a
    return ZOmega(na, nb, nc, nd)
end
Base.:*(g::GridOp, h::GridOp) = GridOp(g * h.u0, g * h.u1)
Base.:*(g::GridOp, x::DOmega) = DOmega(g * x.u, x.k)

conj2(g::GridOp) = GridOp(conj2(g.u0), conj2(g.u1))
to_matrix(g::GridOp) = (real(g.u0), real(g.u1), imag(g.u0), imag(g.u1))

function Base.inv(g::GridOp)
    a0, b0, c0, d0 = g.u0.a, g.u0.b, g.u0.c, g.u0.d
    a1, b1, c1, d1 = g.u1.a, g.u1.b, g.u1.c, g.u1.d
    v = conj(g.u0) * g.u1
    (v.a + v.c == 0 && abs(v.b) == 1) || throw(ArgumentError("grid operator is not special"))
    u0 = ZOmega(fld(-c1 - a1 - c0 - a0, 2), -b0, fld(c1 + a1 - c0 - a0, 2), b1)
    u1 = ZOmega(fld(c1 - a1 + c0 - a0, 2), d0, fld(-c1 + a1 + c0 - a0, 2), -d1)
    return v.b == -1 ? GridOp(-u0, -u1) : GridOp(u0, u1)
end

function Base.:^(g::GridOp, n::Integer)
    n < 0 && return inv(g)^(-n)
    r = OP_I
    t = g
    while n > 0
        isodd(n) && (r *= t)
        t *= t
        n >>= 1
    end
    return r
end

const OP_Z = GridOp(ZOmega(0, 0, 0, 1), ZOmega(0, -1, 0, 0))
const OP_X = GridOp(ZOmega(0, 1, 0, 0), ZOmega(0, 0, 0, 1))
const OP_S = GridOp(ZOmega(-1, 0, 1, 1), ZOmega(1, -1, 1, 0))
const OP_R = GridOp(ZOmega(0, 0, 1, 0), ZOmega(1, 0, 0, 0))
const OP_K = GridOp(ZOmega(-1, -1, 0, 0), ZOmega(0, -1, 1, 0))
const OP_K_CONJ2 = GridOp(ZOmega(1, -1, 0, 0), ZOmega(0, -1, -1, 0))
const OP_SIGMA_L = GridOp(ZOmega(-1, 0, 1, 1), ZOmega(0, 1, 0, 0))
const OP_SIGMA_R = GridOp(ZOmega(0, 0, 0, 1), ZOmega(1, -1, 1, 0))
const OP_SIGMA_L_INV = GridOp(ZOmega(-1, 0, 1, -1), ZOmega(0, 1, 0, 0))
const OP_SIGMA_R_INV = GridOp(ZOmega(0, 0, 0, 1), ZOmega(1, 1, 1, 0))
