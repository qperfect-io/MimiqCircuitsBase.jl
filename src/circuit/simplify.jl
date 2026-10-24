#
# Copyright © 2026 QPerfect. All Rights Reserved.
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

# Circuit simplification passes. Each takes a circuit and returns a new one
# with the same unitary, global phase included; `simplify` chains them.
#
# The passes work on a compact form of the circuit (circuit/simplify/core.jl):
# each call converts the circuit once, runs, and converts back, reusing the
# instructions it left alone. `simplify` converts once for all its rounds.

include("simplify/table.jl")
include("simplify/core.jl")
include("simplify/passes.jl")

@doc raw"""
    remove_identities(c::Circuit) -> Circuit

Remove gates whose matrix is the identity, such as `GateID`, `GateRZ(0)` or
`GateU(0, 0, 0)`.

The test is on the exact matrix, so a gate that is the identity only up to a
global phase, like `GateRX(2π)`, is kept. Gates with symbolic parameters,
`Delay` and non-unitary operations are always kept.

## Examples

```jldoctest
julia> c = push!(Circuit(), GateRZ(0), 1);

julia> push!(c, GateH(), 1);

julia> remove_identities(c)
1-qubit circuit with 1 instruction:
└── H @ q[1]
```
"""
remove_identities(c::Circuit) = _runsimplify(c, (remove_identities,), 0)

@doc raw"""
    cancel_inverses(c::Circuit) -> Circuit

Delete pairs of gates that multiply to the identity, such as `CX CX`, `H H` or
`S SDG`, also when other gates sit between them as long as the second gate
commutes with all of them.

Two gates cancel when one is the [`inverse`](@ref) of the other on the same
qubits, or when the product of their matrices is the identity, which also
catches `SWAP(1,2) SWAP(2,1)`. Commutation is checked on the gates' matrices,
so for example `Z` passes a `CX` control and `X` passes a `CX` target; gates
with symbolic parameters only pass through each other when both are diagonal.

Multi-controlled X gates (`GateCX`, `GateCCX`, `GateC3X`, `Control(n, GateX())`)
follow structural rules at any width: two of them commute unless the target of
one is a control of the other, they commute with diagonal gates that avoid
their target and with X rotations that avoid their controls, and two on the
same qubits with the same target cancel, whatever the order of the controls.
Other gates wider than six qubits are never moved or cancelled.

Non-unitary operations, barriers and classically controlled gates are never
moved across, and the search looks back a bounded number of instructions.

## Examples

```jldoctest
julia> c = push!(Circuit(), GateCX(), 1, 2);

julia> push!(c, GateZ(), 1);            # Z commutes with the CX control...

julia> push!(c, GateCX(), 1, 2);        # ... so the two CX gates cancel

julia> cancel_inverses(c)
1-qubit circuit with 1 instruction:
└── Z @ q[1]
```
"""
cancel_inverses(c::Circuit) = _runsimplify(c, (cancel_inverses,), 0)

@doc raw"""
    merge_rotations(c::Circuit) -> Circuit

Merge pairs of rotations of the same kind on the same qubits into one, adding
their angles: `RZ(a) RZ(b)` becomes `RZ(a + b)`, and a pair whose sum is the
identity is removed. The two rotations may be separated by gates that commute
with the second one, as in [`cancel_inverses`](@ref).

Merged gates are `GateRX`, `GateRY`, `GateRZ`, `GateP`, `GateU1`, `GateR`,
`GateRXX`, `GateRYY`, `GateRZZ`, `GateRZX`, `GateXXplusYY`, `GateXXminusYY` and
`RPauli`, any of them under the same [`Control`](@ref) (`GateCRZ`, `GateCP`,
…). Gates with more than one parameter merge only when the others are equal.
Symbolic angles are added symbolically.

Single-qubit gates with numeric parameters also merge across kinds, within
families of rotations about the same axis that compose without a global
phase:

- `GateZ`, `GateS`, `GateSDG`, `GateT`, `GateTDG`, `GateP`, `GateU1`
- `GateX`, `GateSX`, `GateSXDG`
- `GateY`, `GateSY`, `GateSYDG`

so `T T` becomes `S` and `S Z` becomes `SDG`. The result is the named gate
when there is one and `GateP` or `GateU` otherwise. `GateRZ`, `GateRX` and
`GateRY` merge only with themselves, since they differ from the other members
of their family by a global phase. Any single-qubit gate with the matrix of
one of these, such as a `GateU`, is treated as that gate.

## Examples

```jldoctest
julia> @variables θ;

julia> c = push!(Circuit(), GateRZ(θ), 1);

julia> push!(c, GateCZ(), 1, 2);        # diagonal gates commute

julia> push!(c, GateRZ(0.5), 1);

julia> merge_rotations(c)
2-qubit circuit with 2 instructions:
├── RZ(0.5 + θ) @ q[1]
└── CZ @ q[1], q[2]

julia> d = push!(Circuit(), GateT(), 1);

julia> push!(d, GateCX(), 1, 2);        # T on the control commutes with CX

julia> push!(d, GateT(), 1);

julia> merge_rotations(d)               # T T = S
2-qubit circuit with 2 instructions:
├── S @ q[1]
└── CX @ q[1], q[2]
```
"""
merge_rotations(c::Circuit) = _runsimplify(c, (merge_rotations,), 0)

