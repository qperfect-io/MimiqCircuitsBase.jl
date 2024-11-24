#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
    sinθ2, cosθ2 = sincos(θ / 2)
    return [cis(γ)*cosθ2 -cis(λ + γ)*sinθ2; cis(ϕ + γ)*sinθ2 cis(ϕ + λ + γ)*cosθ2]
end

function umatrixpi(θ, ϕ, λ, γ=0.0)
    sinθ2, cosθ2 = sincospi(θ / 2)
    return [
        cispi(γ)*cosθ2 -cispi(λ + γ)*sinθ2
        cispi(ϕ + γ)*sinθ2 cispi(ϕ + λ + γ)*cosθ2
    ]
end
