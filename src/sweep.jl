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

@doc raw"""
    ParameterTable(symbols, values)
    ParameterTable(symbol => values, ...)
    ParameterTable(points)

Values for the symbolic parameters of a circuit, one row per point of a sweep.

In a sweep every point binds the same symbols, so a table stores them once, in a
fixed order, together with a matrix of values: row `i` holds the values of
point `i`, and column `j` the values of `symbols[j]`.

- `ParameterTable(symbols, values)` takes the symbols and an
  `npoints × nsymbols` matrix.
- `ParameterTable(θ => xs, φ => ys)` takes one column per symbol. All the
  columns must have the same length, and point `i` takes the `i`-th value of
  each. For every combination of the values instead, use [`gridtable`](@ref).
- `ParameterTable(points)` takes a vector of dictionaries, one per point.
  Every dictionary must bind the same symbols.

Every symbol must be a plain variable, such as one created with `@variables`,
and appear only once. Values are stored as `Float64`.

Tables compose: `a * b` is the Cartesian product, `hcat(a, b)` pairs the points
of two tables of the same length, and `vcat(a, b)` appends the points of `b`
after those of `a`.

`length(t)` is the number of points, `t[i]` is point `i` as a dictionary ready
for [`evaluate`](@ref), and `t[1:2]` or `t[[1, 3]]` is the table of the
selected points. [`listvars`](@ref) gives the symbols, and `Matrix(t)` the
values. Iterating over a table gives its points. Two tables are equal when
they have the same symbols, in the same order, and the same values.

See also [`gridtable`](@ref), [`SweepExperiment`](@ref).

## Examples

```jldoctest
julia> @variables θ φ;

julia> t = ParameterTable(θ => [0.0, 0.5, 1.0], φ => [0.0, 0.25, 0.5])
ParameterTable with 3 points over (θ, φ):
├── θ = 0.0, φ = 0.0
├── θ = 0.5, φ = 0.25
└── θ = 1.0, φ = 0.5

julia> t[2][φ]
0.25

julia> ParameterTable(θ => [0.0, 1.0]) * ParameterTable(φ => [0.0, 0.5])
ParameterTable with 4 points over (θ, φ):
├── θ = 0.0, φ = 0.0
├── θ = 0.0, φ = 0.5
├── θ = 1.0, φ = 0.0
└── θ = 1.0, φ = 0.5
```
"""
struct ParameterTable
    symbols::Vector{Num}
    values::Matrix{Float64}

    function ParameterTable(symbols::AbstractVector, values::AbstractMatrix{<:Real})
        syms = Num[s for s in symbols]
        if size(values, 2) != length(syms)
            throw(DimensionMismatch(
                "the table has $(length(syms)) symbols but $(size(values, 2)) columns of values",
            ))
        end
        for s in syms
            if !SymbolicUtils.issym(Symbolics.value(s))
                throw(ArgumentError("`$s` is not a plain symbolic variable"))
            end
        end
        if !allunique(syms)
            throw(ArgumentError("every symbol must appear only once in a table"))
        end
        return new(syms, Matrix{Float64}(values))
    end
end

function ParameterTable(columns::Pair...)
    isempty(columns) && throw(ArgumentError("a table needs at least one column"))
    n = length(last(first(columns)))
    if any(c -> length(last(c)) != n, columns)
        throw(DimensionMismatch(
            "all columns must have the same length; use `gridtable` for every combination of values",
        ))
    end
    syms = [first(c) for c in columns]
    return ParameterTable(syms, hcat((collect(Float64, last(c)) for c in columns)...))
end

function ParameterTable(points::AbstractVector{<:AbstractDict})
    isempty(points) && throw(ArgumentError("a table needs at least one point"))
    # Dictionaries have no order, so sort by name for a deterministic layout.
    syms = sort!(collect(Num, keys(first(points))); by=string)
    for (i, p) in enumerate(points)
        if length(p) != length(syms) || !all(s -> haskey(p, s), syms)
            throw(ArgumentError("point $i binds different symbols than point 1"))
        end
    end
    values = [Float64(unwrapvalue(p[s])) for p in points, s in syms]
    return ParameterTable(syms, values)
end

