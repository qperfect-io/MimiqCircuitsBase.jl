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
    AbstractKrausChannel{N} <: Operation{N,0,0}

Supertype for all the ``N``-qubit Kraus channels.

A Kraus channel is a quantum operation on a density matrix ``\\rho`` of the form

```math
\\mathcal{E}(\\rho) = \\sum_k E_k \\rho E_k^\\dagger,
```

where ``E_k`` are Kraus operators that need to fulfill ``\\sum_k E_k^\\dagger E_k \\leq I``.

## Special properties:

* [`isCPTP`](@ref): A Kraus channel a completely positive and trace preserving (CPTP)
  operation when ``\\sum_k E_k^\\dagger E_k = I``. Currently, all noise channels
  are CPTP.

* [`ismixedunitary`](@ref): A Kraus channel is called a mixed unitary channel when the
  Kraus operators ``E_k`` are each proportional to a unitary matrix ``U_k``, i.e. when
  ``\\mathcal{E}(\\rho) = \\sum_k p_k U_k \\rho U_k^\\dagger`` with some probabilities
  ``0\\leq p_k \\leq 1`` that add up to 1 and ``U_k^\\dagger U_k = I``.

See also [`krausmatrices`](@ref), [`unitarymatrices`](@ref), [`probabilities`](@ref).
"""
abstract type AbstractKrausChannel{N} <: Operation{N,0,0} end

"""
    isCPTP(krauschannel)

Whether the Kraus channel is Completely Positive, and Trace Preserving.

If the Kraus operators fulfill ``\\sum_k E_k^\\dagger E_k = I`` then the quantum operation
is CPTP. If ``\\sum_k E_k^\\dagger E_k < I``, then it's not CPTP.

Currently, all noise channels are CPTP.
"""
isCPTP(::Type{T}) where {T<:AbstractKrausChannel} = false

isCPTP(::T) where {T} = isCPTP(T)

"""
    ismixedunitary(krauschannel)

Whether the quantum operation is a mixed unitary channel.

This is the case when all the Kraus operators ``E_k`` are proportional to a unitary ``U_k``,
i.e. ``\\mathcal{E}(\\rho) = \\sum_k p_k U_k \\rho U_k^\\dagger`` with some probabilities
``0\\leq p_k \\leq 1`` that add up to 1 and ``U_k^\\dagger U_k = I``.

## Examples

```jldoctests
julia> ismixedunitary(PauliX(0.1))
true

julia> ismixedunitary(AmplitudeDamping(0.1))
false
```
"""
ismixedunitary(::Type{T}) where {T<:AbstractKrausChannel} = false

ismixedunitary(::T) where {T} = ismixedunitary(T)

inverse(::AbstractKrausChannel) = error("Cannot invert Kraus channel")

_power(::AbstractKrausChannel, n) = error("Cannot take the power of a Kraus channel")

"""
    probabilities(mixedunitarychannel)

Probabilities of each Kraus operator for mixed unitary Kraus channels.

A mixed unitary channel is written as ``\\sum_k p_k U_k \\rho U_k^\\dagger``,
where ``p_k`` are the probabilities.

An error is returned for Kraus channels with `ismixedunitary(krauschannel)==false`.

!!! note
    if the Kraus channel is parametric, the probabilities are wrapped in a
    `Symbolics.Num` object. To manipulate expressions use the `Symbolics`
    package.

See also [`ismixedunitary`](@ref), [`unitarymatrices`](@ref), and [`krausmatrices`](@ref).

## Examples

```jldoctests
julia> probabilities(PauliX(0.1))
2-element Vector{Symbolics.Num}:
 0.9
 0.1
```
"""
probabilities(op::AbstractKrausChannel) = _probabilities(op, Val(ismixedunitary(op)))

function _probabilities(::AbstractKrausChannel, ::Val{false})
    error("Probabilities can only be returned for a mixed unitary channel.")
end

function _probabilities(::AbstractKrausChannel, ::Val{true})
    error("Probabilities method not implemented for this mixed unitary channel.")
end

"""
    unwrappedprobabilities(mixedunitarychannel)

Probabilities associated to the specified mixed unitary Kraus channel
without the `Symbolics.Num` wrapper.

!!! note
    If any of the noise channel's parameters is symbolic, an error is thrown.

See [`probabilities`](@ref) for more information.

```jldoctests
julia> unwrappedprobabilities(PauliX(0.1))
2-element Vector{Float64}:
 0.9
 0.1
```
"""
unwrappedprobabilities(kch::AbstractKrausChannel) = unwrapvalue.(probabilities(kch))

"""
    cumprobabilities(mixedunitarychannel)

