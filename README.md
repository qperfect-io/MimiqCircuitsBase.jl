# MimiqCircuitsBase.jl

Core library used to build and manage quantum algorithms as quantum circuits.

## Quick Start

```julia
julia> using MimiqCircuitsBase

julia> c = Circuit()
empty circuit

julia> push!(c, GateX(), 1)
1-qubit circuit with 1 gates:
└── X @ q1

julia> push!(c, GateT(), 1)
1-qubit circuit with 2 gates:
├── X @ q1
└── T @ q1

julia> push!(c, GateX(), 2)
2-qubit circuit with 3 gates:
├── X @ q1
├── T @ q1
└── X @ q2

julia> for i in 1:10
           push!(c, GateH(), i)
       end

julia> push!(c, GateCX(), 2, 3)
10-qubit circuit with 14 gates:
├── X @ q1
├── T @ q1
├── X @ q2
├── H @ q1
├── H @ q2
├── H @ q3
├── H @ q4
├── H @ q5
├── H @ q6
├── H @ q7
├── H @ q8
├── H @ q9
├── H @ q10
└── CX @ q2, q3

julia> push!(c, GateCU(-π, π, π/4, π/8), 3, 4)
10-qubit circuit with 15 gates:
├── X @ q1
├── T @ q1
├── X @ q2
├── H @ q1
├── H @ q2
├── H @ q3
├── H @ q4
├── H @ q5
├── H @ q6
├── H @ q7
├── H @ q8
├── H @ q9
├── H @ q10
├── CX @ q2, q3
└── CU(θ=-π⋅1.0, ϕ=π⋅1.0, λ=π⋅0.25, γ=π⋅0.125) @ q3, q4
````

## COPYRIGHT

Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

