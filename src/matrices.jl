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

pmatrix(λ) = [1 0; 0 cis(λ)]

pmatrixpi(λ) = [1 0; 0 cispi(λ)]

gphase(λ) = cis(λ)

gphasepi(λ) = cispi(λ)

function umatrix(θ, ϕ, λ, γ=0.0)
    return cis(γ) * [
        1+cis(θ) -im*cis(λ)*(1-cis(θ))
        im*cis(ϕ)*(1-cis(θ)) cis(ϕ + λ)*(1+cis(θ))
    ] / 2
end

function umatrixpi(θ, ϕ, λ, γ=0.0)
    return cispi(γ) * [
        1+cispi(θ) -im*cispi(λ)*(1-cispi(θ))
        im*cispi(ϕ)*(1-cispi(θ)) cispi(ϕ + λ)*(1+cispi(θ))
    ] / 2
end

# Deprecated functions (see error in OpenQASM3 paper), and correction on
# https://openqasm.com/language/gates.html#id1

function umatrix_old(θ, ϕ, λ, γ=0.0)
    cosθ2 = cos(θ / 2)
    sinθ2 = sin(θ / 2)
    return [cis(γ)*cosθ2 -cis(λ + γ)*sinθ2; cis(ϕ + γ)*sinθ2 cis(ϕ + λ + γ)*cosθ2]
end

function umatrixpi_old(θ, ϕ, λ, γ=0.0)
    cosθ2 = cospi(θ / 2)
    sinθ2 = sinpi(θ / 2)
    return [
        cispi(γ)*cosθ2 -cispi(λ + γ)*sinθ2
        cispi(ϕ + γ)*sinθ2 cispi(ϕ + λ + γ)*cosθ2
    ]
end
