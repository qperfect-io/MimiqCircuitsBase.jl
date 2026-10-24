#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
    OperationError(optype, msg)

Thrown when an operation of type `optype` is built with invalid arguments, for
example a [`PolynomialOracle`](@ref) whose registers do not add up to its number
of qubits, or a [`QFT`](@ref) on zero qubits. `msg` says what is wrong.

The error prints as `optype: msg`.
"""
struct OperationError <: Exception
    optype::Any
    msg::String
end

function Base.showerror(io::IO, e::OperationError)
    print(io, e.optype, ": ", e.msg)
end

"""
    UndefinedValue(n)

Thrown when a parameter has to be converted to a number but `n` is still
symbolic, for example when sampling a noise channel whose probability is an
unbound variable. Bind the variables first with [`evaluate`](@ref).

The error prints as `Undefined value n.`.
"""
struct UndefinedValue <: Exception
    n::Num
end

function Base.showerror(io::IO, e::UndefinedValue)
    print(io, "Undefined value $(e.n).")
end

"""
    DecompositionError(msg)

Thrown when [`decompose`](@ref) or [`decompose_step`](@ref) cannot rewrite an
operation: the rule does not match it, or no rule of the basis leads to its
terminal operations, as for noise channels under [`QASMBasis`](@ref). `msg` says
which operation and why.

The error prints as `Error during decomposition: msg`.
"""
struct DecompositionError <: Exception
    msg::String
end

function Base.showerror(io::IO, e::DecompositionError)
    print(io, "Error during decomposition: ", e.msg)
end
