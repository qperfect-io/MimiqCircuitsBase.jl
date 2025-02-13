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

# References
# [1] Barenco, A. et al. Elementary gates for quantum computation. Phys. Rev. A 52, 3457–3467 (1995).

function decompose!(circ::Circuit, control::Control{1}, qtargets, _, _)
    op = getoperation(control)
    for inst in decompose(op)
        push!(circ, Control(getoperation(inst)), qtargets[1], [qtargets[i+1] for i in getqubits(inst)]...)
    end
    return circ
end

function _controlrotation_decompose!(circ::Circuit, op::Operation{1,0}, qtargets)
    controls = qtargets[1:end-1]
    target = qtargets[end]

    if isempty(controls)
        push!(circ, op, target)
    elseif length(controls) == 1
        push!(circ, Control(op), qtargets...)
    else
        _control_recursive_decompose!(circ, Control(length(controls), op), qtargets)
    end
    return circ
end

# decomposition of multi controlled X gate according to Lemma 7.2 and 7.3 of [1]
function _controlx_decompose!(circ::Circuit, ctrl, trgt, ancl)
    nctrl = length(ctrl)
    nqubits = nctrl + 1 + length(ancl)

    if nctrl == 0
        push!(circ, GateX(), trgt)

    elseif nctrl <= 2
        push!(circ, Control(nctrl, GateX()), ctrl..., trgt)

    elseif nqubits >= 2 * nctrl - 1 && nctrl >= 3
        #push!(circ, Control(nctrl, GateX()), ctrl..., trgt)
        #return circ
        # Decomposition according to Lemma 7.2 of [1]
        c2x = Control(2, GateX())

        circ1 = Circuit()
        for i in 1:nctrl-3
            push!(circ1, c2x, ctrl[end-i], ancl[end-i], ancl[end-i+1])
        end

        circ2 = push!(Circuit(), c2x, ctrl[1], ctrl[2], ancl[end-nctrl+3])
        circ3 = push!(Circuit(), c2x, ctrl[end], ancl[end], trgt)

        append!(circ, circ3)
        append!(circ, circ1)
        append!(circ, circ2)
        append!(circ, inverse(circ1))
        append!(circ, circ3)
        append!(circ, circ1)
        append!(circ, circ2)
        append!(circ, inverse(circ1))

    elseif !isempty(ancl)
        # Decomposition according to Lemma 7.3 of [1]

        m = nqubits ÷ 2

        free1 = Int[ctrl[m+1:end]..., trgt, ancl[2:end]...]
        ctrl1 = ctrl[1:m]
        trgt1 = ancl[1]
        circ1 = _controlx_decompose!(Circuit(), ctrl1, trgt1, free1)
        # equivalent to
        #circ1 = push!(Circuit(), Control(length(qctrl1), GateX()), ctrl1..., trgt1)

        free2 = Int[ctrl[1:m]..., ancl[2:end]...]
        ctrl2 = Int[ctrl[m+1:end]..., ancl[1]]
        trgt2 = trgt
        circ2 = _controlx_decompose!(Circuit(), ctrl2, trgt2, free2)
        # equivalent to
        #circ2 = push!(Circuit(), Control(length(qctrl2), GateX()), ctrl2..., trgt2)

        append!(circ, circ1)
        append!(circ, circ2)
        append!(circ, circ1)
        append!(circ, circ2)
    else
        # just in the case that there are no free qubits
        _control_recursive_decompose!(circ, Control(ctrl, GateX()), ctrl..., trgt)
    end

    return circ
end

# recursive decomposition according to Lemma 7.5 of [1]
function _control_recursive_decompose!(circ::Circuit, control::Control{N,1}, qtargets) where {N}
    V = Power(getoperation(control), 1 // 2)
    Vdag = inverse(V)

    push!(circ, Control(1, V), qtargets[end-1:end]...)

    _controlx_decompose!(circ, qtargets[1:N-1], qtargets[N], qtargets[end:end])
    #push!(circ, Control(N - 1, GateX()), qtargets[1:N]...)

    push!(circ, Control(1, Vdag), qtargets[end-1:end]...)

    _controlx_decompose!(circ, qtargets[1:N-1], qtargets[N], qtargets[end:end])
    #push!(circ, Control(N - 1, GateX()), qtargets[1:N]...)

    newtargets = [qtargets[1:end-2]..., qtargets[end]]

    if N == 2
        push!(circ, Control(N - 1, V), newtargets...)
    else
        _control_recursive_decompose!(circ, Control(N - 1, V), newtargets)
    end
end

function _control_recursive_decompose!(circ::Circuit, control::Control{1}, qtargets)
    push!(circ, control, qtargets...)
end

function decompose!(circ::Circuit, control::Control{N}, qtargets, _, _) where {N}
    ncontrols = N
    op = getoperation(control)
    ntargets = numqubits(op)

    controls = qtargets[1:ncontrols]
    targets = qtargets[end-ntargets+1:end]

    if ntargets != 1 || ncontrols == 1
        # do not decompose the control gates, but just decompose the internal
        # gate and then apply the resulting gates with controls
        newcirc = decompose!(Circuit(), op, targets, [], [])

        for inst in newcirc
            push!(circ, Control(N, getoperation(inst)), controls..., getqubits(inst)...)
        end
    else
        _control_recursive_decompose!(circ, control, qtargets)
    end

    return circ
end

