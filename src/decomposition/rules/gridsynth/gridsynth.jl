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
# The algorithmic core of this rule (module `_GridSynth`, defined here and in
# the files it includes) is a Julia port of pygridsynth 1.2.0
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

"""
    _GridSynth

Internal implementation of the Ross–Selinger gridsynth algorithm.

Notation follows the paper: ω = e^{iπ/4}, λ = 1 + √2, and `conj2` is the
√2-conjugation (√2 ↦ -√2, written x• in the paper). Gate sequences are
returned as `Char` vectors in matrix-product order (leftmost gate is the
leftmost matrix factor, i.e. the last one applied).
"""
module _GridSynth

include("numeric.jl")
include("rings.jl")
include("gridop.jl")
include("region.jl")
include("upright.jl")
include("gridproblem.jl")
include("rng.jl")
include("diophantine.jl")
include("exact.jl")

# ---------------------------------------------------------------------------
# Approximate synthesis
# ---------------------------------------------------------------------------

function solve_fixed_k(sets, k::Int, has_phase::Bool, seed::UInt64, dloop::Int, floop::Int)
    result = Ref{Union{Nothing,DOmegaUnitary}}(nothing)
    solve_tdgp(sets..., k) do z
        residue(z * conj(z)) == 0 && return false
        if has_phase
            z = z * DOmega(ZOmega(0, -1, 1, 0), 1)
        end
        xi = DRootTwo(1) - DRootTwo(conj(z) * z)
        w = diophantine_dyadic(xi, seed, dloop, floop)
        w === nothing && return false
        z = reduce_denomexp(z)
        w = reduce_denomexp(w)
        z, w = _align(z, w)
        k1 = reduce_denomexp(z + w).k
        k2 = reduce_denomexp(z + mul_by_omega(w)).k
        k3 = reduce_denomexp(z + mul_by_omega_inv(w)).k
        if has_phase
            result[] = k1 <= k2 && k1 <= k3 ? unitary(z, w, -1) : unitary(z, mul_by_omega_inv(w), -1)
        else
            result[] = k1 <= k2 ? unitary(z, w, 0) : unitary(z, mul_by_omega(w), 0)
        end
        return true
    end
    return result[]
end

"""
    precision_bits(epsilon) -> Int

BigFloat precision needed to synthesize with error `epsilon` (the digit count
used by newsynth: 15 + 2.5⌈log₁₀(1/ε)⌉ decimal digits).
"""
function precision_bits(epsilon::Real)
    digits = 15 + 2.5 * ceil(-log10(epsilon))
    return ceil(Int, digits * log2(10))
end

"""
    gridsynth(theta, epsilon; seed=0, dloop=10, floop=10) -> Vector{Char}

Clifford+T approximation of Rz(θ) = diag(e^{-iθ/2}, e^{iθ/2}) up to a global
phase, with operator-norm error at most `epsilon`. Returns a word over
`'H'`, `'S'`, `'T'`, `'X'` in matrix-product order. Must be called with
BigFloat precision of at least `precision_bits(epsilon)`.
"""
function gridsynth(theta::BigFloat, epsilon::BigFloat; seed::Integer=0, dloop::Int=10, floop::Int=10)
    seed = UInt64(seed)
    er0 = EpsilonRegion(theta, epsilon)
    ud0 = UnitDisk()
    # Solutions of the form e^{iπ/8}·U are searched for in the regions scaled
    # by (2 ± √2); they are equivalent up to global phase.
    er1 = EpsilonRegion(theta, epsilon, ZRootTwo(2, 1))
    ud1 = UnitDisk(ZRootTwo(2, -1))
    opG = to_upright_ellipse_pair(er0.ellipse, ud0.ellipse)
    sets0 = (er0, ud0, to_upright_set_pair(er0, ud0, opG)...)
    sets1 = (er1, ud1, to_upright_set_pair(er1, ud1, opG)...)

    # Same (k, has_phase) visiting order as the reference implementation.
    k = 0
    has_phase = false
    while true
        U = solve_fixed_k(has_phase ? sets1 : sets0, k, has_phase, seed, dloop, floop)
        U === nothing || return decompose_domega_unitary(U)
        if k >= 2
            has_phase = !has_phase
            has_phase && (k += 1)
        elseif k == 0 && !has_phase
            k = 1
        elseif k == 1 && !has_phase
            k, has_phase = 0, true
        elseif k == 0 && has_phase
            k = 1
        else
            k, has_phase = 2, false
        end
    end
end

end # module _GridSynth

# Smaller tolerances still work but take seconds per rotation, and a Float64
# angle is only known to about 1e-16 anyway.
const GRIDSYNTH_MIN_EPSILON = 1e-100

