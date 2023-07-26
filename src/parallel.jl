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

"""
    struct Parallel{N,M,L,T<:Operation{M,0}} <: Operation{L,0} end
"""
struct Parallel{N,M,L,T<:Operation{M,0}} <: Operation{L,0}
    op::T

    function Parallel(repeats::Integer, op::Operation{N,0}) where {N}
        new{repeats,N,repeats * N,Operation{N,0}}(op)
    end
end

inverse(p::Parallel{N}) where {N} = Parallel(N, inverse(p.op))

opname(::Type{<:Parallel}) = "Parallel"

function Base.show(io::IO, p::Parallel{N}) where {N}
    print(io, opname(Parallel), "(", N, ", ", p.op, ")")
end

function matrix(p::Parallel{N}) where {N}
    mat = matrix(p.op)
    return kron([mat for _ in 1:N]...)
end
