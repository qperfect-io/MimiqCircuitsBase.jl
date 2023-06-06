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

"""
    gettarget(instruction, i)

Returns the i-th target qubit of an instruction.

!!!warn
    Deprecated in favor of [`getqubit`](@ref) and [`getbit`](@ref)
"""
function gettarget end

"""
    gettargets(instruction)

Returns all the quantum qubits to which the instruction is applied.

!!!warn
    Deprecated in favor of [`getqubits`](@ref) and [`getbits`](@ref)
"""
function gettargets end

"""
    getqubit(instruction, i)

Returns the i-th target qubit of an instruction.

See also [`getqubits`](@ref), [`getbit`](@ref), [`getbits`](@ref),
"""
function getqubit end

"""
    getqubits(instruction)

Returns all the quantum bits to which the instruction is applied.

See also [`getqubit`](@ref), [`getbits`](@ref), [`getbit`](@ref),
"""
function getqubits end

"""
    getbit(instruction, i)

Returns the i-th target classical bit of an instruction.

See also [`getbits`](@ref), [`getqubit`](@ref), [`getqubits`](@ref),
"""
function getbit end

"""
    getbits(instruction)

Returns all the classical bits to which the instruction is applied.

See also [`getbit`](@ref), [`getqubits`](@ref), [`getqubit`](@ref),
"""
function getbits end


function _checktargets(targets, N, type="qubit")
    L = length(targets)

    if length(targets) != N
        throw(ArgumentError("Wrong number of targets: given $L for $N-$type operation"))
    end

    if any(x -> x <= 0, targets)
        throw(ArgumentError("Target $(type)s must be positive and >=1"))
    end

    if !allunique(targets)
        throw(ArgumentError("Target $(type)s cannot be repeated"))
    end

    nothing
end

"""
    struct Instruction{N,M,T<:Operation}

Element of a quantum circuit, representing a `N`-qubit gate applied to `N` targets

# Parameters

* `gate::T` actual gate represented
* `qtargets::NTuple{N, Int64}` indices specifying the quantum bits on which the
  instruction is applied
* `ctargets::NTuple{N, Int64}` indices specifying the classical bits on which
  the instruction is applied
"""
struct Instruction{N,M,T<:Operation}
    op::T
    qtargets::NTuple{N,Int64}
    ctargets::NTuple{M,Int64}

    function Instruction(op::T, qtargets::NTuple{N,<:Integer}, ctargets::NTuple{M,<:Integer}) where {N,M,T<:Operation}
        _checktargets(qtargets, N, "qubit")
        _checktargets(ctargets, M, "bit")

        new{N,M,T}(op, qtargets, ctargets)
    end
end

function Instruction(gate::T, qtargets::Vararg{Integer,N}) where {N,T<:Gate{N}}
    Instruction(gate, qtargets, ())
end

function Instruction(::Gate{N}, ::Vararg{Integer,M}) where {M,N}
    throw(ArgumentError("Wrong number of targets: given $M for $N-qubit gate"))
end

function Instruction(b::Barrier, qtargets::Vararg{Integer})
    Instruction(b, qtargets, ())
end

function Instruction(::Type{Barrier}, qtargets::Vararg{Integer})
    Instruction(Barrier(), qtargets, ())
end

numqubits(::Type{Instruction{N,M}}) where {N,M} = N
numqubits(::Instruction{N,M}) where {N,M} = N

numbits(::Type{Instruction{N,M}}) where {N,M} = M
numbits(::Instruction{N,M}) where {N,M} = M

getqubit(g::Instruction, i) = g.qtargets[i]
getqubits(g::Instruction) = g.qtargets

getbit(g::Instruction, i) = g.ctargets[i]
getbits(g::Instruction) = g.ctargets

@deprecate gettarget getqubit
@deprecate gettargets getqubits

"""
    getoperation(getoperation)

Returns the quantum operation associated to the given gate instruction.
"""
getoperation(g::Instruction) = g.op

opname(g::Instruction) = opname(g.op)

inverse(c::Instruction) = Instruction(inverse(getoperation(c)), getqubits(c)...)

function Base.show(io::IO, g::Instruction)
    compact = get(io, :compact, false)

    if compact
        print(io, getoperation(g), "@")
        join(io, map(x -> "q$x", getqubits(g)), ",")
        join(io, map(x -> "c$x", getbits(g)), ",")
    else
        print(io, getoperation(g), " @ ")
        join(io, map(x -> "q$x", getqubits(g)), ", ")
        join(io, map(x -> "c$x", getbits(g)), ", ")
    end
end

matrix(g::Instruction{N,0,<:Gate{N}}) where {N} = matrix(getoperation(g))