@doc raw"""
    gridtable(symbol => values, ...)

Build the [`ParameterTable`](@ref) of every combination of the given values,
the Cartesian product of the columns.

The first symbol varies slowest and the last one fastest, so
`gridtable(θ => [0, 1], φ => [0, 2, 4])` has 6 points: `θ = 0` with each `φ`,
then `θ = 1` with each `φ`. It is the same as multiplying the one-column tables
with `*`.

## Examples

```jldoctest
julia> @variables θ φ;

julia> gridtable(θ => [0.0, 1.0], φ => [0.0, 2.0, 4.0])
ParameterTable with 6 points over (θ, φ):
├── θ = 0.0, φ = 0.0
├── θ = 0.0, φ = 2.0
├── θ = 0.0, φ = 4.0
├── θ = 1.0, φ = 0.0
├── θ = 1.0, φ = 2.0
└── θ = 1.0, φ = 4.0
```
"""
gridtable(columns::Pair...) = reduce(*, (ParameterTable(c) for c in columns))

Base.length(t::ParameterTable) = size(t.values, 1)

listvars(t::ParameterTable) = copy(t.symbols)

Base.Matrix(t::ParameterTable) = copy(t.values)

Base.getindex(t::ParameterTable, i::Integer) =
    Dict{Num,Float64}(zip(t.symbols, view(t.values, i, :)))

Base.getindex(t::ParameterTable, i::AbstractVector) = ParameterTable(t.symbols, t.values[i, :])

Base.firstindex(::ParameterTable) = 1
Base.lastindex(t::ParameterTable) = length(t)

# Symbols compare with `isequal`: `==` on `Num` builds a symbolic equation.
Base.isequal(a::ParameterTable, b::ParameterTable) =
    isequal(a.symbols, b.symbols) && isequal(a.values, b.values)
Base.:(==)(a::ParameterTable, b::ParameterTable) =
    isequal(a.symbols, b.symbols) && a.values == b.values
Base.hash(t::ParameterTable, h::UInt) = hash(t.values, hash(t.symbols, hash(ParameterTable, h)))

Base.iterate(t::ParameterTable, i::Integer=1) = i > length(t) ? nothing : (t[i], i + 1)

Base.eltype(::Type{ParameterTable}) = Dict{Num,Float64}

function _checkdisjoint(a::ParameterTable, b::ParameterTable)
    shared = filter(s -> any(x -> isequal(x, s), b.symbols), a.symbols)
    if !isempty(shared)
        throw(ArgumentError("both tables give values for $(join(shared, ", "))"))
    end
end

function Base.:*(a::ParameterTable, b::ParameterTable)
    _checkdisjoint(a, b)
    na, nb = length(a), length(b)
    # Point (i, j) of the product, with `i` slowest, is row `(i - 1) * nb + j`.
    ia = repeat(1:na; inner=nb)
    ib = repeat(1:nb; outer=na)
    return ParameterTable(vcat(a.symbols, b.symbols), hcat(a.values[ia, :], b.values[ib, :]))
end

function Base.hcat(a::ParameterTable, b::ParameterTable)
    _checkdisjoint(a, b)
    if length(a) != length(b)
        throw(DimensionMismatch(
            "cannot pair the points of tables with $(length(a)) and $(length(b)) points",
        ))
    end
    return ParameterTable(vcat(a.symbols, b.symbols), hcat(a.values, b.values))
end

# Pairwise by hand, here and in `vcat`: on Julia 1.13, `reduce` and `foldl`
# over a tuple take a fast path for `hcat`/`vcat` that never calls the
# two-table method.
Base.hcat(a::ParameterTable, b::ParameterTable, c::ParameterTable...) =
    hcat(hcat(a, b), c...)

function Base.vcat(a::ParameterTable, b::ParameterTable)
    # Accept the same symbols in any order, and lay `b` out like `a`.
    perm = [findfirst(x -> isequal(x, s), b.symbols) for s in a.symbols]
    if length(a.symbols) != length(b.symbols) || any(isnothing, perm)
        throw(ArgumentError("only tables over the same symbols can be concatenated"))
    end
    return ParameterTable(a.symbols, vcat(a.values, b.values[:, perm]))
end

Base.vcat(a::ParameterTable, b::ParameterTable, c::ParameterTable...) =
    vcat(vcat(a, b), c...)

function _showpoint(io::IO, t::ParameterTable, i::Integer)
    join(io, ("$s = $v" for (s, v) in zip(t.symbols, view(t.values, i, :))), ", ")
end

function Base.show(io::IO, t::ParameterTable)
    print(io, "ParameterTable(", length(t), " points over (")
    join(io, t.symbols, ", ")
    print(io, "))")
end

