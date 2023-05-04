#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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

pmatrix(λ) = ComplexF64[1 0; 0 cis(λ)]

pmatrixpi(λ) = ComplexF64[1 0; 0 cispi(λ)]

gphase(λ) = cis(λ)

gphasepi(λ) = cispi(λ)

function umatrix(θ, ϕ, λ, γ=0.0)::Matrix{ComplexF64}
    cosθ2 = cos(θ / 2)
    sinθ2 = sin(θ / 2)
    ComplexF64[cis(γ)*cosθ2 -cis(λ + γ)*sinθ2; cis(ϕ + γ)*sinθ2 cis(ϕ + λ + γ)*cosθ2]
end

function umatrixpi(θ, ϕ, λ, γ=0.0)::Matrix{ComplexF64}
    cosθ2 = cospi(θ / 2)
    sinθ2 = sinpi(θ / 2)
    ComplexF64[
        cispi(γ)*cosθ2 -cispi(λ + γ)*sinθ2
        cispi(ϕ + γ)*sinθ2 cispi(ϕ + λ + γ)*cosθ2
    ]
end

function rmatrix(θ, ϕ)::Matrix{ComplexF64}
    cosθ2 = cos(θ / 2)
    sinθ2 = sin(θ / 2)
    ComplexF64[cosθ2 -im*cis(-ϕ)*sinθ2; -im*cis(ϕ)*sinθ2 cosθ2]
end

function rmatrixpi(θ, ϕ)::Matrix{ComplexF64}
    cosθ2 = cospi(θ / 2)
    sinθ2 = sinpi(θ / 2)
    ComplexF64[cosθ2 -im*cispi(-ϕ)*sinθ2; -im*cispi(ϕ)*sinθ2 cosθ2]
end


rxmatrix(θ) = umatrixpi(θ / π, -1 / 2, 1 / 2)
rymatrix(θ) = umatrixpi(θ / π, 0, 0) |> _decomplex
rzmatrix(λ) = gphasepi(-λ / π / 2) * umatrixpi(0, 0, λ / π)
