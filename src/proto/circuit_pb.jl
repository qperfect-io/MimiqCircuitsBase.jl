# Autogenerated using ProtoBuf.jl v1.0.15 on 2024-06-10T08:50:01.858
# original file: /home/vase.moeini/Code/MimiqCircuitsBase.jl/src/proto/circuit.proto (proto3 syntax)

module circuit_pb

import ProtoBuf as PB
using ProtoBuf: OneOf
using ProtoBuf.EnumX: @enumx

export FunctionType, Rational, Measure, Reset, Irrational, Symbol, MeasureReset, Barrier
export ArgValue, GateType, IfStatement, ArgFunction, Operation, Control, GateCustom
export Parallel, Gate, Inverse, Power, ComplexArg, Instruction, Generalized, GateCall
export Circuit, Arg, GateDecl

# Abstract types to help resolve mutually recursive definitions
abstract type var"##AbstractIfStatement" end
abstract type var"##AbstractArgFunction" end
abstract type var"##AbstractOperation" end
abstract type var"##AbstractControl" end
abstract type var"##AbstractGateCustom" end
abstract type var"##AbstractParallel" end
abstract type var"##AbstractGate" end
abstract type var"##AbstractInverse" end
abstract type var"##AbstractPower" end
abstract type var"##AbstractComplexArg" end
abstract type var"##AbstractInstruction" end
abstract type var"##AbstractGeneralized" end
abstract type var"##AbstractGateCall" end
abstract type var"##AbstractCircuit" end
abstract type var"##AbstractArg" end
abstract type var"##AbstractGateDecl" end


@enumx FunctionType ADD=0 MUL=1 DIV=2 POW=3 SIN=5 COS=6 TAN=7 EXP=8 LOG=9 IDENTITY=10

struct Rational
    num::Int64
    den::Int64
end
PB.default_values(::Type{Rational}) = (;num = zero(Int64), den = zero(Int64))
PB.field_numbers(::Type{Rational}) = (;num = 1, den = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Rational})
    num = zero(Int64)
    den = zero(Int64)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            num = PB.decode(d, Int64)
        elseif field_number == 2
            den = PB.decode(d, Int64)
        else
            PB.skip(d, wire_type)
        end
    end
    return Rational(num, den)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Rational)
    initpos = position(e.io)
    x.num != zero(Int64) && PB.encode(e, 1, x.num)
    x.den != zero(Int64) && PB.encode(e, 2, x.den)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Rational)
    encoded_size = 0
    x.num != zero(Int64) && (encoded_size += PB._encoded_size(x.num, 1))
    x.den != zero(Int64) && (encoded_size += PB._encoded_size(x.den, 2))
    return encoded_size
end

struct Measure  end

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Measure})
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        PB.skip(d, wire_type)
    end
    return Measure()
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Measure)
    initpos = position(e.io)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Measure)
    encoded_size = 0
    return encoded_size
end

struct Reset  end

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Reset})
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        PB.skip(d, wire_type)
    end
    return Reset()
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Reset)
    initpos = position(e.io)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Reset)
    encoded_size = 0
    return encoded_size
end

@enumx Irrational PI=0 EULER=1

struct Symbol
    value::String
end
PB.default_values(::Type{Symbol}) = (;value = "")
PB.field_numbers(::Type{Symbol}) = (;value = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Symbol})
    value = ""
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            value = PB.decode(d, String)
        else
            PB.skip(d, wire_type)
        end
    end
    return Symbol(value)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Symbol)
    initpos = position(e.io)
    !isempty(x.value) && PB.encode(e, 1, x.value)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Symbol)
    encoded_size = 0
    !isempty(x.value) && (encoded_size += PB._encoded_size(x.value, 1))
    return encoded_size
end

struct MeasureReset  end

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:MeasureReset})
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        PB.skip(d, wire_type)
    end
    return MeasureReset()
end

function PB.encode(e::PB.AbstractProtoEncoder, x::MeasureReset)
    initpos = position(e.io)
    return position(e.io) - initpos
end
function PB._encoded_size(x::MeasureReset)
    encoded_size = 0
    return encoded_size
end

struct Barrier
    numqubits::Int64
