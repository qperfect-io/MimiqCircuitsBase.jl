# MimiqCircuitsBase.jl

[![Build Status](https://github.com/qperfect-io/MimiqCircuitsBase.jl/workflows/CI/badge.svg)](https://github.com/qperfect-io/MimiqCircuitsBase.jl/actions)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.qperfect.io/MimiqCircuits.jl/stable/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

**MimiqCircuitsBase.jl** is the core library for building and managing quantum circuits in the MIMIQ ecosystem. It provides fundamental data structures, gate definitions, and circuit manipulation tools that form the foundation of QPerfect's MIMIQ Virtual Quantum Computer.

Part of the [MIMIQ](https://qperfect.io) ecosystem by [QPerfect](https://qperfect.io).

## Overview

This library provides all the essential building blocks for quantum algorithm development:

- 🎯 **Comprehensive gate library** including standard gates, generalized operations, and custom gates
- 🔧 **Circuit construction** with intuitive API for building complex quantum algorithms
- 🎨 **ASCII and Unicode visualization** for circuit diagrams
- 📊 **Measurements and observables** including expectation values
- 🔄 **Circuit transformations** such as inverse, decomposition, and swap removal
- 🧮 **Classical control flow** with if-statements and conditional operations
- 🚧 **Barriers and annotations** for circuit organization

## Installation

Add the QPerfect registry first:

```julia
using Pkg
Pkg.Registry.add("General")
Pkg.Registry.add(RegistrySpec(url="https://github.com/qperfect-io/QPerfectRegistry.git"))
```

Then install the package:

```julia
Pkg.add("MimiqCircuitsBase")
```

> **Note:** Most users should install [MimiqCircuits.jl](https://github.com/qperfect-io/MimiqCircuits.jl) which includes this package and provides remote execution capabilities on the MIMIQ Cloud Services.

## Quick Examples

### Basic Circuit Construction

```julia
using MimiqCircuitsBase

# Create a simple entanglement circuit
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2)
push!(c, Measure(), 1:2, 1:2)

# Visualize the circuit
draw(c)
```

**Output:**

```
      ┌─┐   ┌─┐
q[1]: ┤H├─●─┤M├───
      └─┘┌┴┐└╥┘┌─┐
q[2]: ───┤X├─╫─┤M├
         └─┘ ║ └╥┘
   c:════════╩══╩═
             1  2
```

### Multi-Qubit Gates and Control

```julia
using MimiqCircuitsBase

c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2:10)  # Apply CX to qubit 1 and qubits 2-10
push!(c, ExpectationValue(GateZ()), 1, 1)
push!(c, Measure(), 1:10, 1:10)

draw(c)
```

**Output:**

```
      ┌─┐                           ┌───┐┌─┐
q[1]: ┤H├─●──●──●──●──●──●──●──●──●─┤⟨Z⟩├┤M├──────
      └─┘┌┴┐ │  │  │  │  │  │  │  │ └─╥─┘└╥┘┌─┐
q[2]: ───┤X├─┼──┼──┼──┼──┼──┼──┼──┼───╫───╫─┤M├───
         └─┘┌┴┐ │  │  │  │  │  │  │   ║   ║ └╥┘┌─┐
q[3]: ──────┤X├─┼──┼──┼──┼──┼──┼──┼───╫───╫──╫─┤M├
            └─┘┌┴┐ │  │  │  │  │  │   ║   ║  ║ └╥┘
...
```

### Quantum Algorithms

```julia
using MimiqCircuitsBase

# Quantum Fourier Transform
c = Circuit()
push!(c, QFT(10), 1:10...)
push!(c, Barrier(10), 1:10...)
push!(c, inverse(QFT(10)), 1:10...)

draw(c)
```

**Output:**

```
      ┌──────┐░┌───────┐
q[1]: ┤1     ├░┤1      ├
      │      │░│       │
q[2]: ┤2     ├░┤2      ├
      │      │░│       │
q[3]: ┤3     ├░┤3      ├
      │  QFT │░│  QFT† │
...
      │      │░│       │
q[10]:┤10    ├░┤10     ├
      └──────┘░└───────┘
```

### Conditional Operations

```julia
using MimiqCircuitsBase

c = Circuit()
push!(c, GateH(), [1, 2])
push!(c, GateT(), 2)
push!(c, GateCX(), 1, 2)
push!(c, Measure(), 1, 1)
push!(c, IfStatement(GateS(), bs"1"), 1, 1)  # Apply S gate if measurement is 1

draw(c)
```

**Output:**

```
      ┌─┐                     ┌─┐
q[1]: ┤H├───────●─────────────┤S├
      └─┘┌─┐┌─┐┌┴┐┌─┐         └╥┘
q[2]: ───┤H├┤T├┤X├┤M├──────────╫─
         └─┘└─┘└─┘└╥┘          ║
                   ║ ┌───────┐○╝
   c: ═════════════╩═│c[1]==1│═══
                   1 └───────┘
```

## Available Gates and Operations

### Standard Quantum Gates

- Single-qubit: `GateH`, `GateX`, `GateY`, `GateZ`, `GateS`, `GateT`, `GateRX`, `GateRY`, `GateRZ`, `GateU`
- Two-qubit: `GateCX` (CNOT), `GateCY`, `GateCZ`, `GateCH`, `GateSWAP`, `GateISWAP`
- Three-qubit: `GateCCX` (Toffoli), `GateCSWAP` (Fredkin)
- Multi-controlled: `GateCU`, `GateCRX`, `GateCRY`, `GateCRZ`

### Generalized Operations

- `QFT` - Quantum Fourier Transform
- `PhaseGradient` - Phase gradient gate
- `PolynomialOracle` - Polynomial phase oracle
- Custom gates and power operations

### Measurements and Observables

- `Measure` - Computational basis measurement
- `ExpectationValue` - Expectation value of observables
- `MeasureXX`, `MeasureYY`, `MeasureZZ` - Pauli basis measurements

### Noise and Decoherence

- `Depolarizing` - Depolarizing channel
- `Dephasing` - Phase damping
- `AmplitudeDamping` - Amplitude damping
- `PauliNoise` - General Pauli noise
- `ThermalNoise` - Thermal relaxation

### Circuit Control

- `Barrier` - Prevent gate reordering
- `IfStatement` - Conditional operations based on classical bits
- `Reset` - Reset qubits to |0⟩ state

## Documentation

For complete documentation, visit the [MimiqCircuits.jl documentation](https://docs.qperfect.io/MimiqCircuits.jl/stable/) which includes comprehensive guides for MimiqCircuitsBase.

## Related Packages

- **[MimiqCircuits.jl](https://github.com/qperfect-io/MimiqCircuits.jl)** - Main package with remote execution capabilities (includes this package)
- **[MimiqLink.jl](https://github.com/qperfect-io/MimiqLink.jl)** - Connection and authentication for MIMIQ Cloud Services
- **[mimiqcircuits-python](https://github.com/qperfect-io/mimiqcircuits-python)** - Python equivalent of this library

## Contributing

We welcome contributions! Whether it's:

- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🔧 Code contributions

Please open an issue or pull request on GitHub.

## Support

- 📧 Email: <mimiq.support@qperfect.io>
- 🐛 Issues: [GitHub Issues](https://github.com/qperfect-io/MimiqCircuitsBase.jl/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/qperfect-io/MimiqCircuits.jl/discussions)

## COPYRIGHT

Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
Copyright © 2023-2024 QPerfect. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
