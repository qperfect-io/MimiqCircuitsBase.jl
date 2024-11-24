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
    add_noise_to_gate_single!(c, g, noise; before=false)

Add a noise operation `noise` after/before every instance of a given operation `g`.

The noise operation `noise` can be a Kraus channel or a gate and will act on the same qubits
as the operation `g` it is being added to.

See [`add_noise!`](@ref) for more information.
"""
function add_noise_to_gate_single!(c::Circuit, g::Operation, noise::Union{AbstractKrausChannel,AbstractGate}; before=false)
    if g == noise
        error("Noise can't be the same as gate, otherwise recursion problem.")
    end

    rel = before ? 0 : 1

    i = 1
    while i <= length(c)
        if getoperation(c[i]) == g
            insert!(c, i + rel, noise, getqubits(c[i])...)
            # Shift by one because of noise added
            i += 1
        end
        # Shift by one because of gate considered
        i += 1
    end

    return c
end

"""
    add_noise_to_gate_parallel!(c, g, noise; before=false)

Add a block of noise operations `noise` after/before every block of a given operation `g`.

The function identifies blocks of consecutive transversal operations of type `g` and
adds after each such block a block of transversal noise operations `noise`. The noise operation
`noise` can be a Kraus channel or a gate and will act on the same qubits as the operation `g` it
is being added to.

See [`add_noise!`](@ref) for more information.
"""
function add_noise_to_gate_parallel!(c::Circuit, g::Operation, noise::Union{AbstractKrausChannel,AbstractGate}; before=false)
    if g == noise
        error("noise can't be the same as operation g, otherwise recursion problem.")
    end

    i = 1
    while i <= length(c)
        inds = [i]

        # This is to check that gates in block are transversal
        qubits = collect(getqubits(c[i]))

        if getoperation(c[i]) == g
            # Identify transversal block
            j = i + 1
            while j <= length(c) && getoperation(c[j]) == g && !any(map(x -> x in qubits, getqubits(c[j])))
                push!(inds, j)
                append!(qubits, collect(getqubits(c[j])))
                j += 1
            end

            # Insert block of noise after transversal block
            for (rel, j) in enumerate(inds)
                if before
                    insert!(c, i + (rel - 1), noise, getqubits(c[j+(rel-1)])...)
                else #after
                    insert!(c, inds[end] + 1 + (rel - 1), noise, getqubits(c[j])...)
                end
            end
            # Shift by length of noise block
            i += length(inds)
        end
        # Shift by length of gates block
        i += length(inds)
    end

    return c
end

"""
    add_noise!(c, g, noise; before=false, parallel=false)

Add a noise operation `noise` to every operation `g` in the circuit `c`.

The noise operation `noise` can be a Kraus channel or a gate and will act on the same qubits
as the operation `g` it is being added to.

The operations `g` and `noise` have to act on the same number of qubits.

## Arguments

* `c`: Circuit.
* `g`: Operation to which noise will be added.
* `noise`: Kraus channel or gate that will be added to each operation `g`.
* `before`: (optional) Bool, default=`false`. If `before` is `false` then the
  noise is added right after the operation; if it's `true` it's added right before.
* `parallel`: (optional) Bool, default=`false`. If `parallel` is `false` then
  the noise is added immediately after/before the operation. If it's `true` the
  function identifies blocks of consecutive transversal operations of type `g` and
  adds after each such block a block of transversal noise operations `noise`. The result
  of both should be equivalent, it's only the order of operations that changes.

## Returns

The circuit `c` with the noise added in place.

## Examples

Parallel vs not parallel.

```jldoctests
julia> c = push!(Circuit(), GateH(), 1:3);

julia> add_noise!(c, GateH(), AmplitudeDamping(0.2))
3-qubit circuit with 6 instructions:
├── H @ q[1]
├── AmplitudeDamping(0.2) @ q[1]
├── H @ q[2]
├── AmplitudeDamping(0.2) @ q[2]
├── H @ q[3]
└── AmplitudeDamping(0.2) @ q[3]

julia> c = push!(Circuit(), GateH(), 1:3);

julia> add_noise!(c, GateH(), AmplitudeDamping(0.2); parallel=true)
3-qubit circuit with 6 instructions:
├── H @ q[1]
├── H @ q[2]
├── H @ q[3]
├── AmplitudeDamping(0.2) @ q[1]
├── AmplitudeDamping(0.2) @ q[2]
└── AmplitudeDamping(0.2) @ q[3]
```

