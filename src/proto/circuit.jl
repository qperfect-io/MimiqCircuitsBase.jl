#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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

const GATEMAP = Bijection(Dict(
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

const GENERALIZEDGATEMAP = Bijection(Dict(
    QFT => circuit_pb.GeneralizedType.QFT,
    PhaseGradient => circuit_pb.GeneralizedType.PhaseGradient,
    PolynomialOracle => circuit_pb.GeneralizedType.PolynomialOracle,
    Diffusion => circuit_pb.GeneralizedType.Diffusion,
    GateRNZ => circuit_pb.GeneralizedType.GateRNZ,
))

function fromproto(op::circuit_pb.Gate, declcache=nothing)
    oop = op.gate[]
    if hasmethod(fromproto, Tuple{typeof(oop), typeof(declcache)})
        return fromproto(oop, declcache)
    end
    return fromproto(oop)
end

function toproto(g::T) where {T<:AbstractGate}
    type = get(GATEMAP, T, nothing)
    params = toproto.(getparams(g))

    if !isnothing(type)
        return circuit_pb.SimpleGate(type, collect(params))
    else
        mtype = get(GENERALIZEDGATEMAP, T.name.wrapper, nothing)

        if isnothing(mtype)
            error(lazy"Not defined ProtoBuf conversion of type $(T).")
        end

        return circuit_pb.Generalized(mtype, collect(params), Int64[qregsizes(g)...])
    end
end

function fromproto(g::circuit_pb.SimpleGate)
    T = get(inv(GATEMAP), g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleGate type $(g.mtype).")
    params = map(fromproto, g.parameters)
    return T(params...)
end

function fromproto(g::circuit_pb.Generalized)
    params = map(fromproto, g.args)
    rs = g.qregsizes

    if g.mtype == circuit_pb.GeneralizedType.QFT
        return QFT(rs..., params...)
    elseif g.mtype == circuit_pb.GeneralizedType.PhaseGradient
        return PhaseGradient(rs..., params...)
    elseif g.mtype == circuit_pb.GeneralizedType.PolynomialOracle
        return PolynomialOracle(rs..., params...)
    elseif g.mtype == circuit_pb.GeneralizedType.Diffusion
        return Diffusion(rs..., params...)
    elseif g.mtype == circuit_pb.GeneralizedType.GateRNZ
        return GateRNZ(rs[1], params[1])
    else
        error("Unknown generalized gate: $(g.mtype)")
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

function toproto(decl::GateDecl, declcache=nothing)
    instructions = map(inst -> toproto(inst, declcache), decl.instructions)
    args = map(toproto, decl.arguments)
    return circuit_pb.GateDecl(string(decl.name), collect(args), instructions)
end

function fromproto(decl::circuit_pb.GateDecl, declcache=nothing)
    instructions = map(inst -> fromproto(inst, declcache), decl.instructions)
    args = map(fromproto, decl.args)
    return GateDecl(Symbol(decl.name), Tuple(args), instructions)
end

function toproto(cl::GateCall)
    decl = toproto(cl._decl)
    args = collect(map(toproto, cl._args))
    return circuit_pb.GateCall(decl, args)
end

function toproto(cl::GateCall, declcache)
    declid = objectid(cl._decl)

    if !haskey(declcache[1], declid)
        declcache[1][declid] = toproto_declaration(cl._decl, declcache)
        push!(declcache[2], declid)
    end

    args = collect(map(toproto, cl._args))
    return circuit_pb.CachedGateCall(declid, args)
end

function fromproto(cl::circuit_pb.GateCall)
    decl = fromproto(cl.decl)
    args = map(fromproto, cl.args)
    return GateCall(decl, args...)
end

function fromproto(cl::circuit_pb.CachedGateCall, declcache)
    declid = cl.id

    if !haskey(declcache, declid)
        error("Gate declaration with id $(declid) not found in cache.")
    end

    decl = declcache[declid]
    args = map(fromproto, cl.args)

    return GateCall(decl, args...)
end

function toproto(g::Control{N}, declcache=nothing) where {N}
    op = circuit_pb.Gate(_build_oneof(g.op, declcache))
    return circuit_pb.Control(op, N)
end

function fromproto(g::circuit_pb.Control, declcache=nothing)
    op = fromproto(g.operation, declcache)
    return Control(g.numcontrols, op)
end

function toproto(g::Power{P}, declcache=nothing) where {P}
    op = circuit_pb.Gate(_build_oneof(g.op, declcache))

    if P isa Rational
        return circuit_pb.Power(op, OneOf(:rational_val, toproto(P)))
    elseif P isa Integer
        return circuit_pb.Power(op, OneOf(:int_val, Int64(P)))
    end

    return circuit_pb.Power(op, OneOf(:double_val, Float64(P)))
end

function fromproto(g::circuit_pb.Power, declcache=nothing)
    op = fromproto(g.operation, declcache)
    power = fromproto(g.power[])
    return Power(op, power)
end

function toproto(g::Inverse, declcache=nothing)
    op = circuit_pb.Gate(_build_oneof(g.op, declcache))
    return circuit_pb.Inverse(op)
end

function fromproto(g::circuit_pb.Inverse, declcache=nothing)
    op = fromproto(g.operation, declcache)
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

function toproto(g::RPauli)
    return circuit_pb.RPauli(toproto(g.pauli), toproto(g.θ))
end

function fromproto(g::circuit_pb.RPauli)
    return RPauli(fromproto(g.pauli), fromproto(g.theta))
end

const OPERATORMAP = Bijection(Dict(
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

function fromproto(op::circuit_pb.Operator, declcache=nothing)
    oop = op.operator[]

    if oop isa circuit_pb.RescaledGate
        return fromproto(oop, declcache)
    end

    return fromproto(op.operator[])
end

function toproto(g::T) where {T<:AbstractOperator}
    type = get(OPERATORMAP, T.name.wrapper, nothing)
    isnothing(type) && error(lazy"Not defined ProtoBuf conversion of type $(T).")
    params = toproto.(getparams(g))
    return circuit_pb.SimpleOperator(type, collect(params))
end

function fromproto(g::circuit_pb.SimpleOperator)
    T = get(inv(OPERATORMAP), g.mtype, nothing)
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

function toproto(g::RescaledGate, declcache=nothing)
    op = circuit_pb.Gate(_build_oneof(getoperation(g), declcache))
    return circuit_pb.RescaledGate(op, toproto(getscale(g)))
end

function fromproto(g::circuit_pb.RescaledGate, declcache=nothing)
    op = fromproto(g.operation, declcache)
    scale = fromproto(g.scale)
    return RescaledGate(op, scale)
end

const KRAUSCHANNELMAP = Bijection(Dict(
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

function fromproto(op::circuit_pb.KrausChannel, declcache=nothing)
    oop = op.krauschannel[]
    if oop isa circuit_pb.MixedUnitaryChannel
        return fromproto(oop, declcache)
    end
    fromproto(oop)
end

function toproto(g::T,) where {T<:AbstractKrausChannel}
    type = get(KRAUSCHANNELMAP, T, nothing)
    isnothing(type) && error(lazy"Not defined ProtoBuf conversion of type $(T).")
    params = toproto.(getparams(g))
    return circuit_pb.SimpleKrausChannel(type, collect(params))
end

function fromproto(g::circuit_pb.SimpleKrausChannel)
    T = get(inv(KRAUSCHANNELMAP), g.mtype, nothing)
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

function toproto(g::MixedUnitary{N}, declcache=nothing) where {N}
    rgs = map(op -> toproto(op, declcache), krausoperators(g))
    return circuit_pb.MixedUnitaryChannel(rgs)
end

function fromproto(g::circuit_pb.MixedUnitaryChannel, declcache=nothing)
    return MixedUnitary(map(x -> fromproto(x, declcache), g.operators))
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

const OPERATIONMAP = Bijection(Dict(
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
    Pow => circuit_pb.OperationType.Pow,
))

const GENERALIZEDOPERATIONMAP = Bijection(Dict(
    Barrier => circuit_pb.GeneralizedOperationType.Barrier,
    Add => circuit_pb.GeneralizedOperationType.Add,
    Multiply => circuit_pb.GeneralizedOperationType.Multiply,
))

function fromproto(op::circuit_pb.Operation, declcache)
    oop = op.operation[]
    if hasmethod(fromproto, Tuple{typeof(oop), typeof(declcache)})
        return fromproto(oop, declcache)
    else
        return fromproto(oop)
    end
end

function toproto(g::T) where {T<:Operation}
    type = get(OPERATIONMAP, T, nothing)
    params = toproto.(getparams(g))

    if !isnothing(type)
        return circuit_pb.SimpleOperation(type, collect(params))
    else
        mtype = get(GENERALIZEDOPERATIONMAP, T.name.wrapper, nothing)

        if !isnothing(mtype)
            return circuit_pb.GeneralizedOperation(mtype, numqubits(g), numbits(g), numzvars(g), collect(params))
        else
            error(lazy"Not defined ProtoBuf conversion of type $(T).")
        end
    end
end

function fromproto(g::circuit_pb.SimpleOperation)
    T = get(inv(OPERATIONMAP), g.mtype, nothing)
    isnothing(T) && error(lazy"Unsupported ProtoBuf SimpleOperation type $(g.mtype).")
    params = map(fromproto, g.parameters)
    return T(params...)
end

function fromproto(g::circuit_pb.GeneralizedOperation)
    nq = g.numqubits
    nb = g.numbits
    nz = g.numzvars
    params = map(fromproto, g.parameters)

    if g.mtype == circuit_pb.GeneralizedOperationType.Barrier
        return Barrier(nq)
    elseif g.mtype == circuit_pb.GeneralizedOperationType.Add
        return Add(nz, params...)
    elseif g.mtype == circuit_pb.GeneralizedOperationType.Multiply
        return Multiply(nz, params...)
    else
        error(lazy"Unsupported ProtoBuf GeneralizedOperation type $(g.mtype).")
    end
end

function toproto(g::Amplitude)
    return circuit_pb.Amplitude(toproto(getbitstring(g)))
end

function fromproto(g::circuit_pb.Amplitude)
    return Amplitude(fromproto(g.bs))
end

function toproto(g::ExpectationValue{N,T}, declcache=nothing) where {N,T}
    op = circuit_pb.Operator(_build_oneof(g.op, declcache))
    return circuit_pb.ExpectationValue(op)
end

function fromproto(g::circuit_pb.ExpectationValue, declcache=nothing)
    oop = g.operator
    if oop isa circuit_pb.RescaledGate
        return ExpectationValue(fromproto(oop, declcache))
    end
    return ExpectationValue(fromproto(oop))
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

const ANNOTATIONMAP = Bijection(Dict(
    QubitCoordinates => circuit_pb.AnnotationType.QubitCoordinates,
    ShiftCoordinates => circuit_pb.AnnotationType.ShiftCoordinates,
    Tick => circuit_pb.AnnotationType.Tick,
))

const GENERALIZEDANNOTATIONMAP = Bijection(Dict(
    Detector => circuit_pb.GeneralizedAnnotationType.Detector,
    ObservableInclude => circuit_pb.GeneralizedAnnotationType.ObservableInclude,
))

function toproto(g::T) where {T<:AbstractAnnotation}
    type = get(ANNOTATIONMAP, T, nothing)
    notes = map(x -> toproto(x, circuit_pb.Note), getnotes(g))

    if !isnothing(type)
        if T == Tick
            if !isempty(notes)
                @warn "Ignoring notes for Tick annotation."
            end
            return circuit_pb.SimpleAnnotation(type, [])
        else
            return circuit_pb.SimpleAnnotation(type, notes)
        end
    else
        mtype = get(GENERALIZEDANNOTATIONMAP, T.name.wrapper, nothing)

        if isnothing(mtype)
            error(lazy"Not defined ProtoBuf conversion of type $(T).")
        end

        return circuit_pb.GeneralizedAnnotation(mtype, numqubits(g), numbits(g), numzvars(g), notes)
    end
end

function fromproto(g::circuit_pb.SimpleAnnotation)
    T = get(inv(ANNOTATIONMAP), g.mtype, nothing)
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

function fromproto(g::circuit_pb.GeneralizedAnnotation)
    notes = map(x -> fromproto(x), g.notes)
    nq = g.numqubits
    nb = g.numbits
    nz = g.numzvars

    if g.mtype == circuit_pb.GeneralizedAnnotationType.Detector
        return Detector(nb, notes...)
    elseif g.mtype == circuit_pb.GeneralizedAnnotationType.ObservableInclude
        return ObservableInclude(nb, notes...)
    else
        error("Unknown generalized annotation: $(g.mtype)")
    end
end

function toproto(g::IfStatement{N}, declcache=nothing) where {N}
    op = circuit_pb.Operation(_build_oneof(getoperation(g), declcache))
    bs = toproto(g.bs)
    return circuit_pb.IfStatement(op, bs)
end

function fromproto(c::circuit_pb.IfStatement, declcache=nothing)
    op = fromproto(c.operation, declcache)
    return IfStatement(op, fromproto(c.bitstring))
end

function toproto(s::String)
    return circuit_pb.Arg(OneOf(:symbol_value, circuit_pb.Symbol(s)))
end

function toproto(r::Repeat, declcache=nothing)
    op = circuit_pb.Operation(_build_oneof(getoperation(r), declcache))
    return circuit_pb.Repeat(numrepeats(r), op)
end

function fromproto(r::circuit_pb.Repeat, declcache=nothing)
    op = fromproto(r.operation, declcache)
    return Repeat(r.numrepeats, op)
end

function toproto(inst::Instruction, declcache=nothing)
    op = circuit_pb.Operation(_build_oneof(getoperation(inst), declcache))
    return circuit_pb.Instruction(op, Int64[getqubits(inst)...], Int64[getbits(inst)...,], Int64[getztargets(inst)...])
end

function fromproto(inst::circuit_pb.Instruction, declcache=nothing)
    op = fromproto(inst.operation, declcache)
    return Instruction(op, inst.qtargets..., inst.ctargets..., inst.ztargets...)
end

function toproto(circuit::Circuit)
    declorder = UInt64[]
    declcache = Dict{UInt64,circuit_pb.Declaration}()
    instructions = map(inst -> toproto(inst, (declcache, declorder)), circuit)
    return circuit_pb.Circuit(instructions, declcache, declorder)
end

function fromproto(c::circuit_pb.Circuit)
    declcache = Dict()

    for k in c.declorder
        declcache[k] = fromproto(c.decls[k], declcache)
    end

    instructions = map(inst -> fromproto(inst, declcache), c.instructions)
    return Circuit(instructions)
end

function toproto(block::Block, declcache=nothing)
    instructions = map(inst -> toproto(inst, declcache), block)
    return circuit_pb.Block(numqubits(block), numbits(block), numzvars(block), instructions)
end

function fromproto(block::circuit_pb.Block, declcache=nothing)
    instructions = map(inst -> fromproto(inst, declcache), block.instructions)
    return Block(block.numqubits, block.numbits, block.numzvars, instructions)
end

function fromproto(block::circuit_pb.Declaration, declcache=nothing)
    decl = block.decl[]
    if decl isa circuit_pb.GateDecl
        return fromproto(decl, declcache)
    elseif decl isa circuit_pb.Block
        return fromproto(decl, declcache)
    end

    error("Unknown declaration type: $(block.decl)")
end

function toproto_declaration(decl, declcache=nothing)
    return circuit_pb.Declaration(_build_oneof(decl, declcache))
end

function _build_oneof(gop, declcache=nothing)
    op = if !isnothing(declcache) && (gop isa GateCall || gop isa MixedUnitary || gop isa RescaledGate || gop isa Power || gop isa Control || gop isa Inverse || gop isa Parallel || gop isa ExpectationValue || gop isa IfStatement || gop isa Block || gop isa Repeat || gop isa GateDecl)
        toproto(gop, declcache)
    else
        toproto(gop)
    end

    op isa circuit_pb.SimpleGate ? OneOf(:simplegate, op) :
    op isa circuit_pb.CustomGate ? OneOf(:customgate, op) :
    op isa circuit_pb.Generalized ? OneOf(:generalized, op) :
    op isa circuit_pb.Control ? OneOf(:control, op) :
    op isa circuit_pb.Power ? OneOf(:power, op) :
    op isa circuit_pb.Inverse ? OneOf(:inverse, op) :
    op isa circuit_pb.Parallel ? OneOf(:parallel, op) :
    op isa circuit_pb.GateCall ? OneOf(:gatecall, op) :
    op isa pauli_pb.PauliString ? OneOf(:paulistring, op) :
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
    op isa circuit_pb.GeneralizedOperation ? OneOf(:generalizedoperation, op) :
    op isa circuit_pb.Amplitude ? OneOf(:amplitude, op) :
    op isa circuit_pb.ExpectationValue ? OneOf(:expectationvalue, op) :
    op isa circuit_pb.SimpleAnnotation ? OneOf(:simpleannotation, op) :
    op isa circuit_pb.GeneralizedAnnotation ? OneOf(:generalizedannotation, op) :
    op isa circuit_pb.CachedGateCall ? OneOf(:cachedgatecall, op) :
    op isa circuit_pb.RPauli ? OneOf(:rpauli, op) :
    op isa circuit_pb.Repeat ? OneOf(:repeat, op) :
    op isa circuit_pb.Block ? OneOf(:block, op) :
    op isa circuit_pb.GateDecl ? OneOf(:gatedecl, op) :
    throw(ArgumentError(lazy"Cannot wrap a `$(typeof(op))` into a ProtoBuf `OneOf`."))
end
