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
    struct IfStatement{N,M} <: Operation{N,M}
"""
struct IfStatement{N,M} <: Operation{N,M}
    op::Operation{N,0}
    val::BitState

    function IfStatement{N,M}(op, val) where {N,M}
        if length(val) != M
            throw(ArgumentError("The length of the BitState must be equal to the number of classical bits"))
        end

        new{N,M}(op, val)
    end
end

function IfStatement(op::Operation{N,0}, val::BitState) where {N}
    if length(val) < 1
        throw(ArgumentError("The value must have at least one classical bit"))
    end
    return IfStatement{N,length(val)}(op, val)
end

inverse(s::IfStatement) = IfStatement(inverse(s.op), s.val)

opname(::Type{<:IfStatement}) = "If"

function Base.show(io::IO, s::IfStatement)
    print(io, opname(IfStatement), "(", s.op, ", ", string(s.val), ")")
end
