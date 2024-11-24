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

function ctrl(m::Matrix{T})::Matrix{T} where {T}
    id = typeof(m)(I, size(m)...)
    cat(id, m, dims=(1, 2))
end

function ctrl2(m::Matrix{T})::Matrix{T} where {T}

    return [1.0 0.0 0.0 0.0
        0.0 m[1, 1] 0.0 m[1, 2]
        0.0 0.0 1.0 0.0
        0.0 m[2, 1] 0.0 m[2, 2]]
end

function ctrlfs(m::Matrix{T})::Matrix{T} where {T}

    return ctrl(m) * ctrl2(m)
end

function ctrlsf(m::Matrix{T})::Matrix{T} where {T}

    return ctrl2(m) * ctrl(m)
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
            join(io, map(x -> _displaypi(getparam(op, x)), parnames(op)), sep)
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
            join(io, map(x -> _displaypi(getparam(op, x)), parnames(op)), sep)
            print(io, ")")
            return nothing
        end
    end)
end

# prints the name of an operation nad wraps it in parentheses if the operation
# is a wrapper (but not if it is aliased)
@generated function _show_wrapped_parens(io::IO, m, op::T) where {T}
    if iswrapper(T) && !isopalias(T)
        return quote
            print(io, '(')
            show(io, m, op)
            print(io, ')')
        end
    else
        return :(show(io, m, op))
    end
end

@generated function _print_wrapped_parens(io::IO, op::T) where {T}
    if iswrapper(T) && !isopalias(T)
        return :(print(io, '(', op, ')'))
    else
        return :(print(io, op))
    end
end

function _symbolics_can_convert(x::Num)
    val = Symbolics.value(x)
    val isa Num && return false
    val isa SymbolicUtils.BasicSymbolic{Irrational{:π}} && return true
    val isa SymbolicUtils.BasicSymbolic{Irrational{:ℯ}} && return true
    val isa Number && return true
    return false
end

_substitute_irrationals(expr) = Symbolics.substitute(expr, Dict(π => Float64(π), ℯ => Float64(ℯ)))

_convert_to_number(x::Num) = Symbolics.value(x)

Base.cis(x::Num) = cos(x) + im * sin(x)
Base.cispi(x::Num) = cospi(x) + im * sinpi(x)

function unwrapvalue(g::Num)
    v = Symbolics.value(g)
    if v isa Number
        return v
    elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:π}}
        return π
    elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:ℯ}}
        return ℯ
    else
        throw(UndefinedValue(g))
    end
end

unwrapvalue(g::Real) = g

unwrapvalue(g::Complex{<:Real}) = g

unwrapvalue(g::Complex{Num}) = complex(unwrapvalue(real(g)), unwrapvalue(imag(g)))
