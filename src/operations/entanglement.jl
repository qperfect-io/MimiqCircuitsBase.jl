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

@doc raw"""
    BondDim()

Operation to get the bond dimension between two halves of the system and store in a z-register.

The bond dimension is only defined for a matrix-product state (MPS), which
can be written as (with ``i_1=i_{N+1}=1``)

```math
|\psi \rangle = \sum_{s_1,s_2,\ldots=1}^2
\sum_{i_2}^{\chi_2} \sum_{i_3}^{\chi_3} \ldots \sum_{i_N}^{\chi_N}
A^{(s_1)}_{i_1i_2} A^{(s_2)}_{i_2 i_3} A^{(s_3)}_{i_3 i_4} \ldots
A^{(s_N)}_{i_{N}i_{N+1}} | s_1, s_2, s_3, \ldots, s_N \rangle .
```
Here, ``\chi_k`` is the bond dimension, i.e. the dimension of the index ``i_k``.
The first and last bond dimensions are dummies, ``chi_0=chi_N=1``.
A bond dimension of 1 means there is no entanglement between the two halves
of the system.

See also [`VonNeumannEntropy`](@ref), [`SchmidtRank`](@ref).

## Examples

When pushing to a circuit, the qubit index ``k`` that we give will get back
the bond dimension ``i_{k}`` in the above notation, i.e. the bond dimension
between qubit ``k-1`` and qubit ``k``. For ``k=1`` the bond dimension
returned will always be 1.

```jldoctests
julia> k = 5;

julia> c = push!(Circuit(), BondDim(), k, 1)
5-qubit circuit with 1 instructions:
└── BondDim @ q[5], z[1]

```
"""
struct BondDim <: Operation{1,0,1} end

opname(::Type{<:BondDim}) = "BondDim"

inverse(::BondDim) = BondDim()

isunitary(::Type{<:BondDim}) = true

@doc raw"""
    VonNeumannEntropy()

Operation to get the bipartite Von Neumann entanglement entropy and store in a z-register.

The entanglement entropy for a bipartition into subsystems ``A`` and ``B``
is defined for a pure state ``\rho = | \psi \rangle\langle \psi |`` as

```math
\mathcal{S}(\rho_A) = - \mathrm{Tr}(\rho_A \log_2 \rho_A) 
= - \mathrm{Tr}(\rho_B \log_2 \rho_B)
= \mathcal{S}(\rho_A)
```

where ``\rho_A = \mathrm{Tr}_B(\rho)`` is the reduced density matrix.
A product state has ``\mathcal{S}(\rho_A)=0`` and a maximally entangled state
between ``A`` and ``B`` gives ``\mathcal{S}(\rho_A)=1``.

We only consider bipartitions where ``A=\{1,\ldots,k-1\}`` and ``B=\{k,\ldots,N\}``,
for some ``k`` and where ``N`` is the total number of qubits.

When the system is open (i.e. with noise) and we are using quantum trajectories,
the entanglement entropy of each trajectory is returned during execution.

See also [`BondDim`](@ref), [`SchmidtRank`](@ref).

## Examples

When pushing to a circuit, the qubit index ``k`` takes the role of the above bipartition
into ``A`` and ``B``. For ``k=1``, ``A`` is empty and the entanglement entropy will
always return 0.

```jldoctests
julia> k = 5;

julia> c = push!(Circuit(), VonNeumannEntropy(), k, 1)
5-qubit circuit with 1 instructions:
└── VonNeumannEntropy @ q[5], z[1]

```
"""
struct VonNeumannEntropy <: Operation{1,0,1} end

opname(::Type{<:VonNeumannEntropy}) = "VonNeumannEntropy"

inverse(::VonNeumannEntropy) = VonNeumannEntropy()

isunitary(::Type{<:VonNeumannEntropy}) = true

@doc raw"""
    SchmidtRank()

Operation to get the Schmidt rank of a bipartition and store in a z-register.

A Schmidt decomposition for a bipartition into subsystems ``A`` and ``B``
is defined for a pure state as 

```math
|\psi\rangle = \sum_{i=1}^{r} s_i |\alpha_i\rangle \otimes |\beta_i\rangle,
```

where ``|\alpha_i\rangle`` (``|\beta_i\rangle``) are orthonormal states acting
on ``A`` (``B``). The Schmidt rank is the number of terms ``r`` in the sum.
A product state gives ``r=1`` and ``r>1`` signals entanglement.

We only consider bipartitions where ``A=\{1,\ldots,k-1\}`` and ``B=\{k,\ldots,N\}``,
for some ``k`` and where ``N`` is the total number of qubits.

In MPS, when the state is optimally compressed, the Schmidt rank should
be equal to the bond dimension [`BondDim`](@ref).

See also [`VonNeumannEntropy`](@ref).

## Examples

When pushing to a circuit, the qubit index ``k`` takes the role of the above bipartition
into ``A`` and ``B``. For ``k=1``, ``A`` is empty and the Schmidt rank will
always return 1.

```jldoctests
julia> k = 5;

julia> c = push!(Circuit(), SchmidtRank(), k, 1)
5-qubit circuit with 1 instructions:
└── SchmidtRank @ q[5], z[1]

```
"""
struct SchmidtRank <: Operation{1,0,1} end

opname(::Type{<:SchmidtRank}) = "SchmidtRank"

inverse(::SchmidtRank) = SchmidtRank()

isunitary(::Type{<:SchmidtRank}) = true

