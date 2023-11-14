using MimiqCircuitsBase
using BenchmarkTools
using Random

include("circuits.jl")

const SUITE = BenchmarkGroup()

SUITE["circuit"] = BenchmarkGroup()

# build the example circuits
SUITE["circuit"]["examples"] = BenchmarkGroup()

let group = SUITE["circuit"]["examples"]

    for nqubits in [4, 32, 64]
        for d in [1, 8, 16]
            group["QCBM", nqubits, d] = @benchmarkable build_qcbm($nqubits, $d)
        end
        group["AQFT", nqubits] = @benchmarkable build_aqft($nqubits)
        group["GHZ", nqubits] = @benchmarkable build_aqft($nqubits)
        group["Parametric", nqubits] = @benchmarkable build_parametric($nqubits)
        group["Ansatz3", nqubits] = @benchmarkable build_ansatz3($nqubits)
    end

    for d in [1, 10, 100]
        group["Google", 15, d] = @benchmarkable build_googlesupremacy($d; nc=3, nr=2)
        group["Google", 54, d] = @benchmarkable build_googlesupremacy($d)
    end
end


SUITE["circuit"]["setparameters"] = BenchmarkGroup()
SUITE["circuit"]["getparameters"] = BenchmarkGroup()

let group = SUITE["circuit"]
    for nq in [4, 16, 32, 64]
        # getparameters
        group["getparameters"]["Parametric", nq] = @benchmarkable getparameters(c) setup = (c = build_parametric($nq))
        group["getparameters"]["Ansatz3", nq] = @benchmarkable getparameters(c) setup = (c = build_ansatz3($nq))

        # setparameters!
        group["setparameters"]["Parametric", nq] = @benchmarkable setparameters!(c, params) setup = (c = build_parametric($nq); params = Dict(:λ => rand()))
        group["setparameters"]["Ansatz3", nq] = @benchmarkable setparameters!(c, params) setup = (
            c = build_ansatz3($nq);
            params = Dict(
                :θ1 => rand(),
                :θ2 => rand(),
                :θ3 => rand()
            )
        )
    end
end

# push single gates into circuits
SUITE["circuit"]["push"] = BenchmarkGroup()

let group = SUITE["circuit"]["push"]
    for optype in MimiqCircuitsBase.OPERATION_TYPES
        if optype <: AbstractGate
            group[opname(optype)] = @benchmarkable push!(c, ($optype(params...)), qubits...) setup = (c = Circuit(); params = rand(numparams($optype)); qubits = collect(1:numqubits($optype)))
        else
            group[opname(optype)] = @benchmarkable push!(c, $optype, qubits..., clbits...) setup = (c = Circuit(); qubits = collect(1:numqubits($optype)); clbits = collect(1:numbits($optype)))
        end
    end

end

# iterate over circuits
SUITE["circuit"]["iteration"] = BenchmarkGroup()

@noinline function apply_instruction(inst::Instruction)
    s = 0

    for q in getqubits(inst)
        s += q
    end

    for c in getbits(inst)
        s += c
    end

    return s
end

function iterate_circuit(c::Circuit)
    s = 0
    for inst in c
        s += apply_instruction(inst)
    end
    return s
end

let group = SUITE["circuit"]["iteration"]
    for d in [1, 10, 100]
        group["Google", 15, d] = @benchmarkable iterate_circuit(c) setup = (c = build_googlesupremacy($d; nc=3, nr=2))
        group["Google", 54, d] = @benchmarkable iterate_circuit(c) setup = (c = build_googlesupremacy($d))
    end
end

SUITE["circuit"]["append"] = BenchmarkGroup()

let group = SUITE["circuit"]["append"]
    group["samequbits"] = @benchmarkable append!(c, other) setup = (c = build_googlesupremacy(1); other = build_googlesupremacy(2))
    group["differenqubits"] = @benchmarkable append!(c, other) setup = (c = build_googlesupremacy(1; nc=3, nr=2); other = build_googlesupremacy(2))
end

# operations
SUITE["operation"] = BenchmarkGroup()

# construct an operation
SUITE["operation"]["construction"] = BenchmarkGroup()

let group = SUITE["operation"]["construction"]
    for optype in MimiqCircuitsBase.OPERATION_TYPES
        if optype <: ParametricGate
            group[opname(optype)] = @benchmarkable $optype(rand(numparams($optype))...)
        else
            group[opname(optype)] = @benchmarkable $optype()
        end
    end
end

# get the matrix of an operation
SUITE["operation"]["matrix"] = BenchmarkGroup()

let group = SUITE["operation"]["matrix"]
    for optype in MimiqCircuitsBase.OPERATION_TYPES
        if !(optype <: AbstractGate)
            continue
        end
        group[opname(optype)] = @benchmarkable matrix(op) setup = (op = $optype(rand(numparams($optype))...))
    end
end
