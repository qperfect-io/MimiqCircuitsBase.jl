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

using LinearAlgebra
using NearestNeighbors

"""
    SolovayKitaevRewrite <: RewriteRule

Rewrite rule that approximates arbitrary single-qubit unitaries using the
Solovay-Kitaev algorithm, producing a sequence of Clifford+T gates.

The algorithm recursively refines an initial approximation using group
commutators, achieving ε-approximation with O(log^c(1/ε)) gates where c ≈ 3.97.

# Parameters

- `depth::Int`: Recursion depth (default: 3). Higher depth = better precision but more gates.
- `simplify::Bool`: Whether to simplify the resulting gate sequence (default: true).
- `basis_gates::Vector{AbstractGate}`: The basis set to use (default: Clifford+T).
- `net_max_depth::Int`: Max depth for generating the initial epsilon-net (default: 15).
- `net_max_points::Int`: Max points in the epsilon-net (default: 100,000).
- `net_min_dist::Float64`: Minimum distance for epsilon-net points (default: 0.01).

# Supported Operations

- `GateRZ(λ)` — Z-rotation by angle λ
- `GateRY(θ)` — Y-rotation by angle θ
- `GateRX(θ)` — X-rotation by angle θ
- `GateU(θ, ϕ, λ, γ)` — General single-qubit unitary

Symbolic parameters are not supported.

# Output Gates

The decomposition produces gates from the provided `basis_gates`. 
For the default Clifford+T basis: `GateH`, `GateS`, `GateSDG`, `GateT`, `GateTDG`, `GateX`, `GateY`, `GateZ`.

# Examples

```julia
# Default depth (3)
decompose_step(GateRZ(0.123); rule=SolovayKitaevRewrite())

# Higher precision, custom basis
decompose_step(GateRZ(0.123); rule=SolovayKitaevRewrite(5; basis_gates=[GateH(), GateT()]))
```

# References

- Dawson & Nielsen, "The Solovay-Kitaev algorithm" (2005)
- Kitaev, Shen, Vyalyi, "Classical and Quantum Computation" (2002)

See also [`RewriteRule`](@ref), [`SpecialAngleRewrite`](@ref).
"""
struct SolovayKitaevRewrite <: RewriteRule
    depth::Int
    simplify::Bool
    basis_gates::Vector{AbstractGate}
    net_max_depth::Int
    net_max_points::Int
    net_min_dist::Float64

    function SolovayKitaevRewrite(depth::Int=3; simplify::Bool=true, basis_gates=collect(SK_BASIC_GATES), net_max_depth::Int=SK_NET_MAX_DEPTH, net_max_points::Int=SK_NET_MAX_POINTS, net_min_dist::Float64=SK_NET_MIN_DIST)
        depth < 0 && throw(ArgumentError("depth must be non-negative"))
        new(depth, simplify, basis_gates, net_max_depth, net_max_points, net_min_dist)
    end
end

# === matches — single-qubit rotations with concrete angles ===

function matches(::SolovayKitaevRewrite, g::GateRZ)
    return !issymbolic(g.λ)
end

function matches(::SolovayKitaevRewrite, g::GateRY)
    return !issymbolic(g.θ)
end

function matches(::SolovayKitaevRewrite, g::GateRX)
    return !issymbolic(g.θ)
end

function matches(::SolovayKitaevRewrite, g::GateU)
    return !issymbolic(g.θ) && !issymbolic(g.ϕ) && !issymbolic(g.λ)
end

matches(::SolovayKitaevRewrite, ::Operation) = false

# === SU(2) Utilities ===

"""
    to_su2(U::AbstractMatrix) -> Matrix{ComplexF64}

Project a 2×2 unitary matrix to SU(2) by removing the global phase.
"""
function to_su2(U::AbstractMatrix)
    d = det(U)
    # Use principal square root for consistent phase choice
    phase = sqrt(d)
    return Matrix{ComplexF64}(U / phase)
end