"""
    GridSynthRewrite(; epsilon=1e-10, seed=0)

Rewrite rule that approximates `GateRZ` with a Clifford+T sequence, using the
Ross–Selinger gridsynth algorithm.

For `GateRZ(λ)` the rule emits a sequence of `GateH`, `GateS`, `GateSDG`,
`GateZ`, `GateT` and `GateX` whose unitary `V` satisfies
`min_φ ‖RZ(λ) − e^{iφ}V‖ ≤ epsilon` in operator norm. The approximation holds
up to a global phase, which is dropped. The T-count is about
`3·log₂(1/epsilon)` and, except for rare failures of the integer factoring
step, optimal among ancilla-free Clifford+T circuits with this error. Angles
that are multiples of `π/4` give their exact short decomposition.

The factoring step is randomized. For a fixed `seed`, the same angle and
tolerance always give the same sequence. Results are cached per angle, since
circuits often repeat the same rotation.

# Keyword Arguments

- `epsilon::Real`: operator-norm tolerance, `1e-100 ≤ epsilon < 1` (default
  `1e-10`). A rotation takes a few milliseconds at `1e-10` and up to about a
  second at `1e-100`.
- `seed::Integer`: seed of the randomized factoring step, in `[0, 2^64)`
  (default `0`).

Throws an `ArgumentError` if `epsilon` or `seed` is out of range. Decomposing
a `GateRZ` whose angle is not finite throws an `ArgumentError`.

# Supported Operations

- `GateRZ(λ)` with a numeric angle `λ`.

Symbolic angles are not matched. `GateRX`, `GateRY` and `GateU` must first be
reduced to Z-rotations, for example with [`ZYZRewrite`](@ref) and
[`ToZRotationRewrite`](@ref). [`CliffordTBasis`](@ref) does this and uses
this rule by default.

# Examples

```julia
# Approximate one rotation to the default tolerance 1e-10
decompose_step(GateRZ(0.123); rule=GridSynthRewrite())

# A coarser tolerance gives fewer T gates
decompose_step(GateRZ(0.123); rule=GridSynthRewrite(epsilon=1e-4))

# Choose the tolerance used by the Clifford+T basis
decompose(circuit; basis=CliffordTBasis(rotations=GridSynthRewrite(epsilon=1e-8)))
```

# References

- N. J. Ross and P. Selinger, "Optimal ancilla-free Clifford+T approximation
  of z-rotations", Quantum Inf. Comput. 16, 901 (2016), arXiv:1403.2975.

See also [`RewriteRule`](@ref), [`SolovayKitaevRewrite`](@ref), [`CliffordTBasis`](@ref).
"""
struct GridSynthRewrite <: RewriteRule
    epsilon::Float64
    seed::UInt64

    function GridSynthRewrite(; epsilon::Real=1e-10, seed::Integer=0)
        epsilon = Float64(epsilon)
        GRIDSYNTH_MIN_EPSILON <= epsilon < 1 || throw(
            ArgumentError("epsilon must be in [$GRIDSYNTH_MIN_EPSILON, 1), got $epsilon"),
        )
        0 <= seed <= typemax(UInt64) ||
            throw(ArgumentError("seed must be in [0, 2^64), got $seed"))
        new(epsilon, UInt64(seed))
    end
end

matches(::GridSynthRewrite, g::GateRZ) = !issymbolic(g.λ)
matches(::GridSynthRewrite, ::Operation) = false

# Circuits often repeat the same angle (QFT, Trotter steps), and synthesis at
# small epsilon costs milliseconds per call, so results are memoized. The cache
# is cleared rather than evicted when full; entries are cheap to recompute.
const _GRIDSYNTH_CACHE = Dict{Tuple{Float64,Float64,UInt64},Vector{Char}}()
const _GRIDSYNTH_CACHE_LOCK = ReentrantLock()
const _GRIDSYNTH_CACHE_MAX = 10_000

# The do-block form of setprecision is task-local only from Julia 1.12; before
# that it sets the global BigFloat precision, so concurrent syntheses at
# different epsilons would change each other's precision.
const _GRIDSYNTH_PRECISION_LOCK = ReentrantLock()

function _gridsynth_word(rule::GridSynthRewrite, λ::Float64)
    key = (λ, rule.epsilon, rule.seed)
    cached = lock(_GRIDSYNTH_CACHE_LOCK) do
        get(_GRIDSYNTH_CACHE, key, nothing)
    end
    cached === nothing || return cached
    word = lock(_GRIDSYNTH_PRECISION_LOCK) do
        setprecision(BigFloat, _GridSynth.precision_bits(rule.epsilon)) do
            _GridSynth.gridsynth(BigFloat(λ), BigFloat(rule.epsilon); seed=rule.seed)
        end
    end
    lock(_GRIDSYNTH_CACHE_LOCK) do
        length(_GRIDSYNTH_CACHE) >= _GRIDSYNTH_CACHE_MAX && empty!(_GRIDSYNTH_CACHE)
        _GRIDSYNTH_CACHE[key] = word
    end
    return word
end

function decompose_step!(builder, rule::GridSynthRewrite, g::GateRZ, qtargets, _, _)
    q = qtargets[1]
    λ = Float64(unwrapvalue(g.λ))
    isfinite(λ) || throw(ArgumentError("GridSynthRewrite: angle $λ is not finite"))
    word = _gridsynth_word(rule, λ)
    # The word is in matrix-product order, so the last letter acts first.
    i = length(word)
    while i >= 1
        c = word[i]
        if c == 'S'
            n = 0
            while i >= 1 && word[i] == 'S'
                n += 1
                i -= 1
            end
            n &= 3
            n == 1 && push!(builder, GateS(), q)
            n == 2 && push!(builder, GateZ(), q)
            n == 3 && push!(builder, GateSDG(), q)
            continue
        elseif c == 'H'
            push!(builder, GateH(), q)
        elseif c == 'T'
            push!(builder, GateT(), q)
        elseif c == 'X'
            push!(builder, GateX(), q)
        end
        i -= 1
    end
    return builder
end
