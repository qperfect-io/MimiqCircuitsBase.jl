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

const DEFAULT_OPTIMIZATION_OPTIMIZER = "COBYLA"
const DEFAULT_OPTIMIZATION_LABEL = "optexp_julia"
const DEFAULT_OPTIMIZATION_MAXITERS = nothing
const DEFAULT_OPTIMIZATION_ZREGISTER = 1

function check_optimization_args(circuit, initparams, zregister)
    if isempty(circuit)
        throw(ArgumentError("The circuit must not be empty."))
    end

    if !issymbolic(circuit)
        throw(ArgumentError("The circuit must be symbolic."))
    end

    for key in keys(initparams)
        if !SymbolicUtils.issym(Symbolics.value(key))
            throw(ArgumentError("All keys in initparams must be symbolic variables."))
        end
    end

    cvars = Set(listvars(circuit))
    pvars = Set(keys(initparams))

    if cvars != pvars
        throw(ArgumentError("Initial values must be given for each symbolic variable in the circuit."))
    end

    if zregister < 1
        throw(ArgumentError("zregister must be ≥ 1"))
    end

    return nothing
end

@doc raw"""
    OptimizationExperiment(circuit, initparams[; optimizer = "COBYLA"][, label = "optexp_julia"][, maxiters = nothing][, zregister = 1])

Represents a variational quantum optimization experiment that can be
executed by MIMIQ.

Defines the quantum circuit, initial parameter values, optimizer, and
other metadata needed to launch a parameter optimization run using
classical optimizers.

## Parameters

- circuit: The parametric quantum circuit that evaluates the cost function.
- initparams: Dictionary of initial parameter values.
- optimizer: Optimization method to use. Must be one of: "BFGS",
  "LBFGS", "CG", "NELDERMEAD", "NEWTON", "COBYLA", "CMAES". Default is
  "COBYLA".
- label: Label for this experiment. Default is "optexp_julia".
- maxiters: Maximum number of iterations. Default is nothing (unlimited).
- zregister: Index of the Z-register variable storing the value of the cost function.
  Default is 1.

## Examples

```jldoctest
julia> c = Circuit()
empty circuit

julia> @variables x
1-element Vector{Symbolics.Num}:
 x

julia> h = Hamiltonian()
empty hamiltonian

julia> push!(c, GateRZ(x), 2)
2-qubit circuit with 1 instruction:
└── RZ(x) @ q[2]

julia> push!(h, 0.0910, PauliString("XY"), 1, 2)
2-qubit hamiltonian with 1 terms:
+
└── 0.091 * XY @ q[1:2]

julia> push_expval!(c, h, 1, 2)
2-qubit, 1-vars circuit with 4 instructions:
├── RZ(x) @ q[2]
├── ⟨XY⟩ @ q[1:2], z[1]
├── z[1] *= 0.091
└── z[1] += 0.0

julia> initparams = Dict(x => 0.1)
Dict{Symbolics.Num, Float64} with 1 entry:
  x => 0.1


julia> ex = OptimizationExperiment(c, Dict(x => 0.1), optimizer="COBYLA", label="my_exp", maxiters=100, zregister=1)
OptimizationExperiment:
├── optimizer: COBYLA
├── label: my_exp
├── maxiters: 100
├── zregister: 1
└── initparams:
    └── x => 0.1
```
"""
struct OptimizationExperiment
    circuit::Circuit
    initparams::Dict{Symbolics.Num,<:Real}
    optimizer::String
    label::String
    maxiters::Union{Nothing,Int}
    zregister::Int

    function OptimizationExperiment(
        circuit::Circuit,
        initparams::Dict;
        optimizer::String=DEFAULT_OPTIMIZATION_OPTIMIZER,
        label::String=DEFAULT_OPTIMIZATION_LABEL,
        maxiters::Union{Nothing,Int}=DEFAULT_OPTIMIZATION_MAXITERS,
        zregister::Int=DEFAULT_OPTIMIZATION_ZREGISTER
    )

        check_optimization_args(circuit, initparams, zregister)
        return new(circuit, initparams, optimizer, label, maxiters, zregister)
    end
end

function Base.show(io::IO, m::MIME"text/plain", ex::OptimizationExperiment)
    println(io, "OptimizationExperiment:")
    println(io, "├── optimizer: ", ex.optimizer)
    println(io, "├── label: ", ex.label)
    println(io, "├── maxiters: ", ex.maxiters)
    println(io, "├── zregister: ", ex.zregister)

    # Init params
    nparams = length(ex.initparams)
    println(io, "└── initparams:")

    # Adjust internal prefixes
    for (i, (k, v)) in enumerate(sort(collect(ex.initparams); by=x -> string(first(x))))
        last_param = (i == nparams)
        prefix = last_param ? "    └── " : "    ├── "
        println(io, prefix, k, " => ", v)
    end
end

numparams(ex::OptimizationExperiment) = length(ex.initparams)
numqubits(ex::OptimizationExperiment) = numqubits(ex.circuit)
numbits(ex::OptimizationExperiment) = numbits(ex.circuit)
numzvars(ex::OptimizationExperiment) = numzvars(ex.circuit)

