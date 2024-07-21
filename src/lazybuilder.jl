#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    LazyArg()

Placeholder for a lazy argument in a `LazyExpr`.
"""
struct LazyArg end

Base.show(io::IO, ::LazyArg) = print(io, "?")

"""
    LazyExpr(type, args)

Helps evaluating expressions lazily.

Evaluation occurs only then the `LazyExpr` is called with some arguments,
and the arguments will be passed to the inner part of the expression.
"""
struct LazyExpr
    obj::Any
    args::Vector{Any}

    function LazyExpr(t, args...)
        new(t, Any[args...])
    end
end

function _lazy_recursive_evaluate!(args, expr::LazyExpr)
    actual = []
    for arg in expr.args
        if arg isa LazyArg
            if isempty(args)
                error("Not enough arguments for lazy expression.")
            end
            push!(actual, popfirst!(args))
        elseif arg isa LazyExpr
            push!(actual, _lazy_recursive_evaluate!(args, arg))
        else
            push!(actual, arg)
        end
    end

    return expr.obj(actual...)
end

(expr::LazyExpr)(args...) = _lazy_recursive_evaluate!(collect(args), expr)

power(l::LazyExpr, pwr) = LazyExpr(power, l, pwr)
power(l::LazyExpr) = LazyExpr(power, l, LazyArg())

inverse(l::LazyExpr) = LazyExpr(inverse, l)

function Base.show(io::IO, l::LazyExpr)
    typeinfo = get(io, :typeinfo, nothing)
    if typeinfo == "lazy"
        print(io, l.obj, "(")
        join(io, l.args, ", ")
        print(io, ")")
    else
        nio = IOContext(io, :typeinfo => "lazy")
        print(nio, "lazy ", l.obj, "(")
        join(nio, l.args, ", ")
        print(nio, ")")
    end
end

