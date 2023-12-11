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

```@repl
julia> c = Circuit()
empty circuit

julia> push!(c, GateH(), 1)
1-qubit circuit with 1 instructions:
└── H @ q[1]

julia> push!(c, GateCX(), 1, 2:4)
4-qubit circuit with 4 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── CX @ q[1], q[3]
└── CX @ q[1], q[4]

julia> push!(c, Barrier(1), 1:4)
4-qubit circuit with 8 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── CX @ q[1], q[3]
├── CX @ q[1], q[4]
├── Barrier @ q[1]
├── Barrier @ q[2]
├── Barrier @ q[3]
└── Barrier @ q[4]

julia> for i in 1:4
           push!(c, Measure(), i, i)
       end

julia> c
4-qubit circuit with 12 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── CX @ q[1], q[3]
├── CX @ q[1], q[4]
├── Barrier @ q[1]
├── Barrier @ q[2]
├── Barrier @ q[3]
├── Barrier @ q[4]
├── Measure @ q[1], c[1]
├── Measure @ q[2], c[2]
├── Measure @ q[3], c[3]
└── Measure @ q[4], c[4]
```

```@meta
DocTestSetup = nothing
```