end
PB.default_values(::Type{Barrier}) = (;numqubits = zero(Int64))
PB.field_numbers(::Type{Barrier}) = (;numqubits = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Barrier})
    numqubits = zero(Int64)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            numqubits = PB.decode(d, Int64)
        else
            PB.skip(d, wire_type)
        end
    end
    return Barrier(numqubits)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Barrier)
    initpos = position(e.io)
    x.numqubits != zero(Int64) && PB.encode(e, 1, x.numqubits)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Barrier)
    encoded_size = 0
    x.numqubits != zero(Int64) && (encoded_size += PB._encoded_size(x.numqubits, 1))
    return encoded_size
end

struct ArgValue
    arg_value::Union{Nothing,OneOf{<:Union{Int64,Float64,Bool}}}
end
PB.oneof_field_types(::Type{ArgValue}) = (;
    arg_value = (;integer_value=Int64, double_value=Float64, bool_value=Bool),
)
PB.default_values(::Type{ArgValue}) = (;integer_value = zero(Int64), double_value = zero(Float64), bool_value = false)
PB.field_numbers(::Type{ArgValue}) = (;integer_value = 1, double_value = 2, bool_value = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:ArgValue})
    arg_value = nothing
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            arg_value = OneOf(:integer_value, PB.decode(d, Int64))
        elseif field_number == 2
            arg_value = OneOf(:double_value, PB.decode(d, Float64))
        elseif field_number == 3
            arg_value = OneOf(:bool_value, PB.decode(d, Bool))
        else
            PB.skip(d, wire_type)
        end
    end
    return ArgValue(arg_value)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::ArgValue)
    initpos = position(e.io)
    if isnothing(x.arg_value);
    elseif x.arg_value.name === :integer_value
        PB.encode(e, 1, x.arg_value[]::Int64)
    elseif x.arg_value.name === :double_value
        PB.encode(e, 2, x.arg_value[]::Float64)
    elseif x.arg_value.name === :bool_value
        PB.encode(e, 3, x.arg_value[]::Bool)
    end
    return position(e.io) - initpos
end
function PB._encoded_size(x::ArgValue)
    encoded_size = 0
    if isnothing(x.arg_value);
    elseif x.arg_value.name === :integer_value
        encoded_size += PB._encoded_size(x.arg_value[]::Int64, 1)
    elseif x.arg_value.name === :double_value
        encoded_size += PB._encoded_size(x.arg_value[]::Float64, 2)
    elseif x.arg_value.name === :bool_value
        encoded_size += PB._encoded_size(x.arg_value[]::Bool, 3)
    end
    return encoded_size
end

@enumx GateType GateU=0 GateID=1 GateX=2 GateY=3 GateZ=4 GateH=5 GateS=6 GateT=7 GateP=8 GateRX=10 GateRY=11 GateRZ=12 GateR=13 GateU1=14 GateU2=15 GateU3=16 GateSWAP=17 GateISWAP=18 GateECR=19 GateDCX=20 GateRXX=21 GateRYY=22 GateRZZ=23 GateRZX=24 GateXXplusYY=25 GateXXminusYY=26 GateUPhase=27

struct IfStatement{T1<:Union{Nothing,var"##AbstractOperation"},T2<:Union{Nothing,var"##AbstractArg"}} <: var"##AbstractIfStatement"
    operation::T1
    value::T2
    nbits::Int64
end
PB.default_values(::Type{IfStatement}) = (;operation = nothing, value = nothing, nbits = zero(Int64))
PB.field_numbers(::Type{IfStatement}) = (;operation = 1, value = 2, nbits = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:IfStatement})
    operation = Ref{Union{Nothing,Operation}}(nothing)
    value = Ref{Union{Nothing,Arg}}(nothing)
    nbits = zero(Int64)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, operation)
        elseif field_number == 2
            PB.decode!(d, value)
        elseif field_number == 3
            nbits = PB.decode(d, Int64)
        else
            PB.skip(d, wire_type)
        end
    end
    return IfStatement(operation[], value[], nbits)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::IfStatement)
    initpos = position(e.io)
    !isnothing(x.operation) && PB.encode(e, 1, x.operation)
    !isnothing(x.value) && PB.encode(e, 2, x.value)
    x.nbits != zero(Int64) && PB.encode(e, 3, x.nbits)
    return position(e.io) - initpos