@doc raw"""
    resynthesize_1q(c::Circuit) -> Circuit

Replace every run of two or more single-qubit gates on the same qubit by one
[`GateU`](@ref), or remove it when the run multiplies to the identity.

A run ends at any instruction touching the qubit that is not a single-qubit
gate with numeric parameters. Single gates are left as they are.

## Examples

```jldoctest
julia> c = push!(Circuit(), GateH(), 1);

julia> push!(c, GateS(), 1);

julia> push!(c, GateH(), 1);

julia> length(resynthesize_1q(c))
1
```
"""
resynthesize_1q(c::Circuit) = _runsimplify(c, (resynthesize_1q,), 0)

@doc raw"""
    resynthesize_2q(c::Circuit) -> Circuit

Regroup the gates of `c` into blocks acting on at most two qubits, as
[`fuse`](@ref) does, and rewrite each two-qubit block with the fewest `GateCX`
it needs, between zero and three, found from its KAK decomposition
[Kraus2001](@cite) and the circuits of [Vatan2004](@cite).

A block is rewritten only when that lowers its number of two-qubit gates: a
SWAP written as three CX gates stays as it is, since it needs all three, while
any longer sequence on the same pair of qubits comes down to three or fewer. The rewritten block uses
`GateCX`, `GateU` and `GateRX`, `GateRY`, `GateRZ`, `GateH`; follow with
[`resynthesize_1q`](@ref) to merge the single-qubit gates it leaves behind.

Gates with symbolic parameters and non-unitary operations are left alone and
end the blocks around them.

## Examples

```jldoctest
julia> c = Circuit();

julia> for _ in 1:2                     # three CX with rotations in between...
           push!(c, GateCX(), 1, 2)
           push!(c, GateRX(0.3), 1)
       end

julia> push!(c, GateCX(), 1, 2);

julia> count(inst -> numqubits(inst) == 2, resynthesize_2q(c))  # ...need only one
1
```
"""
resynthesize_2q(c::Circuit) = _runsimplify(c, (resynthesize_2q,), 0)

@doc raw"""
    resynthesize_linear(c::Circuit) -> Circuit

Rewrite every block made only of `GateX`, `GateCX` and `GateSWAP` gates, of any
width, by resynthesizing the map it computes.

Such a block sends the basis state ``x`` to ``A x \oplus b`` for an invertible
Boolean matrix ``A``, so it is a classical linear (affine) function of the bits.
The block is rebuilt from ``A`` with Patel-Markov-Hayes elimination
[Patel2008](@cite), which needs ``O(n^2/\log n)`` CX gates for ``n`` qubits,
followed by one `GateX` for each set bit of ``b``. The rewrite is kept only when it has fewer two-qubit gates than
the block, or as many and fewer gates in total. A block that computes the
identity is removed.

This finds savings that local passes miss, such as CX ladders that partly undo
each other over many qubits. Blocks are collected like [`fuse`](@ref) does, and
end at any other instruction on their qubits.

It is not one of the [`DEFAULT_SIMPLIFY_PASSES`](@ref): circuits where CX
networks are a small part gain little from it. Pass it to [`simplify`](@ref)
explicitly when they are not.

## Examples

```jldoctest
julia> c = Circuit();

julia> for _ in 1:2, q in 1:3               # a CX ladder, applied twice...
           push!(c, GateCX(), q, q + 1)
       end

julia> count(inst -> numqubits(inst) == 2, resynthesize_linear(c))  # ...needs 2 CX
2
```
"""
resynthesize_linear(c::Circuit) = _runsimplify(c, (resynthesize_linear,), 0)

