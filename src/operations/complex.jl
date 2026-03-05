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
    Add(N[, constant=0.0])

Add several z-register variables between them and optionally a constant.
The result is strored in the first z-register variable given.

## Examples

```jldoctests
julia> Add(3)
z[?1] += z[?2] + z[?3]

julia> Add(4)
z[?1] += z[?2] + z[?3] + z[?4]

julia> Add(4, 2.0)
z[?1] += 2.0 + z[?2] + z[?3] + z[?4]

julia> c = push!(Circuit(), Add(3), 1,2,3)
3-vars circuit with 1 instruction:
└── z[1] += z[2] + z[3]

julia> push!(c, Add(5), 1,2,3,4,5)
5-vars circuit with 2 instructions:
├── z[1] += z[2] + z[3]
└── z[1] += z[2] + z[3] + z[4] + z[5]

julia> push!(c, Add(5, 2.0), 1,2,3,4,5)
5-vars circuit with 3 instructions:
├── z[1] += z[2] + z[3]
├── z[1] += z[2] + z[3] + z[4] + z[5]
└── z[1] += 2.0 + z[2] + z[3] + z[4] + z[5]
```
"""
struct Add{N} <: Operation{0,0,N}
    term::Num
    function Add(N, constant=0.0)
        if N < 1
            throw(ArgumentError("Add requires at least one z-variable."))
        end
        new{N}(constant)
    end
end

opname(::Type{<:Add}) = "Add"

function Base.show(io::IO, ::MIME"text/plain", g::Instruction{0,0,M,<:Add}) where {M}
    space = get(io, :compact, false) ? "" : " "

    zvars = getztargets(g)
    op = getoperation(g)

    print(io, "z[$(zvars[1])]$space+=$space")

    if M > 1
        if !iszero(op.term)
            print(io, "$(op.term)$space+$space")
        end
        join(io, map(z -> "z[$z]", zvars[2:end]), "$space+$space")
    else
        print(io, "$(op.term)")
    end

    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", g::Add{N}) where {N}
    space = get(io, :compact, false) ? "" : " "

    print(io, "z[?1]$space+=$space")

    if N > 1
        if !iszero(g.term)
            print(io, "$(g.term)$space+$space")
        end
        join(io, map(z -> "z[?$z]", 2:N), "$space+$space")
    else
        print(io, "$(g.term)")
    end

    return nothing
end

"""
    Multiply(N[, constant=1.0])

Multiply several z-register variables between them and optionally a constant.
The result is strored in the first z-register variable given.

## Examples

```jldoctests
julia> Multiply(3)
z[?1] *= z[?2] * z[?3]

julia> Multiply(4)
z[?1] *= z[?2] * z[?3] * z[?4]

julia> Multiply(4, 2.0)
z[?1] *= 2.0 * z[?2] * z[?3] * z[?4]

julia> c = push!(Circuit(), Multiply(4), 1,2,3,4)
4-vars circuit with 1 instruction:
└── z[1] *= z[2] * z[3] * z[4]

julia> push!(c, Multiply(5, 2.0), 1,2,3,4,5)
5-vars circuit with 2 instructions:
├── z[1] *= z[2] * z[3] * z[4]
└── z[1] *= 2.0 * z[2] * z[3] * z[4] * z[5]
```
"""
struct Multiply{N} <: Operation{0,0,N}
    factor::Num

    function Multiply(N, constant=1.0)
        if N < 1
            throw(ArgumentError("Multiply requires at least one z-variable."))
        end
        new{N}(constant)
    end
end

opname(::Type{<:Multiply}) = "Multiply"

function Base.show(io::IO, ::MIME"text/plain", g::Instruction{0,0,M,<:Multiply}) where {M}
    space = get(io, :compact, false) ? "" : " "

    zvars = getztargets(g)
    op = getoperation(g)

    print(io, "z[$(zvars[1])]$space*=$space")
    if M > 1
        if !isone(op.factor)
            print(io, "$(op.factor)$space*$space")
        end
        join(io, map(z -> "z[$z]", zvars[2:end]), "$space*$space")
    else
        print(io, "$(op.factor)")
    end

    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", g::Multiply{N}) where {N}
    space = get(io, :compact, false) ? "" : " "

    print(io, "z[?1]$space*=$space")

    if N > 1
        if !isone(g.factor)
            print(io, "$(g.factor)$space*$space")
        end
        join(io, map(z -> "z[?$z]", 2:N), "$space*$space")
    else
        print(io, "$(g.factor)")
    end

    return nothing
end

"""
    Pow(exp)

Exponentiate a Z-register variable.

# Examples

```jldoctests
julia> Pow(2.0)
z[?] = z[?]^2.0

julia> Pow(-2.0)
z[?] = z[?]^(-2.0)

julia> c = push!(Circuit(), Pow(2.0), 1)
1-vars circuit with 1 instruction:
└── z[1] = z[1]^2.0

julia> push!(c, Pow(-2.0), 1)
1-vars circuit with 2 instructions:
├── z[1] = z[1]^2.0
└── z[1] = z[1]^(-2.0)
```
"""
struct Pow <: Operation{0,0,1}
    exponent::Num

    function Pow(exp)
        if isone(exp)
            @warn "Pow(1) will be equivalent to a no-op."
        end
        new(exp)
    end
end

function Base.show(io::IO, ::MIME"text/plain", g::Instruction{0,0,1,<:Pow})
    space = get(io, :compact, false) ? "" : " "
    zvars = getztargets(g)
    op = getoperation(g)
    print(io, "z[$(zvars[1])]$space=$space")
    if op.exponent >= 0
        print(io, "z[$(zvars[1])]^$(op.exponent)")
    else
        print(io, "z[$(zvars[1])]^($(op.exponent))")
    end
    nothing
end

function Base.show(io::IO, ::MIME"text/plain", g::Pow)
    space = get(io, :compact, false) ? "" : " "
    print(io, "z[?]$space=$space")
    if g.exponent >= 0
        print(io, "z[?]^$(g.exponent)")
    else
        print(io, "z[?]^($(g.exponent))")
    end
    nothing
end