Cumulative sum of probabilities of a mixed unitary Kraus channel.

A mixed unitary channel is written as ``\\sum_k p_k U_k \\rho U_k^\\dagger``,
where ``p_k`` are the probabilities.

An error is returned for Kraus channels with `ismixedunitary(krauschannel)==false`.

!!! note
    if the Kraus channel is parametric, the cumprobabilities are wrapped in a
    `Symbolics.Num` object. To manipulate expressions use the `Symbolics`
    package.

See also [`probabilities`](@ref), [`ismixedunitary`](@ref).

## Examples

```jldoctests
julia> cumprobabilities(Depolarizing1(0.1))
4-element Vector{Symbolics.Num}:
                0.9
 0.9333333333333333
 0.9666666666666667
                1.0
```
"""
cumprobabilities(op::AbstractKrausChannel) = _cumprobabilities(op, Val(ismixedunitary(op)))

function _cumprobabilities(::AbstractKrausChannel, ::Val{false})
    error("Cumulative sum of probabilities can only be returned for a mixed unitary channel.")
end

_cumprobabilities(op::AbstractKrausChannel, ::Val{true}) = cumsum(probabilities(op))

"""
    unwrappedcumprobabilities(mixedunitarychannel)

Cumulative sum of probabilities associated to the specified mixed unitary Kraus channel
without the `Symbolics.Num` wrapper.

!!! note
    If any of the noise channel's parameters is symbolic, an error is thrown.

See [`cumprobabilities`](@ref) for more information.

```jldoctests
julia> unwrappedcumprobabilities(Depolarizing1(0.1))
4-element Vector{Float64}:
 0.9
 0.9333333333333333
 0.9666666666666667
 1.0
```
"""
unwrappedcumprobabilities(kch::AbstractKrausChannel) = unwrapvalue.(cumprobabilities(kch))

"""
    krausmatrices(krauschannel)

Kraus matrices associated to the given Kraus channel.

A mixed unitary channel is written as ``\\sum_k p_k U_k \\rho U_k^\\dagger``,
where ``U_k`` are the unitary matrices returned by this function.

!!! note
    if the Kraus channel is parametric, the matrix elements are wrapped in a
    `Symbolics.Num` object. To manipulate expressions use the `Symbolics`
    package.

## Examples

```jldoctests
julia> krausmatrices(AmplitudeDamping(0.1))
2-element Vector{Matrix{Float64}}:
 [1.0 0.0; 0.0 0.9486832980505138]
 [0.0 0.31622776601683794; 0.0 0.0]
```

For mixed unitary channels the Kraus matrices are the unitary matrices
times the square root of the probabilities.

```jldoctests
julia> krausmatrices(PauliX(0.2))
2-element Vector{Matrix{Symbolics.Num}}:
 [0.8944271909999159 -0.0; 0.0 0.8944271909999159]
 [0.0 0.4472135954999579; 0.4472135954999579 0.0]
```
"""
krausmatrices(kch::AbstractKrausChannel) = _krausmatrices(kch, Val(ismixedunitary(kch)))

function _krausmatrices(kch::AbstractKrausChannel, ::Val{false})
    return [matrix(kraus) for kraus in krausoperators(kch)]
end

function _krausmatrices(much::AbstractKrausChannel, ::Val{true})
    return sqrt.(probabilities(much)) .* unitarymatrices(much)
end

krausmatrices(g::Instruction{N,0,<:AbstractKrausChannel{N}}) where {N} = krausmatrices(getoperation(g))

"""
    unwrappedkrausmatrices(krauschannel)

Returns the Kraus matrices associated to the specified Kraus channel without
the `Symbolics.Num` wrapper.

!!! note
    If any of the noise channel's parameters is symbolic, an error is thrown.

See [`krausmatrices`](@ref) for more information.

## Examples

```jldoctests
julia> unwrappedkrausmatrices(AmplitudeDamping(0.1))
2-element Vector{Matrix{Float64}}:
 [1.0 0.0; 0.0 0.9486832980505138]
 [0.0 0.31622776601683794; 0.0 0.0]
```
"""
function unwrappedkrausmatrices(kch::AbstractKrausChannel)
    return [unwrapvalue.(kmat) for kmat in krausmatrices(kch)]
end

"""
    krausoperators(kraus)

Kraus operators associated to the given Kraus channel.

See also [`krausmatrices`](@ref).

## Examples

