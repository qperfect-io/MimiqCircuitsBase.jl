#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 3.0 (the "License");
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
    PhaseAmplitudeDamping(p,γ,β)

One-qubit phase amplitude damping noise channel.

This channel is defined by:

```math
\mathcal{E}(\rho) =
\begin{pmatrix}
    (1-\gamma)\rho_{00}+\gamma p & (1-2\beta)\sqrt{1-\gamma}\rho_{01} \\
    (1-2\beta)\sqrt{1-\gamma}\rho_{10} & (1-\gamma)\rho_{11} + (1-p)\gamma
\end{pmatrix}
```

Here, ``p, \gamma, \beta \in [0,1]``.

This channel is equivalent to a `GeneralizedAmplitudeDamping(p,γ)` channel
(see [`GeneralizedAmplitudeDamping`](@ref)), followed by a `PauliZ(β)`
channel (see [`PauliZ`](@ref)).

Use [`krausmatrices`](@ref) to see a Kraus matrix representation of the channel.

See also [`AmplitudeDamping`](@ref), [`GeneralizedAmplitudeDamping`](@ref),
and [`ThermalNoise`](@ref).

## Examples

```jldoctests
julia> push!(Circuit(), PhaseAmplitudeDamping(0.1, 0.2, 0.3), 1)
1-qubit circuit with 1 instructions:
└── PhaseAmplitudeDamping(0.1,0.2,0.3) @ q[1]
```

"""
struct PhaseAmplitudeDamping <: AbstractKrausChannel{1}
    p::Num
    gamma::Num
    beta::Num

    function PhaseAmplitudeDamping(p, gamma, beta)
        if !(p isa Symbolics.Num) && (p < 0 || p > 1)
            throw(ArgumentError("Value of p must be between 0 and 1."))
        end
        if !(gamma isa Symbolics.Num) && (gamma < 0 || gamma > 1)
            throw(ArgumentError("Value of gamma must be between 0 and 1."))
        end
        if !(beta isa Symbolics.Num) && (beta < 0 || beta > 1)
            throw(ArgumentError("Value of beta must be between 0 and 1."))
        end

        return new(p, gamma, beta)
    end
end

function evaluate(pad::PhaseAmplitudeDamping, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(pad.p, d)
    evaluated_gamma = Symbolics.substitute(pad.gamma, d)
    evaluated_beta = Symbolics.substitute(pad.beta, d)

    concrete_p = Symbolics.value(evaluated_p)
    concrete_gamma = Symbolics.value(evaluated_gamma)
    concrete_beta = Symbolics.value(evaluated_beta)

    if (concrete_p isa Real) && (concrete_gamma isa Real) && (concrete_beta isa Real)

        if (concrete_p < 0 || concrete_p > 1) || (concrete_gamma < 0 || concrete_gamma > 1) || (concrete_beta < 0 || concrete_beta > 1)
            throw(ArgumentError("Values of p, gamma, and beta must be between 0 and 1 after evaluation."))
        end

        return PhaseAmplitudeDamping(concrete_p, concrete_gamma, concrete_beta)
    end

    return PhaseAmplitudeDamping(evaluated_p, evaluated_gamma, evaluated_beta)
end



opname(::Type{<:PhaseAmplitudeDamping}) = "PhaseAmplitudeDamping"

function krausoperators(pad::PhaseAmplitudeDamping)
    p = pad.p
    gamma = pad.gamma
    beta = pad.beta

    K = sqrt(1 - gamma) * (1 - 2 * beta) / (1 - gamma * p)

    pref1 = sqrt(1 - gamma * p)
    pref2 = sqrt(1 - gamma * (1 - p) - (1 - gamma * p) * K^2)
    pref3 = sqrt(gamma * p)
    pref4 = sqrt(gamma * (1 - p))

    # TODO: Change order depending on parameters to evaluate always the highest norm op first.
    return [
        DiagonalOp(pref1 * K, pref1),
        Projector0(pref2),
        SigmaMinus(pref3),
        SigmaPlus(pref4)
    ]
end

@doc raw"""
    ThermalNoise(T₁, T₂, t, nₑ)

One-qubit thermal noise channel.

The thermal noise channel is equivalent to the [`PhaseAmplitudeDamping`](@ref) channel,
but it is parametrized instead as