function isvalid(ex::OptimizationExperiment)
    try
        check_optimization_args(ex.circuit, ex.initparams, ex.zregister)
    catch _
        return false
    end
    return true
end

changeparameters(ope::OptimizationExperiment, d::Dict) =
    OptimizationExperiment(
        ope.circuit,
        Dict(k => get(d, k, v) for (k, v) in ope.initparams);
        optimizer=ope.optimizer,
        label=ope.label,
        maxiters=ope.maxiters,
        zregister=ope.zregister
    )

function changelistofparameters(ex::OptimizationExperiment, θ::AbstractVector)
    vars = sort(listvars(ex.circuit); by=string)

    if length(vars) != length(θ)
        error("Length of value list does not match listvars. Expected $(length(vars)), got $(length(θ))")
    end

    parammap = Dict(v => θ[i] for (i, v) in enumerate(vars))
    return changeparameters(ex, parammap)
end

getparams(ope::OptimizationExperiment) = ope.initparams
getparam(ope::OptimizationExperiment, d) = ope.initparams[d]
getparam(ope::OptimizationExperiment, d::Symbol) = ope.initparams[Symbolics.variable(d)]

@doc raw"""
    OptimizationRun()

Stores the result of a single evaluation of the cost function during optimization.

This struct includes the parameter values used, the final cost value,
and the associated QCS results (such as expectation values and samples).

## Parameters

- `cost::Float64`: Final cost (objective) value for the parameters.
- `parameters::Dict{String,Float64}`: Optimized parameter values.
- `results::QCSResults`: Raw execution results from the quantum circuit simulation.

## Examples

```jldoctest
julia> run = OptimizationRun()
OptimizationRun:
├── cost: 0.0
├── parameters:
└── results: QCSResults(...)
```
"""
struct OptimizationRun
    cost::Float64
    parameters::Dict{Symbolics.Num,Float64}
    results::QCSResults
end

OptimizationRun() = OptimizationRun(0.0, Dict{String,Float64}(), QCSResults())

function Base.show(io::IO, m::MIME"text/plain", run::OptimizationRun; prefix="")
    println(io, prefix, "OptimizationRun:")
    println(io, prefix, "├── cost: ", run.cost)
    println(io, prefix, "├── parameters:")

    # Convert keys to strings for sorting, but keep values intact
    sorted_keys = sort(string.(keys(run.parameters)))
    for k_str in sorted_keys
        # If original keys are not strings, find the matching one
        for (orig_k, v) in run.parameters
            if string(orig_k) == k_str
                println(io, prefix, "│   ", k_str, " => ", v)
            end
        end
    end

    println(io, prefix, "└── results: ", "QCSResults(...)")
end

getcost(opr::OptimizationRun) = opr.cost
getparams(opr::OptimizationRun) = opr.parameters
getparam(opr::OptimizationRun, pn) = opr.parameters[pn]
getparam(opr::OptimizationRun, pn::Symbol) = opr.parameters[Symbolics.variable(pn)]
getresultofbest(opr::OptimizationRun) = opr.results


@doc raw"""
    OptimizationResults()

Container for storing the best optimization result and the full history of runs.

This object captures the optimization trajectory, including the best solution
found so far and all intermediate steps.

## Parameters

- `best::OptimizationRun`: Best optimization run found.
- `history::Vector{OptimizationRun}`: All runs evaluated during optimization.

## Examples

```jldoctest
julia> results = OptimizationResults()
OptimizationResults:
├── Best Run:
│   OptimizationRun:
│   ├── cost: 0.0
│   ├── parameters:
│   └── results: QCSResults(...)
└── History (0 runs):
```
"""
struct OptimizationResults
    best::OptimizationRun
    history::Vector{OptimizationRun}
end

OptimizationResults() = OptimizationResults(OptimizationRun(), OptimizationRun[])

getbest(ops::OptimizationResults) = ops.best
getresultsofhistory(ops::OptimizationResults) = getfield.(ops.history, :results)
getresultofbest(ops::OptimizationResults) = ops.best.results
costhistory(res::OptimizationResults) = getcost.(res.history)

function Base.show(io::IO, m::MIME"text/plain", res::OptimizationResults)
    println(io, "OptimizationResults:")

    # Best Run
    println(io, "├── Best Run:")
    show(io, m, res.best; prefix="│   ")

    # History
    nhistory = length(res.history)
    println(io, "└── History (", nhistory, " runs):")
    for (i, run) in enumerate(res.history)
        is_last = (i == nhistory)
        connector = is_last ? "    └── " : "    ├── "
        subprefix = is_last ? "        " : "    │   "
        println(io, connector, "Run ", i, ":")
        show(io, m, run; prefix=subprefix)
    end
end

Base.iterate(res::OptimizationResults) = iterate(res.history)
Base.iterate(res::OptimizationResults, state) = iterate(res.history, state)
Base.length(res::OptimizationResults) = length(res.history)
Base.getindex(res::OptimizationResults, i::Int) = res.history[i]
Base.lastindex(res::OptimizationResults) = lastindex(res.history)
Base.firstindex(res::OptimizationResults) = firstindex(res.history)
