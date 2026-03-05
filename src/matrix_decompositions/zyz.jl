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

    # Calculate theta from diagonal magnitude
    cos_theta_2 = min(abs(u00), 1.0)
    theta = 2 * acos(cos_theta_2)

    # Handle corner cases for numerical stability when sin(theta/2) is small

    # Case 1: theta ~ 0 (Identity-like)
    # U is diagonal-dominant. We extract phases directly from diagonal elements.
    if isapprox(theta, 0, atol=1e-10)
        gamma = angle(u00)
        # u11 = e^{i(gamma + phi + lambda)}
        # We can arbitrarily split phi and lambda. Let phi = 0.
        return (0.0, 0.0, angle(u11) - gamma, gamma)
    end

    # Case 2: theta ~ pi (X-like)
    # U is off-diagonal-dominant. We extract phases from off-diagonal elements.
    if isapprox(theta, π, atol=1e-10)
        # u10 = e^{i(gamma + phi)}. Let phi = 0 => gamma = angle(u10)
        gamma = angle(u10)
        # u01 = -e^{i(gamma + lambda)}
        lambda = angle(u01) - gamma - π
        return (theta, 0.0, lambda, gamma)
    end

    # General case
    # Extract gamma from u00 phase (cos term)
    gamma = angle(u00)

    # Extract phi and lambda from off-diagonals (sin terms)
    phi = angle(u10) - gamma
    lambda = angle(-u01) - gamma

    return (theta, phi, lambda, gamma)
end
