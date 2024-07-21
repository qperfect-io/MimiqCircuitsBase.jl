#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    depth(circuit)

Compute the depth of a quantum circuit.

The depth of a quantum circuit is a metric computing the maximum time (in units of quantum
gates application) between the input and output of the circuit.
"""
function depth(c::Circuit)
    d = zeros(Int64, numqubits(c) + numbits(c))
    for g in c
        optargets = collect(getqubits(g))
        dm = maximum(d[optargets])
        for t in getqubits(g)
            d[t] = dm + 1
        end
        for t in getbits(g)
            d[t+numqubits(c)] = dm + 1
        end
    end
    return maximum(d)
end