Parallel will not work if gates aren't transversal.

```jldoctests
julia> c = push!(Circuit(), GateCZ(), 1, 2:4);

julia> add_noise!(c, GateCZ(), Depolarizing2(0.1); parallel=true)
4-qubit circuit with 6 instructions:
├── CZ @ q[1], q[2]
├── Depolarizing(2,0.1) @ q[1:2]
├── CZ @ q[1], q[3]
├── Depolarizing(2,0.1) @ q[1,3]
├── CZ @ q[1], q[4]
└── Depolarizing(2,0.1) @ q[1,4]
```

The `before=true` option is mostly used for `Measure`.

```jldoctests
julia> c = push!(Circuit(), Measure(), 1:3, 1:3);

julia> add_noise!(c, Measure(), PauliX(0.1); before=true)
3-qubit circuit with 6 instructions:
├── PauliX(0.1) @ q[1]
├── M @ q[1], c[1]
├── PauliX(0.1) @ q[2]
├── M @ q[2], c[2]
├── PauliX(0.1) @ q[3]
└── M @ q[3], c[3]
```

Unitary gates are added in the same way.

```jldoctests
julia> c = push!(Circuit(), GateH(), 1:3);

julia> add_noise!(c, GateH(), GateRX(0.01))
3-qubit circuit with 6 instructions:
├── H @ q[1]
├── RX(0.01) @ q[1]
├── H @ q[2]
├── RX(0.01) @ q[2]
├── H @ q[3]
└── RX(0.01) @ q[3]
```

"""
function add_noise!(c::Circuit, g::Operation, noise::Union{AbstractKrausChannel,AbstractGate};
    before=false, parallel=false)
    if !(before isa Bool) || !(parallel isa Bool)
        error("Parameters before and parallel have to be of type Bool.")
    end

    if numqubits(g) != numqubits(noise)
        error("Noise channel and operation must have the same number of target qubits")
    end

    if !parallel
        add_noise_to_gate_single!(c, g, noise; before=before)
    else
        add_noise_to_gate_parallel!(c, g, noise; before=before)
    end

    return c
end

# """
#     add_noise!(c, g, noise; before=false, parallel=false)

# Add a set of noise operations `noise` to a set of operations `g` in the circuit `c`.

# If `k` indexes the elements of the `g` and `noise` vectors, then the function
# adds the noise operation `noise[k]` to every operation `g[k]` in the circuit.

# See also documentation for unvectorized [`add_noise!`].

# ## Arguments

# * `c`: Circuit.
# * `g`: Vector of Operations to which noise will be added. It has to have the same length
#   as `noise`. The operations `g[k]` and `noise[k]` have to act on the same number of qubits for
#   each element `k`.
# * `noise`: Vector of Kraus channels or gates that will be added to each
#   operation in `g`. It has to have the same length as `g`. The operations `g[k]` and
#   `noise[k]` have to act on the same number of qubits for each element `k`.
# * `before`: (optional) Bool or Vector{Bool}, default=`false`. If `before[k]` is `false` then
#   the noise is added after the operation `g[k]`; if it's `true` it's added before. If `before` is
#   a single Bool it is broadcasted to the length of `g` and `noise`. If it's a Vector it must
#   have the same length as `g` and `noise`.
# * `parallel`: (optional) Bool or Vector{Bool}, default=`false`. If `parallel[k]` is `false`
#   then the noise is added immediately after/before the operation `g[k]`; if it's `true` the
#   function identifies blocks of consecutive transversal gates of type `g[k]` and adds after
#   each block a block of transversal noise operations `noise`. If `parallel` is
#   a single Bool it is broadcasted to the length of `g` and `noise`. If it's a Vector it must
#   have the same length as `g` and `noise`.

# ## Returns

# The circuit `c` with the noise added in place.

# ## Examples

# We first prepare a circuit.

# ```jldoctests addnoise
# julia> c = push!(Circuit(), GateH(), 1:3);

# julia> push!(c, GateCZ(), 1, 2:3);