"""
    matrix_to_point(U::Matrix) -> Vector{Float64}

Map an SU(2) matrix to a point in R⁴ (the 3-sphere S³).

For SU(2), a matrix [[a, -b*], [b, a*]] is determined by its first column [a, b].
We map this to [Re(a), Im(a), Re(b), Im(b)] ∈ S³.
"""
function matrix_to_point(U::Matrix)
    a, b = U[1, 1], U[2, 1]
    return Float64[real(a), imag(a), real(b), imag(b)]
end

"""
    operator_norm_distance(U::Matrix, V::Matrix) -> Float64

Compute the operator norm distance ||U - V||.
For SU(2) matrices, this equals 2·sin(θ/2) where θ is the geodesic distance.
"""
function operator_norm_distance(U::Matrix, V::Matrix)
    # For 2×2, operator norm = largest singular value of (U-V)
    # Efficient approximation using Frobenius norm (upper bound, tight for SU(2))
    s = 0.0
    for i = 1:2, j = 1:2
        d = U[i, j] - V[i, j]
        s += abs2(d)
    end
    return sqrt(s)
end

"""
    extract_rotation_angle(U::Matrix{ComplexF64}) -> Float64

Extract the rotation angle θ from an SU(2) matrix U = exp(iθ n·σ/2).
Returns θ ∈ [0, 2π].
"""
function extract_rotation_angle(U::Matrix{ComplexF64})
    # For U = cos(θ/2)I + i·sin(θ/2)(n·σ), we have tr(U) = 2cos(θ/2)
    cos_half = real(tr(U)) / 2
    cos_half = clamp(cos_half, -1.0, 1.0)
    return 2 * acos(cos_half)
end

"""
    extract_rotation_axis(U::Matrix{ComplexF64}) -> Vector{Float64}

Extract the rotation axis n from an SU(2) matrix U = exp(iθ n·σ/2).
Returns a unit vector in R³. If U ≈ I, returns [0, 0, 1].
"""
function extract_rotation_axis(U::Matrix{ComplexF64})
    # U = cos(θ/2)I + i⋅sin(θ/2)(n⋅σ)
    # n_k = Im(Tr(U σ_k)) / (2 sin(θ/2))

    nx = imag(U[1, 2] + U[2, 1]) / 2  # sin(θ/2)·nx
    ny = real(U[1, 2] - U[2, 1]) / 2  # sin(θ/2)·ny
    nz = imag(U[1, 1] - U[2, 2]) / 2  # sin(θ/2)·nz

    n = Float64[nx, ny, nz]
    norm_n = norm(n)

    if norm_n < 1e-10
        # U ≈ I, axis is undefined; return default
        return Float64[0.0, 0.0, 1.0]
    end

    return n / norm_n
end

"""
    axis_angle_to_su2(axis::Vector{Float64}, θ::Float64) -> Matrix{ComplexF64}

Construct an SU(2) matrix from rotation axis and angle.
U = cos(θ/2)·I + i·sin(θ/2)·(n·σ)
"""
function axis_angle_to_su2(axis::Vector{Float64}, θ::Float64)
    c = cos(θ / 2)
    s = sin(θ / 2)
    nx, ny, nz = axis

    return ComplexF64[
        c+im*s*nz s*(im*nx+ny)
        s*(im*nx-ny) c-im*s*nz
    ]
end

"""
    find_orthogonal_axes(n::Vector{Float64}) -> Tuple{Vector{Float64}, Vector{Float64}}

Find two orthonormal vectors v, w that are perpendicular to n,
such that (v, w, n) form a right-handed coordinate system.
"""
function find_orthogonal_axes(n::Vector{Float64})
    # Choose initial vector not parallel to n
    if abs(n[1]) < 0.9
        seed = Float64[1.0, 0.0, 0.0]
    else
        seed = Float64[0.0, 1.0, 0.0]
    end

    # Gram-Schmidt
    v = seed - dot(seed, n) * n
    v = v / norm(v)

    w = cross(v, n)
    w = w / norm(w)

    return v, w
end

# === ε-net Generation ===

"""Basic gates for the ε-net."""
const SK_BASIC_GATES =
    (GateH(), GateT(), GateTDG(), GateS(), GateSDG(), GateX(), GateY(), GateZ())

