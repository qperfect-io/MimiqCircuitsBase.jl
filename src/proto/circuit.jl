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

fromproto(x::Float64) = x
fromproto(x::Int64) = x

function toproto(r::Rational)
    return circuit_pb.Rational(r.num, r.den)
end

function fromproto(r::circuit_pb.Rational)
    return Rational(r.num, r.den)
end

toproto(::Irrational{:π}) = circuit_pb.Irrational.PI

toproto(::Irrational{:ℯ}) = circuit_pb.Irrational.EULER

function fromproto(x::circuit_pb.Irrational.T)
    if x == circuit_pb.Irrational.PI
        return Base.π
    elseif x == circuit_pb.Irrational.EULER
        return Base.ℯ
    end

    error("Cannot convert $(x) into an irrational number")
end

function toproto(g::Num)
    v = Symbolics.value(g)

    if !(v isa Num)
        if v isa SymbolicUtils.BasicSymbolic{<:Irrational}
            vv = toproto(SymbolicUtils.arguments(v)[1])
            return circuit_pb.Arg(OneOf(:irrational_value, vv))
        elseif v isa Number
            if v isa Integer
                vv = OneOf(:integer_value, Int64(v))
            elseif v isa AbstractFloat
                vv = OneOf(:double_value, Float64(v))
            elseif v isa Bool
                vv = OneOf(:bool_value, Bool(v))
            end

            return circuit_pb.Arg(OneOf(:argvalue_value, circuit_pb.ArgValue(vv)))
        end
    end

    pt = toproto(v)

    if pt isa circuit_pb.ArgFunction
        return circuit_pb.Arg(OneOf(:argfunction_value, pt))
    end
    return circuit_pb.Arg(OneOf(:symbol_value, pt))
end

function fromproto(g::circuit_pb.Arg)
    return Num(fromproto(g.arg[]))
end

function func_to_proto(f)
    f == Base.:+ ? circuit_pb.FunctionType.ADD :
    f == Base.:* ? circuit_pb.FunctionType.MUL :
    f == Base.:/ ? circuit_pb.FunctionType.DIV :
    f == Base.:^ ? circuit_pb.FunctionType.POW :
    f == Base.sin ? circuit_pb.FunctionType.SIN :
    f == Base.cos ? circuit_pb.FunctionType.COS :
    f == Base.tan ? circuit_pb.FunctionType.TAN :
    f == Base.exp ? circuit_pb.FunctionType.EXP :
    f == Base.log ? circuit_pb.FunctionType.LOG :
    f == Base.identity ? circuit_pb.FunctionType.IDENTITY :
    error("Not supported function: $(f)")
end

function proto_to_func(f)
    f == circuit_pb.FunctionType.ADD ? Base.:+ :
    f == circuit_pb.FunctionType.MUL ? Base.:* :
    f == circuit_pb.FunctionType.DIV ? Base.:/ :
    f == circuit_pb.FunctionType.POW ? Base.:^ :
    f == circuit_pb.FunctionType.SIN ? Base.sin :
    f == circuit_pb.FunctionType.COS ? Base.cos :
    f == circuit_pb.FunctionType.TAN ? Base.tan :
    f == circuit_pb.FunctionType.EXP ? Base.exp :
    f == circuit_pb.FunctionType.LOG ? Base.log :
    f == circuit_pb.FunctionType.IDENTITY ? Base.identity :
    error("Not supported function: $(f)")
end

function toproto(g::Symbolics.BasicSymbolic)
    if Symbolics.issym(g)
        return circuit_pb.Symbol(string(g.name))
    end

    op = Symbolics.operation(g)

    type = func_to_proto(op)

    if isnothing(type)
        error("Not supported function: $(op)")
    end

    args = map(toproto, Num.(Symbolics.arguments(g)))

    return circuit_pb.ArgFunction(type, args)
end

function fromproto(g::circuit_pb.ArgFunction)
    op = proto_to_func(g.mtype)

    if isnothing(op)
        error("Not supported function: $(g.mtype)")
    end

    args = map(fromproto, g.args)
    return op(args...)
