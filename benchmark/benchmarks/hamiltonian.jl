#
# Copyright © 2025-2026 QPerfect. All Rights Reserved.
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

# ====================== #
# HAMILTONIAN BENCHMARKS #
# ====================== #

SUITE["hamiltonian"] = BenchmarkGroup(["Benchmarks for Hamiltonians"])

# --- construction ---
SUITE["hamiltonian"]["construction"] = BenchmarkGroup()

for n in [10, 100, 1000]
    SUITE["hamiltonian"]["construction"]["push_terms_n$n"] = @benchmarkable begin
        h = Hamiltonian()
        for i in 1:$n
            push!(h, 1.0, PauliString("X"), 1)
        end
        h
    end

    SUITE["hamiltonian"]["construction"]["push_struct_n$n"] = @benchmarkable begin
        h = Hamiltonian()
        term = HamiltonianTerm(1.0, PauliString("X"), 1)
        for i in 1:$n
            push!(h, term)
        end
        h
    end
end

# --- matrix generation ---
SUITE["hamiltonian"]["matrix"] = BenchmarkGroup()

for nq in [2, 4, 6, 8]
    local h = Hamiltonian()
    # Create a simple Ising-like Hamiltonian
    for i in 1:nq
        push!(h, 1.0, PauliString("X"), i)
        if i < nq
            push!(h, 0.5, PauliString("ZZ"), i, i + 1)
        end
    end

    SUITE["hamiltonian"]["matrix"]["Ising_nq$nq"] = @benchmarkable matrix($h)
end

# --- circuit generation ---
SUITE["hamiltonian"]["circuits"] = BenchmarkGroup()

# Create a fixed Hamiltonian for circuit generation benchmarks
# 5 qubits, mixture of 1 and 2 qubit terms
const H5 = Hamiltonian()
for i in 1:5
    push!(H5, 1.0, PauliString("X"), i)
    push!(H5, 0.2, PauliString("Z"), i)
    for j in (i+1):5
        push!(H5, 0.5, PauliString("XX"), i, j)
    end
end
const QUBITS5 = (1, 2, 3, 4, 5)

SUITE["hamiltonian"]["circuits"]["expval"] = @benchmarkable begin
    c = Circuit()
    push_expval!(c, $H5, $QUBITS5...)
    c
end

SUITE["hamiltonian"]["circuits"]["lietrotter"] = @benchmarkable begin
    c = Circuit()
    push_lietrotter!(c, $QUBITS5, $H5, 1.0, 10)
    c
end

for order in [2, 4]
    SUITE["hamiltonian"]["circuits"]["suzukitrotter_o$order"] = @benchmarkable begin
        c = Circuit()
        push_suzukitrotter!(c, $QUBITS5, $H5, 1.0, 5, $order)
        c
    end
end

for order in [2, 4]
    SUITE["hamiltonian"]["circuits"]["yoshidatrotter_o$order"] = @benchmarkable begin
        c = Circuit()
        push_yoshidatrotter!(c, $QUBITS5, $H5, 1.0, 5, $order)
        c
    end
end