const SK_NET_MAX_DEPTH = 15
const SK_NET_MAX_POINTS = 100_000
const SK_NET_MIN_DIST = 0.01

"""
    generate_epsilon_net(basis_gates, max_depth, max_points, min_dist) -> (points, gate_sequences)

Generate an ε-net over SU(2) using Breadth-First Search.
"""
function generate_epsilon_net(
    basis_gates::Vector{<:AbstractGate},
    max_depth::Int=SK_NET_MAX_DEPTH,
    max_points::Int=SK_NET_MAX_POINTS,
    min_dist::Float64=SK_NET_MIN_DIST
)
    # Start with identity
    I2 = Matrix{ComplexF64}(I, 2, 2)

    points = Vector{Vector{Float64}}()
    sequences = Vector{Vector{AbstractGate}}()

    push!(points, matrix_to_point(I2))
    push!(sequences, AbstractGate[])

    current_level = [(I2, AbstractGate[])]

    for _ = 1:max_depth
        next_level = Vector{Tuple{Matrix{ComplexF64},Vector{AbstractGate}}}()

        for (U, gates) in current_level
            for g in basis_gates
                U_new = matrix(g) * U
                U_new_su2 = to_su2(U_new)
                p_new = matrix_to_point(U_new_su2)

                is_far = true
                for p in points
                    if sum((p .- p_new) .^ 2) < min_dist^2
                        is_far = false
                        break
                    end
                end

                if is_far
                    new_gates = vcat(gates, [g])
                    push!(next_level, (U_new_su2, new_gates))
                    push!(points, p_new)
                    push!(sequences, new_gates)

                    if length(points) >= max_points
                        return points, sequences
                    end
                end
            end
        end
        current_level = next_level
        isempty(current_level) && break
    end
    return points, sequences
end

# === Global Cache (Thread-Safe) ===

struct SKCacheEntry
    net_tree::KDTree
    net_sequences::Vector{Vector{AbstractGate}}
    net_matrices::Vector{Matrix{ComplexF64}}
end

const _SK_CACHE = Dict{UInt64,SKCacheEntry}()
const _SK_CACHE_LOCK = ReentrantLock()

"""
    get_sk_cache(basis_gates; max_depth, max_points, min_dist) -> SKCacheEntry

Get or initialize the Solovay-Kitaev lookup tables.
"""
function get_sk_cache(
    basis_gates::Vector{<:AbstractGate};
    max_depth::Int=SK_NET_MAX_DEPTH,
    max_points::Int=SK_NET_MAX_POINTS,
    min_dist::Float64=SK_NET_MIN_DIST
)
    # Hash basis + params
    h = hash(basis_gates)
    h = hash(max_depth, h)
    h = hash(max_points, h)
    h = hash(min_dist, h)

    lock(_SK_CACHE_LOCK) do
        if haskey(_SK_CACHE, h)
            return _SK_CACHE[h]
        end

        points, sequences = generate_epsilon_net(basis_gates, max_depth, max_points, min_dist)
        points_mat = reduce(hcat, points)
        net_tree = KDTree(points_mat)

        net_matrices = [sequence_to_matrix(seq) for seq in sequences]

        entry = SKCacheEntry(net_tree, sequences, net_matrices)
        _SK_CACHE[h] = entry
        return entry
    end
end

# === Gate Sequence Operations ===

"""
    invert_sequence(gates) -> Vector{AbstractGate}

Return the inverse of a gate sequence: (g₁ g₂ ... gₙ)† = gₙ† ... g₂† g₁†
"""
function invert_sequence(gates::Vector{AbstractGate})
    return AbstractGate[inverse(g) for g in reverse(gates)]
end

"""
    sequence_to_matrix(gates) -> Matrix{ComplexF64}

Compute the unitary matrix for a gate sequence.
"""
function sequence_to_matrix(gates::Vector{AbstractGate})
    M = Matrix{ComplexF64}(I, 2, 2)
    for g in gates
        M = matrix(g) * M
    end
    return M
end

