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


@doc raw"""
    ReadoutErr(p0, p1)
    ReadoutErr(confusionmatrix)

Represents a classical readout error applied immediately after a measurement. 
Can be initialized either from a 2×2 confusion matrix or from the error probabilities
``p0`` and ``p1``.

The error is defined by a 2×2 *confusion matrix*:

```math
\begin{pmatrix}{cc}
    P(\text{report} 0 | \text{true} 0) & P(\text{report} 1 | \text{true} 0)=P_0\\
    P(\text{report} 0 | \text{true} 1) = P_1 & P(\text{report} 1 | {true} 1)
\end{pmatrix}
```

Each row corresponds to the *true quantum outcome* (0 in the first row, 1 in
the second row) while each column corresponds to the *reported classical
outcome* after noise. Each entry at position ``(i,j)`` gives the probability of
reporting ``j``` when the true outcome was ``i``.
"""
struct ReadoutErr <: Operation{0,1,0}
    p0::Num
    p1::Num

    function ReadoutErr(p0, p1)
        if !(p0 isa Symbolics.Num) && !(0.0 ≤ p0 ≤ 1.0)
            throw(ArgumentError("p0 must be in [0,1], got $p0"))
        end
        if !(p1 isa Symbolics.Num) && !(0.0 ≤ p1 ≤ 1.0)
            throw(ArgumentError("p1 must be in [0,1], got $p1"))
        end
        return new(p0, p1)
    end
end

# convenience constructor from error probabilities
function ReadoutErr(confusion::AbstractMatrix{<:Real})
    size(confusion) == (2, 2) ||
        throw(ArgumentError("ReadoutErr confusion matrix must be 2×2"))

    if any(x -> x isa Symbolics.Num, confusion)
        throw(ArgumentError("Confusion matrix cannot contain symbolic elements."))
    end

    cmatrix = Matrix{Float64}(confusion)

    # Check probabilities
    if any(x -> x < 0 || x > 1, cmatrix)
        throw(ArgumentError("Confusion matrix entries must be in [0,1]"))
    end

    # Check row sums ≈ 1
    for i in 1:2
        if !(sum(cmatrix[i, :]) ≈ 1.0)
            throw(ArgumentError("Row $i of confusion matrix must sum to 1"))
        end
    end

    ReadoutErr(confusion[1, 2], confusion[2, 1])
end

function evaluate(op::ReadoutErr, d::Dict=Dict())
    p0_eval = Symbolics.substitute(op.p0, d)
    p1_eval = Symbolics.substitute(op.p1, d)

    p0_val = issymbolic(p0_eval) ? p0_eval : unwrapvalue(p0_eval)
    p1_val = issymbolic(p1_eval) ? p1_eval : unwrapvalue(p1_eval)

    if p0_val isa Real && !(0.0 ≤ p0_val ≤ 1.0)
        throw(ArgumentError("p0 must be in [0,1] after evaluation, got $p0_val"))
    end
    if p1_val isa Real && !(0.0 ≤ p1_val ≤ 1.0)
        throw(ArgumentError("p1 must be in [0,1] after evaluation, got $p1_val"))
    end

    return ReadoutErr(p0_val, p1_val)
end

opname(::Type{<:ReadoutErr}) = "RErr"

matrix(op::ReadoutErr) = [1-op.p0 op.p0; op.p1 1-op.p1]

function Base.show(io::IO, ::MIME"text/plain", op::ReadoutErr)
    print(io, "$(opname(op))($(op.p0), $(op.p1))")
end
