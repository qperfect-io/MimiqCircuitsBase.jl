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

@doc raw"""
    _csd_decomposition(U::AbstractMatrix)

Perform Cosine-Sine Decomposition (CSD) on a unitary matrix `U`.
Returns `(L0, L1, R0, R1, theta)` such that:

```math
U = \begin{pmatrix} L_0 & 0 \\ 0 & L_1 \end{pmatrix} 
    \begin{pmatrix} C & -S \\ S & C \end{pmatrix} 
    \begin{pmatrix} R_0 & 0 \\ 0 & R_1 \end{pmatrix}
```

where ``C = \operatorname{diag}(\cos(\theta))`` and ``S = \operatorname{diag}(\sin(\theta))``.
``L_0, L_1, R_0, R_1`` are unitary matrices of half size.
``\theta`` is a vector of angles.
"""
function _csd_decomposition(U::AbstractMatrix)
    n = size(U, 1)
    if n % 2 != 0
        error("Matrix dimension must be even for CSD.")
    end
    m = n ÷ 2

    # Partition U
    u00 = U[1:m, 1:m]
    u01 = U[1:m, m+1:n]
    u10 = U[m+1:n, 1:m]
    u11 = U[m+1:n, m+1:n]

    # u00 = L0 * C_diag * R0
    F = svd(u00)
    L0 = F.U
    C_diag = F.S
    R0 = F.Vt

    # Re-normalize C to be in [0, 1] range (numerical stability)
    C_diag = min.(max.(C_diag, 0.0), 1.0)
    theta = acos.(C_diag)

    L1 = zeros(ComplexF64, m, m)
    R1 = zeros(ComplexF64, m, m)

    threshold = 1e-6

    determined_indices = findall(x -> x > threshold, sin.(theta))
    undetermined_indices = findall(x -> x <= threshold, sin.(theta))

    # Fill determined parts where sin(theta) != 0
    S_inv = [1.0 / sin(theta[i]) for i in determined_indices]

    # Derivation from u10 = L1 * S * R0 and u01 = - L0 * S * R1
    X = u10 * R0'
    Y = L0' * u01

    for (i, idx) in enumerate(determined_indices)
        L1[:, idx] = X[:, idx] * S_inv[i]
        R1[idx, :] = -Y[idx, :] * S_inv[i]
    end

    # Fill undetermined parts (where sin(theta) ≈ 0)
    # The relation u11 = L1 C R1 must be satisfied.
    # We solve for the remaining parts using the SVD of the residual.
    if !isempty(undetermined_indices)
        L1_det = L1[:, determined_indices]
        R1_det = R1[determined_indices, :]
        C_det = Diagonal(cos.(theta[determined_indices]))

        Rem = u11 - L1_det * C_det * R1_det

        F_rem = svd(Rem)
        n_undet = length(undetermined_indices)

        L1[:, undetermined_indices] = F_rem.U[:, 1:n_undet]
        R1[undetermined_indices, :] = F_rem.Vt[1:n_undet, :]
    end

    return L0, L1, R0, R1, theta
end