# julia> push!(c, Measure(), 1:3, 1:3)
# 3-qubit circuit with 8 instructions:
# ├── H @ q[1]
# ├── H @ q[2]
# ├── H @ q[3]
# ├── CZ @ q[1], q[2]
# ├── CZ @ q[1], q[3]
# ├── Measure @ q[1], c[1]
# ├── Measure @ q[2], c[2]
# └── Measure @ q[3], c[3]

# ```

# Then we specify for each operation in the circuit which noise will be added,
# together with the optional parameters. The output is equivalent to sequentially
# calling `add_noise!` on each element of the input vectors.

# ```jldoctests addnoise
# julia> operations = [GateH(), GateCZ(), Measure()];

# julia> channels = [AmplitudeDamping(0.2), Depolarizing2(0.1), PauliX(0.1)];

# julia> before = [false, false, true];

# julia> parallel = [true, false, true];

# julia> add_noise!(c, operations, channels; before=before, parallel=parallel)
# 3-qubit circuit with 16 instructions:
# ├── H @ q[1]
# ├── H @ q[2]
# ├── H @ q[3]
# ├── AmplitudeDamping(0.2) @ q[1]
# ├── AmplitudeDamping(0.2) @ q[2]
# ├── AmplitudeDamping(0.2) @ q[3]
# ├── CZ @ q[1], q[2]
# ├── Depolarizing(2,0.1) @ q[1:2]
# ├── CZ @ q[1], q[3]
# ├── Depolarizing(2,0.1) @ q[1,3]
# ├── PauliX(0.1) @ q[1]
# ├── PauliX(0.1) @ q[2]
# ├── PauliX(0.1) @ q[3]
# ├── Measure @ q[1], c[1]
# ├── Measure @ q[2], c[2]
# └── Measure @ q[3], c[3]
# ```
# """
# function add_noise!(c::Circuit, g::Vector{<:Operation}, noise::Vector{<:Union{AbstractKrausChannel,AbstractGate}};
#     before=false, parallel=false)
#     if !(before isa Bool) && !(before isa Vector{Bool})
#         error("parameter before has to be a Bool or a Vector{Bool}.")
#     end

#     if !(parallel isa Bool) && !(parallel isa Vector{Bool})
#         error("parameter parallel has to be a Bool or a Vector{Bool}.")
#     end

#     if length(g) != length(noise)
#         error("Vectors of operations and noise channels have to have the same length.")
#     end

#     nops = length(g)

#     # Vectorize optional parameters
#     if before isa Bool
#         before = fill(before, nops)
#     else
#         if length(before) != nops
#             error("Vector of before has to have the same length as Vector of operations.")
#         end
#     end

#     if parallel isa Bool
#         parallel = fill(parallel, nops)
#     else
#         if length(parallel) != nops
#             error("Vector of before has to have the same length as Vector of operations.")
#         end
#     end

#     # Add noise gate by gate
#     for k in 1:nops
#         add_noise!(c, g[k], noise[k]; before=before[k], parallel=parallel[k])
#     end

#     return c
# end

"""
    add_noise(c, g, noise; before=false, parallel=false)

Add noise operation `noise` to every operation `g` in circuit `c`.

A copy of `c` is created and then noise is added to the copy.

See [`add_noise!`] for more information.
"""
function add_noise(c::Circuit, g::Operation, noise::Union{AbstractKrausChannel,AbstractGate};
    before=false, parallel=false)
    circ = Circuit()
    for inst in c
        push!(circ, inst)
    end

    return add_noise!(circ, g, noise; before=before, parallel=parallel)
end

# """
#     add_noise(c, g, noise; before=false, parallel=false)

# Add a set of noise operations `noise` to a set of operations `g` in the circuit `c`.

# A copy of `c` is created and then noise is added to the copy.

# See [`add_noise!`] for more information.
# """
# function add_noise(c::Circuit, g::Vector{<:Operation}, noise::Vector{<:Union{AbstractKrausChannel,AbstractGate}};
#     before=false, parallel=false)
#     circ = Circuit()
#     for inst in c
#         push!(circ, inst)
#     end

#     return add_noise!(circ, g, noise; before=before, parallel=parallel)
# end
