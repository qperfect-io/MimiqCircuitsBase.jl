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
using Random
using LinearAlgebra
using Symbolics
using MimiqCircuitsBase

areequal(a, b) = a == b
areequal(a::T, b::T) where {T<:AbstractAnnotation} = getnotes(a) == getnotes(b)
function areequal(a::Num, b::Num)
    if issymbolic(a) != issymbolic(b)
        return false
    end
    if !issymbolic(a)
        return a == b
    end
    return string(simplify(a)) == string(simplify(b))
end
function areequal(a::T, b::T) where {T<:AbstractOperator}
    all(x -> areequal(x[1], x[2]), zip(getparams(a), getparams(b)))
end
areequal(a::GateCustom{N}, b::GateCustom{N}) where {N} = all(areequal.(matrix(a), matrix(b)))
areequal(a::Operator{N}, b::Operator{N}) where {N} = all(areequal.(matrix(a), matrix(b)))
areequal(a::Instruction{N,M,T}, b::Instruction{N,M,T}) where {N,M,T} = areequal(getoperation(a), getoperation(b)) && getqubits(a) == getqubits(b) && getbits(a) == getbits(b)
areequal(a::Circuit, b::Circuit) = all(x -> areequal(first(x), last(x)), zip(a._instructions, b._instructions))
areequal(a::IfStatement, b::IfStatement) = areequal(a.op, b.op) && a.val == b.val

function randunitary(n::Integer)
    mat = rand(ComplexF64, n, n)
    exp(im .* (mat .+ adjoint(mat)))
end

function saveloadproto(c::Circuit)
    mktemp() do fname, _
        saveproto(fname, c)
        return loadproto(fname, Circuit)
    end
end

function saveloadproto(c::QCSResults)
    mktemp() do fname, _
        saveproto(fname, c)
        return loadproto(fname, QuickSort)
    end
end

function testsaveloadproto(c)
    newc = saveloadproto(c)
    @test areequal(c, newc)
end
