"""
This module renames all gates present in MimiqCircuitsBase.GATES to filter out the "Gate" part of the name
"""
module Aliases

using ..MimiqCircuitsBase

# Dict of all aliased created
# could be an array of clas and methods instead
ALIASED_GATES = Dict{Any,Any}()
"""
This function create an aliase for the given name that will create an Instruction list from the given aguments and GateType
and export the aliase
"""
function rename_gates(new_name::String, gate_type::DataType)
    new_name = Symbol(new_name)
    # Define variable name from string
    nb_args = numparams(gate_type)

    """
    Sets up the arguments anf gate type for the gate creation
    """
    function create_instructions(targets::Vararg{Any,K}) where {K}
        gate = gate_type(targets[1:nb_args]...)
        instruction_list = Vector{Instruction}([])
        return push!(instruction_list, gate, targets[nb_args+1:end]...)
    end

    @eval (($new_name) = ($create_instructions))
    ALIASED_GATES[gate_type] = new_name
    @eval (export ($new_name))
end

# iterates over all common gates
for gate in MimiqCircuitsBase.GATES
    # gets the name of the class
    gate_name = String(gate.name.name)
    if startswith(gate_name, "Gate")
        rename_gates(gate_name[5:end], gate)
    elseif gate_name == "Control"
        rename_gates(MimiqCircuitsBase._opname(gate), gate)
    end
end

# Is not a gate so it is necessary to do it manually 
rename_gates("M", Measure)
rename_gates("R", Reset)

export ALIASED_GATES

Base.:*(circuit::Circuit, arg::Instruction) = return push!(circuit, arg)
function Base.:*(circuit::Circuit, args::Vector{Instruction})
    for inst in args
        circuit * inst
    end
    return circuit
end

Base.:*(arg::Instruction, arg2::Instruction) = return Vector{Instruction}([arg, arg2])
Base.:*(args1::Vector{Instruction}, args2::Vector{Instruction}) = return Vector{Instruction}([args1..., args2...])
Base.:*(::Circuit, ::AbstractGate) = throw(ArgumentError("The Aliased \"<|\" or \"*\" syntax is not compatible with usual the usual Gates.
Please use one of the aliases in ALIASED_GATES with this syntax or revert back to the push syntax.

use ?<| to see examples"))
Base.:*(::AbstractGate, ::AbstractGate) = throw(ArgumentError("The Aliased \"<|\" or \"*\" syntax is not compatible with usual the usual Gates.
Please use one of the aliases in ALIASED_GATES with this syntax or revert back to the push syntax

use ?<| to see examples"))

"""
The following operator allow user to define circuit with the following format

'''
c = Circuit()

# add gate H
c <| H(1)

# add multiple H
c <| H(2:3)

# add rotation gate
c <- RX(0.5, 1)

# add GateCX
c <| CX(1, 4)
# or
c <| CX(1:2, 3:4)

# add Measure
c <| Measure(1, 1)

# Can be used to separate registers
c <| Measure(2:4, 2:4)
'''
"""
<|(arg1::Any, arg2::Any) = arg1 * arg2

export *
export <|

end