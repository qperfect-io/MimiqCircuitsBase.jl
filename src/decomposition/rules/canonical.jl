#
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
    CanonicalRewrite

Canonical rewrite rules for the MIMIQ framework.

Built so that most operations are decomposed down to a basic set of
gates ([`GateU`](@ref) and [`GateCX`](@ref)),
"""
struct CanonicalRewrite <: RewriteRule end


# One canonical rewrite step of `op` on targets `1:N`, or `op` itself when the
# rule leaves it unchanged (as for `GateU` and `GateCX`). Wrappers such as
# `Control`, `Inverse` and `Power` transform these pieces one at a time, so
# they only ever see one level of the wrapped operation's decomposition.
function _canonical_pieces(op::Operation{N,M,L}) where {N,M,L}
    if matches(CanonicalRewrite(), op)
        return decompose_step(op)
    end
    return push!(Circuit(), op, 1:N..., 1:M..., 1:L...)
end
