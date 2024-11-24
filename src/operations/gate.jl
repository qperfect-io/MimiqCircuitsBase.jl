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

"""
    AbstractGate{N} <: AbstractOperator{N}

Supertype for all the `N`-qubit unitary gates.

See also [`hilbertspacedim`](@ref), [`inverse`](@ref), [`isunitary`](@ref),
[`matrix`](@ref), [`numqubits`](@ref), [`opname`](@ref)
"""
abstract type AbstractGate{N} <: AbstractOperator{N} end

# documentation defined in src/abstract.jl
# in this library gate is a shorthand for 
# unitary gate.
isunitary(::Type{T}) where {T<:AbstractGate} = true

# documentation defined in src/docstrings.jl
# by default gates are wrapped in the Inverse operation
inverse(op::AbstractGate) = Inverse(op)

_power(op::AbstractGate, n) = Power(op, n)

function opsquared(::AbstractGate{N}) where {N}
    if N == 1
        return GateID()
    else
        return Parallel(N, GateID())
    end
end
