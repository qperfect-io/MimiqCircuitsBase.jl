# Installation instructions

Julia is required to use `MimiqCircuitsBase.jl`. If you do not have it on your
system, please refer to the [official website](https://julialang.org). We
recommend to install Julia via the [juliaup
tool](https://github.com/julialang/juliaup#installation), which will manage
updates and multiple versions of Julia on the same system automatically.

To install the latest version of `MimiqCircuitsBase.jl`, use the Julia's
built-in package manager (accessed by pressing `]` in the Julia REPL command
prompt).

Before installing the package itself, since we didn't add it to the public
Julia General registry, make sure to have installed QPerfect's own package
registry.

```julia
julia> ]
(v1.9) pkg> registry update
(v1.9) pkg> registry add https://github.com/qperfect-io/QPerfectRegistry.git
(v1.9) pkg> add MimiqCircuitsBase
```

!!! note
    The `] registry update` command will make sure, if this is your first time
    starting up Julia, to install and download the Julia General registry,
    where most packages are registered.

