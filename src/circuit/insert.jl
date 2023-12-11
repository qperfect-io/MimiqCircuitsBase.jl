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

function Base.insert!(c::Circuit, i::Integer, g::Operation{N,M}, targets::Vararg{Integer,L}) where {N,M,L}
    if N + M != L
        throw(ArgumentError("Wrong number of targets: given $L total for $N qubits $M bits operation"))
    end

    insert!(c, i, Instruction(g, targets[1:N], targets[end-M+1:end]))
end

function Base.insert!(c::Circuit, i::Integer, ::Type{T}, targets...) where {T<:Operation}
    if numparams(T) != 0
        error("Parametric type. Use `insert!(c, i, T(args...), targets...)` instead.")
    end
    return insert!(c, i, T(), targets...)
end

