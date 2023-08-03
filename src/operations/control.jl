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
    struct Control{N,M,L,T<:Operation{M,0}} <: Operation{L,0} end
"""
struct Control{N,M,L,T<:Operation{M,0}} <: Operation{L,0}
    op::T

    function Control(controls::Integer, op::Operation{N,0}) where {N}
        new{controls,N,controls + N,Operation{N,0}}(op)
    end
end

Control(op::Operation{N,0}) where {N} = Control(1, op)

inverse(c::Control{N}) where {N} = Control(N, inverse(c.op))

opname(::Type{<:Control}) = "Control"

function Base.show(io::IO, c::Control{N}) where {N}
    print(io, opname(Control), "(", N, ", ", c.op, ")")
end

function matrix(c::Control{N,M,L}) where {N,M,L}
    opmat = matrix(c.op)

    Mdim = 2^M
    Ldim = 2^L

    mat = zeros(ComplexF64, (Ldim, Ldim))
    mat[end-Mdim+1:end, end-Mdim+1:end] = opmat

    for i in 1:Ldim-Mdim
        mat[i, i] = 1.0
    end

    # FIX: should it be _decomplex(mat) ?
    return mat
end
