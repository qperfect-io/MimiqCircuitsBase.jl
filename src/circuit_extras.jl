#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
    depth(circuit)

Compute the depth of a quantum circuit.

The depth of a quantum circuit is a metric computing the maximum time (in units of quantum
gates application) between the input and output of the circuit.
"""
function depth(c::Circuit)
    d = zeros(Int64, numqubits(c) + numbits(c) + numzvars(c))
    for g in c
        if iszero(numqubits(g)) && iszero(numbits(g)) && iszero(numzvars(g))
            continue
        end

        optargets = vcat(collect(getqubits(g)), collect(getbits(g)) .+ numqubits(c), collect(getztargets(g)) .+ (numqubits(c) + numbits(c)))
        dm = maximum(d[optargets])

        for t in optargets
            d[t] = dm + 1
        end
    end
    return maximum(d)
end

"""
    remove_unused(circuit)

Removes unused qubits, bits, and zvars from the given quantum circuit.

Returns the modified circuit and the mappings from old indices to new indices.

## Example

```jldoctest
begin
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, GateCX(), 1, 3:2:7)
    push!(c, Measure(), 1:2:7, 1:2:7)
    push!(c, ExpectationValue(GateZ()), 9, 9)
end

cr, qubit_map, bit_map, zvar_map = remove_unused(c)
cr

# output

5-qubit, 4-bit, 1-vars circuit with 9 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── CX @ q[1], q[3]
├── CX @ q[1], q[4]
├── M @ q[1], c[1]
├── M @ q[2], c[2]
├── M @ q[3], c[3]
├── M @ q[4], c[4]
└── ⟨Z⟩ @ q[5], z[1]
```
"""
function remove_unused(c::Circuit)
    used_qubits = BitSet()
    used_bits = BitSet()
    used_zvars = BitSet()

    for g in c
        for q in getqubits(g)
            push!(used_qubits, q)
        end
        for b in getbits(g)
            push!(used_bits, b)
        end
        for z in getztargets(g)
            push!(used_zvars, z)
        end
    end

    qubit_map = Dict{Int,Int}()
    bit_map = Dict{Int,Int}()
    zvar_map = Dict{Int,Int}()

    new_qubit_index = 1
    for q in sort(collect(used_qubits))
        qubit_map[q] = new_qubit_index
        new_qubit_index += 1
    end

    new_bit_index = 1
    for b in sort(collect(used_bits))
        bit_map[b] = new_bit_index
        new_bit_index += 1
    end

    new_zvar_index = 1
    for z in sort(collect(used_zvars))
        zvar_map[z] = new_zvar_index
        new_zvar_index += 1
    end

    new_circuit = Circuit()

    for g in c
        new_qubits = Tuple(qubit_map[q] for q in getqubits(g) if haskey(qubit_map, q))
        new_bits = Tuple(bit_map[b] for b in getbits(g) if haskey(bit_map, b))
        new_ztargets = Tuple(zvar_map[z] for z in getztargets(g) if haskey(zvar_map, z))

        push!(new_circuit, Instruction(getoperation(g), new_qubits, new_bits, new_ztargets))
    end

    return new_circuit, qubit_map, bit_map, zvar_map
end

"""
    remove_swaps(circuit; recursive=false)

Remove all SWAP gates from a quantum circuit by tracking qubit permutations and
remapping subsequent operations to their correct physical qubits.

Returns a tuple of:
- `new_circuit`: Circuit with SWAP gates removed and operations remapped
- `qubit_permutation`: Final permutation where `qubit_permutation[i]` gives the
  physical qubit location of logical qubit `i`

## Arguments

- `circuit`: Input quantum circuit
- `recursive=false`: If `true`, recursively remove swaps from nested blocks/subcircuits

## Details

When a SWAP gate is encountered on qubits `(i, j)`, instead of keeping the gate:
1. The qubit mapping is updated to track that logical qubits `i` and `j` have
   exchanged physical positions
2. All subsequent gates are automatically remapped to operate on the correct
   physical qubits

This transformation preserves circuit semantics while eliminating SWAP overhead.

## Examples

```jldoctest
julia> c = Circuit()
       push!(c, GateH(), 1)
       push!(c, GateSWAP(), 1, 2)
       push!(c, GateCX(), 2, 3)
       new_c, perm = remove_swaps(c)
       new_c
3-qubit circuit with 2 instructions:
├── H @ q[1]
└── CX @ q[1], q[3]

julia> perm  # Logical qubit 1 is at physical position 2, logical 2 at position 1
3-element Vector{Int64}:
 2
 1
 3
```

