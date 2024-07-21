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

using RecipesBase
import Measures: mm

@recipe function f(res::QCSResults; endianess=:big, max_outcomes=15)
    x = []
    y = []
    for (bs, s) in histsamples(res)
        push!(x, to01(bs; endianess=endianess))
        push!(y, s)
    end
    ps = sortperm(y; rev=true)
    permute!(x, ps)
    permute!(y, ps)

    # NOTE: this should come before the truncation
    nsamples = sum(y)

    x = x[1:min(length(x), max_outcomes)]
    nbars = length(x)

    y = y[1:nbars]

    nq = length(first(x))

    size := (800, 400 + 10 * nq)
    margin := 10mm
    bottom_margin := nq * 1.7mm

    title := "$(res.simulator) $(res.version) fidelity=$(mean(res.fidelities))"
    @series begin
        seriestype := :bar
        yguide := "Counts ($nsamples samples)"
        xguide := "Bitstring"
        legend := nothing
        xrotation := 90
        xticks := ((1:nbars) .- 0.5, x)
        fill := "#0c7e8f"
        return x, y
    end
end
