#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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

function _checkpushtargets(targets, N, type="qubit")
    L = length(targets)

    if length(targets) != N
        throw(ArgumentError("Wrong number of targets: given $L total for $N-$type operation"))
    end

    if any(x -> any(y -> y <= 0, x), targets)
        throw(ArgumentError("Target $(type)s must be positive and >=1"))
    end

    # PERF: this is a double pass the qubit/bit targets, but it is probably
    # the only way of doing it.
    for tgs in shortestzip(targets...)
        if length(unique(tgs)) != length(tgs)
            throw(ArgumentError("Target $(type)s must be the different"))
        end
    end

    nothing
end

# allows for `push!(c, GateCX(), [1, 2], 3)` syntax to add `CX @ q1, q3` and
# `CX @ q2, q3`. Also works for `push!(c, GateX(), 1:4)` for applying H to all
# of 4 targets.
function Base.push!(c::Circuit, g::Operation{N,M}, targets::Vararg{Any,L}) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    _checkpushtargets(targets[1:N], N, "qubit")
    _checkpushtargets(targets[end-M+1:end], M, "bit")

    for tgs in shortestzip(targets...)
        qts = tgs[1:N]
        cts = tgs[end-M+1:end]
        push!(c, Instruction(g, qts..., cts...; checks=false))
    end

    return c
end

function Base.push!(c::Circuit, ::Type{T}, targets...) where {T<:Operation}
    if numparams(T) != 0
        error("Parametric type. Use `push!(c, T(args...), targets...)` instead.")
    end

    return push!(c, T(), targets...)
end