function Base.show(io::IO, ::MIME"text/plain", t::ParameterTable)
    n = length(t)
    print(io, "ParameterTable with ", n, n == 1 ? " point" : " points", " over (")
    join(io, t.symbols, ", ")
    print(io, "):")
    # Long tables show their first and last points only.
    shown = n <= 10 ? collect(1:n) : vcat(1:5, n-4:n)
    for (k, i) in enumerate(shown)
        if n > 10 && k == 6
            print(io, "\n├── ⋮")
        end
        print(io, "\n", k == length(shown) ? "└── " : "├── ")
        _showpoint(io, t, i)
    end
end

@doc raw"""
    SweepExperiment(circuit, table)

A parameter sweep: a symbolic `circuit` and the [`ParameterTable`](@ref) of
values to run it with, one execution per point.

The table must give values for exactly the free symbols of the circuit, no
more and no fewer, so a missing or misspelled symbol is caught when the
experiment is built rather than when the sweep runs.

`length(ex)` is the number of points, `ex[i]` is the circuit evaluated at point
`i`, `ex[1:2]` is the experiment over the selected points only, and iterating
over the experiment gives the evaluated circuits in order.
Executing it on a backend returns one result per point.

See also [`ParameterTable`](@ref), [`gridtable`](@ref).

## Examples

```jldoctest
julia> @variables θ;

julia> c = push!(Circuit(), GateRX(θ), 1);

julia> ex = SweepExperiment(c, ParameterTable(θ => [0.0, π / 2, π]))
SweepExperiment:
├── circuit: 1-qubit circuit with 1 instruction
└── table: ParameterTable(3 points over (θ))

julia> ex[2]
1-qubit circuit with 1 instruction:
└── RX(π/2) @ q[1]
```
"""
struct SweepExperiment
    circuit::Circuit
    table::ParameterTable

    function SweepExperiment(circuit::Circuit, table::ParameterTable)
        if !issymbolic(circuit)
            throw(ArgumentError("the circuit of a sweep must be symbolic"))
        end
        cvars = Set(listvars(circuit))
        tvars = Set(listvars(table))
        missingvars = setdiff(cvars, tvars)
        if !isempty(missingvars)
            throw(ArgumentError(
                "the table gives no values for $(join(sort(string.(collect(missingvars))), ", "))",
            ))
        end
        extravars = setdiff(tvars, cvars)
        if !isempty(extravars)
            throw(ArgumentError(
                "the table gives values for $(join(sort(string.(collect(extravars))), ", ")), which the circuit does not use",
            ))
        end
        return new(circuit, table)
    end
end

Base.length(ex::SweepExperiment) = length(ex.table)

Base.getindex(ex::SweepExperiment, i::Integer) = evaluate(ex.circuit, ex.table[i])

Base.getindex(ex::SweepExperiment, i::AbstractVector) = SweepExperiment(ex.circuit, ex.table[i])

Base.firstindex(::SweepExperiment) = 1
Base.lastindex(ex::SweepExperiment) = length(ex)

Base.isequal(a::SweepExperiment, b::SweepExperiment) =
    isequal(a.circuit, b.circuit) && isequal(a.table, b.table)
Base.:(==)(a::SweepExperiment, b::SweepExperiment) = a.circuit == b.circuit && a.table == b.table
# `Circuit` has no structural hash, so only the table goes in.
Base.hash(ex::SweepExperiment, h::UInt) = hash(ex.table, hash(SweepExperiment, h))

Base.iterate(ex::SweepExperiment, i::Integer=1) =
    i > length(ex) ? nothing : (ex[i], i + 1)

Base.eltype(::Type{SweepExperiment}) = Circuit

numqubits(ex::SweepExperiment) = numqubits(ex.circuit)
numbits(ex::SweepExperiment) = numbits(ex.circuit)
numzvars(ex::SweepExperiment) = numzvars(ex.circuit)
listvars(ex::SweepExperiment) = listvars(ex.table)

function Base.show(io::IO, ::MIME"text/plain", ex::SweepExperiment)
    println(io, "SweepExperiment:")
    print(io, "├── circuit: ")
    _show_circuit_summary(io, ex.circuit)
    print(io, "\n└── table: ", ex.table)
end

# The one-line header a circuit prints before its instructions.
function _show_circuit_summary(io::IO, c::Circuit)
    s = sprint(show, MIME"text/plain"(), c)
    print(io, rstrip(first(split(s, '\n')), ':'))
end