end
function PB._encoded_size(x::IfStatement)
    encoded_size = 0
    !isnothing(x.operation) && (encoded_size += PB._encoded_size(x.operation, 1))
    !isnothing(x.value) && (encoded_size += PB._encoded_size(x.value, 2))
    x.nbits != zero(Int64) && (encoded_size += PB._encoded_size(x.nbits, 3))
    return encoded_size
end

struct ArgFunction{T1<:Union{Nothing,var"##AbstractArg"}} <: var"##AbstractArgFunction"
    functiontype::FunctionType.T
    args::Vector{T1}
end
PB.default_values(::Type{ArgFunction}) = (;functiontype = FunctionType.ADD, args = Vector{Arg}())
PB.field_numbers(::Type{ArgFunction}) = (;functiontype = 1, args = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:ArgFunction})
    functiontype = FunctionType.ADD
    args = PB.BufferedVector{Arg}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            functiontype = PB.decode(d, FunctionType.T)
        elseif field_number == 2
            PB.decode!(d, args)
        else
            PB.skip(d, wire_type)
        end
    end
    return ArgFunction(functiontype, args[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::ArgFunction)
    initpos = position(e.io)
    x.functiontype != FunctionType.ADD && PB.encode(e, 1, x.functiontype)
    !isempty(x.args) && PB.encode(e, 2, x.args)
    return position(e.io) - initpos
end
function PB._encoded_size(x::ArgFunction)
    encoded_size = 0
    x.functiontype != FunctionType.ADD && (encoded_size += PB._encoded_size(x.functiontype, 1))
    !isempty(x.args) && (encoded_size += PB._encoded_size(x.args, 2))
    return encoded_size
end

struct Operation <: var"##AbstractOperation"
    operation::Union{Nothing,OneOf{<:Union{var"##AbstractGate",var"##AbstractControl",var"##AbstractPower",var"##AbstractInverse",Barrier,Measure,Reset,var"##AbstractIfStatement",var"##AbstractGeneralized",var"##AbstractGateCustom",var"##AbstractGateCall",var"##AbstractParallel",MeasureReset}}}
end
PB.oneof_field_types(::Type{Operation}) = (;
    operation = (;gate=Gate, control=Control, power=Power, inverse=Inverse, barrier=Barrier, measure=Measure, reset=Reset, ifstatement=IfStatement, generalized=Generalized, custom=GateCustom, gatecall=GateCall, parallel=Parallel, measurereset=MeasureReset),
)
PB.default_values(::Type{Operation}) = (;gate = nothing, control = nothing, power = nothing, inverse = nothing, barrier = nothing, measure = nothing, reset = nothing, ifstatement = nothing, generalized = nothing, custom = nothing, gatecall = nothing, parallel = nothing, measurereset = nothing)
PB.field_numbers(::Type{Operation}) = (;gate = 1, control = 2, power = 3, inverse = 4, barrier = 5, measure = 6, reset = 7, ifstatement = 8, generalized = 9, custom = 10, gatecall = 11, parallel = 12, measurereset = 13)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Operation})
    operation = nothing
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            operation = OneOf(:gate, PB.decode(d, Ref{Gate}))
        elseif field_number == 2
            operation = OneOf(:control, PB.decode(d, Ref{Control}))
        elseif field_number == 3
            operation = OneOf(:power, PB.decode(d, Ref{Power}))
        elseif field_number == 4
            operation = OneOf(:inverse, PB.decode(d, Ref{Inverse}))
        elseif field_number == 5
            operation = OneOf(:barrier, PB.decode(d, Ref{Barrier}))
        elseif field_number == 6
            operation = OneOf(:measure, PB.decode(d, Ref{Measure}))
        elseif field_number == 7
            operation = OneOf(:reset, PB.decode(d, Ref{Reset}))
        elseif field_number == 8
            operation = OneOf(:ifstatement, PB.decode(d, Ref{IfStatement}))
        elseif field_number == 9
            operation = OneOf(:generalized, PB.decode(d, Ref{Generalized}))
        elseif field_number == 10
            operation = OneOf(:custom, PB.decode(d, Ref{GateCustom}))
        elseif field_number == 11
            operation = OneOf(:gatecall, PB.decode(d, Ref{GateCall}))
        elseif field_number == 12
            operation = OneOf(:parallel, PB.decode(d, Ref{Parallel}))
        elseif field_number == 13
            operation = OneOf(:measurereset, PB.decode(d, Ref{MeasureReset}))
        else
            PB.skip(d, wire_type)
        end
    end
    return Operation(operation)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Operation)
    initpos = position(e.io)
    if isnothing(x.operation);
    elseif x.operation.name === :gate
        PB.encode(e, 1, x.operation[]::Gate)
    elseif x.operation.name === :control
        PB.encode(e, 2, x.operation[]::Control)
    elseif x.operation.name === :power
        PB.encode(e, 3, x.operation[]::Power)
    elseif x.operation.name === :inverse
        PB.encode(e, 4, x.operation[]::Inverse)
    elseif x.operation.name === :barrier
        PB.encode(e, 5, x.operation[]::Barrier)
    elseif x.operation.name === :measure
        PB.encode(e, 6, x.operation[]::Measure)
    elseif x.operation.name === :reset
        PB.encode(e, 7, x.operation[]::Reset)
    elseif x.operation.name === :ifstatement
        PB.encode(e, 8, x.operation[]::IfStatement)
    elseif x.operation.name === :generalized
        PB.encode(e, 9, x.operation[]::Generalized)
    elseif x.operation.name === :custom
        PB.encode(e, 10, x.operation[]::GateCustom)
    elseif x.operation.name === :gatecall
        PB.encode(e, 11, x.operation[]::GateCall)
    elseif x.operation.name === :parallel
        PB.encode(e, 12, x.operation[]::Parallel)
    elseif x.operation.name === :measurereset
        PB.encode(e, 13, x.operation[]::MeasureReset)
    end
    return position(e.io) - initpos