"""
    simplify_sequence(gates, basis_gates) -> Vector{AbstractGate}

Simplify a gate sequence. If basis is standard Clifford+T, use algebraic rules.
Otherwise, use generic inverse cancellation.
"""
function simplify_sequence(gates::Vector{AbstractGate}, basis_gates::Vector{<:AbstractGate})
    # Check if we are using the standard basis
    if length(basis_gates) == length(SK_BASIC_GATES) && all(g in SK_BASIC_GATES for g in basis_gates)
        return simplify_sequence_clifford_t(gates)
    end

    return simplify_sequence_generic(gates)
end

function simplify_sequence(gates::Vector{AbstractGate})
    # Fallback if basis not provided (assume generic or try best effort)
    return simplify_sequence_generic(gates)
end

function simplify_sequence_clifford_t(gates::Vector{AbstractGate})
    isempty(gates) && return gates

    result = AbstractGate[]
    for g in gates
        if isempty(result)
            push!(result, g)
        else
            last_g = result[end]
            if _gates_cancel_clifford_t(last_g, g)
                pop!(result)
            elseif (combined = _try_combine_gates_clifford_t(last_g, g)) !== nothing
                pop!(result)
                push!(result, combined)
            else
                push!(result, g)
            end
        end
    end

    # Multiple passes
    prev_len = length(gates)
    while length(result) < prev_len
        prev_len = length(result)
        result = _simplify_pass_clifford_t(result)
    end
    return result
end

function _simplify_pass_clifford_t(gates::Vector{AbstractGate})
    isempty(gates) && return gates
    result = AbstractGate[]
    for g in gates
        if isempty(result)
            push!(result, g)
        else
            last_g = result[end]
            if _gates_cancel_clifford_t(last_g, g)
                pop!(result)
            elseif (combined = _try_combine_gates_clifford_t(last_g, g)) !== nothing
                pop!(result)
                push!(result, combined)
            else
                push!(result, g)
            end
        end
    end
    return result
end

function simplify_sequence_generic(gates::Vector{AbstractGate})
    isempty(gates) && return gates
    # Generic simplification: only remove adjacent inverses
    # g * g' = I
    result = AbstractGate[]
    for g in gates
        if isempty(result)
            push!(result, g)
        else
            last_g = result[end]
            # Check if inverses
            if g == inverse(last_g) || last_g == inverse(g)
                # Note: This relies on equality and inverse being correctly defined
                pop!(result)
            else
                push!(result, g)
            end
        end
    end
    return result
end

function _gates_cancel_clifford_t(g::AbstractGate, h::AbstractGate)
    (g isa GateT && h isa GateTDG) && return true
    (g isa GateTDG && h isa GateT) && return true
    (g isa GateS && h isa GateSDG) && return true
    (g isa GateSDG && h isa GateS) && return true
    (g isa GateH && h isa GateH) && return true
    (g isa GateX && h isa GateX) && return true
    (g isa GateY && h isa GateY) && return true
    (g isa GateZ && h isa GateZ) && return true
    return false
end

function _try_combine_gates_clifford_t(g::AbstractGate, h::AbstractGate)
    # T * T = S
    (g isa GateT && h isa GateT) && return GateS()
    (g isa GateTDG && h isa GateTDG) && return GateSDG()
    # S * S = Z
    (g isa GateS && h isa GateS) && return GateZ()
    (g isa GateSDG && h isa GateSDG) && return GateZ()
    return nothing
end

# === Group Commutator Decomposition (Key Component!) ===