_SIMPLIFY_PASSES[remove_identities] = _remove_identities
_SIMPLIFY_PASSES[cancel_inverses] = (ctx, c) -> _peephole(_cancelpair, ctx, c)
_SIMPLIFY_PASSES[merge_rotations] = (ctx, c) -> _peephole(_mergepair, ctx, c)
_SIMPLIFY_PASSES[resynthesize_1q] = _resynthesize_1q
_SIMPLIFY_PASSES[resynthesize_2q] = _resynthesize_2q
_SIMPLIFY_PASSES[resynthesize_linear] = _resynthesize_linear

@doc raw"""
    simplify(c::Circuit; passes=DEFAULT_SIMPLIFY_PASSES, maxiter=10) -> Circuit

Simplify a circuit by running `passes` in order, repeatedly, until a round no
longer lowers the number of two-qubit gates or, failing that, the total number
of instructions. The result has the same unitary as `c`, global phase
included, and the same measurements, resets and other non-unitary operations
in the same order.

`passes` is any collection of functions from `Circuit` to `Circuit`. The
default, [`DEFAULT_SIMPLIFY_PASSES`](@ref), is

1. [`remove_identities`](@ref)
2. [`cancel_inverses`](@ref)
3. [`merge_rotations`](@ref)
4. [`resynthesize_2q`](@ref)
5. [`resynthesize_1q`](@ref)

[`resynthesize_linear`](@ref) is not among them: it pays off on circuits with
large CX networks, such as arithmetic or error-correction encoders, and costs
extra rounds for little on others. Add it where it fits, for example
`passes=(remove_identities, cancel_inverses, merge_rotations,
resynthesize_linear, resynthesize_2q, resynthesize_1q)`.

Gates are rewritten numerically, so single-qubit runs come out as `GateU` and
named gates such as `GateH` or `GateS` may be replaced by it. Pass a subset to
keep them, for example `passes=(remove_identities, cancel_inverses,
merge_rotations)`. Gates with symbolic parameters are only touched by the
first three passes.

## Examples

```jldoctest
julia> c = push!(Circuit(), GateCX(), 1, 2);

julia> push!(c, GateRZ(0.2), 1);        # RZ commutes with the CX control...

julia> push!(c, GateCX(), 1, 2);        # ...so the two CX gates cancel

julia> push!(c, GateRZ(0.3), 1);        # and the rotations merge

julia> simplify(c)
1-qubit circuit with 1 instruction:
└── RZ(0.5) @ q[1]
```
"""
function Symbolics.simplify(c::Circuit; passes=DEFAULT_SIMPLIFY_PASSES, maxiter::Integer=10)
    all(p -> haskey(_SIMPLIFY_PASSES, p), passes) && return _runsimplify(c, passes, maxiter)

    # Other functions among the passes: the same rounds, on circuits.
    cost = _simplifycost(c)
    version = 0
    seen = fill(-1, length(passes))
    for _ in 1:maxiter
        next = c
        for (k, pass) in enumerate(passes)
            seen[k] == version && continue
            d = pass(next)
            d == next || (version += 1)
            seen[k] = version
            next = d
        end
        nextcost = _simplifycost(next)
        nextcost < cost || break
        c, cost = next, nextcost
    end
    return c
end

"""
    DEFAULT_SIMPLIFY_PASSES

The passes [`simplify`](@ref) runs by default, in order: `remove_identities`,
`cancel_inverses`, `merge_rotations`, `resynthesize_2q`, `resynthesize_1q`.
"""
const DEFAULT_SIMPLIFY_PASSES =
    (remove_identities, cancel_inverses, merge_rotations, resynthesize_2q, resynthesize_1q)
