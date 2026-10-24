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
# Solver for the Diophantine equation t†t = ξ (Ross–Selinger §6): factoring,
# primality testing, modular square roots and the effort bounds that limit
# them.

# Bounds the effort spent on factoring (Pollard rho rounds) and on retrying
# unsolved factors. When a bound is hit the candidate is abandoned and the
# caller moves on to the next one.
mutable struct Effort
    rng::SplitMix64
    dloop::Int
    floop::Int
    dcount::Int
    fcount::Int
end

check_diophantine_continue(e::Effort) = e.dcount < e.dloop && (e.dcount += 1; true)
check_factoring_continue(e::Effort) = e.fcount < e.floop && (e.fcount += 1; true)

const NO_SOLUTION = :no_solution
const UNSOLVED = :unsolved

# Brent's variant of Pollard rho. Returns a nontrivial factor or `nothing`.
function find_factor(n::BigInt, e::Effort; M::Int=128)
    iseven(n) && n > 2 && return big(2)
    a = randint(e.rng, 1, n)
    y, r, k = a, 1, 0
    L = floor(10.0^(ndigits(n) / 4) * 1.1774 + 10)
    e.fcount = 0
    while true
        x = y + n
        while k < r
            q = big(1)
            y0 = y
            for _ in 1:M
                y = mod(y * y + a, n)
                q = mod(q * (x - y), n)
                k += 1
                k == r && break
            end
            g = gcd(q, n)
            if g != 1
                if g == n
                    y = y0
                    for _ in 1:M
                        y = mod(y * y + a, n)
                        g = gcd(x - y, n)
                        g != 1 && break
                    end
                end
                return g == n ? nothing : g
            end
            (k >= L || !check_factoring_continue(e)) && return nothing
        end
        r <<= 1
    end
end

function sqrt_negative_one(p::BigInt, e::Effort; L::Int=100)
    for _ in 1:L
        b = randint(e.rng, 1, p - 1)
        h = powermod(b, (p - 1) >> 2, p)
        r = mod(h * h, p)
        r == p - 1 && return h
        r != 1 && return nothing
    end
    return nothing
end

# First component of (x + √base)^n in F_p[√base].
function fp2_pow_first(x::BigInt, base::BigInt, p::BigInt, n::BigInt)
    ra, rb = big(1), big(0)
    ta, tb = mod(x, p), big(1)
    while n > 0
        if isodd(n)
            ra, rb = mod(ra * ta + mod(rb * tb, p) * base, p), mod(ra * tb + rb * ta, p)
        end
        ta, tb = mod(ta * ta + mod(tb * tb, p) * base, p), mod(2 * ta * tb, p)
        n >>= 1
    end
    return ra
end

# Square root of x modulo the prime p (Cipolla), or `nothing`.
function root_mod(x::Integer, p::BigInt, e::Effort; L::Int=100)
    x = mod(big(x), p)
    p == 2 && return x
    iszero(x) && return big(0)
    iseven(p) && p > 2 && return nothing
    powermod(x, (p - 1) ÷ 2, p) != 1 && return nothing
    for _ in 1:L
        b = randint(e.rng, 1, p - 1)
        powermod(b, p - 1, p) != 1 && return nothing
        base = mod(b * b + p - x, p)
        if powermod(base, (p - 1) ÷ 2, p) != 1
            return fp2_pow_first(b, base, p, (p + 1) ÷ 2)
        end
    end
    return nothing
end

# Probabilistic primality test, kept identical to the reference implementation.
function is_prime(n::BigInt, e::Effort; L::Int=4)
    n = abs(n)
    (n == 0 || n == 1) && return false
    iseven(n) && return n == 2
    r, d = 0, n - 1
    while iseven(d)
        r += 1
        d >>= 1
    end
    for _ in 1:L
        a = powermod(randint(e.rng, 1, n - 1), d, n)
        a == 1 && return true
        for _ in 1:r
            a == n - 1 && return true
            a = mod(a * a, n)
        end
    end
    return false
end