"""
    gc_decompose(Δ::Matrix{ComplexF64}) -> Tuple{Matrix{ComplexF64}, Matrix{ComplexF64}}

Decompose an SU(2) matrix Δ (close to identity) into matrices V and W
such that the group commutator [V, W] = V W V† W† approximates Δ.

This is the balanced group commutator construction from Dawson-Nielsen.
For Δ representing a rotation by angle θ, V and W will be rotations
by angle ≈ √θ around carefully chosen axes.

# Mathematical Background

For small rotations, if V = exp(iφ v·σ/2) and W = exp(iφ w·σ/2),
then [V,W] ≈ exp(i φ² (v×w)·σ/2) to leading order.

To achieve [V,W] ≈ Δ = exp(iθ n·σ/2):
- Choose φ ≈ √θ  
- Choose v, w perpendicular to each other such that v×w ∝ n
"""
function gc_decompose(Δ::Matrix{ComplexF64})
    θ = extract_rotation_angle(Δ)

    # Handle near-identity case
    if θ < 1e-12
        I2 = Matrix{ComplexF64}(I, 2, 2)
        return I2, I2
    end

    n = extract_rotation_axis(Δ)

    # Balanced group commutator construction (Dawson-Nielsen).
    # φ satisfies: 4 sin²(φ/2) cos²(φ/2) = sin²(θ/2)

    sin_half_theta = sin(θ / 2)

    # Clamp argument to valid range for asin
    arg = sqrt(clamp(sin_half_theta / 2, 0.0, 1.0))
    φ = 2 * asin(arg)

    # Choose v and w perpendicular to each other, with v×w = n
    # This ensures the commutator rotates around the correct axis
    v, w = find_orthogonal_axes(n)

    # v, w are chosen such that v×w = n

    V = axis_angle_to_su2(v, φ)
    W = axis_angle_to_su2(w, φ)

    return V, W
end

# === Solovay-Kitaev Algorithm ===

"""
    find_nearest_in_net(U::Matrix{ComplexF64}, cache::SKCacheEntry) -> Vector{AbstractGate}

Find the gate sequence in the ε-net that best approximates U.
Handles the SU(2) double cover (U and -U represent the same rotation).
"""
function find_nearest_in_net(U::Matrix{ComplexF64}, cache::SKCacheEntry)
    pt = matrix_to_point(U)

    # Find nearest neighbor
    idx, _ = nn(cache.net_tree, pt)

    # Also check antipodal point (SU(2) double cover: U ≡ -U)
    pt_neg = -pt
    idx_neg, _ = nn(cache.net_tree, pt_neg)

    # Compare actual operator distances
    seq = cache.net_sequences[idx]
    seq_neg = cache.net_sequences[idx_neg]

    mat = cache.net_matrices[idx]
    mat_neg = cache.net_matrices[idx_neg]

    dist = operator_norm_distance(U, mat)
    dist_neg = operator_norm_distance(U, mat_neg)

    return dist <= dist_neg ? copy(seq) : copy(seq_neg)
end

