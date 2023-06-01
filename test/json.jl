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

# barrier
push!(c, Barrier, 1, 2, 3, 4)
push!(c, Barrier, 1, 3, 8, 10)
push!(c, Barrier, 26)
push!(c, Barrier, 3, 28)

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
    gate = GateCustom(rand(T, 2^N, 2^N))
    for i in 1:nq
        push!(c, gate, i)
    end
end

for T in [Float64, ComplexF64]
    N = 2
    gate = GateCustom(rand(T, 2^N, 2^N))
    for targets in [(1, 2), (2, 1), (nq - 1, nq), (nq, nq - 1), (1, nq), (nq, 1)]
        push!(c, gate, targets...)
    end
end

json = tojson(c)
cnew = fromjson(json)

for (g1, g2) in zip(c.instructions, cnew.instructions)

    @test typeof(g1) == typeof(g2)

    op1 = getoperation(g1)
    op2 = getoperation(g2)

    @test length(getqubits(g1)) == length(getqubits(g2))
    @test length(getbits(g1)) == length(getbits(g2))

    if op1 isa ParametricGate
        @test typeof(op1) == typeof(op2)
        for par in parnames(op1)
            @test getfield(op1, par) == getfield(op2, par)
        end
    elseif op1 isa GateCustom
        @test numqubits(op1) == numqubits(op2)
        @test complex(matrix(op1)) == matrix(op2)
    else
        @test op1 === op2
    end

end
