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
    emplace!(circuit, operation, registers...)

Emplace an operation at the end of a circuit and applies it to the given
registers.

```jldoctests
julia> emplace!(Circuit(), control(3, GateSWAP()), [1,2,3], [4,5])
5-qubit circuit with 1 instructions:
└── C₃SWAP @ q[1:3], q[4:5]

julia> QFT()
lazy QFT(?)

julia> emplace!(Circuit(), QFT(), [1,2,3])
3-qubit circuit with 1 instructions:
└── QFT @ q[1:3]

```

"""
function emplace! end

function emplace!(c::Circuit, op::Operation, regs...)
    lr = length(regs)
    lq = length(qregsizes(op))
    lc = length(cregsizes(op))

    if lr != lq + lc
        error(lazy"Wrong number of registers. Expected $(lq) quantum + $(lc) classical, got $(lr)")
    end

    qr = qregsizes(op)
    for i in 1:lq
        if length(regs[i]) != qr[i]
            error(lazy"Wrong size for $(i)th quantum register. Expected $(qr[i]), got $(length(regs[i])).")
        end
    end

    cr = cregsizes(op)
    for i in 1:lc
        if length(regs[i+lq]) != cr[i]
            error(lazy"Wrong size for $(i)th classical register. Expected $(cr[i]), got $(length(regs[i + lq])).")
        end
    end

    push!(c, op, (regs...)...)
end

function _lazy_recursive_evaluate_emplace!(args, expr::LazyExpr)
    actual = []

    if expr.obj == parallel && expr.args[1] isa LazyArg
        arg = expr.args[2]

        la = length(args)

        op = if arg isa LazyExpr
            _lazy_recursive_evaluate!(args, arg)
        elseif arg isa Operation
            arg
        else
            error("Invalid argument for Parallel")
        end

        lr = length(qregsizes(op))

        if la % lr != 0
            error("Cannot deduce repetitions from number of registers.")
        end

        return Parallel(div(la, lr), op)
    end

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

function emplace!(c::Circuit, op::LazyExpr, regs...)
    obj = _lazy_recursive_evaluate_emplace!(collect(length.(regs)), op)

    if obj isa LazyExpr
        throw(ArgumentError("Lazy expression not fully evaluated."))
    end

    emplace!(c, obj, regs...)
end
