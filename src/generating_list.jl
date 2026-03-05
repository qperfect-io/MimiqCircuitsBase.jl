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

mutable struct InheritanceTree
    base_type::Type
    class_tree::Dict{Symbol,Vector{Symbol}}
    roots::Vector{Symbol}
end

function InheritanceTree(base_type::Type)
    InheritanceTree(base_type, Dict{Symbol,Vector{Symbol}}(), Symbol[])
end

function _walk!(tree::InheritanceTree, ptype::Type)
    for subtype in subtypes(ptype)
        (subtype isa DataType || subtype isa UnionAll) || continue
        T = Base.unwrap_unionall(subtype)
        name = nameof(T)
        parent = nameof(Base.unwrap_unionall(supertype(T)))
        name == parent && continue
        push!(get!(tree.class_tree, parent, Symbol[]), name)
        _walk!(tree, subtype)
    end
end

function extract_classes!(tree::InheritanceTree, mod::Module)
    # walk declared subtypes
    _walk!(tree, tree.base_type)

    haskey(tree.class_tree, nameof(tree.base_type)) || push!(tree.roots, nameof(tree.base_type))

    # get alias consts like: const GateCP = typeof(Control(GateP(π)))
    for alias in names(mod; all=true, imported=true)
        isdefined(mod, alias) || continue
        binding = try
            getfield(mod, alias)
        catch
            continue
        end
        (binding isa DataType && binding <: tree.base_type) || continue

        # use the CONST name: :GateCP, :GateCRX, :GateS, ...
        child = alias

        # skip obvious buckets/base
        if child in (:AbstractGate, nameof(tree.base_type))
            continue
        end

        T = Base.unwrap_unionall(binding)

        # detect nearest parent by *type
        parent =
            (isdefined(mod, :Control) && T <: getfield(mod, :Control)) ? :Control :
            (isdefined(mod, :Power) && T <: getfield(mod, :Power)) ? :Power :
            (isdefined(mod, :Inverse) && T <: getfield(mod, :Inverse)) ? :Inverse :
            nameof(Base.unwrap_unionall(supertype(T)))

        push!(get!(tree.class_tree, parent, Symbol[]), child)
    end

    # tidy in case
    for k in keys(tree.class_tree)
        unique!(tree.class_tree[k])
        sort!(tree.class_tree[k]; by=String)
    end
end

function print_tree(tree::InheritanceTree; indent::String="", root::Union{Nothing,Symbol}=nothing, last::Bool=true)
    if root === nothing
        root = !isempty(tree.roots) ? tree.roots[1] : nameof(tree.base_type)
    end

    println(indent * (last ? "└── " : "├── ") * string(root))

    children = get(tree.class_tree, root, Symbol[])
    for (i, child) in enumerate(children)
        is_last = i == length(children)
        print_tree(tree;
            indent=indent * (last ? "    " : "│   "),
            root=child,
            last=is_last
        )
    end
end

