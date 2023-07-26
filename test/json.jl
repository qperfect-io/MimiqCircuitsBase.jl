using JSON
using Random

Random.seed!(20230501)

const NCONTROLS = 3
const REPEATS = 3
const BARRIERN = 5
const CUSTOMN = 3

function _testdict(op; verbose=false)
    dict = MimiqCircuitsBase.todict(op)
    @test dict[:name] == opname(op)
    @test dict[:N] == numqubits(op)
    @test dict[:M] == numbits(op)

    if verbose
        @info "" MimiqCircuitsBase.fromdict(Operation, dict) op
    end

    @test areequal(MimiqCircuitsBase.fromdict(Operation, dict), op)
    @test areequal(fromjson(Operation, tojson(op)), op)

    nothing
end

function _pushtotest!(c::Circuit, op::Operation)
    push!(c, op, 1:numqubits(op)..., 1:numbits(op)...)
    push!(c, op, numqubits(op):-1:1..., numbits(op):-1:1...)
end

function _testcircuit(c::Circuit)
    @test areequal(MimiqCircuitsBase.fromdict(Circuit, MimiqCircuitsBase.todict(c)), c)
    @test areequal(fromjson(Circuit, tojson(c)), c)
end

function _testcircuit(op::Operation)
    c = Circuit()

    _pushtotest!(c, op)

    _testcircuit(c)

    nothing
end

@testset "Simple non parametric Operations" begin
    NONPARAMETRICOPS = [GateX, GateY, GateZ, GateH, GateS, GateSDG, GateT, GateTDG, GateSX, GateSXDG, GateID, GateCX, GateCY, GateCZ, GateCH, GateSWAP, GateISWAP, GateISWAPDG, Reset, Measure]
    @testset "$(opname(optype))" for optype in NONPARAMETRICOPS
        op = optype()

        _testdict(op)
        _testcircuit(op)
    end
end

@testset "Simple parametric Operations" begin
    PARAMETRICOPS = [GateP, GateRX, GateRY, GateRZ, GateU1, GateU2, GateU2DG, GateU3, GateU, GateCP, GateCRX, GateCRY, GateCRZ, GateCU]
    @testset "$(opname(optype))" for optype in PARAMETRICOPS
        op = optype(rand(numparams(optype))...)

        _testdict(op)
        _testcircuit(op)
    end
end

@testset "Barriers" begin
    c = Circuit()

    for n in 1:BARRIERN
        op = Barrier(n)

        _testdict(op)
        _pushtotest!(c, op)
    end

    _testcircuit(c)
end

@testset "Composite Operations" begin
    @testset "Control" begin
        c = Circuit()

        for controls in 1:NCONTROLS
            op = Control(controls, GateX())

            _testdict(op)
            _pushtotest!(c, op)
        end

        for controls in 1:NCONTROLS
            op = Control(controls, GateCX())

            _testdict(op)
            _pushtotest!(c, op)
        end

        _testcircuit(c)
    end

    @testset "Parallel" begin
        c = Circuit()

        for repeats in 1:REPEATS
            op = Parallel(repeats, GateX())

            _testdict(op)
            _pushtotest!(c, op)
        end

        for repeats in 1:REPEATS
            op = Parallel(repeats, GateCX())

            _testdict(op)
            _pushtotest!(c, op)
        end

        _testcircuit(c)
    end

    @testset "IfStatement" begin
        c = Circuit()

        begin
            op = IfStatement(GateX(), bs"1")

            _testdict(op)
            _pushtotest!(c, op)
        end

        begin
            op = IfStatement(GateX(), bs"110")

            _testdict(op)
            _pushtotest!(c, op)
        end

        begin
            op = IfStatement(GateCX(), bs"001")

            _testdict(op)
            _pushtotest!(c, op)
        end

        _testcircuit(c)
    end

    @testset "Combined" begin
        op = Control(2, Parallel(3, Control(GateX())))

        _testdict(op)
        _testcircuit(op)
    end
end

@testset "Custom gates" begin
    c = Circuit()

    # Complex
    for N in 1:CUSTOMN
        op = GateCustom(randunitary(2^N))

        _testdict(op)
        _pushtotest!(c, op)
    end

    _testcircuit(c)
end
