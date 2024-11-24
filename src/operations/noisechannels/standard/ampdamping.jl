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

@doc raw"""
    AmplitudeDamping(γ)

One-qubit amplitude damping noise channel.

This channel is defined by the Kraus operators

```math
E_1 =
\begin{pmatrix}
    1 & 0 \\
    0 & \sqrt{1-\gamma}
\end{pmatrix}
,\quad
E_2 =
\begin{pmatrix}
    0 & \sqrt{\gamma} \\
    0 & 0
\end{pmatrix},
```

where ``\gamma \in [0,1]``.

Physically, it corresponds to an energy gain/loss process, such as spontaneous emission.

## Examples

```jldoctests
julia> push!(Circuit(), AmplitudeDamping(0.1), 1)
1-qubit circuit with 1 instructions:
└── AmplitudeDamping(0.1) @ q[1]
```
"""
struct AmplitudeDamping <: AbstractKrausChannel{1}
    gamma::Num

    function AmplitudeDamping(gamma)
        # Allow symbolic values by skipping range checks for symbolic types
        if !(gamma isa Symbolics.Num) && (gamma < 0 || gamma > 1)
            throw(ArgumentError("Value of gamma must be between 0 and 1."))
        end

        return new(gamma)
    end
end

function evaluate(ad::AmplitudeDamping, d::Dict=Dict())
    # Substitute value for gamma
    evaluated_gamma = Symbolics.substitute(ad.gamma, d)
    concrete_gamma = Symbolics.value(evaluated_gamma)

    if concrete_gamma isa Real
        if concrete_gamma < 0 || concrete_gamma > 1
            throw(ArgumentError("Value of gamma must be between 0 and 1 after evaluation."))
        end

        return AmplitudeDamping(concrete_gamma)
    end

    return AmplitudeDamping(evaluated_gamma)
end


opname(::Type{<:AmplitudeDamping}) = "AmplitudeDamping"

function krausoperators(ad::AmplitudeDamping)
    return [
        DiagonalOp(1, sqrt(1 - ad.gamma)),
        SigmaMinus(sqrt(ad.gamma))
    ]
end

@doc raw"""
    GeneralizedAmplitudeDamping(p,γ)

One-qubit generalized amplitude damping noise channel.

This channel is defined by the Kraus operators

```math
E_1 =
\sqrt{p}
\begin{pmatrix}
    1 & 0 \\
    0 & \sqrt{1-\gamma}
\end{pmatrix}
,\quad
E_2 =
\sqrt{p}
\begin{pmatrix}
    0 & \sqrt{\gamma} \\
    0 & 0
\end{pmatrix}
,\quad
E_3 =
\sqrt{1-p}
\begin{pmatrix}
    \sqrt{1-\gamma} & 0 \\
    0 & 1
\end{pmatrix}
,\quad
E_4 =
\sqrt{1-p}
\begin{pmatrix}
    0 & 0 \\
    \sqrt{\gamma} & 0
\end{pmatrix},
```

where ``\gamma, p \in [0,1]``.

Physically, it corresponds to a combination of spontaneous emission
and spontaneous absorption with probabilities ``p`` and ``1-p``, respectively.

## Examples

```jldoctests
julia> push!(Circuit(), GeneralizedAmplitudeDamping(0.1, 0.3), 1)
1-qubit circuit with 1 instructions:
└── GeneralizedAmplitudeDamping(0.1,0.3) @ q[1]
```
"""
struct GeneralizedAmplitudeDamping <: AbstractKrausChannel{1}
    p::Num
    gamma::Num

    function GeneralizedAmplitudeDamping(p, gamma)
        # Allow symbolic values by skipping range checks for symbolic types
        if !(p isa Symbolics.Num) && (p < 0 || p > 1)
            throw(ArgumentError("Value of p must be between 0 and 1."))
        end
        if !(gamma isa Symbolics.Num) && (gamma < 0 || gamma > 1)
            throw(ArgumentError("Value of gamma must be between 0 and 1."))
        end

        return new(p, gamma)
    end
end

function evaluate(gad::GeneralizedAmplitudeDamping, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(gad.p, d)
    evaluated_gamma = Symbolics.substitute(gad.gamma, d)

    concrete_p = Symbolics.value(evaluated_p)
    concrete_gamma = Symbolics.value(evaluated_gamma)

    if (concrete_p isa Real) && (concrete_gamma isa Real)
        if (concrete_p < 0 || concrete_p > 1) || (concrete_gamma < 0 || concrete_gamma > 1)
            throw(ArgumentError("Values of p and gamma must be between 0 and 1 after evaluation."))
        end

        return GeneralizedAmplitudeDamping(concrete_p, concrete_gamma)
    end

    # If either p or gamma is symbolic, skip checks and return instance with evaluated values
    return GeneralizedAmplitudeDamping(evaluated_p, evaluated_gamma)
end


opname(::Type{<:GeneralizedAmplitudeDamping}) = "GeneralizedAmplitudeDamping"

function krausoperators(gad::GeneralizedAmplitudeDamping)
    # TODO: Change order depending on p>0.5 or p<0.5 to evaluate always the highest norm op first.
    p = gad.p
    gamma = gad.gamma
    return [
        DiagonalOp(sqrt(p), sqrt(p) * sqrt(1 - gamma)),
        DiagonalOp(sqrt(1 - p) * sqrt(1 - gamma), sqrt(1 - p)),
        SigmaMinus(sqrt(p) * sqrt(gamma)),
        SigmaPlus(sqrt(1 - p) * sqrt(gamma))
    ]
end