end
function PB._encoded_size(x::Operation)
    encoded_size = 0
    if isnothing(x.operation);
    elseif x.operation.name === :gate
        encoded_size += PB._encoded_size(x.operation[]::Gate, 1)
    elseif x.operation.name === :control
        encoded_size += PB._encoded_size(x.operation[]::Control, 2)
    elseif x.operation.name === :power
        encoded_size += PB._encoded_size(x.operation[]::Power, 3)
    elseif x.operation.name === :inverse
        encoded_size += PB._encoded_size(x.operation[]::Inverse, 4)
    elseif x.operation.name === :barrier
        encoded_size += PB._encoded_size(x.operation[]::Barrier, 5)
    elseif x.operation.name === :measure
        encoded_size += PB._encoded_size(x.operation[]::Measure, 6)
    elseif x.operation.name === :reset
        encoded_size += PB._encoded_size(x.operation[]::Reset, 7)
    elseif x.operation.name === :ifstatement
        encoded_size += PB._encoded_size(x.operation[]::IfStatement, 8)
    elseif x.operation.name === :generalized
        encoded_size += PB._encoded_size(x.operation[]::Generalized, 9)
    elseif x.operation.name === :custom
        encoded_size += PB._encoded_size(x.operation[]::GateCustom, 10)
    elseif x.operation.name === :gatecall
        encoded_size += PB._encoded_size(x.operation[]::GateCall, 11)
    elseif x.operation.name === :parallel
        encoded_size += PB._encoded_size(x.operation[]::Parallel, 12)
    elseif x.operation.name === :measurereset
        encoded_size += PB._encoded_size(x.operation[]::MeasureReset, 13)
    end
    return encoded_size
end

struct Control <: var"##AbstractControl"
    operation::Union{Nothing,Operation}
    numcontrols::Int64
end
PB.default_values(::Type{Control}) = (;operation = nothing, numcontrols = zero(Int64))
PB.field_numbers(::Type{Control}) = (;operation = 1, numcontrols = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Control})
    operation = Ref{Union{Nothing,Operation}}(nothing)
    numcontrols = zero(Int64)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, operation)
        elseif field_number == 2
            numcontrols = PB.decode(d, Int64)
        else
            PB.skip(d, wire_type)
        end
    end
    return Control(operation[], numcontrols)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Control)
    initpos = position(e.io)
    !isnothing(x.operation) && PB.encode(e, 1, x.operation)
    x.numcontrols != zero(Int64) && PB.encode(e, 2, x.numcontrols)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Control)
    encoded_size = 0
    !isnothing(x.operation) && (encoded_size += PB._encoded_size(x.operation, 1))
    x.numcontrols != zero(Int64) && (encoded_size += PB._encoded_size(x.numcontrols, 2))
    return encoded_size
