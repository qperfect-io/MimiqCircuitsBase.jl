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
    Control(numcontrols, gate) <: AbstractGate

Control modifier, similar to OpenQASM 3.0 `ctrl @ gate`.
It wraps a given gate and adds a number of controls to it.

!!! note
    By default the first `numcontrols` qubits are used as controls, and the
    remaining ones as targets for the wrapped gate.

See also [`Power`](@ref), [`Inverse`](@ref), [`getoperation`](@ref),
[`iswrapper`](@ref), [`numcontrols`](@ref), [`numtargets`](@ref).

## Examples

```jldoctests
julia> Control(1, GateX())
CX

julia> Control(3, GateH())
C₃H

julia> Control(24, GateSWAP())
C₂₄SWAP
```

## Decomposition

The default decomposition of a `Control` gate is build by applying recursively
Lemma 7.3 of [Barenco1995](@cite). This requires to decompose multicontrolled-``X``
gates, which is done recursively, according to Lemma 7.2 and 7.3 of
[Barenco1995](@cite).

Here we give a simple example of a decomposition of a ``C_5T`` gate.

```jldoctests
julia> decompose(Control(3,GateT()))
4-qubit circuit with 9 instructions:
├── C(Z^(1//8)) @ q[3], q[4]
├── C₂X @ q[1:2], q[3]
├── C((Z^(1//8))†) @ q[3], q[4]
├── C₂X @ q[1:2], q[3]
├── C(Z^(1//16)) @ q[2], q[4]
├── CX @ q[1], q[2]
├── C((Z^(1//16))†) @ q[2], q[4]
├── CX @ q[1], q[2]
└── C(Z^(1//16)) @ q[1], q[4]
```

!!! detail
    Some decompositions have been overrided with optimized versions, to reduce
    the number of gates used.
"""
struct Control{N,M,L,T<:AbstractGate{M}} <: AbstractGate{L}
    op::T

    function Control{N,M,L,T}(args...; kwargs...) where {N,M,L,T<:Operation{M,0}}
        if !(N isa Integer) || !(M isa Integer) || !(L isa Integer)
            throw(ArgumentError("The first 3 arguments of Control must be integers"))
        end

        if N < 1
            throw(ArgumentError("Invalid number of controls. Must be >= 1."))
        end

        if N + M != L
            throw(ArgumentError("Invalid Control{N,M,L,T} parameters. N+M must be = L."))
        end

        new{N,M,L,T}(T(args...; kwargs...))
    end

    function Control(controls::Integer, op::T) where {N,T<:Operation{N,0}}

        if controls < 1
            throw(ArgumentError("Invalid number of controls. Must be >= 1."))
        end

        return new{controls,N,controls + N,T}(op)
    end
end

Control(controls::Integer, op::Control) = Control(controls + numcontrols(op), getoperation(op))

"""
    Control(gate)

Build a controlled gate with 1 control.
"""
Control(op::Operation{N,0}) where {N} = Control(1, op)

"""
    control([numcontrols], gate)

Build a multicontrolled gate.

The number of controls can be omitted to be lazily evaluated later.

## Examples

Standard examples, with all the arguments spefcified.

```jldoctests
julia> control(1, GateX())
CX

julia> control(2, GateX())
C₂X

julia> control(3, GateCH())
C₄H

```
"""
function control end

control(numcontrols::Integer, op::Operation{N,0}) where {N} = Control(numcontrols, op)

control(op::Operation{N,0}) where {N} = LazyExpr(control, LazyArg(), op)
control(num_controls, l::LazyExpr) = LazyExpr(control, num_controls, l)
control(l::LazyExpr) = LazyExpr(control, LazyArg(), l)

getoperation(c::Control) = c.op

iswrapper(::Type{<:Control}) = true

# control and inverse are commuting
# we prefer the control modifier to be applied last
inverse(c::Control{N}) where {N} = Control(N, inverse(getoperation(c)))

# control and power are commuting
# we prefer the control modifier to be applied last
_power(c::Control{N}, pwr) where {N} = Control(N, power(getoperation(c), pwr))

qregsizes(op::Control{N,M,L,T}) where {N,M,L,T} = (N, qregsizes(getoperation(op))...)

# numparams is defined by default from parnames
parnames(::Type{Control{N,M,L,T}}) where {N,M,L,T} = parnames(T)

# access directly the parameters of the wrapped gate
getparam(c::Control, name::Symbol) = getparam(getoperation(c), name)

opname(::Type{<:Control}) = "Control"

"""
    numcontrols(control)

Number of controls of a given multicontrolled gate.

## See also

[`Control`](@ref), [`numtargets`](@ref), [`numqubits`](@ref)
"""
function numcontrols end

numcontrols(::Type{<:Control{N}}) where {N} = N

numcontrols(::T) where {T<:Control} = numcontrols(T)

"""
    numtargets(control)

Get the number of targets of a given multicontrolled gate.

## Examples

numcontro
## See also

[`Control`](@ref), [`numtargets`](@ref), [`numqubits`](@ref)
"""
function numtargets end

numtargets(::Type{<:Control{N,M}}) where {N,M} = M

numtargets(::T) where {T<:Control} = numtargets(T)

function _ctrl_matrix(::Val{N}, op::Operation{M,0}) where {N,M}
    opmat = matrix(op)
    L = N + M

    Mdim = 2^M
    Ldim = 2^L

    T = eltype(opmat)

    mat = zeros(promote_type(T, Float64), (Ldim, Ldim))
    mat[end-Mdim+1:end, end-Mdim+1:end] = opmat

    for i in 1:Ldim-Mdim
        mat[i, i] = 1.0
    end

    return mat
end

function _ctrl_matrix(::Val{N}, opmat::AbstractMatrix) where {N}
    Mdim = size(opmat, 1)
    M = Mdim >> 1

    L = N + M

    Ldim = 2^L

    T = eltype(opmat)

    mat = zeros(promote_type(T, Float64), (Ldim, Ldim))
    mat[end-Mdim+1:end, end-Mdim+1:end] = opmat

    for i in 1:Ldim-Mdim
        mat[i, i] = 1.0
    end

    return mat
end

@generated _matrix(::Type{Control{N,M,L,T}}) where {N,M,L,T} = _ctrl_matrix(Val(N), _matrix(T))

function _matrix(::Type{Control{N,M,L,T}}, args...) where {N,M,L,T}
    return _ctrl_matrix(Val(N), _matrix(T, args...))
end

function Base.show(io::IO, c::Control{1})
    print(io, "C")
    _print_wrapped_parens(io, getoperation(c))
end

function Base.show(io::IO, c::Control{N}) where {N}
    subscript = collect("₀₁₂₃₄₅₆₇₈₉")
    Ntext = join(map(x -> subscript[x+1], reverse(digits(N))))
    print(io, "C", Ntext)
    _print_wrapped_parens(io, getoperation(c))
end
