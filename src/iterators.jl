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
module CircuitIterators

using MimiqCircuitsBase
using Random

export samplemixedunitaries

struct SampleMixedUnitaries
    c::Circuit
    rng::AbstractRNG
end

function samplemixedunitaries(c::Circuit, rng::AbstractRNG=Random.GLOBAL_RNG)
    SampleMixedUnitaries(c, rng)
end

function Base.iterate(s::SampleMixedUnitaries, state=nothing)
    if isnothing(state)
        state = 1
    end

    if state > length(s.c)
        return nothing
    end

    inst = s.c[state]
    op = getoperation(inst)

    if !(op isa AbstractKrausChannel && ismixedunitary(typeof(op)))
        return inst, state + 1
    end

    cumulative_probs = cumsum(probabilities(op))

    r = rand(s.rng)
    k = searchsortedfirst(cumulative_probs, r)

    # substitute noise by instance
    return Instruction(unitarygates(op)[k], getqubits(inst), getbits(inst)), state + 1
end

Base.length(s::SampleMixedUnitaries) = length(s.c)

Base.IteratorSize(::Type{SampleMixedUnitaries}) = Base.HasLength()

Base.IteratorEltype(::Type{SampleMixedUnitaries}) = Base.EltypeUnknown()

end # module CircuitIterators