end

struct GateCustom{T1<:Union{Nothing,var"##AbstractComplexArg"}} <: var"##AbstractGateCustom"
    nqubits::Int64
    matrix::Vector{T1}
end
PB.default_values(::Type{GateCustom}) = (;nqubits = zero(Int64), matrix = Vector{ComplexArg}())
PB.field_numbers(::Type{GateCustom}) = (;nqubits = 1, matrix = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:GateCustom})
    nqubits = zero(Int64)
    matrix = PB.BufferedVector{ComplexArg}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            nqubits = PB.decode(d, Int64)
        elseif field_number == 2
            PB.decode!(d, matrix)
        else
            PB.skip(d, wire_type)
        end
    end
    return GateCustom(nqubits, matrix[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::GateCustom)
    initpos = position(e.io)
    x.nqubits != zero(Int64) && PB.encode(e, 1, x.nqubits)
    !isempty(x.matrix) && PB.encode(e, 2, x.matrix)
    return position(e.io) - initpos
end
function PB._encoded_size(x::GateCustom)
    encoded_size = 0
    x.nqubits != zero(Int64) && (encoded_size += PB._encoded_size(x.nqubits, 1))
    !isempty(x.matrix) && (encoded_size += PB._encoded_size(x.matrix, 2))
    return encoded_size
end

struct Parallel <: var"##AbstractParallel"
    operation::Union{Nothing,Operation}
    numrepeats::Int64
end
PB.default_values(::Type{Parallel}) = (;operation = nothing, numrepeats = zero(Int64))
PB.field_numbers(::Type{Parallel}) = (;operation = 1, numrepeats = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Parallel})
    operation = Ref{Union{Nothing,Operation}}(nothing)
    numrepeats = zero(Int64)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, operation)
        elseif field_number == 2
            numrepeats = PB.decode(d, Int64)
        else
            PB.skip(d, wire_type)
        end
    end
    return Parallel(operation[], numrepeats)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Parallel)
    initpos = position(e.io)
    !isnothing(x.operation) && PB.encode(e, 1, x.operation)
    x.numrepeats != zero(Int64) && PB.encode(e, 2, x.numrepeats)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Parallel)
    encoded_size = 0
    !isnothing(x.operation) && (encoded_size += PB._encoded_size(x.operation, 1))
    x.numrepeats != zero(Int64) && (encoded_size += PB._encoded_size(x.numrepeats, 2))
    return encoded_size
end

struct Gate{T1<:Union{Nothing,var"##AbstractArg"}} <: var"##AbstractGate"
    gtype::GateType.T
    parameters::Vector{T1}
end
PB.default_values(::Type{Gate}) = (;gtype = GateType.GateU, parameters = Vector{Arg}())
PB.field_numbers(::Type{Gate}) = (;gtype = 1, parameters = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Gate})
    gtype = GateType.GateU
    parameters = PB.BufferedVector{Arg}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            gtype = PB.decode(d, GateType.T)
        elseif field_number == 2
            PB.decode!(d, parameters)
        else
            PB.skip(d, wire_type)
        end
    end
    return Gate(gtype, parameters[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Gate)
    initpos = position(e.io)
    x.gtype != GateType.GateU && PB.encode(e, 1, x.gtype)
    !isempty(x.parameters) && PB.encode(e, 2, x.parameters)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Gate)
    encoded_size = 0
    x.gtype != GateType.GateU && (encoded_size += PB._encoded_size(x.gtype, 1))
    !isempty(x.parameters) && (encoded_size += PB._encoded_size(x.parameters, 2))
    return encoded_size
end

struct Inverse <: var"##AbstractInverse"
    operation::Union{Nothing,Operation}