# Refines a partial factorisation into pairwise coprime factors.
function decompose_relatively_int_prime(partial::Vector{Tuple{BigInt,Int}})
    u = 1
    stack = reverse(partial)
    facs = Tuple{BigInt,Int}[]
    while !isempty(stack)
        b, kb = pop!(stack)
        i = 1
        while true
            if i > length(facs)
                if b == 1 || b == -1
                    b == -1 && isodd(kb) && (u = -u)
                else
                    push!(facs, (b, kb))
                end
                break
            end
            a, ka = facs[i]
            if a == b || a == -b
                a == -b && isodd(kb) && (u = -u)
                facs[i] = (a, ka + kb)
                break
            end
            g = gcd(a, b)
            if g == 1
                i += 1
                continue
            end
            ua, facsa = decompose_relatively_int_prime([(fld(a, g), ka), (g, ka + kb)])
            u *= ua
            facs[i] = facsa[1]
            append!(facs, facsa[2:end])
            push!(stack, (fld(b, g), kb))
            break
        end
    end
    return u, facs
end

function decompose_relatively_zomega_prime(partial::Vector{Tuple{ZRootTwo,Int}})
    u = ZRootTwo(1)
    stack = reverse(partial)
    facs = Tuple{ZRootTwo,Int}[]
    one_ = ZRootTwo(1)
    while !isempty(stack)
        b, kb = pop!(stack)
        i = 1
        while true
            if i > length(facs)
                if similar_(b, one_)
                    u *= b^kb
                else
                    push!(facs, (b, kb))
                end
                break
            end
            a, ka = facs[i]
            if similar_(a, b)
                u *= zdiv(b, a)^kb
                facs[i] = (a, ka + kb)
                break
            end
            g = zgcd(a, b)
            if similar_(g, one_)
                i += 1
                continue
            end
            ua, facsa = decompose_relatively_zomega_prime([(zdiv(a, g), ka), (g, ka + kb)])
            u *= ua
            facs[i] = facsa[1]
            append!(facs, facsa[2:end])
            push!(stack, (zdiv(b, g), kb))
            break
        end
    end
    return u, facs
end

# Finds t ∈ Z[ω] with t†t ~ η for a prime (or prime-power candidate) η, where
# p = |N(η)|. `divisor` is the element t must divide (p itself or η).
function adj_decompose_prime(p::BigInt, divisor::ZOmega, check, e::Effort)
    p = abs(p)
    (p == 0 || p == 1) && return ZOmega(p)
    p == 2 && return ZOmega(-1, 0, 1, 0)
    if is_prime(p, e)
        if p & 3 == 1
            h = sqrt_negative_one(p, e)
            h === nothing && return UNSOLVED
            t = zgcd(h + ZOmega(0, 1, 0, 0), divisor)
            return check(t) ? t : UNSOLVED
        elseif p & 7 == 3
            h = root_mod(-2, p, e)
            h === nothing && return UNSOLVED
            t = zgcd(h + ZOmega(1, 0, 1, 0), divisor)
            return check(t) ? t : UNSOLVED
        elseif p & 7 == 7
            return root_mod(2, p, e) === nothing ? UNSOLVED : NO_SOLUTION
        end
        return UNSOLVED
    end
    if p & 7 == 7
        return root_mod(2, p, e) === nothing ? UNSOLVED : NO_SOLUTION
    end
    return UNSOLVED
end

function adj_decompose_int_prime(p::BigInt, e::Effort)
    check(t) = (n = conj(t) * t; n == p || n == -p)
    return adj_decompose_prime(p, ZOmega(abs(p)), check, e)
end

function adj_decompose_int_prime_power(p::BigInt, k::Int, e::Effort)
    iseven(k) && return ZOmega(p^(k ÷ 2))
    t = adj_decompose_int_prime(p, e)
    return t isa Symbol ? t : t^k
end