```jldoctests
julia> krausoperators(PauliX(0.2))
2-element Vector{Operator{1}}:
 Operator([0.8944271909999159 -0.0; 0.0 0.8944271909999159])
 Operator([0.0 0.4472135954999579; 0.4472135954999579 0.0])

julia> krausoperators(AmplitudeDamping(0.1))
2-element Vector{AbstractOperator{1}}:
 D(1, 0.9486832980505138)
 SigmaMinus(0.31622776601683794)
```
"""
krausoperators(kch::AbstractKrausChannel) = _krausoperators(kch, Val(ismixedunitary(kch)))

function _krausoperators(::AbstractKrausChannel, ::Val{false})
    error("krausoperators method needs to be implemented for this Kraus channel.")
end

function _krausoperators(much::AbstractKrausChannel, ::Val{true})
    return [Operator(Ek) for Ek in krausmatrices(much)]
end

"""
    squaredkrausoperators(kraus)

Square of of Kraus operators (``O^\\dagger O``) associated to the given Kraus channel.

See also [`krausoperators`](@ref).

## Examples

```jldoctests
julia> squaredkrausoperators(AmplitudeDamping(0.1))
2-element Vector{AbstractOperator{1}}:
 D(1, 0.8999999999999999)
 P₁(0.1)
```
"""
squaredkrausoperators(kch::AbstractKrausChannel) = opsquared.(krausoperators(kch))

"""
    unitarymatrices(mixedunitarychannel)

Unitary matrices associated to the given mixed unitary Kraus channel.

A mixed unitary channel is written as ``\\sum_k p_k U_k \\rho U_k^\\dagger``,
where ``U_k`` are the unitary matrices.

An error is returned for Kraus channels with `ismixedunitary(krauschannel)==false`.

!!! note
    if the Kraus channel is parametric, the matrix elements are wrapped in a
    `Symbolics.Num` object. To manipulate expressions use the `Symbolics`
    package.

See also [`ismixedunitary`](@ref), [`probabilities`](@ref), and [`krausmatrices`](@ref).

## Examples

```jldoctests
julia> unitarymatrices(PauliX(0.2))
2-element Vector{Matrix}:
 [1.0 -0.0; 0.0 1.0]
 [0 1; 1 0]
```
"""
unitarymatrices(much::AbstractKrausChannel) = _unitarymatrices(much, Val(ismixedunitary(much)))

function _unitarymatrices(::AbstractKrausChannel, ::Val{false})
    error("unitarymatrices only available for mixed unitary Kraus channels")
end

function _unitarymatrices(much::AbstractKrausChannel, ::Val{true})
    return [matrix(Uk) for Uk in unitarygates(much)]
end

unitarymatrices(g::Instruction{N,0,<:AbstractKrausChannel{N}}) where {N} = unitarymatrices(getoperation(g))

"""
    unwrappedunitarymatrices(krauschannel)

Returns the unitary Kraus matrices associated to the mixed unitary Kraus channel
without the `Symbolics.Num` wrapper.

!!! note
    If any of the noise channel's parameters is symbolic, an error is thrown.

See [`unitarymatrices`](@ref) for more information.

## Examples

```jldoctests
julia> unwrappedunitarymatrices(PauliX(0.2))
2-element Vector{Matrix}:
 [1.0 -0.0; 0.0 1.0]
 [0 1; 1 0]
```
"""
function unwrappedunitarymatrices(much::AbstractKrausChannel)
    return [unwrapvalue.(kmat) for kmat in unitarymatrices(much)]
end

"""
    unitarygates(krauschannel)

Unitary gates associated to the given mixed unitary Kraus channel.

A mixed unitary channel is written as ``\\sum_k p_k U_k \\rho U_k^\\dagger``,
where ``U_k`` are the unitary operators returned by this function.

An error is returned for Kraus channels with `ismixedunitary(krauschannel)==false`.

See also [`ismixedunitary`](@ref), [`unitarymatrices`](@ref), and [`krausmatrices`](@ref).
    
## Examples

```jldoctests
julia> unitarygates(PauliNoise([0.9,0.1],["II","XX"]))
2-element Vector{PauliString{2}}:
 II
 XX
```
"""
function unitarygates(::AbstractKrausChannel)
    error("unitarygates only works with mixed unitary channels.
           Either this Kraus channel is not mixed unitary,
           or unitarygates method needs to be implemented for this Kraus channel.")
end

function Base.show(io::IO, krauschannel::AbstractKrausChannel)
    compact = get(io, :compact, false)
    print(io, opname(krauschannel))
    if numparams(krauschannel) > 0
        print(io, "(")
        join(io, map(x -> _displaypi(getproperty(krauschannel, x)), parnames(krauschannel)), compact ? "," : ", ")
        print(io, ")")
    end
end

Base.show(io::IO, ::MIME"text/plain", krauschannel::AbstractKrausChannel) = show(io, krauschannel)