end
PB.default_values(::Type{Inverse}) = (;operation = nothing)
PB.field_numbers(::Type{Inverse}) = (;operation = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Inverse})
    operation = Ref{Union{Nothing,Operation}}(nothing)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, operation)
        else
            PB.skip(d, wire_type)
        end
    end
    return Inverse(operation[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Inverse)
    initpos = position(e.io)
    !isnothing(x.operation) && PB.encode(e, 1, x.operation)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Inverse)
    encoded_size = 0
    !isnothing(x.operation) && (encoded_size += PB._encoded_size(x.operation, 1))
    return encoded_size
end

struct Power <: var"##AbstractPower"
    operation::Union{Nothing,Operation}
    power::Union{Nothing,OneOf{<:Union{Float64,Rational,Int64}}}
end
PB.oneof_field_types(::Type{Power}) = (;
    power = (;double_val=Float64, rational_val=Rational, int_val=Int64),
)
PB.default_values(::Type{Power}) = (;operation = nothing, double_val = zero(Float64), rational_val = nothing, int_val = zero(Int64))
PB.field_numbers(::Type{Power}) = (;operation = 1, double_val = 2, rational_val = 3, int_val = 4)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Power})
    operation = Ref{Union{Nothing,Operation}}(nothing)
    power = nothing
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, operation)
        elseif field_number == 2
            power = OneOf(:double_val, PB.decode(d, Float64))
        elseif field_number == 3
            power = OneOf(:rational_val, PB.decode(d, Ref{Rational}))
        elseif field_number == 4
            power = OneOf(:int_val, PB.decode(d, Int64))
        else
            PB.skip(d, wire_type)
        end
    end
    return Power(operation[], power)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Power)
    initpos = position(e.io)
    !isnothing(x.operation) && PB.encode(e, 1, x.operation)
    if isnothing(x.power);
    elseif x.power.name === :double_val
        PB.encode(e, 2, x.power[]::Float64)
    elseif x.power.name === :rational_val
        PB.encode(e, 3, x.power[]::Rational)
    elseif x.power.name === :int_val
        PB.encode(e, 4, x.power[]::Int64)
    end
    return position(e.io) - initpos
end
function PB._encoded_size(x::Power)
    encoded_size = 0
    !isnothing(x.operation) && (encoded_size += PB._encoded_size(x.operation, 1))
    if isnothing(x.power);
    elseif x.power.name === :double_val
        encoded_size += PB._encoded_size(x.power[]::Float64, 2)
    elseif x.power.name === :rational_val
        encoded_size += PB._encoded_size(x.power[]::Rational, 3)
    elseif x.power.name === :int_val
        encoded_size += PB._encoded_size(x.power[]::Int64, 4)
    end
    return encoded_size
end

struct ComplexArg{T1<:Union{Nothing,var"##AbstractArg"},T2<:Union{Nothing,var"##AbstractArg"}} <: var"##AbstractComplexArg"
    real::T1
    imag::T2
end
PB.default_values(::Type{ComplexArg}) = (;real = nothing, imag = nothing)
PB.field_numbers(::Type{ComplexArg}) = (;real = 1, imag = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:ComplexArg})
    real = Ref{Union{Nothing,Arg}}(nothing)
    imag = Ref{Union{Nothing,Arg}}(nothing)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, real)
        elseif field_number == 2
            PB.decode!(d, imag)
        else
            PB.skip(d, wire_type)
        end
    end
    return ComplexArg(real[], imag[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::ComplexArg)
    initpos = position(e.io)
    !isnothing(x.real) && PB.encode(e, 1, x.real)
    !isnothing(x.imag) && PB.encode(e, 2, x.imag)
    return position(e.io) - initpos
end
function PB._encoded_size(x::ComplexArg)
    encoded_size = 0
    !isnothing(x.real) && (encoded_size += PB._encoded_size(x.real, 1))
    !isnothing(x.imag) && (encoded_size += PB._encoded_size(x.imag, 2))
    return encoded_size
end

struct Instruction <: var"##AbstractInstruction"
    operation::Union{Nothing,Operation}
    qtargets::Vector{Int64}
    ctargets::Vector{Int64}
end
PB.default_values(::Type{Instruction}) = (;operation = nothing, qtargets = Vector{Int64}(), ctargets = Vector{Int64}())
PB.field_numbers(::Type{Instruction}) = (;operation = 1, qtargets = 2, ctargets = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Instruction})
    operation = Ref{Union{Nothing,Operation}}(nothing)
    qtargets = PB.BufferedVector{Int64}()
    ctargets = PB.BufferedVector{Int64}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, operation)
        elseif field_number == 2
            PB.decode!(d, wire_type, qtargets)
        elseif field_number == 3
            PB.decode!(d, wire_type, ctargets)
        else
            PB.skip(d, wire_type)
        end
    end
    return Instruction(operation[], qtargets[], ctargets[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Instruction)
    initpos = position(e.io)
    !isnothing(x.operation) && PB.encode(e, 1, x.operation)
    !isempty(x.qtargets) && PB.encode(e, 2, x.qtargets)
    !isempty(x.ctargets) && PB.encode(e, 3, x.ctargets)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Instruction)
    encoded_size = 0
    !isnothing(x.operation) && (encoded_size += PB._encoded_size(x.operation, 1))
    !isempty(x.qtargets) && (encoded_size += PB._encoded_size(x.qtargets, 2))
    !isempty(x.ctargets) && (encoded_size += PB._encoded_size(x.ctargets, 3))
    return encoded_size
