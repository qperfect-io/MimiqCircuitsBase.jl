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

@doc raw"""
    PolynomialOracle(xregsize, yregsize, a, b, c, d)
    PolynomialOracle(a, b, c, d) # lazy

Quantum oracle for a polynomial function of two registers.

Applies a ``\pi`` phase shift to any basis state which satifies
``a xy + bx + cy + d == 0``, where ``\ket{x}`` and ``\ket{y}`` are the states of
the two registers.

## Examples

```jldoctests
julia> c = push!(Circuit(), PolynomialOracle(5,5,1,2,3,4), 1:10...)
10-qubit circuit with 1 instructions:
└── PolynomialOracle(1, 2, 3, 4) @ q[1:5], q[6:10]

julia> push!(c, inverse(PolynomialOracle(5,5,1,2,3,4)), 1:10...)
10-qubit circuit with 2 instructions:
├── PolynomialOracle(1, 2, 3, 4) @ q[1:5], q[6:10]
└── PolynomialOracle(1, 2, 3, 4) @ q[1:5], q[6:10]
```

!!! warn
    This operation is not yet implemented for decomposition. Might not work with
    some backends, where is not specifically implemented.
"""
struct PolynomialOracle{NX,NY,N} <: AbstractGate{N}
    a::Num
    b::Num
    c::Num
    d::Num

    function PolynomialOracle{NX,NY,N}(a, b, c, d) where {NX,NY,N}
        if NX + NY != N
            throw(OperationError(PolynomialOracle, "Expected NX + NY == N, got $(NX) + $(NY) == $N."))
        end

        if !(NX isa Integer) || !(NY isa Integer) || !(N isa Integer)
            throw(OperationError(PolynomialOracle, "NX, NY, N, must be integers."))
        end

        if NX < 0 || NY < 0
            throw(OperationError(PolynomialOracle, "Number of qubits must be positive"))
        end

        if N < 1
            throw(OperationError(PolynomialOracle, "At least one register must have a size > 0"))
        end

        new{NX,NY,N}(a, b, c, d)
    end
end

function PolynomialOracle(nx, ny, a, b, c, d)
    PolynomialOracle{nx,ny,nx + ny}(a, b, c, d)
end

function PolynomialOracle(a, b, c, d)
    LazyExpr(PolynomialOracle, LazyArg(), LazyArg(), a, b, c, d)
end

opname(::Type{<:PolynomialOracle}) = "PolynomialOracle"

isunitary(::Type{<:PolynomialOracle}) = true

qregsizes(::PolynomialOracle{NX,NY,N}) where {NX,NY,N} = (NX, NY)

inverse(s::PolynomialOracle{NX,NY,N}) where {NX,NY,N} = s

# TODO: change when ID is generalized
_power(s::PolynomialOracle{NX,NY,N}, pwr) where {NX,NY,N} = _power_idempotent(s, control(N - 1, GateID()), pwr)

# decomposition requires auxiliary qubits
function decompose!(::Circuit, ::PolynomialOracle{NX,NY,N}, _, _) where {NX,NY,N}
    error("Unknown decomposition for PolynomialOracle")
end