function adj_decompose_int(n::BigInt, e::Effort)
    facs = Tuple{BigInt,Int}[(abs(n), 1)]
    t = ZOmega(1)
    while !isempty(facs)
        p, k = pop!(facs)
        tp = adj_decompose_int_prime_power(p, k, e)
        if tp === NO_SOLUTION
            return NO_SOLUTION
        elseif tp === UNSOLVED
            fac = find_factor(p, e)
            if fac === nothing
                push!(facs, (p, k))
                check_diophantine_continue(e) || return NO_SOLUTION
            else
                push!(facs, (fld(p, fac), k))
                push!(facs, (fac, k))
                _, facs = decompose_relatively_int_prime(facs)
            end
        else
            t *= tp
        end
    end
    return t
end

# ξ ~ ξ•
function adj_decompose_selfassociate(xi::ZRootTwo, e::Effort)
    iszero(xi) && return ZOmega(0)
    n = gcd(xi.a, xi.b)
    r = zdiv(xi, n)
    t1 = adj_decompose_int(n, e)
    t1 isa Symbol && return NO_SOLUTION
    return iszero(zrem(r, ZRootTwo(0, 1))) ? t1 * ZOmega(0, 0, 1, 1) : t1
end

function adj_decompose_zomega_prime(eta::ZRootTwo, e::Effort)
    check(t) = similar_zomega(conj(t) * t, ZOmega(eta))
    return adj_decompose_prime(znorm(eta), ZOmega(eta), check, e)
end

function similar_zomega(x::ZOmega, y::ZOmega)
    return iszero(zdivrem(x, y)[2]) && iszero(zdivrem(y, x)[2])
end

function adj_decompose_zomega_prime_power(eta::ZRootTwo, k::Int, e::Effort)
    iseven(k) && return ZOmega(eta^(k ÷ 2))
    t = adj_decompose_zomega_prime(eta, e)
    return t isa Symbol ? t : t^k
end

# gcd(ξ, ξ•) = 1
function adj_decompose_selfcoprime(xi::ZRootTwo, e::Effort)
    facs = Tuple{ZRootTwo,Int}[(xi, 1)]
    t = ZOmega(1)
    while !isempty(facs)
        eta, k = pop!(facs)
        teta = adj_decompose_zomega_prime_power(eta, k, e)
        if teta === NO_SOLUTION
            return NO_SOLUTION
        elseif teta === UNSOLVED
            facn = find_factor(abs(znorm(eta)), e)
            if facn === nothing
                push!(facs, (eta, k))
                check_diophantine_continue(e) || return NO_SOLUTION
            else
                fac = zgcd(xi, ZRootTwo(facn))
                push!(facs, (zdiv(eta, fac), k))
                push!(facs, (fac, k))
                _, facs = decompose_relatively_zomega_prime(facs)
            end
        else
            t *= teta
        end
    end
    return t
end

function adj_decompose(xi::ZRootTwo, e::Effort)
    iszero(xi) && return ZOmega(0)
    d = zgcd(xi, conj2(xi))
    eta = zdiv(xi, d)
    t1 = adj_decompose_selfassociate(d, e)
    t1 isa Symbol && return NO_SOLUTION
    t2 = adj_decompose_selfcoprime(eta, e)
    t2 isa Symbol && return NO_SOLUTION
    return t1 * t2
end

function diophantine(xi::ZRootTwo, e::Effort)
    e.dcount = 0
    iszero(xi) && return ZOmega(0)
    (xi < 0 || conj2(xi) < 0) && return NO_SOLUTION
    t = adj_decompose(xi, e)
    t isa Symbol && return NO_SOLUTION
    u = zdiv(xi, ZRootTwo(conj(t) * t))
    v = sqrt(u)
    v === nothing && return NO_SOLUTION
    return v * t
end

# Solves t†t = ξ for ξ ∈ D[√2]; returns a DOmega or `nothing`.
function diophantine_dyadic(xi::DRootTwo, seed::UInt64, dloop::Int, floop::Int)
    e = Effort(SplitMix64(seed), dloop, floop, 0, 0)
    kodd = isodd(xi.k)
    t = diophantine(kodd ? xi.alpha * LAMBDA : xi.alpha, e)
    t isa Symbol && return nothing
    kodd && (t *= ZOmega(0, -1, 1, 0))
    return DOmega(t, (xi.k >> 1) + Int(kodd))
end
