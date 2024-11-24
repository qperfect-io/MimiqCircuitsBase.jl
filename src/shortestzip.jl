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

struct ShortestZip{I}
    xs::I
    length::Int

    function ShortestZip(xs::I) where {I}
        ls = filter(x -> x > 1, length.(xs))
        if isempty(ls)
            len = 1
        else
            len = minimum(ls)
        end

        return new{I}(xs, len)
    end
end

function Base.iterate(it::ShortestZip, state=nothing)
    i = isnothing(state) ? 1 : state

    if i > it.length
        return nothing
    end

    res = map(it.xs) do x
        if x isa AbstractArray || x isa Tuple
            return x[i]
        else
            return x
        end
    end

    return (res, i + 1)
end

function Base.length(x::ShortestZip)
    return x.length
end

shortestzip(xs...) = ShortestZip(xs)