```jldoctest
julia> c = Circuit()
       push!(c, GateSWAP(), 1, 2)
       push!(c, GateSWAP(), 2, 3)
       push!(c, GateCX(), 1, 3)  # After swaps: logical 1 -> physical 3, logical 3 -> physical 1
       new_c, perm = remove_swaps(c)
       new_c
3-qubit circuit with 2 instructions:
├── CX @ q[2], q[1]
└── ID @ q[3]

julia> perm
3-element Vector{Int64}:
 2
 3
 1
```
"""
function remove_swaps end

# Reverse instruction order and invert each gate operation.
function _reverse_and_invert(insts)
    return [
        Instruction(inverse(getoperation(inst)), getqubits(inst), getbits(inst), getztargets(inst))
        for inst in Iterators.reverse(insts)
    ]
end

# Pad instructions with GateID to preserve qubit arity.
function _pad_to_arity!(insts, target_nq)
    nq = numqubits(insts)
    for q in (nq+1):target_nq
        push!(insts, Instruction(GateID(), (q,), (), ()))
    end
end

function remove_swaps(c::Vector{<:Instruction}; cache=Dict(), recursive=false)
    perm = collect(1:numqubits(c))
    new_insts = Instruction[]

    for inst in c
        op = getoperation(inst)
        qubits = collect(getqubits(inst))
        if op isa GateSWAP
            q1, q2 = qubits
            perm[q1], perm[q2] = perm[q2], perm[q1]
        elseif recursive && (
            op isa GateCall ||
            op isa Block ||
            (op isa Inverse && getoperation(op) isa GateCall)
            # Control and IfStatement excluded: their internal SWAPs are conditional
            # and cannot be tracked as unconditional permutations.
        )
            new_block, block_map = remove_swaps(op; cache=cache, recursive=recursive)
            new_qubits = Tuple(perm[q] for q in qubits)
            push!(new_insts, Instruction(new_block, new_qubits, getbits(inst), getztargets(inst)))
            perm[qubits] = perm[qubits[block_map]]
        else
            new_qubits = Tuple(perm[q] for q in qubits)
            push!(new_insts, Instruction(op, new_qubits, getbits(inst), getztargets(inst)))
        end
    end

    return new_insts, perm
end

function remove_swaps(c::Circuit; kwargs...)
    insts, qubit_map = remove_swaps(c._instructions; kwargs...)
    _pad_to_arity!(insts, numqubits(c))
    return Circuit(insts), qubit_map
end

function remove_swaps(op::Operation; kwargs...)
    return op, collect(1:numqubits(op))
end

function remove_swaps(decl::GateDecl{N,M}; cache=Dict(), recursive=false) where {N,M}
    if haskey(cache, decl)
        return cache[decl]
    end

    insts, qubit_map = remove_swaps(decl._instructions; cache=cache, recursive=recursive)
    _pad_to_arity!(insts, N)

    newdecl = (GateDecl(decl.name, decl._arguments, insts), qubit_map)
    cache[decl] = newdecl
    return newdecl
end

function remove_swaps(op::GateCall; kwargs...)
    decl, qubit_map = remove_swaps(op._decl; kwargs...)
    return GateCall(decl, op._args...), qubit_map
end

function remove_swaps(block::Block; cache=Dict(), kwargs...)
    if haskey(cache, block)
        return cache[block]
    end

    insts, qubit_map = remove_swaps(block._instructions; cache=cache, kwargs...)
    nq = numqubits(block)
    if length(qubit_map) < nq
        append!(qubit_map, (length(qubit_map) + 1):nq)
    end
    newblock = Block(nq, numbits(block), numzvars(block), insts), qubit_map
    cache[block] = newblock
    return newblock
end


function remove_swaps(inv::Inverse{N,<:GateCall{N}}; cache=Dict(), recursive=false) where {N}
    if haskey(cache, inv)
        return cache[inv]
    end

    gatecall = getoperation(inv)
    decl = gatecall._decl

    # Expand the inverse body, remove swaps, then rebuild the forward body
    # to keep the Inverse(GateCall(...)) wrapper.
    inv_insts = _reverse_and_invert(decl._instructions)
    inv_decl = GateDecl(decl.name, decl._arguments, inv_insts)
    inv_call, qubit_map = remove_swaps(GateCall(inv_decl, gatecall._args...); cache=cache, recursive=recursive)

    fwd_insts = _reverse_and_invert(inv_call._decl._instructions)
    fwd_decl = GateDecl(inv_call._decl.name, inv_call._decl._arguments, fwd_insts)
    result = (inverse(GateCall(fwd_decl, inv_call._args...)), qubit_map)
    cache[inv] = result
    return result
end
