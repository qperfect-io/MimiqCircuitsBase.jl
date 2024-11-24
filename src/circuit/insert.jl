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
    insert!(c::Circuit, i::Integer, operation::Operation{N,M,L}, targets::Vararg{Integer,K})

Insert an operation into the circuit at a specific position, with the given targets.

# Arguments
- `c::Circuit`: The quantum circuit where the operation will be inserted.
- `i::Integer`: The position in the circuit where the operation will be inserted (1-based index).
- `operation::Operation{N,M,L}`: The operation to apply, working on N qubits, M classical bits, and L z-variables.
- `targets::Vararg{Integer,K}`: The target qubits, classical bits, and z-variables, where `K` must match the number of required targets for the operation.

# Errors
- `ArgumentError`: Raised if the number of targets provided does not match the required qubits, bits, or z-variables for the operation.

# Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, GateX(), 1:4)
4-qubit circuit with 4 instructions:
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> insert!(c, 1, GateCX(), 1, 3)
4-qubit circuit with 5 instructions:
├── CX @ q[1], q[3]
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]
```
"""

function Base.insert!(c::Circuit, i::Integer, g::Operation{N,M,L}, targets::Vararg{Integer,K}) where {N,M,L,K}
    if g isa AbstractOperator && !(g isa AbstractGate)
        throw(ArgumentError("Cannot insert an AbstractOperator $(g) that is not an AbstractGate to the circuit."))
    end

    if N + M + L != K
        throw(ArgumentError("Wrong number of targets: given $K total for $N qubits $M bits operation $L z-variables"))
    end

    insert!(c, i, Instruction(g, targets[1:N], targets[N+1:N+M], targets[N+M+1:K]))
end

"""
    insert!(c::Circuit, i::Integer, operation_type::Type{T}, targets...)

Insert a non-parametric operation of a specific type into the circuit at a given position.

# Arguments
- `c::Circuit`: The quantum circuit where the operation will be inserted.
- `i::Integer`: The position (1-based index) in the circuit where the operation will be inserted.
- `operation_type::Type{T}`: The type of the operation to apply.
- `targets`: The target qubits, bits, or z-variables for the operation.

# Errors
- `ArgumentError`: Raised if the operation type is parametric (i.e., it requires parameters). 

# Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> c=Circuit()
empty circuit

julia> push!(c, GateX(), 1:4)        
4-qubit circuit with 4 instructions:
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> insert!(c, 3, GateRX(π/2), 5)
5-qubit circuit with 5 instructions:
├── X @ q[1]
├── X @ q[2]
├── RX(π/2) @ q[5]
├── X @ q[3]
└── X @ q[4]
```
"""
function Base.insert!(c::Circuit, i::Integer, ::Type{T}, targets...) where {T<:Operation}
    if numparams(T) != 0
        error("Parametric type. Use `insert!(c, i, T(args...), targets...)` instead.")
    end

    if T <: AbstractOperator && !(T <: AbstractGate)
        throw(ArgumentError("Cannot insert an AbstractOperator $(T) that is not an AbstractGate to the circuit."))
    end

    return insert!(c, i, T(), targets...)
end