@doc raw"""
    show_mimiq_hierarchy()
    show_mimiq_hierarchy([type])
    show_mimiq_hierarchy([type, [module]])

Show an hierarchy of the MIMIQ `type` and its subtypes.

!!! note
    Restrictted to `type <: Operation` types

```jldoctests
julia> show_mimiq_hierarchy()
└── Operation
    ├── AbstractAnnotation
    │   ├── Detector
    │   ├── ObservableInclude
    │   ├── QubitCoordinates
    │   ├── ShiftCoordinates
    │   └── Tick
    ├── AbstractClassical
    │   ├── And
    │   ├── Not
    │   ├── Or
    │   ├── ParityCheck
    │   ├── SetBit0
    │   ├── SetBit1
    │   └── Xor
    ├── AbstractKrausChannel
    │   ├── AmplitudeDamping
    │   ├── Depolarizing
    │   ├── Depolarizing1
    │   ├── Depolarizing2
    │   ├── GeneralizedAmplitudeDamping
    │   ├── Kraus
    │   ├── MixedUnitary
    │   ├── PauliNoise
    │   ├── PauliX
    │   ├── PauliY
    │   ├── PauliZ
    │   ├── PhaseAmplitudeDamping
    │   ├── ProjectiveNoiseX
    │   ├── ProjectiveNoiseY
    │   ├── ProjectiveNoiseZ
    │   ├── Reset
    │   ├── ResetX
    │   ├── ResetY
    │   ├── ResetZ
    │   └── ThermalNoise
    ├── AbstractMeasurement
    │   ├── Measure
    │   ├── MeasureReset
    │   ├── MeasureResetX
    │   ├── MeasureResetY
    │   ├── MeasureResetZ
    │   ├── MeasureX
    │   ├── MeasureXX
    │   ├── MeasureY
    │   ├── MeasureYY
    │   ├── MeasureZ
    │   └── MeasureZZ
    ├── AbstractOperator
    │   ├── AbstractGate
    │   │   ├── Control
    │   │   │   ├── GateC3X
    │   │   │   ├── GateCCP
    │   │   │   ├── GateCCX
    │   │   │   ├── GateCH
    │   │   │   ├── GateCP
    │   │   │   ├── GateCRX
    │   │   │   ├── GateCRY
    │   │   │   ├── GateCRZ
    │   │   │   ├── GateCS
    │   │   │   ├── GateCSDG
    │   │   │   ├── GateCSWAP
    │   │   │   ├── GateCSX
    │   │   │   ├── GateCSXDG
    │   │   │   ├── GateCU
    │   │   │   ├── GateCX
    │   │   │   ├── GateCY
    │   │   │   └── GateCZ
    │   │   ├── Delay
    │   │   ├── Diffusion
    │   │   ├── GateCall
    │   │   ├── GateCustom
    │   │   ├── GateDCX
    │   │   ├── GateECR
    │   │   ├── GateH
    │   │   ├── GateHXY
    │   │   ├── GateHXZ
    │   │   ├── GateHYZ
    │   │   ├── GateID
    │   │   ├── GateISWAP
    │   │   ├── GateP
    │   │   ├── GateR
    │   │   ├── GateRNZ
    │   │   ├── GateRX
    │   │   ├── GateRXX
    │   │   ├── GateRY
    │   │   ├── GateRYY
    │   │   ├── GateRZ
    │   │   ├── GateRZX
    │   │   ├── GateRZZ
    │   │   ├── GateSWAP
    │   │   ├── GateU
    │   │   ├── GateU1
    │   │   ├── GateU2
    │   │   ├── GateU3
    │   │   ├── GateX
    │   │   ├── GateXXminusYY
    │   │   ├── GateXXplusYY
    │   │   ├── GateY
    │   │   ├── GateZ
    │   │   ├── Inverse
    │   │   │   ├── GateISWAPDG
    │   │   │   ├── GateSDG
    │   │   │   ├── GateSXDG
    │   │   │   ├── GateSYDG
    │   │   │   └── GateTDG
    │   │   ├── Parallel
    │   │   ├── PauliString
    │   │   ├── PhaseGradient
    │   │   ├── PolynomialOracle
    │   │   ├── Power
    │   │   │   ├── GateS
    │   │   │   ├── GateSX
    │   │   │   ├── GateSY
    │   │   │   └── GateT
    │   │   ├── QFT
    │   │   └── RPauli
    │   ├── DiagonalOp
    │   ├── Operator
    │   ├── Projector0
    │   ├── Projector00
    │   ├── Projector01
    │   ├── Projector1
    │   ├── Projector10
    │   ├── Projector11
    │   ├── ProjectorX0
    │   ├── ProjectorX1
    │   ├── ProjectorY0
    │   ├── ProjectorY1
    │   ├── ProjectorZ0
    │   ├── ProjectorZ1
    │   ├── RescaledGate
    │   ├── SigmaMinus
    │   └── SigmaPlus
    ├── Add
    ├── Amplitude
    ├── Barrier
    ├── Block
    ├── BondDim
    ├── ExpectationValue
    ├── IfStatement
    ├── Multiply
    ├── Pow
    ├── ReadoutErr
    ├── Repeat
    ├── SchmidtRank
    └── VonNeumannEntropy
```
"""
function show_mimiq_hierarchy(base_type::Type{<:Operation}=Operation, mod::Module=parentmodule(base_type))
    tree = InheritanceTree(base_type)
    extract_classes!(tree, mod)
    print_tree(tree)
    return nothing
end
