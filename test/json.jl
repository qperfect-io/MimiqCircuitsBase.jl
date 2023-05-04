using JSON

nq = 26
c = Circuit()

#non parametric 1-qubit gate
for gatetype in
    Type[GateX, GateY, GateZ, GateH, GateS, GateSDG, GateTDG, GateSX, GateSXDG, GateID]
    gate = gatetype()

    for i in 1:nq
        push!(c, gate, i)
    end
end

# non parametric 2-qubit gate
for gatetype in Type[GateCX, GateCY, GateCZ, GateCH, GateSWAP, GateISWAP, GateISWAPDG]
    gate = gatetype()
    for targets in [(1, 2), (2, 1), (nq - 1, nq), (nq, nq - 1), (1, nq), (nq, 1)]
        push!(c, gate, targets...)
    end
end

# parametric 1-qubit gate
for gatetype in Type[GateP, GateRX, GateRY, GateRZ, GateU1, GateU2, GateU2DG, GateU3, GateU]
    gate = gatetype(rand(numparams(gatetype))...)
    for i in 1:nq
        push!(c, gate, i)
    end
end

# parametric 2-qubit gate
for gatetype in Type[GateCP, GateCRX, GateCRY, GateCRZ, GateCU]
    gate = gatetype(rand(numparams(gatetype))...)
    for targets in [(1, 2), (2, 1), (nq - 1, nq), (nq, nq - 1), (1, nq), (nq, 1)]
        push!(c, gate, targets...)
    end
end

for T in [Float64, ComplexF64]
    N = 1
    gate = Gate(rand(T, 2^N, 2^N))
    for i in 1:nq
        push!(c, gate, i)
    end
end

for T in [Float64, ComplexF64]
    N = 2
    gate = Gate(rand(T, 2^N, 2^N))
    for targets in [(1, 2), (2, 1), (nq - 1, nq), (nq, nq - 1), (1, nq), (nq, 1)]
        push!(c, gate, targets...)
    end
end

json = tojson(c)
cnew = fromjson(json)

for (g1, g2) in zip(c.gates, cnew.gates)

    if g1.gate isa ParametricGate
        @test typeof(g1) == typeof(g2)
        for par in parnames(g1.gate)
            @test getfield(g1.gate, par) == getfield(g2.gate, par)
        end
    elseif g1.gate isa Gate
        @test numqubits(g1) == numqubits(g2)
        @test complex(matrix(g1)) == matrix(g2)
    else
        @test typeof(g1) == typeof(g2)
    end

end
