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
# One- and two-dimensional grid problem solvers. Solvers enumerate solutions
# by calling `f(solution)`; `f` returns `true` to stop the enumeration, and
# the solver then returns `true`.

# One-dimensional grid problem: all β ∈ Z[√2] with β ∈ I and β• ∈ J.
function odgp_internal(f, I::Interval, J::Interval)
    (width(I) < 0 || width(J) < 0) && return false
    swap = false
    if width(I) > 0 && width(J) <= 0
        I, J = J, I
        swap = true
    end
    # Rescale by powers of λ until J has width in [1, λ): the solutions of the
    # scaled problem map back by multiplication with λ⁻ⁿ.
    mult = ZRootTwo(1)
    lam = to_real(LAMBDA)
    while true
        n = width(J) <= 0 ? 0 : floorlog(width(J), lam)
        n == 0 && break
        I = I * to_real(LAMBDA^n)
        J = J * to_real(conj2(LAMBDA)^n)
        mult = mult * LAMBDA^(-n)
    end
    s2 = sqrt2()
    for a in ceil(BigInt, (I.l + J.l) / 2):floor(BigInt, (I.r + J.r) / 2)
        for b in ceil(BigInt, s2 * (a - J.r) / 2):floor(BigInt, s2 * (a - J.l) / 2)
            beta = ZRootTwo(a, b) * mult
            swap && (beta = conj2(beta))
            f(beta) && return true
        end
    end
    return false
end

function solve_odgp(f, I::Interval, J::Interval)
    (width(I) < 0 || width(J) < 0) && return false
    alpha = ZRootTwo(floor(BigInt, (I.l + J.l) / 2), floor(BigInt, sqrt2() * (I.l - J.l) / 4))
    return odgp_internal(I - to_real(alpha), J - to_real(conj2(alpha))) do beta
        beta = beta + alpha
        within(I, to_real(beta)) && within(J, to_real(conj2(beta))) && f(beta)
    end
end

function solve_odgp_with_parity(f, I::Interval, J::Interval, beta::ZRootTwo)
    p = parity(beta)
    s2 = sqrt2()
    return solve_odgp((I - p) * s2 / 2, (J - p) * (-s2) / 2) do alpha
        f(alpha * ZRootTwo(0, 1) + p)
    end
end

function solve_scaled_odgp(f, I::Interval, J::Interval, k::Integer)
    scale = pow_sqrt2(k)
    return solve_odgp(I * scale, isodd(k) ? (-J) * scale : J * scale) do alpha
        f(DRootTwo(alpha, k))
    end
end

function solve_scaled_odgp_with_parity(f, I::Interval, J::Interval, k::Integer, beta::DRootTwo)
    if k == 0
        return solve_odgp_with_parity(I, J, renew_denomexp(beta, 0).alpha) do alpha
            f(DRootTwo(alpha, 0))
        end
    end
    p = parity(renew_denomexp(beta, k))
    offset = p == 0 ? DRootTwo(0) : power_of_inv_sqrt2(k)
    return solve_scaled_odgp(I - to_real(offset), J - to_real(conj2(offset)), k - 1) do alpha
        f(alpha + offset)
    end
end

function _first_scaled_odgp(I::Interval, J::Interval, k::Integer)
    found = Ref{Union{Nothing,DRootTwo}}(nothing)
    solve_scaled_odgp(I, J, k) do alpha
        found[] = alpha
        true
    end
    return found[]
end

# Two-dimensional grid problem: all z ∈ D[ω] with denominator exponent k such
# that z ∈ setA and z• ∈ setB, using the upright bounding boxes computed by
# `to_upright_set_pair`.
function solve_tdgp(f, setA, setB, opG, _, _, bboxA::Rectangle, bboxB::Rectangle, k::Integer)
    opG_inv = inv(opG)
    alpha0 = _first_scaled_odgp(bboxA.x, bboxB.x, k + 1)
    alpha0 === nothing && return false

    dx = power_of_inv_sqrt2(k)
    v = opG_inv * from_droottwo_vector(dx, DRootTwo(0), k)
    vc = conj2(v)
    Iy_A = fatten(bboxA.y, width(bboxA.y) * 1e-4)
    Iy_B = fatten(bboxB.y, width(bboxB.y) * 1e-4)
    scale_k = BigFloat(2)^k

    return solve_scaled_odgp(Iy_A, Iy_B, k + 1) do beta
        z0 = opG_inv * from_droottwo_vector(alpha0, beta, k + 1)
        tA = intersect(setA, z0, v)
        tB = intersect(setB, conj2(z0), vc)
        (tA === nothing || tB === nothing) && return false
        par = renewing_denomexp(beta - alpha0, k)
        intA = Interval(tA...)
        intB = Interval(tB...)
        dtA = 10 / max(10, scale_k * width(intB))
        dtB = 10 / max(10, scale_k * width(intA))
        solve_scaled_odgp_with_parity(fatten(intA, dtA), fatten(intB, dtB), 1, par) do alpha
            z = opG_inv * from_droottwo_vector(alpha * dx + alpha0, beta, k)
            inside(setA, z) && inside(setB, conj2(z)) && f(z)
        end
    end
end
