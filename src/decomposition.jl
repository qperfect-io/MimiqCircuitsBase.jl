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

# --- general -- 
# not included because needs to be included before the gate defininions
# and before the canonical rule definitions.
#include("decomposition/abstract.jl")

# --- rewrite rules ---
include("decomposition/rules/zyz.jl")
include("decomposition/rules/special_angle.jl")
include("decomposition/rules/to_z_rotation.jl")
include("decomposition/rules/solovay_kitaev.jl")
include("decomposition/rules/toffoli_to_clifford_t.jl")
include("decomposition/rules/flatten_containers.jl")

# not included here because needs to be included before the gate defininions, where
# the canonical decompose_step! methods are defined.
#include("decomposition/rules/canonical.jl")

# --- basis sets ---
include("decomposition/basis/canonical.jl")
include("decomposition/basis/rule.jl")
include("decomposition/basis/openqasm.jl")
include("decomposition/basis/stim.jl")
include("decomposition/basis/clifford_t.jl")
include("decomposition/basis/flattened.jl")

# --- decomposition functions -- 
include("decomposition/decompose_step.jl")
include("decomposition/decompose.jl")
