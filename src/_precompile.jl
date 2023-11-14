# precompile the most used functions

const SIMPLE_GATES = [GateX, GateY, GateZ, GateH, GateS, GateT, GateID, GateSWAP, GateISWAP, GateECR]
const PARAMETRIC_GATES = [GateP, GateRX, GateRY, GateRZ, GateR, GateU, GateU1, GateU2, GateU3, GateRXX, GateRYY, GateRZZ, GateXXplusYY, GateXXminusYY]

function _precompile_()
    for gate_t in SIMPLE_GATES
        nq = numqubits(gate_t)
        precompile(gate_t, ())
        precompile(gate_t, (Circuit, gate_t, Vararg{Int,nq}))
        precompile(Base.push!, (Circuit, gate_t, Vararg{Int,nq}))
        precompile(matrix, (gate_t))
        precompile(cache, (gate_t))
        precompile(matrix, (Power{1 // 2,nq,gate_t}))
        precompile(matrix, (Inverse{nq,gate_t}))
    end

    for gate_t in PARAMETRIC_GATES
        nq = numqubits(gate_t)
        precompile(gate_t, ())
        precompile(Base.push!, (Circuit, gate_t, Vararg{Int,nq}))
        precompile(matrix, (gate_t))
        precompile(cache, (gate_t))
    end
end

