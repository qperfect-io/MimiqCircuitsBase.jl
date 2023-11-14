#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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

#=============#
#== Circuit ==#
#=============#

function toproto(circuit::Circuit)
    instructions = map(toproto, circuit)
    return circuit_pb.Circuit(instructions)
end

function fromproto(c::circuit_pb.Circuit)
    instructions = map(fromproto, c.instructions)
    return Circuit(instructions)
end

#============================#
#== Operation: IfStatement ==#
#============================#

function toproto(g::IfStatement{N}) where {N}
    op = toproto(getoperation(g))
    val = toproto(g.val)
    return circuit_pb.Operation(OneOf(:ifstatement, circuit_pb.IfStatement(op, val, N)))
end

function fromproto(c::circuit_pb.IfStatement)
    return IfStatement(c.nbits, fromproto(c.operation), fromproto(c.value))
end

#=========================#
#== Operation: GateDecl ==#
#=========================#

function toproto(decl::GateDecl)
    instructions = map(toproto, decl.instructions)
    args = map(toproto, decl.arguments)
    return circuit_pb.GateDecl(string(decl.name), collect(args), instructions)
end

function fromproto(decl::circuit_pb.GateDecl)
    instructions = map(fromproto, decl.instructions)
    args = map(fromproto, decl.args)
    return GateDecl(Symbol(decl.name), Tuple(args), instructions)
end

#=========================#
#== Operation: GateCall ==#
#=========================#

function toproto(cl::GateCall)
    decl = toproto(cl._decl)
    args = collect(map(toproto, cl._args))
    return circuit_pb.Operation(OneOf(:gatecall, circuit_pb.GateCall(decl, args)))
end

function fromproto(cl::circuit_pb.GateCall)
    decl = fromproto(cl.decl)
    args = map(fromproto, cl.args)
    return GateCall(decl, args...)
end

#=================#
#== Instruction ==#
#=================#

function toproto(inst::Instruction)
    op = toproto(getoperation(inst))
    return circuit_pb.Instruction(op, Int64[getqubits(inst)...], Int64[getbits(inst)...])
end

function fromproto(inst::circuit_pb.Instruction)
    op = fromproto(inst.operation)
    return Instruction(op, inst.qtargets..., inst.ctargets...)
end

#========================#
#== Operation: Inverse ==#
#========================#

function toproto(g::Inverse)
    op = toproto(g.op)
    return circuit_pb.Operation(OneOf(:inverse, circuit_pb.Inverse(op)))
end

function fromproto(g::circuit_pb.Inverse)
    op = fromproto(g.operation)
    return Inverse(op)
end

#===============#
#== Operation ==#
#===============#

function fromproto(op::circuit_pb.Operation)
    fromproto(op.operation[])
end

#================#
#== ComplexArg ==#
#================#
function toproto(g::Complex{Num})
    return circuit_pb.ComplexArg(toproto(real(g)), toproto(imag(g)))
end

function fromproto(g::circuit_pb.ComplexArg)
    return fromproto(g.real) + im * fromproto(g.imag)
end

#===========================#
#== Operation: GateCustom ==#
#===========================#

function toproto(g::GateCustom{N}) where {N}
    U = reshape(map(toproto, g.U), length(g.U))
    return circuit_pb.Operation(OneOf(:custom, circuit_pb.GateCustom(N, U)))
end

function fromproto(g::circuit_pb.GateCustom)
    U = reshape(map(fromproto, g.matrix), (2^g.nqubits, 2^g.nqubits))
    return GateCustom(U)
end

#========================#
#== Operation: Barrier ==#
#========================#

toproto(::Barrier{N}) where {N} = circuit_pb.Operation(OneOf(:barrier, circuit_pb.Barrier(N)))
fromproto(g::circuit_pb.Barrier) = Barrier(g.numqubits)

#========================#
#== Operation: Control ==#
#========================#

function toproto(g::Control{N}) where {N}
    op = toproto(g.op)
    return circuit_pb.Operation(OneOf(:control, circuit_pb.Control(op, N)))
end

function fromproto(g::circuit_pb.Control)
    op = fromproto(g.operation)
    return Control(g.numcontrols, op)
end

#=========================#
#== Operation: Parallel ==#
#=========================#

function toproto(g::Parallel{N}) where {N}
    op = toproto(g.op)
    return circuit_pb.Operation(OneOf(:parallel, circuit_pb.Parallel(op, N)))
end

function fromproto(g::circuit_pb.Parallel)
    op = fromproto(g.operation)
    return Parallel(g.numrepeats, op)
end

#==============#
#== Rational ==#
#==============#

function toproto(r::Rational)
    return circuit_pb.Rational(r.num, r.den)
end

function fromproto(r::circuit_pb.Rational)
    return Rational(r.num, r.den)
end

#======================#
#== Operation: Power ==#
#======================#

function toproto(g::Power{P}) where {P}
    op = toproto(g.op)

    if P isa Rational
        pwr = circuit_pb.Power(op, OneOf(:rational_val, toproto(P)))
    elseif P isa Integer
        pwr = circuit_pb.Power(op, OneOf(:int_val, Int64(P)))
    else
        pwr = circuit_pb.Power(op, OneOf(:double_val, Float64(P)))
    end

    return circuit_pb.Operation(OneOf(:power, pwr))
end

