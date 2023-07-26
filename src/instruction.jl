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

## Parameters

* `gate::T` actual gate represented
* `qtargets::NTuple{N, Int64}` indices specifying the quantum bits on which the
  instruction is applied
* `ctargets::NTuple{N, Int64}` indices specifying the classical bits on which
  the instruction is applied
"""
struct Instruction{N,M,T<:Operation{N,M}}
    op::T
    qtargets::NTuple{N,Int64}
    ctargets::NTuple{M,Int64}

    function Instruction(op::T, qtargets::NTuple{N,<:Integer}, ctargets::NTuple{M,<:Integer}; checks=true) where {N,M,T<:Operation{N,M}}
        if checks
            _checktargets(qtargets, N, "qubit")
            _checktargets(ctargets, M, "bit")
        end

        new{N,M,T}(op, qtargets, ctargets)
    end
end

function Instruction(op::Operation{N,M}, targets::Vararg{Integer,L}; kwargs...) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    qtargets = targets[1:N]
    ctargets = targets[end-M+1:end]

    Instruction(op, qtargets, ctargets; kwargs...)
end

numqubits(::Type{Instruction{N,M}}) where {N,M} = N
numqubits(::Instruction{N,M}) where {N,M} = N

numbits(::Type{Instruction{N,M}}) where {N,M} = M
numbits(::Instruction{N,M}) where {N,M} = M

getqubit(g::Instruction, i) = g.qtargets[i]
getqubits(g::Instruction) = g.qtargets

getbit(g::Instruction, i) = g.ctargets[i]
getbits(g::Instruction) = g.ctargets

"""
    getoperation(getoperation)

Returns the quantum operation associated to the given gate instruction.
"""
getoperation(g::Instruction) = g.op

opname(g::Instruction) = opname(g.op)

inverse(c::Instruction) = Instruction(inverse(getoperation(c)), getqubits(c)...)

function Base.show(io::IO, g::Instruction)
    compact = get(io, :compact, false)

    print(io, getoperation(g))
    if numbits(g) > 0 || numqubits(g) > 0
        space = compact ? "" : " "
        print(io, "$space@$space")
        join(io, map(x -> "q$x", getqubits(g)), ",$space")
        if numbits(g) != 0 && numqubits(g) != 0
            print(",$space")
        end
        join(io, map(x -> "c$x", getbits(g)), ",$space")
    end
end

matrix(g::Instruction{N,0,<:Gate{N}}) where {N} = matrix(getoperation(g))

