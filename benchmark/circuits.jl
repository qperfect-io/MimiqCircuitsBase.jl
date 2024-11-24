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
using MimiqCircuitsBase
using Random

# QCBM example
function build_qcbm(nqubits, d; rng=Random.GLOBAL_RNG)

    function first_rotation(circuit, nqubits)
        for k = 1:nqubits
            push!(circuit, GateRX(rand(rng)), k)
        end
        for k = 1:nqubits
            push!(circuit, GateRZ(rand(rng)), k)
        end
    end

    function mid_rotation(circuit, nqubits)
        for k = 1:nqubits
            push!(circuit, GateRZ(rand(rng)), k)
        end
        for k = 1:nqubits
            push!(circuit, GateRX(rand(rng)), k)
        end
        for k = 1:nqubits
            push!(circuit, GateRZ(rand(rng)), k)
        end
    end

    function last_rotation(circuit, nqubits)
        for k = 1:nqubits
            push!(circuit, GateRZ(rand(rng)), k)
        end
        for k = 1:nqubits
            push!(circuit, GateRX(rand(rng)), k)
        end
    end

    function entangler(circuit, _, pair_list)
        for p in pair_list
            push!(circuit, GateCX(), p[1], p[2])
        end
    end

    circuit = Circuit()
    pair_list = [(i, mod1(i + 1, nqubits)) for i = 1:nqubits]

    first_rotation(circuit, nqubits)
    entangler(circuit, nqubits, pair_list)

    for _ in 1:d
        mid_rotation(circuit, nqubits)
        entangler(circuit, nqubits, pair_list)
    end

    last_rotation(circuit, nqubits)
    return circuit
end


# AQFT example
function build_aqft(input_size, minphi::Float64=1e-10)
    qc = Circuit()

    # Generate multiple groups of diminishing angle CRZs and H gate
    for i_qubit = input_size:-1:1

        # start laying out gates from highest order qubit (the hidx)
        hidx = input_size - i_qubit

        # precede with an H gate (applied to all qubits)
        push!(qc, GateH(), hidx + 1)

        # if not the highest order qubit, add multiple controlled RZs of decreasing angle
        if hidx < input_size
            num_crzs = i_qubit - 1
            for j = num_crzs:-1:1
                divisor = 1 << (num_crzs - j + 1)
                phi = pi / divisor
                if phi < minphi
                    break
                end
                push!(qc, GateCRZ(-phi), hidx + 1, input_size - j + 1)
            end
        end
    end

    return qc
end

# GHZ circuit
function build_ghz(nq)
    circ = Circuit()

    push!(circ, GateH(), 1)
    push!(circ, GateCX(), 1, 2:nq)

    return circ
end

# Google supremacy circuit
function build_googlesupremacy(
    depth;
    nr::Int64=4,
    nc::Int64=6,
    rng=Random.GLOBAL_RNG
)::Circuit
    SX = GateU(pi / 2, 3 * pi / 2, -3 * pi / 2)
    SY = GateU(pi / 2, 0, 0)
    SW = GateU(3 * pi / 2, 3 * pi / 4, -3 * pi / 4)
    ISWAP = GateISWAP()

    G1vec = [SX; SY; SW]

    # The circuit will create a setup with `nr` rows and `nc` columns.
    # Each column is a double column of qubits.
    #
    # `nr` is the number of qubits in the minor column.
    #
    # The qubit number therefore is:
    n = nc * (2 * nr + 1)

    # For the original circuit, from the Google quantum supremacy paper,
    # `nr = 4` and `nc = 6`

    # to lower right in major col
    apairs = Vector{Tuple{Int64,Int64}}()
    for cc = 1:nc
        st = (cc - 1) * (2 * nr + 1) + 1
        for aa = 0:(nr-1)
            #[(1, 6); (2, 7); (3, 8); (4, 9) ... (10, 15) ...]
            push!(apairs, (st + aa, st + aa + nr + 1))
        end
    end

    # to lower right in minor col
    bpairs = Vector{Tuple{Int64,Int64}}()
    for cc = 1:nc-1
        st = (cc - 1) * (2 * nr + 1) + nr + 2
        for aa = 0:(nr-1)
            #[(6, 11); (7, 12); (8, 13); (9, 14) ... (15 20) ... ]
            push!(bpairs, (st + aa, st + aa + nr + 1))
        end
    end

    # to upper right in minor col
    cpairs = Vector{Tuple{Int64,Int64}}()
    for cc = 1:nc-1
        st = (cc - 1) * (2 * nr + 1) + nr + 2
        for aa = 0:(nr-1)
            # [(6, 10); (7, 11); (8, 12); (9, 13)... (15 19)]
            push!(cpairs, (st + aa, st + aa + nr))
        end
    end

    # to upper right in major col
    dpairs = Vector{Tuple{Int64,Int64}}()
    for cc = 1:nc
        st = (cc - 1) * (2 * nr + 1) + 2
        for aa = 0:(nr-1)
            # [(2, 6); (3, 7); (4, 8); (5, 9) ... (11 15)]
            push!(dpairs, (st + aa, st + aa + nr))
        end
    end

    # Start building the actual circuit
    crc = Circuit()

    oldsel = zeros(Int64, n)

    function randsgl()
        for nn = 1:n
            rn = rand(rng, 1:3)
            while rn == oldsel[nn]
                rn = rand(rng, 1:3)
            end
            push!(crc, G1vec[rn], nn)
            oldsel[nn] = rn
        end
    end

    function A()
        randsgl()
        for mm = 1:length(apairs)
            push!(crc, ISWAP, apairs[mm]...)
        end
    end

    function B()
        randsgl()
        for mm = 1:length(bpairs)
            push!(crc, ISWAP, bpairs[mm]...)
        end
    end

    function C()
        randsgl()
        for mm = 1:length(cpairs)
            push!(crc, ISWAP, cpairs[mm]...)
        end
    end

    function D()
        randsgl()
        for mm = 1:length(dpairs)
            push!(crc, ISWAP, dpairs[mm]...)
        end
    end

    for dd = 1:depth
        if dd % 8 == 1
            A()
        elseif dd % 8 == 2
            B()
        elseif dd % 8 == 3
            C()
        elseif dd % 8 == 4
            D()
        elseif dd % 8 == 5
            C()
        elseif dd % 8 == 6
            D()
        elseif dd % 8 == 7
            A()
        elseif dd % 8 == 0
            B()
        end
    end
    randsgl()

    return crc
end

function build_parametric(n::Integer)
    c = Circuit()
    push!(c, GateH(), 1)

    for i in 1:(n-1)
        push!(c, GateCX(), i, i + i)
    end

    push!(c, Barrier, 1:n...)
    push!(c, GateRZ(), 1:n)
    push!(c, Barrier, 1:n...)

    for i in n:-1:2
        push!(c, GateCX(), i - 1, i)
    end

    push!(c, GateH(), 1)
    push!(c, Measure(), 1, 1)

    return c
end

function build_ansatz3(nq)
    θ1 = Parameter(:θ1)
    θ2 = Parameter(:θ2)
    θ3 = Parameter(:θ3)

    c = Circuit()

    push!(c, GateRZ(θ1), 1)
    push!(c, GateRY(θ2), 1)

    push!(c, GateCX(), 1, 2:nq)

    for i in 1:nq
        push!(c, GateRY(θ3), i)
    end

    return c
end