function fromproto(g::circuit_pb.Power)
    op = fromproto(g.operation)
    power = fromproto(g.power[])
    return Power(op, power)
end

#========================#
#== Operation: Measure ==#
#========================#

function toproto(g::Measure)
    return circuit_pb.Operation(OneOf(:measure, circuit_pb.Measure()))
end

function fromproto(g::circuit_pb.Measure)
    return Measure()
end

#======================#
#== Operation: Reset ==#
#======================#

function toproto(g::Reset)
    return circuit_pb.Operation(OneOf(:reset, circuit_pb.Reset()))
end

function fromproto(g::circuit_pb.Reset)
    return Reset()
end

#=====================#
#== Operation: Gate ==#
#=====================#

const GATEENUMMAP = BiMap(
    Dict(
        GateU => circuit_pb.GateType.GateU,
        GateID => circuit_pb.GateType.GateID,
        GateX => circuit_pb.GateType.GateX,
        GateY => circuit_pb.GateType.GateY,
        GateZ => circuit_pb.GateType.GateZ,
        GateH => circuit_pb.GateType.GateH,
        GateS => circuit_pb.GateType.GateS,
        GateT => circuit_pb.GateType.GateT,
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
    )
)

function toproto(g::T) where {T<:AbstractGate}
    type = getleft(GATEENUMMAP, T, nothing)
    params = collect(map(n -> toproto(getfield(g, n)), fieldnames(T)))

    if isnothing(type)
        return circuit_pb.Operation(OneOf(:generalized, circuit_pb.Generalized(opname(g), params, Int64[qregsizes(g)...])))
    end

    return circuit_pb.Operation(OneOf(:gate, circuit_pb.Gate(type, params)))
end

function fromproto(g::circuit_pb.Gate)
    T = getright(GATEENUMMAP, g.gtype, nothing)
    params = map(fromproto, g.parameters)
    return T(params...)
end

function fromproto(g::circuit_pb.Generalized)
    params = map(fromproto, g.args)
    rs = g.regsizes

    if g.name == "QFT"
        return QFT(rs..., params...)
    elseif g.name == "PhaseGradient"
        return PhaseGradient(rs..., params...)
    elseif g.name == "GPhase"
        return GPhase(rs..., params...)
    else
        error("Unknown generalized gate: $(g.name)")
    end
end

#================#
#== Irrational ==#
#================#

const IRRATIONAL_TO_PROTO = Dict(
    Base.π => circuit_pb.Irrational.PI,
    Base.ℯ => circuit_pb.Irrational.EULER,
)

const PROTO_TO_IRRATIONAL = Dict(zip(values(IRRATIONAL_TO_PROTO), keys(IRRATIONAL_TO_PROTO)))

toproto(x::Irrational) = IRRATIONAL_TO_PROTO[x]
fromproto(x::circuit_pb.Irrational.T) = PROTO_TO_IRRATIONAL[x]

#=========#
#== Arg ==#
#=========#

function toproto(g::Num)
    v = Symbolics.value(g)

    if !(v isa Num)
        if v isa SymbolicUtils.BasicSymbolic{<:Irrational}
            vv = toproto(SymbolicUtils.arguments(v)[1])
            return circuit_pb.Arg(OneOf(:irrational_value, vv))
        elseif v isa Number
            vv = OneOf(v isa Integer ? :integer_value : :double_value, v)
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

#=================#
#== ArgFunction ==#
#=================#

const FUNCTIONENUMMAP_LEFT = Dict(
    Base.:+ => circuit_pb.FunctionType.ADD,
    Base.:* => circuit_pb.FunctionType.MUL,
    Base.:/ => circuit_pb.FunctionType.DIV,
    Base.:^ => circuit_pb.FunctionType.POW,
    Base.sin => circuit_pb.FunctionType.SIN,
    Base.cos => circuit_pb.FunctionType.COS,
    Base.tan => circuit_pb.FunctionType.TAN,
    Base.exp => circuit_pb.FunctionType.EXP,
    Base.log => circuit_pb.FunctionType.LOG,
    Base.identity => circuit_pb.FunctionType.IDENTITY,
)

const FUNCTIONENUMMAP_RIGHT = Dict(zip(values(FUNCTIONENUMMAP_LEFT), keys(FUNCTIONENUMMAP_LEFT)))

function toproto(g::Symbolics.BasicSymbolic)
    if Symbolics.issym(g)
        return circuit_pb.Symbol(string(g.name))
    end

    op = Symbolics.operation(g)

    type = get(FUNCTIONENUMMAP_LEFT, op, nothing)

    if isnothing(type)
        error("Not supported function: $(op)")
    end

    args = map(toproto, Num.(Symbolics.arguments(g)))

    return circuit_pb.ArgFunction(type, args)
end

function fromproto(g::circuit_pb.ArgFunction)
    op = get(FUNCTIONENUMMAP_RIGHT, g.functiontype, nothing)

    if isnothing(op)
        error("Not supported function: $(g.functiontype)")
    end

    args = map(fromproto, g.args)
    return op(args...)
end

#==============#
#== ArgValue ==#
#==============#
function fromproto(g::circuit_pb.ArgValue)
    return g.arg_value[]
end

#============#
#== Symbol ==#
#============#

function fromproto(g::circuit_pb.Symbol)
    return Symbolics.Sym{Real}(Symbol(g.value))
end