end

function fromproto(g::circuit_pb.ArgValue)
    return g.arg_value[]
end

function toproto(g::Complex{Num})
    return circuit_pb.ComplexArg(toproto(real(g)), toproto(imag(g)))
end

function fromproto(g::circuit_pb.ComplexArg)
    return fromproto(g.real) + im * fromproto(g.imag)
end

function fromproto(g::circuit_pb.Symbol)
    return Symbolics.Sym{Real}(Symbol(g.value))
end

const GATEMAP = BiMap(Dict(
    GateID => circuit_pb.GateType.GateID,
    GateX => circuit_pb.GateType.GateX,
    GateY => circuit_pb.GateType.GateY,
    GateZ => circuit_pb.GateType.GateZ,
    GateH => circuit_pb.GateType.GateH,
    GateHXY => circuit_pb.GateType.GateHXY,
    GateHYZ => circuit_pb.GateType.GateHYZ,
    GateS => circuit_pb.GateType.GateS,
    GateT => circuit_pb.GateType.GateT,
    Delay => circuit_pb.GateType.Delay,
    GateU => circuit_pb.GateType.GateU,
    GateP => circuit_pb.GateType.GateP,
    GateRX => circuit_pb.GateType.GateRX,
    GateRY => circuit_pb.GateType.GateRY,
    GateRZ => circuit_pb.GateType.GateRZ,
    GateR => circuit_pb.GateType.GateR,
    GateU1 => circuit_pb.GateType.GateU1,
    GateU2 => circuit_pb.GateType.GateU2,
    GateU3 => circuit_pb.GateType.GateU3,
    GateSWAP => circuit_pb.GateType.GateSWAP,
    GateISWAP => circuit_pb.GateType.GateISWAP,
    GateECR => circuit_pb.GateType.GateECR,
    GateDCX => circuit_pb.GateType.GateDCX,
    GateRXX => circuit_pb.GateType.GateRXX,
    GateRYY => circuit_pb.GateType.GateRYY,
    GateRZZ => circuit_pb.GateType.GateRZZ,
    GateRZX => circuit_pb.GateType.GateRZX,
    GateXXplusYY => circuit_pb.GateType.GateXXplusYY,
    GateXXminusYY => circuit_pb.GateType.GateXXminusYY,
))

function fromproto(op::circuit_pb.Gate)
    fromproto(op.gate[])
end

function toproto(g::T) where {T<:AbstractGate}
    type = getleft(GATEMAP, T, nothing)
    params = toproto.(getparams(g))

    if isnothing(type)
        return circuit_pb.Generalized(opname(g), collect(params), Int64[qregsizes(g)...])
    end

    return circuit_pb.SimpleGate(type, collect(params))
end

