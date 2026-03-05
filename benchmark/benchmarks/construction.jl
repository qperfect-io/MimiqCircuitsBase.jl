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

# =============================== #
# CIRCUIT CONSTRUCTION BENCHMARKS #
# =============================== #

SUITE["construction"] = BenchmarkGroup(["Benchmarks for building circuits"])

# --- push! operations ---
SUITE["construction"]["push"] = BenchmarkGroup()

for n in [10, 100, 1000, 10_000]
    # Single qubit gates
    SUITE["construction"]["push"]["H_x$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateH(), 1)
        end
        c
    end

    # Two qubit gates
    SUITE["construction"]["push"]["CX_x$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateCX(), 1, 2)
        end
        c
    end

    # Parametric gates
    SUITE["construction"]["push"]["RX_x$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateRX(0.5), 1)
        end
        c
    end

    # U3 gates (3 parameters)
    SUITE["construction"]["push"]["U3_x$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateU(0.1, 0.2, 0.3), 1)
        end
        c
    end
end

# --- Vectorized push (broadcasting) ---
SUITE["construction"]["broadcast"] = BenchmarkGroup()

for n in [10, 50, 100, 500]
    SUITE["construction"]["broadcast"]["H_1:$n"] = @benchmarkable begin
        c = Circuit()
        push!(c, GateH(), 1:$n)
        c
    end

    SUITE["construction"]["broadcast"]["CX_pairs_$n"] = @benchmarkable begin
        c = Circuit()
        push!(c, GateCX(), 1:$n, ($n+1):(2*$n))
        c
    end
end

# --- insert! operations ---
SUITE["construction"]["insert"] = BenchmarkGroup()

for n in [100, 500, 1000]
    SUITE["construction"]["insert"]["front_n$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateH(), 1)
        end
        insert!(c, 1, GateX(), 1)
        c
    end

    SUITE["construction"]["insert"]["middle_n$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateH(), 1)
        end
        insert!(c, $n ÷ 2, GateX(), 1)
        c
    end
end

# --- append! circuits ---
SUITE["construction"]["append"] = BenchmarkGroup()

for n in [10, 50, 100]
    c1 = random_circuit(10, n)
    c2 = random_circuit(10, n)

    SUITE["construction"]["append"]["2x$n"] = @benchmarkable begin
        c = Circuit()
        append!(c, $c1)
        append!(c, $c2)
        c
    end
end

# --- deleteat! ---
SUITE["construction"]["deleteat"] = BenchmarkGroup()

for n in [100, 500, 1000]
    SUITE["construction"]["deleteat"]["front_n$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateH(), i)
        end
        deleteat!(c, 1)
        c
    end

    SUITE["construction"]["deleteat"]["back_n$n"] = @benchmarkable begin
        c = Circuit()
        for i in 1:$n
            push!(c, GateH(), i)
        end
        deleteat!(c, $n)
        c
    end
end
