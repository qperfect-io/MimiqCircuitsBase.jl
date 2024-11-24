# MimiqCircuitsBase.jl

Part of MIMIQ by [QPerfect](https://qperfect.io).

This core library provides all the functionalities to build and manage quantum algorithms as quantum circuits.

## Examples

### GHZ state and Expectation Values

The following code

```julia
using MimiqCircuitsBase

c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2:10)
push!(c, ExpectationValue(GateZ()), 1, 1)
push!(c, Measure(), 1:10, 1:10-)
draw(c)
````

will output

```
        ┌─┐                           ┌───┐┌─┐
q[1]:  ╶┤H├─●──●──●──●──●──●──●──●──●─┤⟨Z⟩├┤M├───────────────────────────╴
        └─┘┌┴┐ │  │  │  │  │  │  │  │ └─╥─┘└╥┘┌─┐
q[2]:  ╶───┤X├─┼──┼──┼──┼──┼──┼──┼──┼───╫───╫─┤M├────────────────────────╴
           └─┘┌┴┐ │  │  │  │  │  │  │   ║   ║ └╥┘┌─┐
q[3]:  ╶──────┤X├─┼──┼──┼──┼──┼──┼──┼───╫───╫──╫─┤M├─────────────────────╴
              └─┘┌┴┐ │  │  │  │  │  │   ║   ║  ║ └╥┘┌─┐
q[4]:  ╶─────────┤X├─┼──┼──┼──┼──┼──┼───╫───╫──╫──╫─┤M├──────────────────╴
                 └─┘┌┴┐ │  │  │  │  │   ║   ║  ║  ║ └╥┘┌─┐
q[5]:  ╶────────────┤X├─┼──┼──┼──┼──┼───╫───╫──╫──╫──╫─┤M├───────────────╴
                    └─┘┌┴┐ │  │  │  │   ║   ║  ║  ║  ║ └╥┘┌─┐
q[6]:  ╶───────────────┤X├─┼──┼──┼──┼───╫───╫──╫──╫──╫──╫─┤M├────────────╴
                       └─┘┌┴┐ │  │  │   ║   ║  ║  ║  ║  ║ └╥┘┌─┐
q[7]:  ╶──────────────────┤X├─┼──┼──┼───╫───╫──╫──╫──╫──╫──╫─┤M├─────────╴
                          └─┘┌┴┐ │  │   ║   ║  ║  ║  ║  ║  ║ └╥┘┌─┐
q[8]:  ╶─────────────────────┤X├─┼──┼───╫───╫──╫──╫──╫──╫──╫──╫─┤M├──────╴
                             └─┘┌┴┐ │   ║   ║  ║  ║  ║  ║  ║  ║ └╥┘┌─┐
q[9]:  ╶────────────────────────┤X├─┼───╫───╫──╫──╫──╫──╫──╫──╫──╫─┤M├───╴
                                └─┘┌┴┐  ║   ║  ║  ║  ║  ║  ║  ║  ║ └╥┘┌─┐
q[10]: ╶───────────────────────────┤X├──╫───╫──╫──╫──╫──╫──╫──╫──╫──╫─┤M├╴
                                   └─┘  ║   ║  ║  ║  ║  ║  ║  ║  ║  ║ └╥┘
                                        ║   ║  ║  ║  ║  ║  ║  ║  ║  ║  ║
c:     ═════════════════════════════════╬═══╩══╩══╩══╩══╩══╩══╩══╩══╩══╩═
                                        ║   1  2  3  4  5  6  7  8  9  10
z:     ═════════════════════════════════╩════════════════════════════════
                                        1
```

### Quantum Fourier Transform and inverse

The following code

```julia
c = push!(Circuit(), QFT(10), 1:10...)
push!(c, Barrier(10), 1:10...)
push!(c, inverse(QFT(10)), 1:10...)
draw(c)
```

will output

```
        ┌──────┐░┌───────┐
q[1]:  ╶┤1     ├░┤1      ├╴
        │      │░│       │
q[2]:  ╶┤2     ├░┤2      ├╴
        │      │░│       │
q[3]:  ╶┤3     ├░┤3      ├╴
        │      │░│       │
q[4]:  ╶┤4     ├░┤4      ├╴
        │      │░│       │
q[5]:  ╶┤5     ├░┤5      ├╴
        │   QFT│░│   QFT†│
q[6]:  ╶┤6     ├░┤6      ├╴
        │      │░│       │
q[7]:  ╶┤7     ├░┤7      ├╴
        │      │░│       │
q[8]:  ╶┤8     ├░┤8      ├╴
        │      │░│       │
q[9]:  ╶┤9     ├░┤9      ├╴
        │      │░│       │
q[10]: ╶┤10    ├░┤10     ├╴
        └──────┘░└───────┘
```
### Teleportation

```julia
c = push!(cirtcuit(), GateH(), [1,2])
push!(c, GateT(), 2)
push!(c, GateCX(), 1, 2)
push!(c, Measure(), 1, 1)
push!(c, IfStatement(GateS(), bs"1"), 1, 1)
```

```
       ┌─┐                     ┌─┐
q[1]: ╶┤H├───────●─────────────┤S├
       └─┘┌─┐┌─┐┌┴┐┌─┐         └╥┘
q[2]: ╶───┤H├┤T├┤X├┤M├──────────╫─
          └─┘└─┘└─┘└╥┘          ║
                    ║ ┌───────┐○╝
c:    ══════════════╩═│c[1]==1│═══
                    1 └───────┘
```


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

