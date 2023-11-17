# MimiqCircuitsBase.jl Documentation

## Overview

MimiqCircuitsBase provides a framework to build, manipulate, and analyze quantum
circuits.

## Quick Start

This is an example on how to build a GHZ state preparation circuit with
MimiqCircuitsBase. It has to be noted that this is not the optimal way to do it,
but it is used here to showcase the syntax of MimiqCircuitsBase.

```@meta
DocTestSetup = quote
    using MimiqCircuitsBase
end
```

```jldoctest
julia> c = Circuit()
empty circuit

julia> push!(c, GateH(), 1)
1-qubit circuit with 1 instructions:
└── H @ q1

julia> push!(c, GateCX(), 1, 2:4)
4-qubit circuit with 4 instructions:
├── H @ q1
├── CX @ q1, q2
├── CX @ q1, q3
└── CX @ q1, q4

julia> push!(c, Barrier, 1:4...)
4-qubit circuit with 5 instructions:
├── H @ q1
├── CX @ q1, q2
├── CX @ q1, q3
├── CX @ q1, q4
└── Barrier @ q1, q2, q3, q4

julia> for i in 1:4
           push!(c, Measure(), i, i)
       end

julia> c
4-qubit circuit with 9 instructions:
├── H @ q1
├── CX @ q1, q2
├── CX @ q1, q3
├── CX @ q1, q4
├── Barrier @ q1, q2, q3, q4
├── Measure @ q1, c1
├── Measure @ q2, c2
├── Measure @ q3, c3
└── Measure @ q4, c4
```

```@meta
DocTestSetup = nothing
```