```math
\mathcal{E}(\rho) =
\begin{pmatrix}
    e^{-\Gamma_1 t}\rho_{00}+(1-n_e)(1-e^{-\Gamma_1 t}) & e^{-\Gamma_2 t}\rho_{01} \\
    e^{-\Gamma_2 t}\rho_{10} & e^{-\Gamma_1 t}\rho_{11} + n_e(1-e^{-\Gamma_1 t})
\end{pmatrix}
```

where ``\Gamma_1=1/T_1`` and ``\Gamma_2=1/T_2``, and the parameters must fulfill
``T_1 \geq 0``, ``T_2 \leq 2 T_1``, ``t \geq 0``, and ``0 \leq n_e \leq 1``.

These parameters can be related to the ones used to define the [`PhaseAmplitudeDamping`](@ref)
channel through ``p = 1-n_e``, ``\gamma = 1-e^{-\Gamma_1 t}``, and
``\beta = \frac{1}{2}(1-e^{-(\Gamma_2-\Gamma_1/2)t})``.

See also [`PhaseAmplitudeDamping`](@ref), [`AmplitudeDamping`](@ref),
and [`GeneralizedAmplitudeDamping`](@ref).

## Arguments

* `T₁`: Longitudinal relaxation rate.
* `T₂`: Transversal relaxation rate.
* `t`: Time duration of gate.
* `nₑ`: Excitation fraction when in thermal equilibrium with the environment.

## Examples

```jldoctests
julia> push!(Circuit(), ThermalNoise(0.5, 0.6, 1.2, 0.3), 1)
1-qubit circuit with 1 instructions:
└── ThermalNoise(0.5,0.6,1.2,0.3) @ q[1]
```
"""
struct ThermalNoise <: AbstractKrausChannel{1}
    T1::Num
    T2::Num
    time::Num
    ne::Num

    function ThermalNoise(T1, T2, time, ne)
        if !(T1 isa Symbolics.Num) && (T1 < 0)
            throw(ArgumentError("Value of T1 must be >= 0."))
        end
        if !(T2 isa Symbolics.Num) && (T2 > 2 * T1)
            throw(ArgumentError("Value of T2 must fulfill T2 <= 2*T1."))
        end
        if !(time isa Symbolics.Num) && (time < 0)
            throw(ArgumentError("time must be a positive parameter."))
        end
        if !(ne isa Symbolics.Num) && (ne < 0 || ne > 1)
            throw(ArgumentError("Value of ne must be between 0 and 1."))
        end

        return new(T1, T2, time, ne)
    end
end

function evaluate(tn::ThermalNoise, d::Dict=Dict())
    evaluated_T1 = Symbolics.substitute(tn.T1, d)
    evaluated_T2 = Symbolics.substitute(tn.T2, d)
    evaluated_time = Symbolics.substitute(tn.time, d)
    evaluated_ne = Symbolics.substitute(tn.ne, d)

    concrete_T1 = Symbolics.value(evaluated_T1)
    concrete_T2 = Symbolics.value(evaluated_T2)
    concrete_time = Symbolics.value(evaluated_time)
    concrete_ne = Symbolics.value(evaluated_ne)

    if (concrete_T1 isa Real) && (concrete_T2 isa Real) && (concrete_time isa Real) && (concrete_ne isa Real)
        if concrete_T1 < 0
            throw(ArgumentError("Value of T1 must be >= 0."))
        end
        if concrete_T2 > 2 * concrete_T1
            throw(ArgumentError("Value of T2 must fulfill T2 <= 2*T1."))
        end
        if concrete_time < 0
            throw(ArgumentError("time must be a positive parameter."))
        end
        if concrete_ne < 0 || concrete_ne > 1
            throw(ArgumentError("Value of ne must be between 0 and 1."))
        end

        return ThermalNoise(concrete_T1, concrete_T2, concrete_time, concrete_ne)
    end

    # If any parameter is symbolic, return an instance with evaluated values
    return ThermalNoise(evaluated_T1, evaluated_T2, evaluated_time, evaluated_ne)
end


opname(::Type{<:ThermalNoise}) = "ThermalNoise"

function krausoperators(tn::ThermalNoise)
    Gamma1 = 1 / tn.T1
    Gamma2 = 1 / tn.T2

    p = 1 - tn.ne
    gamma = 1 - exp(-Gamma1 * tn.time)
    beta = 0.5 * (1 - exp(-(Gamma2 - Gamma1 / 2) * tn.time))

    return krausoperators(PhaseAmplitudeDamping(p, gamma, beta))
end