"""
    sk_approximate(U::Matrix{ComplexF64}, depth::Int, basis_gates::Vector{<:AbstractGate}; ...) -> Vector{AbstractGate}

Approximate an SU(2) matrix using the Solovay-Kitaev algorithm.
"""
function sk_approximate(
    U::Matrix{ComplexF64},
    depth::Int,
    basis_gates::Vector{<:AbstractGate}=collect(SK_BASIC_GATES);
    net_max_depth::Int=SK_NET_MAX_DEPTH,
    net_max_points::Int=SK_NET_MAX_POINTS,
    net_min_dist::Float64=SK_NET_MIN_DIST
)
    cache = get_sk_cache(basis_gates; max_depth=net_max_depth, max_points=net_max_points, min_dist=net_min_dist)

    if depth == 0
        return find_nearest_in_net(U, cache)
    end

    U_prev_gates = sk_approximate(U, depth - 1, basis_gates; net_max_depth, net_max_points, net_min_dist)
    U_prev = to_su2(sequence_to_matrix(U_prev_gates))

    Δ = to_su2(U * U_prev')

    # Handle SU(2) double cover
    if real(tr(Δ)) < 0
        Δ = -Δ
    end

    V_mat, W_mat = gc_decompose(Δ)

    V_gates = sk_approximate(V_mat, depth - 1, basis_gates; net_max_depth, net_max_points, net_min_dist)
    W_gates = sk_approximate(W_mat, depth - 1, basis_gates; net_max_depth, net_max_points, net_min_dist)

    V_inv_gates = invert_sequence(V_gates)
    W_inv_gates = invert_sequence(W_gates)

    return vcat(U_prev_gates, W_inv_gates, V_inv_gates, W_gates, V_gates)
end

"""
    sk_approximate_memoized(U::Matrix{ComplexF64}, depth::Int; ...) -> Vector{AbstractGate}

Memoized version of sk_approximate.
"""
function sk_approximate_memoized(
    U::Matrix{ComplexF64},
    depth::Int;
    basis_gates::Vector{<:AbstractGate}=collect(SK_BASIC_GATES),
    net_max_depth::Int=SK_NET_MAX_DEPTH,
    net_max_points::Int=SK_NET_MAX_POINTS,
    net_min_dist::Float64=SK_NET_MIN_DIST,
    memo::Dict{Tuple{UInt64,Int},Vector{AbstractGate}}=Dict{Tuple{UInt64,Int},Vector{AbstractGate}}(),
    tolerance::Float64=1e-8,
)
    cache = get_sk_cache(basis_gates; max_depth=net_max_depth, max_points=net_max_points, min_dist=net_min_dist)

    # Create a hash key based on discretized matrix elements
    key = _matrix_hash(U, tolerance)
    memo_key = (key, depth)

    # Check memo
    haskey(memo, memo_key) && return copy(memo[memo_key])

    if depth == 0
        result = find_nearest_in_net(U, cache)
        memo[memo_key] = result
        return copy(result)
    end

    # Recursive case with memoization
    U_prev_gates = sk_approximate_memoized(U, depth - 1; basis_gates, net_max_depth, net_max_points, net_min_dist, memo, tolerance)
    U_prev = to_su2(sequence_to_matrix(U_prev_gates))

    Δ = to_su2(U * U_prev')

    if real(tr(Δ)) < 0
        Δ = -Δ
    end

    V_mat, W_mat = gc_decompose(Δ)

    V_gates = sk_approximate_memoized(V_mat, depth - 1; basis_gates, net_max_depth, net_max_points, net_min_dist, memo, tolerance)
    W_gates = sk_approximate_memoized(W_mat, depth - 1; basis_gates, net_max_depth, net_max_points, net_min_dist, memo, tolerance)

    # ... Invert and construct
    V_inv_gates = invert_sequence(V_gates)
    W_inv_gates = invert_sequence(W_gates)

    result = vcat(U_prev_gates, W_inv_gates, V_inv_gates, W_gates, V_gates)
    memo[memo_key] = result
    return copy(result)
end


"""Create a hash for an SU(2) matrix based on discretized elements."""
function _matrix_hash(U::Matrix{ComplexF64}, tol::Float64)
    # Discretize to grid
    scale = round(Int, 1 / tol)
    h = UInt64(0)
    for i = 1:2, j = 1:2
        re = round(Int, real(U[i, j]) * scale)
        im = round(Int, imag(U[i, j]) * scale)
        h = hash((re, im), h)
    end
    return h
end

# === decompose_step! Implementations ===

function decompose_step!(builder, rule::SolovayKitaevRewrite, g::GateRZ, qtargets, _, _)
    _sk_decompose!(builder, rule, matrix(g), qtargets[1])
end

function decompose_step!(builder, rule::SolovayKitaevRewrite, g::GateRY, qtargets, _, _)
    _sk_decompose!(builder, rule, matrix(g), qtargets[1])
end

function decompose_step!(builder, rule::SolovayKitaevRewrite, g::GateRX, qtargets, _, _)
    _sk_decompose!(builder, rule, matrix(g), qtargets[1])
end

function decompose_step!(builder, rule::SolovayKitaevRewrite, g::GateU, qtargets, _, _)
    _sk_decompose!(builder, rule, matrix(g), qtargets[1])
end

function _sk_decompose!(builder, rule::SolovayKitaevRewrite, U::Matrix, q)
    # Project to SU(2)
    U_su2 = to_su2(U)

    # Run Solovay-Kitaev 
    memo = Dict{Tuple{UInt64,Int},Vector{AbstractGate}}()
    gates = sk_approximate_memoized(U_su2, rule.depth;
        basis_gates=rule.basis_gates,
        net_max_depth=rule.net_max_depth,
        net_max_points=rule.net_max_points,
        memo)

    # Optionally simplify
    if rule.simplify
        gates = simplify_sequence(gates, rule.basis_gates)
    end

    # Emit gates
    for gate in gates
        push!(builder, gate, q)
    end

    return builder
end
