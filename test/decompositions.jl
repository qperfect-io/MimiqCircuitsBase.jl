
using MimiqCircuitsBase

@testset "1q decomposition" begin
    GATES1Q = filter(gtype -> gtype <: AbstractGate{1}, MimiqCircuitsBase.GATES)
    @testset "$(opname(gtype)) decomposition" for gtype in GATES1Q
        gate = gtype(rand(numparams(gtype))...)

        M = mapreduce(*, reverse(decompose(gate)._instructions)) do g
            matrix(getoperation(g))
        end

        @test matrix(gate) ≈ M
    end
end

@testset "2q decomposition" begin
    GATES2Q = filter(gtype -> gtype <: AbstractGate{2}, MimiqCircuitsBase.GATES)

    @testset "$(opname(gtype)) decomposition" for gtype in GATES2Q
        gate = gtype(rand(numparams(gtype))...)

        M = mapreduce(*, reverse(decompose(gate)._instructions)) do g
            if numqubits(g) == 1
                target = getqubit(g, 1)
                if target == 1
                    return kron(matrix(getoperation(g)), Matrix(I, 2, 2))
                end

                if target == 2
                    return kron(Matrix(I, 2, 2), matrix(getoperation(g)))
                end

                error("Invalid target qubit for gate $g.")
            end

            if numqubits(g) == 2
                if getqubits(g) == (1, 2)
                    return matrix(getoperation(g))
                end

                if getqubits(g) == (2, 1)
                    return matrix(GateSWAP()) * matrix(getoperation(g)) * matrix(GateSWAP())
                end

                error("Invalid qubits for gate $g.")
            end

            error("Invalid number of qubits for gate $g.")
        end

        @test matrix(gate) ≈ M
    end
end

@testset "Circuit decomposition" begin
    @testset "$(opname(gtype))" for gtype in MimiqCircuitsBase.GATES
        gate = gtype(rand(numparams(gtype))...)
        circ = push!(Circuit(), gate, 1:numqubits(gate)..., 1:numbits(gate)...)

        decomposed = decompose(circ)

        @test length(decomposed) >= length(circ)

        for inst in decomposed
            @test MimiqCircuitsBase.issupported_default(getoperation(inst))
        end
    end
end
