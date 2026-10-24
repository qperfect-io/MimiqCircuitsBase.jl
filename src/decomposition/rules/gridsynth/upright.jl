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
# Reduction of an ellipse pair to upright form by repeated application of
# the Step Lemma (Ross–Selinger Appendix A).

function shift_ellipse_pair(P::EllipsePair, n::Integer)
    ln = to_real(LAMBDA^n)
    lin = to_real(LAMBDA^(-n))
    A = Ellipse(P.A.a * lin, P.A.b, P.A.d * ln, P.A.px, P.A.py)
    B = Ellipse(P.B.a * ln, isodd(n) ? -P.B.b : P.B.b, P.B.d * lin, P.B.px, P.B.py)
    return EllipsePair(A, B)
end

# One step of the Step Lemma. Returns (pair, opG_l, opG_r, done).
function step_lemma(P::EllipsePair, gl::GridOp, gr::GridOp)
    A, B = P.A, P.B
    apply(op) = (op * P, gl, op * gr, false)
    if B.b < 0
        return apply(OP_Z)
    elseif bias(A) * bias(B) < 1
        return apply(OP_X)
    elseif bias(P) > 33.971 || bias(P) < 0.029437
        n = round(Int, log(bias(P)) / log(to_real(LAMBDA)) / 8)
        return apply(OP_S^n)
    elseif skew(P) <= 15
        return (P, gl, gr, true)
    elseif bias(P) > 5.8285 || bias(P) < 0.17157
        n = round(Int, log(bias(P)) / log(to_real(LAMBDA)) / 4)
        P = shift_ellipse_pair(P, n)
        if n >= 0
            return (P, gl * OP_SIGMA_L^n, OP_SIGMA_R^n * gr, false)
        else
            return (P, gl * OP_SIGMA_L_INV^(-n), OP_SIGMA_R_INV^(-n) * gr, false)
        end
    elseif 0.24410 <= bias(A) <= 4.0968 && 0.24410 <= bias(B) <= 4.0968
        return apply(OP_R)
    elseif A.b >= 0 && bias(A) <= 1.6969
        return apply(OP_K)
    elseif A.b >= 0 && bias(B) <= 1.6969
        return apply(OP_K_CONJ2)
    elseif A.b >= 0
        n = max(1, floorsqrt(min(bias(A), bias(B)) / 4))
        return apply(GridOp(ZOmega(0, 0, 0, 1), ZOmega(0, 1, 0, 2 * n)))
    else
        n = max(1, floorsqrt(min(bias(A), bias(B)) / 2))
        return apply(GridOp(ZOmega(0, 0, 0, 1), ZOmega(n, 1, -n, 0)))
    end
end

function to_upright_ellipse_pair(A::Ellipse, B::Ellipse)
    P = EllipsePair(normalize(A), normalize(B))
    gl, gr = OP_I, OP_I
    while true
        P, gl, gr, done = step_lemma(P, gl, gr)
        done && break
    end
    return gl * gr
end

function to_upright_set_pair(setA, setB, opG::GridOp)
    P = opG * EllipsePair(setA.ellipse, setB.ellipse)
    return (opG, P.A, P.B, bbox(P.A), bbox(P.B))
end
