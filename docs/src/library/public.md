# Public Documentation

Documentation for `MimiqCircuitsBase.jl`'s public interface.

See the Internals section of the manual for internal package docs.

## MimiqCircuitsBase

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["MimiqCircuitsBase.jl"]
```

## General functions

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["abstract.jl", "docstrings.jl", "evaluate.jl"]
```

## Quantum Circuits and Instructions

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["instruction.jl", "circuit.jl", "circuit_extras.jl", "circuit_macro.jl"]
```

## Operations

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["operation.jl"]
```

### Decompositions

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["decompose.jl"]
```

### Gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["gate.jl"]
```

#### Wrappers

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = [
    "operations/control.jl",
    "operations/inverse.jl",
    "operations/power.jl",
    "operations/parallel.jl",
    "operations/ifstatement.jl",
]
```

#### Global phase

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = [
    "operations/gphase.jl"
]
```

#### Standard Gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = [
    "operations/gates/standard/u.jl",
    "operations/gates/standard/phase.jl",
    "operations/gates/standard/deprecated.jl",
    "operations/gates/standard/pauli.jl",
    "operations/gates/standard/hadamard.jl",
    "operations/gates/standard/id.jl",
    "operations/gates/standard/s.jl",
    "operations/gates/standard/t.jl",
    "operations/gates/standard/sx.jl",
    "operations/gates/standard/rotations.jl",
    "operations/gates/standard/swap.jl",
    "operations/gates/standard/iswap.jl",
    "operations/gates/standard/cpauli.jl",
    "operations/gates/standard/chadamard.jl",
    "operations/gates/standard/cs.jl",
    "operations/gates/standard/csx.jl",
    "operations/gates/standard/cu.jl",
    "operations/gates/standard/cphase.jl",
    "operations/gates/standard/crotations.jl",
    "operations/gates/standard/ecr.jl",
    "operations/gates/standard/dcx.jl",
    "operations/gates/standard/interactions.jl",
    "operations/gates/standard/cswap.jl",
    "operations/gates/standard/cnx.jl",
    "operations/gates/standard/cnp.jl",
]
```

#### Custom gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["custom.jl"]
```

#### Generalized gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = [
    "operations/generalized/qft.jl",
    "operations/generalized/phasegradient.jl",
    "operations/generalized/polynomialoracle.jl",
    "operations/generalized/diffusion.jl",
]
```

### Gate definitions

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["gatedecl.jl"]
```

### Non-unitary operations

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["reset.jl", "measure.jl"]
```

### No-ops

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["barrier.jl"]
```

## Bit Strings

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["bitstrings.jl"]
```