end

struct Generalized{T1<:Union{Nothing,var"##AbstractArg"}} <: var"##AbstractGeneralized"
    name::String
    args::Vector{T1}
    regsizes::Vector{Int64}
end
PB.default_values(::Type{Generalized}) = (;name = "", args = Vector{Arg}(), regsizes = Vector{Int64}())
PB.field_numbers(::Type{Generalized}) = (;name = 1, args = 2, regsizes = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Generalized})
    name = ""
    args = PB.BufferedVector{Arg}()
    regsizes = PB.BufferedVector{Int64}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            name = PB.decode(d, String)
        elseif field_number == 2
            PB.decode!(d, args)
        elseif field_number == 3
            PB.decode!(d, wire_type, regsizes)
        else
            PB.skip(d, wire_type)
        end
    end
    return Generalized(name, args[], regsizes[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Generalized)
    initpos = position(e.io)
    !isempty(x.name) && PB.encode(e, 1, x.name)
    !isempty(x.args) && PB.encode(e, 2, x.args)
    !isempty(x.regsizes) && PB.encode(e, 3, x.regsizes)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Generalized)
    encoded_size = 0
    !isempty(x.name) && (encoded_size += PB._encoded_size(x.name, 1))
    !isempty(x.args) && (encoded_size += PB._encoded_size(x.args, 2))
    !isempty(x.regsizes) && (encoded_size += PB._encoded_size(x.regsizes, 3))
    return encoded_size
end

struct GateCall{T2<:Union{Nothing,var"##AbstractArg"},T1<:Union{Nothing,var"##AbstractGateDecl"}} <: var"##AbstractGateCall"
    decl::T1
    args::Vector{T2}
end
PB.default_values(::Type{GateCall}) = (;decl = nothing, args = Vector{Arg}())
PB.field_numbers(::Type{GateCall}) = (;decl = 1, args = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:GateCall})
    decl = Ref{Union{Nothing,GateDecl}}(nothing)
    args = PB.BufferedVector{Arg}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, decl)
        elseif field_number == 2
            PB.decode!(d, args)
        else
            PB.skip(d, wire_type)
        end
    end
    return GateCall(decl[], args[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::GateCall)
    initpos = position(e.io)
    !isnothing(x.decl) && PB.encode(e, 1, x.decl)
    !isempty(x.args) && PB.encode(e, 2, x.args)
    return position(e.io) - initpos
end
function PB._encoded_size(x::GateCall)
    encoded_size = 0
    !isnothing(x.decl) && (encoded_size += PB._encoded_size(x.decl, 1))
    !isempty(x.args) && (encoded_size += PB._encoded_size(x.args, 2))
    return encoded_size
end

struct Circuit <: var"##AbstractCircuit"
    instructions::Vector{<:Instruction}
end
PB.default_values(::Type{Circuit}) = (;instructions = Vector{Instruction}())
PB.field_numbers(::Type{Circuit}) = (;instructions = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Circuit})
    instructions = PB.BufferedVector{Instruction}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, instructions)
        else
            PB.skip(d, wire_type)
        end
    end
    return Circuit(instructions[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Circuit)
    initpos = position(e.io)
    !isempty(x.instructions) && PB.encode(e, 1, x.instructions)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Circuit)
    encoded_size = 0
    !isempty(x.instructions) && (encoded_size += PB._encoded_size(x.instructions, 1))
    return encoded_size
