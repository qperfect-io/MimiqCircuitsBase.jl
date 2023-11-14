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
    Operation{N,M}

Abstract supertype for all the quantum operations acting on `N` qubits and `M`
classical bits.

## Methods

[`iswrapper`](@ref), [`isunitary`](@ref), [`numbits`](@ref),
[`numqubits`](@ref), [`opname`](@ref)

## See also 

[`AbstractGate`](@ref)
"""
abstract type Operation{N,M} end

numqubits(::Type{<:Operation{N,M}}) where {N,M} = N

numqubits(::Operation{N,M}) where {N,M} = N

opname(::T) where {T<:Operation} = opname(T)

opname(::Type{T}) where {T<:Operation} = string(T)

numbits(::Type{<:Operation{N,M}}) where {N,M} = M

numbits(::Operation{N,M}) where {N,M} = M

isunitary(::Type{T}) where {T<:Operation} = false

"""
    iswrapper(operation)
    iswrapper(operationtype)

Checks if a given operation is a wrapper or not.

## Examples

```@repl
iswrapper(Control)
iswrapper(GateX)
iswrapper(GateSX) # SX is defined as Power(1//2, GateX())
iswrapper(GateCX) # CX is defined as Control(1, GateX())
```

## See also

[`isunitary`](@ref), [`getoperation`](@ref)
"""
function iswrapper end

iswrapper(::Type{<:Operation}) = false

iswrapper(::T) where {T} = iswrapper(T)

"""
    hilbertspacedim(operation)
    hilbertspacedim(operationtype)
    hilbertspacedim(N::Integer)

Hilbert space dimension for the given operation.
For an operation actiing on `N` qubits, it is `2^N`.

## Examples

```@repl
hilbertspacedim(Operation{2, 1})
hilbertspacedim(GateH)
hilbertspacedim(GateH())
hilbertspacedim(GateRX)
hilbertspacedim(GateCX)
hilbertspacedim(4)
```

## See also

[`numqubits`](@ref), [`numbits`](@ref), [`Operation`](@ref),
[`AbstractGate`](@ref)
"""
function hilbertspacedim end

hilbertspacedim(N::Integer) = 1 << N

hilbertspacedim(::Operation{N,M}) where {N,M} = 1 << N

hilbertspacedim(::Type{T}) where {T} = hilbertspacedim(T)

"""
    qregsizes(operation)
    qregsizes(operationtype)

Length of the quantum registers the given operation acts on.

!!! details
    Some operations, such as adders or multipliers, acts on different groups
    of qubits (quantum registers).

## Examples

```@repl
qregsizes(GateRX())
qregsizes(QFT(4))
```

## See also

[`cregsizes`](@ref), [`numqubits`](@ref), [`numbits`](@ref)
"""
qregsizes(::T) where {T} = qregsizes(T)
qregsizes(::Type{<:Operation{N,M}}) where {N,M} = ntuple(x -> 1, N)

"""
    cregsizes(operation)
    cregsizes(operationtype)

Length of the classicalregisters the given operation acts on.

## See also

[`qregsizes`](@ref), [`numqubits`](@ref), [`numbits`](@ref)
"""
cregsizes(::T) where {T} = cregsizes(T)
cregsizes(::Type{<:Operation{N,M}}) where {N,M} = ntuple(x -> 1, M)

"""
    parnames(operation)
    parnames(operationtype)

Name of the parameters allowed for the given operation.

By default it returns the fieldnames of the operation type.

## Examples

```@repl
parnames(GateH)
parnames(GateRX)
parnames(GateCRX)
parnames(Measure)
```

## See also

[`numparams`](@ref), [`getparam`](@ref)
"""
function parnames end

parnames(::T) where {T<:Operation} = parnames(T)

parnames(::Type{T}) where {T<:Operation} = fieldnames(T)

"""
    numparams(operation)
    numparams(operationtype)

Number of parameters for the given parametric operation.
Zero for non parametric operations.

By default it returns the number of fields of the operations.

## Examples

```@repl
numparams(GateH)
numparams(GateU)
numparams(GateRX)
numparams(Measure)
```

## See also

[`parnames`](@ref), [`getparam`](@ref)
"""
function numparams end

numparams(::T) where {T<:Operation} = numparams(T)

numparams(::Type{T}) where {T<:Operation} = length(parnames(T))

"""
    getparam(operation, name)

Value of the corresponding parameter in the given parametric operation.

## Examples

```@repl
getparam(GateRX(π/8), :θ)
```

## See also

[`parnames`](@ref), [`numparams`](@ref), [`getparams`](@ref)
"""
function getparam end

getparam(g::Operation, name) = getfield(g, name)

"""
    getparams(operation)

Value of the parameters in the given parametric operation.

## Examples

```@repl
getparam(GateU(π/8, 3.1, sqrt(2)))
```

## See also

[`parnames`](@ref), [`numparams`](@ref), [`getparam`](@ref)
"""
function getparams end

getparams(g::Operation) = map(x -> getparam(g, x), parnames(g))

function power(op::Operation, n)
    if isone(n)
        return op
    end
    return _power(op, n)
end

function Base.:^(op::Operation, pwr)
    power(op, pwr)
end

function Base.show(io::IO, gate::Operation)
    print(io, opname(gate))
end

