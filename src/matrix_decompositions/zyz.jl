#
# Copyright © 2025-2025 QPerfect. All Rights Reserved.
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

"""
    _zyz_decomposition(U::AbstractMatrix)

Decompose a single qubit unitary matrix `U` into angles `θ, ϕ, λ, γ` such that
`U` is equivalent to `GateU(θ, ϕ, λ, γ)`.

Returns a tuple `(θ, ϕ, λ, γ)`.
"""
function _zyz_decomposition(U::AbstractMatrix)
    # Decompose U = e^{iγ} Rz(ϕ) Ry(θ) Rz(λ)
    # matching the GateU definition:
    # U = e^{iγ} [ cos(θ/2)       -e^{iλ}sin(θ/2) ]
    #            [ e^{iϕ}sin(θ/2)  e^{i(ϕ+λ)}cos(θ/2) ]

    u00 = U[1, 1]
    u01 = U[1, 2]
    u10 = U[2, 1]
    u11 = U[2, 2]

    # cos(θ/2) and sin(θ/2) read straight off the matrix, and θ from their
    # ratio. Going through `acos(|u00|)` instead loses half the significant
    # digits whenever `|u00| ≈ 1` — `acos(1 - ε) ≈ √(2ε)`, so a diagonal matrix
    # comes out with θ ≈ 1.5e-8 instead of 0, which is both a 1e-8 error in the
    # reconstruction and enough to miss any test for "θ is zero".
    c = abs(u00)
    s = abs(u10)
    theta = 2 * atan(s, c)

    # Diagonal: the off-diagonal entries are exactly zero, so ϕ is free — only
    # ϕ + λ is fixed, and the conventional choice is ϕ = 0.
    if iszero(s)
        gamma = angle(u00)
        return (0.0, 0.0, angle(u11) - gamma, gamma)
    end

    # Anti-diagonal: both diagonal entries vanish, so γ and λ cannot be read
    # from them. `u01` and `u10` carry independent phases here (any
    # `[0 b; a 0]` with `|a| = |b| = 1` is unitary), so λ must come from `u01`.
    if c <= 1e-8 * max(c, s)
        gamma = angle(u10)
        return (float(π), 0.0, angle(u01) - gamma - π, gamma)
    end

    # Everywhere else, take every phase from an entry of size cos(θ/2) except
    # ϕ, whose defining entry is `u10`. Reading λ from `u11` rather than from
    # `u01` is what keeps a near-diagonal matrix exact: the noisy `angle(u10)`
    # of a vanishing entry then enters ϕ and λ with opposite signs, so it
    # cancels in `ϕ + λ` — the only combination that multiplies cos(θ/2) — and
    # what it does reach is scaled by sin(θ/2) ≈ 0.
    gamma = angle(u00)
    phi = angle(u10) - gamma
    lambda = angle(u11) - angle(u10)

    return (theta, phi, lambda, gamma)
end
