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

# Tools built on the AncillaAlloc / AncillaFree markers.

@doc raw"""
    ancillas(c::Circuit)

The qubits of `c` that carry an [`AncillaAlloc`](@ref), in increasing order.

These are the clean ancillas that [`decompose`](@ref) added or reused; every
other qubit holds data.

# Examples

```jldoctest
julia> c = push!(Circuit(), Control(4, GateX()), 1:5...);

julia> ancillas(decompose(c; basis=CanonicalBasis(max_ancillas=2)))
2-element Vector{Int64}:
 6
 7
```

See also [`check_ancillas`](@ref), [`merge_ancilla_windows`](@ref).
"""
function ancillas(c::Circuit)
    return sort!(unique(getqubit(inst, 1) for inst in c if getoperation(inst) isa AncillaAlloc))
end

@doc raw"""
    merge_ancilla_windows(c::Circuit)

Return a copy of `c` where an [`AncillaFree`](@ref) followed on the same
qubit, with nothing in between, by an [`AncillaAlloc`](@ref) is removed
together with it.

The two windows become one. This makes two operations that use the same
ancilla adjacent on its wire again, for example so that a pass can cancel a
call against its inverse.

See also [`ancillas`](@ref), [`check_ancillas`](@ref).
"""
function merge_ancilla_windows(c::Circuit)
    keep = trues(length(c))
    # Index of the last instruction on each qubit, if it is an AncillaFree.
    lastfree = Dict{Int,Int}()
    for (i, inst) in enumerate(c)
        op = getoperation(inst)
        if op isa AncillaAlloc
            q = getqubit(inst, 1)
            j = pop!(lastfree, q, 0)
            if j > 0
                keep[i] = keep[j] = false
            end
        elseif op isa AncillaFree
            lastfree[getqubit(inst, 1)] = i
        else
            for q in getqubits(inst)
                delete!(lastfree, q)
            end
        end
    end
    return Circuit(c._instructions[keep])
end

@doc raw"""
    check_ancillas(c::Circuit)

Check that the ancilla markers of `c` are consistent, and throw an
`ArgumentError` naming the first problem otherwise.

It checks that

- on each qubit, every [`AncillaFree`](@ref) closes an open
  [`AncillaAlloc`](@ref), and every window is closed by the end of `c`;
- the last `numancillas(op)` qubit targets of every operation with
  [`numancillas`](@ref) above zero are inside open windows.

It does not simulate `c`: whether an ancilla really is in ``|0⟩`` where the
markers say so is up to whoever placed them.

See also [`ancillas`](@ref).
"""
function check_ancillas(c::Circuit)
    depth = Dict{Int,Int}()
    for (i, inst) in enumerate(c)
        op = getoperation(inst)
        if op isa AncillaAlloc
            q = getqubit(inst, 1)
            depth[q] = get(depth, q, 0) + 1
        elseif op isa AncillaFree
            q = getqubit(inst, 1)
            get(depth, q, 0) > 0 || throw(ArgumentError("instruction $i: AncillaFree on qubit $q, which has no open window"))
            depth[q] -= 1
        else
            L = numancillas(op)
            for q in getqubits(inst)[end-L+1:end]
                get(depth, q, 0) > 0 || throw(ArgumentError("instruction $i: clean ancilla qubit $q of $(opname(op)) is not inside an AncillaAlloc/AncillaFree window"))
            end
        end
    end
    for (q, d) in depth
        d == 0 || throw(ArgumentError("qubit $q: AncillaAlloc without a matching AncillaFree"))
    end
    return nothing
end
