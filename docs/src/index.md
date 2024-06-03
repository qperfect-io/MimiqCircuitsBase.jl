# MimiqCircuitsBase.jl Documentation

## Overview

MimiqCircuitsBase provides a framework to build, manipulate, and analyze quantum
circuits.

## Quick Start

This is an example on how to build a GHZ state preparation circuit with
MimiqCircuitsBase. It has to be noted that this is not the optimal way to do it,
but it is used here to showcase the syntax of MimiqCircuitsBase.

```@repl
using MimiqCircuitsBase
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2:4)
push!(c, Barrier(1), 1:4)
for i in 1:4
    push!(c, Measure(), i, i)
end
c
```