function fromproto(g::circuit_pb.SimpleGate)
    T = getright(GATEMAP, g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleGate type $(g.mtype).")
    params = map(fromproto, g.parameters)
    return T(params...)
end

function fromproto(g::circuit_pb.Generalized)
    params = map(fromproto, g.args)
    rs = g.qregsizes

    if g.name == "QFT"
        return QFT(rs..., params...)
    elseif g.name == "PhaseGradient"
        return PhaseGradient(rs..., params...)
    elseif g.name == "PolynomialOracle"
        return PolynomialOracle(rs..., params...)
    elseif g.name == "Diffusion"
        return Diffusion(rs..., params...)
    else
        error("Unknown generalized gate: $(g.name)")
    end
end

function toproto(g::GateCustom{N}) where {N}
    U = reshape(map(toproto, g.U), length(g.U))
    return circuit_pb.CustomGate(N, U)
end

function fromproto(g::circuit_pb.CustomGate)
    M = 2^g.numqubits
    U = reshape(map(fromproto, g.matrix), (M, M))
    return GateCustom(U)
end

function toproto(decl::GateDecl)
    instructions = map(toproto, decl.circuit)
    args = map(toproto, decl.arguments)
    return circuit_pb.GateDecl(string(decl.name), collect(args), instructions)
end

function fromproto(decl::circuit_pb.GateDecl)
    instructions = map(fromproto, decl.instructions)
    args = map(fromproto, decl.args)
    return GateDecl(Symbol(decl.name), Tuple(args), Circuit(instructions))
end

function toproto(cl::GateCall)
    decl = toproto(cl._decl)
    args = collect(map(toproto, cl._args))
    return circuit_pb.GateCall(decl, args)
end

function fromproto(cl::circuit_pb.GateCall)
    decl = fromproto(cl.decl)
    args = map(fromproto, cl.args)
    return GateCall(decl, args...)
end

function toproto(g::Control{N}) where {N}
    op = circuit_pb.Gate(_build_oneof(g.op))
    return circuit_pb.Control(op, N)
end

function fromproto(g::circuit_pb.Control)
    op = fromproto(g.operation)
    return Control(g.numcontrols, op)
end

function toproto(g::Power{P}) where {P}
    op = circuit_pb.Gate(_build_oneof(g.op))

    if P isa Rational
        return circuit_pb.Power(op, OneOf(:rational_val, toproto(P)))
    elseif P isa Integer
        return circuit_pb.Power(op, OneOf(:int_val, Int64(P)))
    end

    return circuit_pb.Power(op, OneOf(:double_val, Float64(P)))
end

function fromproto(g::circuit_pb.Power)
    op = fromproto(g.operation)
    power = fromproto(g.power[])
    return Power(op, power)
end

function toproto(g::Inverse)
    op = circuit_pb.Gate(_build_oneof(g.op))
    return circuit_pb.Inverse(op)
end

function fromproto(g::circuit_pb.Inverse)
    op = fromproto(g.operation)
    return Inverse(op)
end

function toproto(g::Parallel{N}) where {N}
    op = circuit_pb.Gate(_build_oneof(g.op))
    return circuit_pb.Parallel(op, N)
end

function fromproto(g::circuit_pb.Parallel)
    op = fromproto(g.operation)
    return Parallel(g.numrepeats, op)
end

function toproto(g::PauliString{N}) where {N}
    return circuit_pb.PauliString(N, g.pauli)
end

function fromproto(g::circuit_pb.PauliString)
    return PauliString(g.pauli)
end

const OPERATORMAP = BiMap(Dict(
    SigmaMinus => circuit_pb.OperatorType.SigmaMinus,
    SigmaPlus => circuit_pb.OperatorType.SigmaPlus,
    Projector0 => circuit_pb.OperatorType.Projector0,
    Projector1 => circuit_pb.OperatorType.Projector1,
    Projector00 => circuit_pb.OperatorType.Projector00,
    Projector01 => circuit_pb.OperatorType.Projector01,
    Projector10 => circuit_pb.OperatorType.Projector10,
    Projector11 => circuit_pb.OperatorType.Projector11,
    ProjectorX0 => circuit_pb.OperatorType.ProjectorX0,
    ProjectorX1 => circuit_pb.OperatorType.ProjectorX1,
    ProjectorY0 => circuit_pb.OperatorType.ProjectorY0,
    ProjectorY1 => circuit_pb.OperatorType.ProjectorY1,
    DiagonalOp => circuit_pb.OperatorType.DiagonalOp,
))

function fromproto(op::circuit_pb.Operator)
    fromproto(op.operator[])
end

function toproto(g::T) where {T<:AbstractOperator}
    type = getleft(OPERATORMAP, T.name.wrapper, nothing)
    isnothing(type) && error(lazy"Not defined ProtoBuf conversion of type $(T).")
    params = toproto.(getparams(g))
    return circuit_pb.SimpleOperator(type, collect(params))
end

function fromproto(g::circuit_pb.SimpleOperator)
    T = getright(OPERATORMAP, g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleOperator type $(g.mtype).")
    params = map(fromproto, g.parameters)
    return T(params...)
end

function toproto(g::Operator{N}) where {N}
    O = reshape(map(toproto, transpose(g.O)), length(g.O))
    return circuit_pb.CustomOperator(N, O)
end

function fromproto(g::circuit_pb.CustomOperator)
    M = 2^g.numqubits
    U = reshape(map(fromproto, g.matrix), (M, M))
    return Operator(transpose(U))
end

function toproto(g::RescaledGate)
    op = circuit_pb.Gate(_build_oneof(getoperation(g)))
    return circuit_pb.RescaledGate(op, toproto(getscale(g)))
end

function fromproto(g::circuit_pb.RescaledGate)
    op = fromproto(g.operation)
    scale = fromproto(g.scale)
    return RescaledGate(op, scale)
end

const KRAUSCHANNELMAP = BiMap(Dict(
    ResetX => circuit_pb.KrausChannelType.ResetX,
    ResetY => circuit_pb.KrausChannelType.ResetY,
    Reset => circuit_pb.KrausChannelType.ResetZ,
    AmplitudeDamping => circuit_pb.KrausChannelType.AmplitudeDamping,
    GeneralizedAmplitudeDamping => circuit_pb.KrausChannelType.GeneralizedAmplitudeDamping,
    PhaseAmplitudeDamping => circuit_pb.KrausChannelType.PhaseAmplitudeDamping,
    ThermalNoise => circuit_pb.KrausChannelType.ThermalNoise,
    PauliX => circuit_pb.KrausChannelType.PauliX,
    PauliY => circuit_pb.KrausChannelType.PauliY,
    PauliZ => circuit_pb.KrausChannelType.PauliZ,
    ProjectiveNoiseX => circuit_pb.KrausChannelType.ProjectiveNoiseX,
    ProjectiveNoiseY => circuit_pb.KrausChannelType.ProjectiveNoiseY,
    ProjectiveNoiseZ => circuit_pb.KrausChannelType.ProjectiveNoiseZ,
))

function fromproto(op::circuit_pb.KrausChannel)
    fromproto(op.krauschannel[])
end

function toproto(g::T) where {T<:AbstractKrausChannel}
    type = getleft(KRAUSCHANNELMAP, T, nothing)
    isnothing(type) && error(lazy"Not defined ProtoBuf conversion of type $(T).")
    params = toproto.(getparams(g))
    return circuit_pb.SimpleKrausChannel(type, collect(params))
end

function fromproto(g::circuit_pb.SimpleKrausChannel)
    T = getright(KRAUSCHANNELMAP, g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleKrausChannel type $(g.mtype).")
    params = map(fromproto, g.parameters)
    return T(params...)
end

function toproto(g::Kraus{N}) where {N}
    ks = map(x -> circuit_pb.Operator(_build_oneof(x)), krausoperators(g))
    return circuit_pb.CustomKrausChannel(N, ks)
end

function fromproto(g::circuit_pb.CustomKrausChannel)
    ks = map(x -> fromproto(x), g.operators)
    return Kraus(ks)
end

function toproto(g::Depolarizing{N}) where {N}
    return circuit_pb.DepolarizingChannel(N, toproto(g.p))
end

function fromproto(g::circuit_pb.DepolarizingChannel)
    return Depolarizing(g.numqubits, fromproto(g.probability))
end

function toproto(g::MixedUnitary{N}) where {N}
    rgs = toproto.(krausoperators(g))
    return circuit_pb.MixedUnitaryChannel(rgs)
end

function fromproto(g::circuit_pb.MixedUnitaryChannel)
    return MixedUnitary(fromproto.(g.operators))
end

function toproto(g::PauliNoise{N}) where {N}
    probs = map(toproto, g.p)
    strings = map(toproto, g.strings)
    return circuit_pb.PauliChannel(probs, strings)
end

function fromproto(g::circuit_pb.PauliChannel)
    probs = map(fromproto, g.probabilities)
    strings = map(fromproto, g.paulistrings)
    return PauliNoise(probs, strings)
end

const OPERATIONMAP = BiMap(Dict(
    MeasureX => circuit_pb.OperationType.MeasureX,
    MeasureY => circuit_pb.OperationType.MeasureY,
    MeasureZ => circuit_pb.OperationType.MeasureZ,
    MeasureXX => circuit_pb.OperationType.MeasureXX,
    MeasureYY => circuit_pb.OperationType.MeasureYY,
    MeasureZZ => circuit_pb.OperationType.MeasureZZ,
    MeasureResetX => circuit_pb.OperationType.MeasureResetX,
    MeasureResetY => circuit_pb.OperationType.MeasureResetY,
    MeasureResetZ => circuit_pb.OperationType.MeasureResetZ,
    BondDim => circuit_pb.OperationType.BondDim,
    SchmidtRank => circuit_pb.OperationType.SchmidtRank,
    VonNeumannEntropy => circuit_pb.OperationType.VonNeumannEntropy,
    Not => circuit_pb.OperationType.Not,
))

function fromproto(op::circuit_pb.Operation)
    return fromproto(op.operation[])
end

function toproto(g::T) where {T<:Operation}
    type = getleft(OPERATIONMAP, T, nothing)
    isnothing(type) && error(lazy"Not defined ProtoBuf conversion of type $(T).")
    params = toproto.(getparams(g))
    return circuit_pb.SimpleOperation(type, collect(params))
end

function fromproto(g::circuit_pb.SimpleOperation)
    T = getright(OPERATIONMAP, g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleOperation type $(g.mtype).")
    params = map(fromproto, g.parameters)
    return T(params...)
end

function toproto(g::Amplitude)
    return circuit_pb.Amplitude(toproto(getbitstring(g)))
end

function fromproto(g::circuit_pb.Amplitude)
    return Amplitude(fromproto(g.bs))
end

function toproto(g::ExpectationValue{N,T}) where {N,T}
    op = circuit_pb.Operator(_build_oneof(g.op))
    return circuit_pb.ExpectationValue(op)
end

function fromproto(g::circuit_pb.ExpectationValue)
    op = fromproto(g.operator)
    return ExpectationValue(op)
end

function toproto(::Barrier{N}) where {N}
    return circuit_pb.Barrier(N)
end

function fromproto(g::circuit_pb.Barrier)
    Barrier(g.numqubits)
end

function toproto(a::Detector{N}) where {N}
    notes = map(x -> toproto(x, circuit_pb.Note), getnotes(a))
    return circuit_pb.Detector(N, notes)
end

function fromproto(g::circuit_pb.Detector)
    notes = map(x -> fromproto(x), g.notes)
    Detector(g.numqubits, notes)
end

function toproto(a::ObservableInclude)
    notes = map(x -> toproto(x, circuit_pb.Note), getnotes(a))
    return circuit_pb.ObservableInclude(numbits(a), notes)
end

function fromproto(g::circuit_pb.ObservableInclude)
    notes = map(x -> fromproto(x), g.notes)
    ObservableInclude(g.numbits, notes)
end

function fromproto(g::circuit_pb.Note)
    return g.note[]
end

function toproto(g::Integer, ::Type{circuit_pb.Note})
    return circuit_pb.Note(OneOf(:int_note, Int64(g)))
end

function toproto(g::Number, ::Type{circuit_pb.Note})
    return circuit_pb.Note(OneOf(:double_note, Float64(g)))
end

const ANNOTATIONMAP = BiMap(Dict(
    QubitCoordinates => circuit_pb.AnnotationType.QubitCoordinates,
    ShiftCoordinates => circuit_pb.AnnotationType.ShiftCoordinates,
    Tick => circuit_pb.AnnotationType.Tick,
))

function toproto(g::T) where {T<:AbstractAnnotation}
    type = getleft(ANNOTATIONMAP, T, nothing)
    isnothing(type) && error(lazy"Not defined ProtoBuf conversion of type $(T).")
    notes = map(x -> toproto(x, circuit_pb.Note), getnotes(g))

    if T == Tick
        if !isempty(notes)
            @warn "Ignoring notes for Tick annotation."
        end
        return circuit_pb.SimpleAnnotation(type, [])
    end

    return circuit_pb.SimpleAnnotation(type, notes)
end

function fromproto(g::circuit_pb.SimpleAnnotation)
    T = getright(ANNOTATIONMAP, g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleAnnotation type $(g.mtype).")
    notes = map(x -> fromproto(x), g.notes)

    if T == Tick
        if !isempty(notes)
            @warn "Ignoring notes for Tick annotation."
        end

        return T()
    end

    return T(notes)
end

function toproto(g::IfStatement{N}) where {N}
    op = circuit_pb.Operation(_build_oneof(getoperation(g)))
    bs = toproto(g.bs)
    return circuit_pb.IfStatement(op, bs)
end

function fromproto(c::circuit_pb.IfStatement)
    return IfStatement(fromproto(c.operation), fromproto(c.bitstring))
end

function toproto(inst::Instruction)
    op = circuit_pb.Operation(_build_oneof(getoperation(inst)))
    return circuit_pb.Instruction(op, Int64[getqubits(inst)...], Int64[getbits(inst)...,], Int64[getztargets(inst)...])
end

function fromproto(inst::circuit_pb.Instruction)
    op = fromproto(inst.operation)
    return Instruction(op, inst.qtargets..., inst.ctargets..., inst.ztargets...)
end

function toproto(circuit::Circuit)
    instructions = map(toproto, circuit)
    return circuit_pb.Circuit(instructions)
end

function fromproto(c::circuit_pb.Circuit)
    instructions = map(fromproto, c.instructions)
    return Circuit(instructions)
end

function _build_oneof(gop)
    op = toproto(gop)
    op isa circuit_pb.SimpleGate ? OneOf(:simplegate, op) :
    op isa circuit_pb.CustomGate ? OneOf(:customgate, op) :
    op isa circuit_pb.Generalized ? OneOf(:generalized, op) :
    op isa circuit_pb.Control ? OneOf(:control, op) :
    op isa circuit_pb.Power ? OneOf(:power, op) :
    op isa circuit_pb.Inverse ? OneOf(:inverse, op) :
    op isa circuit_pb.Parallel ? OneOf(:parallel, op) :
    op isa circuit_pb.GateCall ? OneOf(:gatecall, op) :
    op isa circuit_pb.PauliString ? OneOf(:paulistring, op) :
    op isa circuit_pb.SimpleOperator ? OneOf(:simpleoperator, op) :
    op isa circuit_pb.CustomOperator ? OneOf(:customoperator, op) :
    op isa circuit_pb.RescaledGate ? OneOf(:rescaledgate, op) :
    op isa circuit_pb.SimpleKrausChannel ? OneOf(:simplekrauschannel, op) :
    op isa circuit_pb.CustomKrausChannel ? OneOf(:customkrauschannel, op) :
    op isa circuit_pb.DepolarizingChannel ? OneOf(:depolarizingchannel, op) :
    op isa circuit_pb.MixedUnitaryChannel ? OneOf(:mixedunitarychannel, op) :
    op isa circuit_pb.PauliChannel ? OneOf(:paulichannel, op) :
    op isa circuit_pb.SimpleOperation ? OneOf(:simpleoperation, op) :
    op isa circuit_pb.IfStatement ? OneOf(:ifstatement, op) :
    op isa circuit_pb.Barrier ? OneOf(:barrier, op) :
    op isa circuit_pb.Amplitude ? OneOf(:amplitude, op) :
    op isa circuit_pb.ExpectationValue ? OneOf(:expectationvalue, op) :
    op isa circuit_pb.Detector ? OneOf(:detector, op) :
    op isa circuit_pb.ObservableInclude ? OneOf(:observableinc, op) :
    op isa circuit_pb.SimpleAnnotation ? OneOf(:simpleannotation, op) :
    throw(ArgumentError(lazy"Cannot wrap a `$(typeof(op))` into a ProtoBuf `OneOf`."))
end
