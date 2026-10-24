#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    _displaynum(io, x)

Text of `x` as `print(io, x)` writes it. When `io` is `:compact`, a
floating-point number whose compact text reads back as a different value gets
a trailing `…`, so a shortened number does not look exact. Complex numbers are
marked part by part, and numeric `Num`s are unwrapped first. Integers,
rationals and everything else print unchanged, and so do symbolic
expressions: numeric literals inside them are not marked.
"""
_displaynum(io::IO, x) = sprint(print, x; context=io)

function _displaynum(io::IO, x::Num)
    v = Symbolics.value(x)
    return v isa Number ? _displaynum(io, v) : sprint(print, x; context=io)
end

function _displaynum(io::IO, x::AbstractFloat)
    s = sprint(print, x; context=io)
    get(io, :compact, false) || return s
    # Parsing back, rather than comparing with the full text, avoids false
    # marks from suffixes that only the full form carries (e.g. `0.1f0`).
    y = tryparse(typeof(x), s)
    isnothing(y) || isequal(y, x) ? s : s * "…"
end

# Same layout as `Base.show(::IO, ::Complex)`, with each part marked on its own.
function _displaynum(io::IO, z::Complex{<:AbstractFloat})
    get(io, :compact, false) || return sprint(print, z; context=io)
    r, i = reim(z)
    sign = signbit(i) && !isnan(i) ? "-" : "+"
    star = isfinite(i) ? "" : "*"
    return _displaynum(io, r) * sign * _displaynum(io, abs(i)) * star * "im"
end

# Symbolics writes a numeric complex value as `a`, `bim` or `a + bim`.
function _displaynum(io::IO, z::Complex{Num})
    r, i = Symbolics.value(real(z)), Symbolics.value(imag(z))
    (r isa Real && i isa Real) || return sprint(print, z; context=io)
    iszero(i) && return _displaynum(io, r)
    imtext = _displaynum(io, abs(i)) * "im"
    iszero(r) && return (signbit(i) ? "-" : "") * imtext
    return _displaynum(io, r) * (signbit(i) ? " - " : " + ") * imtext
end

"""
    _displayarray(io, A)

Vector or matrix in `print` layout (`[a, b]`, `[a b; c d]`), with every entry
written through `_displaynum`.
"""
_displayarray(io::IO, v::AbstractVector) = "[" * join((_displaynum(io, x) for x in v), ", ") * "]"

function _displayarray(io::IO, m::AbstractMatrix)
    rows = (join((_displaynum(io, x) for x in r), " ") for r in eachrow(m))
    return "[" * join(rows, "; ") * "]"
end

# Prints `A` as Base does (element type prefix included), but in compact
# output the entries go through `_displaynum` so shortened ones are marked.
function _print_array(io::IO, A::AbstractArray)
    compact = get(io, :compact, false)
    base = sprint(print, A; context=IOContext(io, :compact => compact, :typeinfo => Array{Symbolics.Num}))
    if compact
        print(io, base[1:prevind(base, findfirst('[', base))], _displayarray(io, A))
    else
        print(io, base)
    end
end

function _decomplex(m::Matrix{T}) where {T<:Complex}
    if all(isreal, m)
        return real.(m)
    end
    return m
end

_decomplex(m::Matrix{T}) where {T<:Real} = m

function _decomplex(x::Complex)
    if isreal(x)
        return real(float(x))
    end
    return float(x)
end

function _decomplex(x::Real)
    return float(x)
end

function _power_three_idempotent(obj, invobj, idobj, pwr)
    m = pwr % 3
    if m == 0
        return idobj
    elseif m == 1
        return obj
    elseif m == 2
        return invobj
    else
        return Power(obj, pwr)
    end
end

function _power_idempotent(obj, idobj, pwr)
    m = pwr % 2
    if m == 0
        return idobj
    elseif m == 1
        return obj
    else
        return Power(obj, pwr)
    end
end

function isvalidpowerof2(dim::Int)
    return dim >= 2 && (dim & (dim - 1)) == 0
end

# defines the name for an aliased operation see for example GateS, that is shown
# as "GateS" even if it is an alias for power(GateZ(), 1//2)
macro definename(T, name)
    return esc(quote
        opname(::Type{$T}) = $name
        isopalias(::Type{$T}) = true
        function Base.show(io::IO, op::$T)
            sep = get(io, :compact, false) ? "," : ", "
            print(io, $T, "(")
            join(io, map(x -> _displaypi(io, getparam(op, x)), parnames(op)), sep)
            print(io, ")")
            return nothing
        end
        function Base.show(io::IO, ::MIME"text/plain", op::$T)
            if numparams($T) == 0
                print(io, $name)
                return nothing
            end
            sep = get(io, :compact, false) ? "," : ", "
            print(io, $name, "(")
            join(io, map(x -> _displaypi(io, getparam(op, x)), parnames(op)), sep)
            print(io, ")")
            return nothing
        end
    end)
end

# prints the name of an operation nad wraps it in parentheses if the operation
# is a wrapper (but not if it is aliased)
function _show_wrapped_parens(io::IO, m, op::T) where {T}
    if iswrapper(T) && !isopalias(T)
        print(io, '(')
        show(io, m, op)
        print(io, ')')
    else
        show(io, m, op)
    end
    return nothing
end

function _print_wrapped_parens(io::IO, op::T) where {T}
    if iswrapper(T) && !isopalias(T)
        print(io, '(', op, ')')
    else
        print(io, op)
    end
    return nothing
end

# Exact multiples of π for the decomposition rules, so that decomposed circuits
# carry `π/2` rather than `1.5707963267948966`: exact angles print readably and
# cancel exactly (`π/4 + π/4 - π/2` is zero, so no spurious rotation by 1e-16
# survives). They are built once, as dividing `Num(π)` on every call costs more
# than constructing the gate itself.
const _π_2 = Num(π) / 2
const _π_4 = Num(π) / 4
const _π_8 = Num(π) / 8
const _mπ_2 = -_π_2
const _mπ_4 = -_π_4
const _mπ_8 = -_π_8

Base.cis(x::Num) = cos(x) + im * sin(x)
Base.cispi(x::Num) = cospi(x) + im * sinpi(x)

function unwrapvalue(g::Num)
    v = Symbolics.value(g)

    v isa Number && return v

    # Evaluate constant expressions such as `π / 2` numerically first: this is
    # much cheaper than `simplify`, and decomposition rules produce them for
    # every gate with an angle that is a fraction of π.
    if iscall(v)
        vv = Symbolics.value(Symbolics.symbolic_to_float(v))
        vv isa Number && return vv
    end

    # check for constant number
    if !(v isa Num)
        vv = simplify(v)
        vvc = unwrap_const(vv)
        vvc isa Number && return vvc
    end

    # everything else is symbolic (functions or symbols)
    throw(UndefinedValue(g))
end

unwrapvalue(g::Real) = g

unwrapvalue(g::Complex{<:Real}) = g

unwrapvalue(g::Complex{Num}) = complex(unwrapvalue(real(g)), unwrapvalue(imag(g)))

function listsymbols(g)
    Symbolics.get_variables(g; sort=true)
end
