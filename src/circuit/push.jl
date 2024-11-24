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

function _checkpushtargets(targets, N, type="qubit")
    L = length(targets)

    if length(targets) != N
        throw(ArgumentError("Wrong number of targets: given $L total for $N-$type operation"))
    end

    if any(x -> any(y -> y <= 0, x), targets)
        throw(ArgumentError("Target $(type)s must be positive and >=1"))
    end

    # PERF: this is a double pass the qubit/bit targets, but it is probably
    # the only way of doing it.
    for tgs in shortestzip(targets...)
        if length(unique(tgs)) != length(tgs)
            throw(ArgumentError("Target $(type)s must be the different"))
        end
    end

    nothing
end

"""
    push!(circuit::Circuit, operation::Operation, targets::Vararg{Int})

Add an operation to the circuit with the specified qubit, bit, or zvar targets.

This function allows you to push quantum operations onto a circuit, 
specifying the exact qubits, classical bits, or zvars (if applicable) that the operation acts on.

# Arguments
- `circuit::Circuit`: The quantum circuit to which the operation will be added.
- `operation::Operation{N,M,L}`: The operation to apply. It works on N qubits, M classical bits, and L zvars.
- `targets::Vararg{Any,K}`: The target qubits, bits, or zvars for the operation.

# Throws
- `ArgumentError`: If the wrong number of targets is provided.
- `ArgumentError`: If any targets are invalid or not distinct.

# Examples

```jldoctests
julia> c=Circuit()
empty circuit

julia> push!(c, GateCX(), [1, 2], 3)  # Adds `CX @ q1, q3` and `CX @ q2, q3`
3-qubit circuit with 2 instructions:
├── CX @ q[1], q[3]
└── CX @ q[2], q[3]

julia> push!(c, GateX(), 1:4)         # Applies X to all 4 targets
4-qubit circuit with 6 instructions:
├── CX @ q[1], q[3]
├── CX @ q[2], q[3]
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
└── X @ q[4]

julia> push!(c, GateH(), 8)
8-qubit circuit with 7 instructions:
├── CX @ q[1], q[3]
├── CX @ q[2], q[3]
├── X @ q[1]
├── X @ q[2]
├── X @ q[3]
├── X @ q[4]
└── H @ q[8]

```
"""
function Base.push!(c::Circuit, g::Operation{N,M,L}, targets::Vararg{Any,K}) where {N,M,L,K}

    # Check if the operation is an AbstractOperator but not a Gate
    if g isa AbstractOperator && !(g isa AbstractGate)
        throw(ArgumentError("Cannot add an AbstractOperator $(typeof(g)) that is not a AbstractGate to the circuit."))
    end

    if N + M + L != K
        throw(ArgumentError("Wrong number of targets: given $(K) total for $N qubits, $M bits, and $L zvars operation"))
    end

    _checkpushtargets(targets[1:N], N, "qubit")
    _checkpushtargets(targets[N+1:N+M], M, "bit")
    _checkpushtargets(targets[N+M+1:K], L, "zvar")

    for tgs in shortestzip(targets...)
        qts = tgs[1:N]
        cts = tgs[N+1:N+M]
        zts = tgs[N+M+1:end]
        push!(c, Instruction(g, Tuple(qts), Tuple(cts), Tuple(zts); checks=false))
    end

    return c
end

"""
    push!(circuit::Circuit, operation_type::Type{T}, targets...)

Add an operation of a specific type to the circuit with the given targets.

# Arguments
- `circuit::Circuit`: The quantum circuit to which the operation will be added.
- `operation_type::Type{T}`: The type of the operation to apply.
- `targets`: The target qubits, bits, or zvars for the operation.

# Errors
- `ArgumentError`: Raised if the operation type requires parameters (i.e., it is a parametric operation), but none were provided. 


# Examples

```jldoctests
julia> c = Circuit()
empty circuit

julia> push!(c, GateRX(π/2), 1:4)
4-qubit circuit with 4 instructions:
├── RX(π/2) @ q[1]
├── RX(π/2) @ q[2]
├── RX(π/2) @ q[3]
└── RX(π/2) @ q[4]
```
"""
function Base.push!(c::Circuit, ::Type{T}, targets...) where {T<:Operation}
    if numparams(T) != 0
        error("Parametric type. Use `push!(c, T(args...), targets...)` instead.")
    end

    if T <: AbstractOperator && !(T <: AbstractGate)
        throw(ArgumentError("Cannot add an AbstractOperator $(T) that is not an AbstractGate to the circuit."))
    end

    return push!(c, T(), targets...)
end