end

struct Arg <: var"##AbstractArg"
    arg::Union{Nothing,OneOf{<:Union{ArgValue,Symbol,var"##AbstractArgFunction",Irrational.T}}}
end
PB.oneof_field_types(::Type{Arg}) = (;
    arg = (;argvalue_value=ArgValue, symbol_value=Symbol, argfunction_value=ArgFunction, irrational_value=Irrational.T),
)
PB.default_values(::Type{Arg}) = (;argvalue_value = nothing, symbol_value = nothing, argfunction_value = nothing, irrational_value = Irrational.PI)
PB.field_numbers(::Type{Arg}) = (;argvalue_value = 1, symbol_value = 2, argfunction_value = 3, irrational_value = 4)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Arg})
    arg = nothing
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            arg = OneOf(:argvalue_value, PB.decode(d, Ref{ArgValue}))
        elseif field_number == 2
            arg = OneOf(:symbol_value, PB.decode(d, Ref{Symbol}))
        elseif field_number == 3
            arg = OneOf(:argfunction_value, PB.decode(d, Ref{ArgFunction}))
        elseif field_number == 4
            arg = OneOf(:irrational_value, PB.decode(d, Irrational.T))
        else
            PB.skip(d, wire_type)
        end
    end
    return Arg(arg)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Arg)
    initpos = position(e.io)
    if isnothing(x.arg);
    elseif x.arg.name === :argvalue_value
        PB.encode(e, 1, x.arg[]::ArgValue)
    elseif x.arg.name === :symbol_value
        PB.encode(e, 2, x.arg[]::Symbol)
    elseif x.arg.name === :argfunction_value
        PB.encode(e, 3, x.arg[]::ArgFunction)
    elseif x.arg.name === :irrational_value
        PB.encode(e, 4, x.arg[]::Irrational.T)
    end
    return position(e.io) - initpos
end
function PB._encoded_size(x::Arg)
    encoded_size = 0
    if isnothing(x.arg);
    elseif x.arg.name === :argvalue_value
        encoded_size += PB._encoded_size(x.arg[]::ArgValue, 1)
    elseif x.arg.name === :symbol_value
        encoded_size += PB._encoded_size(x.arg[]::Symbol, 2)
    elseif x.arg.name === :argfunction_value
        encoded_size += PB._encoded_size(x.arg[]::ArgFunction, 3)
    elseif x.arg.name === :irrational_value
        encoded_size += PB._encoded_size(x.arg[]::Irrational.T, 4)
    end
    return encoded_size
end

struct GateDecl <: var"##AbstractGateDecl"
    name::String
    args::Vector{Symbol}
    instructions::Vector{<:Instruction}
end
PB.default_values(::Type{GateDecl}) = (;name = "", args = Vector{Symbol}(), instructions = Vector{Instruction}())
PB.field_numbers(::Type{GateDecl}) = (;name = 1, args = 2, instructions = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:GateDecl})
    name = ""
    args = PB.BufferedVector{Symbol}()
    instructions = PB.BufferedVector{Instruction}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            name = PB.decode(d, String)
        elseif field_number == 2
            PB.decode!(d, args)
        elseif field_number == 3
            PB.decode!(d, instructions)
        else
            PB.skip(d, wire_type)
        end
    end
    return GateDecl(name, args[], instructions[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::GateDecl)
    initpos = position(e.io)
    !isempty(x.name) && PB.encode(e, 1, x.name)
    !isempty(x.args) && PB.encode(e, 2, x.args)
    !isempty(x.instructions) && PB.encode(e, 3, x.instructions)
    return position(e.io) - initpos
end
function PB._encoded_size(x::GateDecl)
    encoded_size = 0
    !isempty(x.name) && (encoded_size += PB._encoded_size(x.name, 1))
    !isempty(x.args) && (encoded_size += PB._encoded_size(x.args, 2))
    !isempty(x.instructions) && (encoded_size += PB._encoded_size(x.instructions, 3))
    return encoded_size
end
end # module
