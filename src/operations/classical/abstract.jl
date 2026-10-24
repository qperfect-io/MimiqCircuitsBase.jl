#
# Copyright © 2025-2025 QPerfect. All Rights Reserved.
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
    Abstract Type for all classical Operations
"""
abstract type AbstractClassical{M} <: Operation{0,M,0} end

isunitary(::Type{<:AbstractClassical}) = false

# Print a commutative bitwise operation as `c[t] = c[a] op c[b] ...`. When the
# target is also one of the inputs, the bit is updated in place and printed as
# `c[t] op= ...` with that input removed, which is valid because the operation
# is commutative. More than five inputs, or a compact context, print as
# `c[t] = op @ c[a, b, ...]`.
function _show_logical(io::IO, sym, creg, compact::Bool)
    target, inputs = creg[1], collect(creg[2:end])
    if compact || length(inputs) > 5
        space = compact ? "" : " "
        print(io, "c[$target] = $sym @ c[", join(inputs, ",$space"), "]")
    elseif target in inputs
        deleteat!(inputs, findfirst(==(target), inputs))
        print(io, "c[$target] $sym= ")
        join(io, map(z -> "c[$z]", inputs), " $sym ")
    else
        print(io, "c[$target] = ")
        join(io, map(z -> "c[$z]", inputs), " $sym ")
    end
    return nothing
end
