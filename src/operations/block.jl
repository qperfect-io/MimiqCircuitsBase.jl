#
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
   Block()
   Block(circuit) 
   Block(instructions)
   Block(num_qubits, num_bits, num_variables[, instructions])

A block is a collection of instructions grouped together.
It can be used to encapsulate a set of operations that can be reused in
different contexts.

* Instructions can be added to a block via [`Base.push!`](@ref) in the same way
  as for a circuit.
* Once created a block has a definite number of qubits, bits and z variables.
* Adding operationsthat use more then the specified number of qubits, bits or z
  variables will throw an error.

!!! info
    Circuits or vector of instructions are copied (in the sense of `copy`) when
    passed to a block. This helps ensuring that the underlying instructions
    vectror is not modified outside of what allowed by `Block`.

### Examples

```jldoctest; filter = r"block [a-z0-9]+ " => s"block **** "
julia> shorcode = let c = Circuit()
           push!(c, GateCX(), 1, 2:3)
           push!(c, MeasureZZ(), 1, 2, 1)
           push!(c, MeasureZZ(), 2, 3, 2)
           push!(c, IfStatement(GateX(), bs"10"), 1, 1, 2)
           push!(c, IfStatement(GateX(), bs"11"), 2, 1, 2)
           push!(c, IfStatement(GateX(), bs"01"), 3, 1, 2)
           Block(c)
       end
3-qubit, 2-bit block 2ona3chfcmcqp with 7 instructions:
├── CX @ q[1], q[2]
├── CX @ q[1], q[3]
├── MZZ @ q[1:2], c[1]
├── MZZ @ q[2:3], c[2]
├── IF(c==10) X @ q[1], c[1:2]
├── IF(c==11) X @ q[2], c[1:2]
└── IF(c==01) X @ q[3], c[1:2]

julia> c = Circuit()
empty circuit

julia> begin
           c = Circuit()
           push!(c, shorcode, 1,2,3,1,2)
           push!(c, parallel(3, GateX()), 1:3...)
           push!(c, PauliX(0.1), 1:3)
           push!(c, shorcode, 1,2,3,1,2)
           push!(c, Measure(), 1:3, 1:3)
       end
3-qubit, 3-bit circuit with 9 instructions:
├── block 2ona3chfcmcqp @ q[1:3], c[1:2]
├── ⨷ ³ X @ q[1], q[2], q[3]
├── PauliX(0.1) @ q[1]
├── PauliX(0.1) @ q[2]
├── PauliX(0.1) @ q[3]
├── block 2ona3chfcmcqp @ q[1:3], c[1:2]
├── M @ q[1], c[1]
├── M @ q[2], c[2]
└── M @ q[3], c[3]
```
"""
struct Block{N,M,L} <: Operation{N,M,L}
    _instructions::Vector{<:Instruction}
end

Block(nq, nc, nz, instructions=Instruction[]) = Block{nq,nc,nz}(copy(instructions))

Block(; nq=0, nc=0, nz=0) = Block(nq, nc, nz)

function Block(instructions::Vector{<:Instruction})
    nq = numqubits(instructions)
    nc = numbits(instructions)
    nz = numzvars(instructions)
    return Block{nq,nc,nz}(copy(instructions))
end

Block(circuit::Circuit) = Block(copy(circuit._instructions))

Base.iterate(c::Block) = iterate(c._instructions)
Base.iterate(c::Block, state) = iterate(c._instructions, state)
Base.firstindex(c::Block) = firstindex(c._instructions)
Base.lastindex(c::Block) = lastindex(c._instructions)
Base.length(c::Block) = length(c._instructions)
Base.isempty(c::Block) = isempty(c._instructions)
Base.getindex(c::Block, i::Integer) = getindex(c._instructions, i)
Base.getindex(c::Block, i) = Block(getindex(c._instructions, i))
Base.eltype(c::Block) = eltype(c._instructions)
Base.keys(c::Block) = keys(c._instructions)

numqubits(::T) where {T<:Block} = numqubits(T)
numbits(::T) where {T<:Block} = numbits(T)
numzvars(::T) where {T<:Block} = numzvars(T)

numqubits(::Type{<:Block{N}}) where {N} = N
numbits(::Type{<:Block{N,M}}) where {N,M} = M
numzvars(::Type{<:Block{N,M,L}}) where {N,M,L} = L

function _check_instruction_block(instruction::Instruction, nq, nc, nz)
    nqi = numqubits(instruction)
    if nq != nqi
        throw(ArgumentError("Qubits out of range for a block, expected maximum $nq, got $nqi"))
    end

    nci = numbits(instruction)
    if nc != nci
        throw(ArgumentError("Bits out of range for a block, expected maximum $nc, got $nci"))
    end

    nzi = numzvars(instruction)
    if nz != nzi
        throw(ArgumentError("Z variables out of range for a block, expected maximum $nz, got $nzi"))
    end
end

function Base.push!(c::Block, instruction::Instruction)
    _check_instruction_block(instruction, numqubits(c), numbits(c), numzvars(c))
    push!(c._instructions, instruction)
    return c
end

function _check_instruction_block(::Operation{N,M,L}, targets, nq, nc, nz) where {N,M,L}
    qt = targets[1:N]
    ct = targets[N+1:N+M]
    zt = targets[N+M+1:N+M+L]

    if any(x -> any(y -> y > nq, x), qt)
        throw(ArgumentError("Qubits out of range for a block, expected maximum $nq"))
    end
    if any(x -> any(y -> y > nc, x), ct)
        throw(ArgumentError("Bits out of range for a block, expected maximum $nc"))
    end
    if any(x -> any(y -> y > nz, x), zt)
        throw(ArgumentError("Z variables out of range for a block, expected maximum $nz"))
    end
end

function Base.push!(c::Block, g::Operation, targets...)
    _check_instruction_block(g, targets, numqubits(c), numbits(c), numzvars(c))
    push!(c._instructions, g, targets...)
    return c
end

function Base.show(io::IO, b::Block)
    print(io, "Block(", numqubits(b), ", ", numbits(b), ", ", numzvars(b), ", [")
    print(io, b[1])

    if length(b) > 1
        for inst in b[2:end]
            print(io, ", ", inst, ", ")
        end
    end

    print(io, "])")

    return nothing
end

function _print_instcontainer_header(io::IO, c::Block)
    compact = get(io, :compact, false)

    # blockid string in hexadecimal
    blockid = string(objectid(c), base=36)
    if compact
        print(io, "block $(blockid)")
    else
        _print_instcontainer_header_numbers(io, c)
        print(io, "block $(blockid) with $(length(c)) instructions")
    end
end

function Base.show(io::IO, m::MIME"text/plain", c::Block)
    compact = get(io, :compact, false)

    if !compact && !isempty(c)
        _print_instcontainer_header(io, c)
        print(io, ":\n")

        _show_instructions(io, m, c)
    else
        if isempty(c)
            print(io, "empty circuit")
        else
            _print_instcontainer_header(io, c)
        end
    end

    nothing
end

function decompose!(circuit::Circuit, b::Block, qtargets, ctargets, ztargets)
    for inst in b
        op = getoperation(inst)
        qt = getqubits(inst)
        bt = getbits(inst)
        zt = getztargets(inst)
        push!(circuit, op, [qtargets[i] for i in qt]..., [ctargets[i] for i in bt]..., [ztargets[i] for i in zt]...)
    end

    return circuit
end

isunitary(b::Block{N,0,L}) where {N,L} = all(x -> isunitary(x) for inst in b)
