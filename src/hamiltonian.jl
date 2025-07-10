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


@doc raw"""
    HamiltonianTerm(coefficient, pauli, qubits...)

A single term in a quantum Hamiltonian consisting of a real coefficient and a tensor product of Pauli operators.

Each `HamiltonianTerm` represents an operator of the form:

```math
H_j = c_j \cdot P_j = c_j \cdot \left(P^{(1)} \otimes P^{(2)} \otimes \dots \right)
```
where c_j is a real-valued scalar and P_j is a Pauli string (e.g., "XZ") acting on specific qubits.

See also: [`Hamiltonian`](@ref), [`PauliString`](@ref)

## Examples

```jldoctests
julia> HamiltonianTerm(0.5, PauliString("XZ"), 1, 2)
0.5 * XZ @ q[1:2]
```
"""
struct HamiltonianTerm{N}
    coefficient::Float64
    pauli::PauliString
    qubits::NTuple{N,Int}

    HamiltonianTerm(coefficient::Float64, pauli::PauliString{N}, qubits::Vararg{Int,N}) where {N} = begin
        if any(q -> q < 1, qubits)
            throw(ArgumentError("Target qubits must be positive and >=1"))
        elseif length(unique(qubits)) != length(qubits)
            throw(ArgumentError("Duplicate qubits are not allowed: $qubits"))
        end
        new{N}(coefficient, pauli, qubits)
    end

end

getoperation(h::HamiltonianTerm) = h.pauli
getcoefficient(h::HamiltonianTerm) = h.coefficient
getqubits(h::HamiltonianTerm) = h.qubits

function Base.show(io::IO, m::MIME"text/plain", h::HamiltonianTerm)
    space = get(io, :compact, false) ? "" : " "
    op = getoperation(h)
    print(io, "$(getcoefficient(h))$space*$space")
    let io1 = IOContext(io, :compact => true)
        show(io1, m, op)
    end
    print(io, "$space@$space")
    ps = _partition(getqubits(h), cumsum(qregsizes(op)))
    join(io, map(x -> "q" * _string_with_square(_findunitrange(x), ","), ps), ",$space")
end


@doc raw"""
    Hamiltonian()

Constructs a quantum Hamiltonian composed of a sum of `HamiltonianTerm`s.

The full Hamiltonian is expressed as:

```math
H = \sum_j c_j \cdot P_j
```
where each term consists of a real coefficient c_j and a Pauli string P_j
acting on a subset of qubits.

See also: [`Hamiltonian`](@ref), [`PauliString`](@ref)

## Examples

```jldoctests
julia> h = Hamiltonian()
empty hamiltonian

julia> push!(h, 1.0, PauliString("XX"), 1, 2)
2-qubit hamiltonian with 1 terms:
+
└── 1.0 * XX @ q[1:2]

julia> push!(h, 0.5, PauliString("Z"), 2)
2-qubit hamiltonian with 2 terms:
+
├── 1.0 * XX @ q[1:2]
└── 0.5 * Z @ q[2]

```
"""
struct Hamiltonian
    terms::Vector{HamiltonianTerm}
end
Hamiltonian() = Hamiltonian(HamiltonianTerm[])

function numqubits(h::Hamiltonian)
    isempty(h.terms) && return 0
    return maximum(Iterators.map(g -> maximum(getqubits(g), init=0), h.terms))
end

function Base.push!(h::Hamiltonian, term::HamiltonianTerm)
    push!(h.terms, term)
    return h
end

function Base.push!(h::Hamiltonian, coeff::Float64, pauli::PauliString, qubits...)
    push!(h, HamiltonianTerm(coeff, pauli, qubits...))
    return h
end

function add_terms!(h::Hamiltonian, terms::HamiltonianTerm...)
    append!(h.terms, terms)
    return h
end

function _paulichar_matrix(p::Char)
    if p == 'I'
        return _matrix(GateID)
    elseif p == 'X'
        return _matrix(GateX)
    elseif p == 'Y'
        return _matrix(GateY)
    elseif p == 'Z'
        return _matrix(GateZ)
    else
        throw(ArgumentError("Invalid Pauli character: $p"))
    end
end

function matrix(h::Hamiltonian)
    nq = numqubits(h)
    dim = 2^nq
    mat = zeros(ComplexF64, dim, dim)

    for term in h.terms
        coeff = getcoefficient(term)
        qubits = collect(getqubits(term))

        ps = sortperm(qubits)
        qubits = qubits[ps]
        pstr = pstring(getoperation(term))[ps]

        term_mat, qidx = if qubits[1] == 1
            _paulichar_matrix(pstr[1]), 2
        else
            _paulichar_matrix('I'), 1
        end

        i = 2
        while qidx <= length(qubits)
            while i < qubits[qidx]
                term_mat = kron(term_mat, _paulichar_matrix('I'))
                i += 1
            end
            term_mat = kron(term_mat, _paulichar_matrix(pstr[qidx]))
            i += 1
            qidx += 1
        end

        for _ in i:nq
            term_mat = kron(term_mat, _paulichar_matrix('I'))
        end

        mat .+= coeff * term_mat
    end

    return mat
end

function Base.show(io::IO, m::MIME"text/plain", c::Hamiltonian)
    compact = get(io, :compact, false)
    rows, _ = displaysize(io)
    n = length(c)
    if !compact && !isempty(c)
        println(io, "$(numqubits(c))-qubit hamiltonian with $(n) terms:")
        println(io, "+")

        if rows - 4 <= 0
            print(io, "└── ...")
        elseif rows - 4 >= n
            for g in c.terms[1:end-1]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end
            print(io, "└── ")
            show(io, m, c.terms[end])
        else
            chunksize = div(rows - 6, 2)

            for g in c.terms[1:chunksize]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end

            println(io, "⋮   ⋮")

            for g in c.terms[end-chunksize:end-1]
                print(io, "├── ")
                show(io, m, g)
                print(io, '\n')
            end

            print(io, "└── ")
            show(io, m, c.terms[end])
        end
    else
        if isempty(c)
            print(io, "empty hamiltonian")
        else
            print(io, "$(numqubits(c))-qubit hamiltonian with $(length(c)) terms")
        end
    end

    nothing
end

Base.iterate(h::Hamiltonian) = iterate(h.terms)
Base.iterate(h::Hamiltonian, state) = iterate(h.terms, state)
Base.firstindex(h::Hamiltonian) = firstindex(h.terms)
Base.lastindex(h::Hamiltonian) = lastindex(h.terms)
Base.length(h::Hamiltonian) = length(h.terms)
Base.isempty(h::Hamiltonian) = isempty(h.terms)
Base.getindex(h::Hamiltonian, i::Integer) = getindex(h.terms, i)
Base.getindex(h::Hamiltonian, i) = Hamiltonian(getindex(h.terms, i))
Base.eltype(::Hamiltonian) = Instruction


@doc raw"""
    push_expval!(circuit, hamiltonian, qubits...; firstzvar=...)

Pushes an expectation value estimation circuit for a given Hamiltonian.

This operation measures the expectation value of a Hamiltonian and stores
the result in a Z-register, combining the contributions of individual Pauli term
evaluations.

For each term ``c_j P_j``, the circuit performs:

```math
\langle \psi | c_j P_j | \psi \rangle
```
## Examples

 ```jldoctests
julia> h = Hamiltonian()
empty hamiltonian

julia> push!(h, 0.7, PauliString("X"), 1)
1-qubit hamiltonian with 1 terms:
+
└── 0.7 * X @ q[1]

julia> push!(h, -0.3, PauliString("Z"), 1)
1-qubit hamiltonian with 2 terms:
+
├── 0.7 * X @ q[1]
└── -0.3 * Z @ q[1]

julia> c = Circuit()
empty circuit

julia> push_expval!(c, h, 1)
1-qubit, 2-vars circuit with 5 instructions:
├── ⟨X⟩ @ q[1], z[1]
├── z[1] *= 0.7
├── ⟨Z⟩ @ q[1], z[2]
├── z[2] *= -0.3
└── z[1] += z[2]
```
"""
function push_expval!(circ::Circuit, hamiltonian, qubits...; firstzvar=numzvars(circ) + 1)
    if length(qubits) != numqubits(hamiltonian)
        throw(ArgumentError("Number of qubits does not match Hamiltonian"))
    end

    zvar = copy(firstzvar)
    for term in hamiltonian
        push!(circ, ExpectationValue(getoperation(term)), [qubits[i] for i in getqubits(term)]..., zvar)
        push!(circ, Multiply(1, getcoefficient(term)), zvar)
        zvar += 1
    end

    push!(circ, Add(zvar - firstzvar), firstzvar:zvar-1...)
    return circ
end

function _pauliexp(g::HamiltonianTerm, t, qubits::Tuple)
    p = getoperation(g)
    s = pstring(p)

    param = getcoefficient(g) * t

    if s == "X"
        return Instruction(GateRX(param), qubits, (), ())
    elseif s == "Y"
        return Instruction(GateRY(param), qubits, (), ())
    elseif s == "Z"
        return Instruction(GateRZ(param), qubits, (), ())
    elseif s == "XX"
        return Instruction(GateRXX(param), qubits, (), ())
    elseif s == "YY"
        return Instruction(GateRYY(param), qubits, (), ())
    elseif s == "ZZ"
        return Instruction(GateRZZ(param), qubits, (), ())
    elseif s == "ZX"
        return Instruction(GateRZX(param), qubits, (), ())
    elseif s == "XZ"
        return Instruction(GateRZX(param), reverse(qubits), (), ())
    else
        return Instruction(RPauli(p, param), qubits, (), ())
    end
end

@doc raw"""
    push_lietrotter!(circuit, qubits, hamiltonian, t, steps)

Adds a Lie-Trotter expansion of the Hamiltonian `hamiltonian` to the circuit `circuit` for the qubits `qubits` over time `t` with `steps` steps.

The Lie-Trotter expansion is a method for approximating the time evolution operator of a Hamiltonian. It is particularly useful for simulating quantum systems.

## Examples

```jldoctests
julia> h = Hamiltonian()
empty hamiltonian

julia> push!(h, 1.0, PauliString("XX"), 1, 2)
2-qubit hamiltonian with 1 terms:
+
└── 1.0 * XX @ q[1:2]

julia> c = Circuit()
empty circuit

julia> push_lietrotter!(c, (1, 2), h, 1.0, 3)
2-qubit circuit with 3 instructions:
├── trotter(0.333333) @ q[1:2]
├── trotter(0.333333) @ q[1:2]
└── trotter(0.333333) @ q[1:2]
```
"""
function push_lietrotter!(circuit::Circuit, qubits, hamiltonian::Hamiltonian, t::Real, steps::Integer)
    if length(qubits) != numqubits(hamiltonian)
        throw(ArgumentError("Number of qubits does not match Hamiltonian"))
    end

    tstep = t / steps

    @variables Δt

    ch = Circuit()

    # exp(-im * tstep * term)
    for hterm in hamiltonian
        push!(ch, _pauliexp(hterm, 2 * Δt, getqubits(hterm)))
    end

    # make the trotter expansion as a single block / gate declaration
    # so that is can be reused multiple times within the circuit
    decl = GateDecl(:trotter, (Symbolics.value(Δt),), ch)

    # actually push the expansion for every step
    for _ in 1:steps
        push!(circuit, decl(tstep), qubits...)
    end

    return circuit
end

@doc raw"""
    push_suzukitrotter!(circuit, qubits, hamiltonian, t, steps)

Adds a Suzuki-Trotter expansion of the Hamiltonian `hamiltonian` to the circuit `circuit` for the qubits `qubits` over time `t` with `steps` steps.

The Suzuki-Trotter expansion is a method for approximating the time evolution operator of a Hamiltonian. It is particularly useful for simulating quantum systems.

The expansion performed is a ``n``th-order expansion according to the Suzuki construction.

The second-order expansion is given by:

```math
\mathrm{e} = \mathrm{e}^{-\imath t H} \approx
\left[\prod_{j=1}^{m} \mathrm{e}^{-\imath\frac{\Delta t}{2} H_j} \prod_{j=m-1}^{1} \mathrm{e}^{-\imath\frac{\Delta t}{2} H_j}\right)\right]^k
```

where the Hamiltonian `H` can be expressed as a sum of `m` terms `H_j`:

```math
H = \sum_{j=1}^{m} H_j
```

and ``\Delta t = t / n_\text{steps}``.

Higher orders are derived from the Suzuki recursion relation

```math
S_{2k}(\lambda) = [S_{2k−2}(p_k \lambda)]^2 \, S_{2k−2}((1 − 4p_k)\lambda)[S_{2k−2}(p_k\lambda)]^2
\qquad
p_k = (4 - 4^{1/(2k-1)})^{-1}
```

## Examples

```jldoctests
julia> h = Hamiltonian()
empty hamiltonian

julia> push!(h, 1.0, PauliString("XX"), 1, 2)
2-qubit hamiltonian with 1 terms:
+
└── 1.0 * XX @ q[1:2]

julia> c = Circuit()
empty circuit

julia> push_suzukitrotter!(c, (1, 2), h, 1.0, 5, 2)
2-qubit circuit with 5 instructions:
├── suzukitrotter_2(0.2) @ q[1:2]
├── suzukitrotter_2(0.2) @ q[1:2]
├── suzukitrotter_2(0.2) @ q[1:2]
├── suzukitrotter_2(0.2) @ q[1:2]
└── suzukitrotter_2(0.2) @ q[1:2]
```
"""
function push_suzukitrotter!(circuit::Circuit, qubits, hamiltonian::Hamiltonian, t::Real, steps::Integer, order::Integer=2)
    # see e.g. [https://arxiv.org/pdf/quant-ph/0508139]
    # and [https://arxiv.org/abs/2211.02691]
    # and [https://arxiv.org/pdf/math-ph/0506007]

    if length(qubits) != numqubits(hamiltonian)
        throw(ArgumentError("Number of qubits does not match Hamiltonian"))
    end

    if order < 2 || !iseven(order)
        throw(ArgumentError("Suzuki-Trotter order must be an even integer greater than or equal to 2. Got $(order)."))
    end

    tstep = t / steps

    @variables λ

    ch = Circuit()

    # exp(-im * tstep / 2 * term)
    for hterm in hamiltonian
        push!(ch, _pauliexp(hterm, λ, getqubits(hterm)))
    end

    # exp(-im * tstep / 2 * term)
    for hterm in reverse(hamiltonian.terms)
        push!(ch, _pauliexp(hterm, λ, getqubits(hterm)))
    end

    # make the suzuki-trotter expansion as a single block / gate declaration
    # so that is can be reused multiple times within the circuit
    decls = [GateDecl(Symbol("suzukitrotter_2"), (Symbolics.value(λ),), ch)]

    for k = 2:div(order, 2)

        # S_{2k}(\lambda) = [S_{2k−2}(p_k \lambda)]^2 \, S_{2k−2}((1 − 4p_k)\lambda)[S_{2k−2}(p_k\lambda)]^2
        # p_k = (4 - 4^{1/(2k-1)})^{-1}

        ck = Circuit()
        pk = 1 / (4 - 4^(1 // (2k - 1)))

        push!(ck, decls[end](pk * λ), qubits...)
        push!(ck, decls[end](pk * λ), qubits...)

        push!(ck, decls[end]((1 - 4pk) * λ), qubits...)

        push!(ck, decls[end](pk * λ), qubits...)
        push!(ck, decls[end](pk * λ), qubits...)

        push!(decls, GateDecl(Symbol("suzukitrotter_$(2k)"), (Symbolics.value(λ),), ck))
    end

    # actually push the expansion for every step
    for _ in 1:steps
        push!(circuit, decls[end](tstep), qubits...)
    end

    return circuit
end

@doc raw"""
    push_yoshidatrotter!(circuit, qubits, hamiltonian, t, steps, order)

Adds a Yoshida-type symmetric composition of second-order Suzuki-Trotter expansions 
to the circuit for the qubits `qubits`, approximating the time evolution 
under the Hamiltonian over total time `t`, using `steps` steps and a given even `order`.

The Yoshida composition recursively constructs higher-order integrators of order 2, 4, 6, ... 
based on symmetric products of lower-order evolutions:

```math
S_{2(k+1)}(t) = S_{2k}(w₁·t) ⋅ S_{2k}(w₂·t) ⋅ S_{2k}(w₁·t)
```

where the weights `w₁` and `w₂ = 1 - 2w₁` are chosen to cancel higher-order error terms.
Specifically, they are:

```math
w₁ = 1 / (2 - 2^(1 / (2k + 1)))
w₂ = -2^(1 / (2k + 1)) / (2 - 2^(1 / (2k + 1)))
```

This method improves the accuracy of the approximation to the time evolution operator 
`exp(-i * t * H)` by nesting second-order symmetric expansions with non-uniform time scaling.

!!! note
    The `order` must be an even number (2, 4, 6, ...). Internally, order 2 uses a standard second-order Suzuki-Trotter step.

See also: [`push_suzukitrotter!`](@ref), [`GateDecl`](@ref)

```jldoctests
## Examples

julia> h = Hamiltonian()
empty hamiltonian

julia> push!(h, 1.0, PauliString("XX"), 1, 2)
2-qubit hamiltonian with 1 terms:
+
└── 1.0 * XX @ q[1:2]

julia> c = Circuit()
empty circuit

julia> push_yoshidatrotter!(c, (1, 2), h, 1.0, 5, 4)
2-qubit circuit with 5 instructions:
├── yoshidatrotter_4(0.2) @ q[1:2]
├── yoshidatrotter_4(0.2) @ q[1:2]
├── yoshidatrotter_4(0.2) @ q[1:2]
├── yoshidatrotter_4(0.2) @ q[1:2]
└── yoshidatrotter_4(0.2) @ q[1:2]
```
"""

function push_yoshidatrotter!(circuit::Circuit, qubits, hamiltonian::Hamiltonian, t::Real, steps::Integer, order::Integer=4)
    # see e.g. [https://aiichironakano.github.io/phys516/Yoshida-symplectic-PLA00.pdf]

    if length(qubits) != numqubits(hamiltonian)
        throw(ArgumentError("Number of qubits does not match Hamiltonian"))
    end

    if order < 2 || !iseven(order)
        throw(ArgumentError("Yoshida-Trotter order must be an even integer ≥ 2. Got $(order)."))
    end

    tstep = t / steps

    @variables λ
    ch = Circuit()

    # Construct S_2(λ)
    for hterm in hamiltonian

        push!(ch, _pauliexp(hterm, λ, getqubits(hterm)))
    end
    for hterm in reverse(hamiltonian.terms)
        push!(ch, _pauliexp(hterm, λ, getqubits(hterm)))
    end

    decls = [GateDecl(Symbol("yoshidatrotter_2"), (Symbolics.value(λ),), ch)]

    # Recursively build higher orders using Yoshida symmetric composition
    for k = 2:div(order, 2)
        α = 1 / (2 - 2^(1 / (2k - 1)))
        β = -2^(1 / (2k - 1)) / (2 - 2^(1 / (2k - 1)))

        ck = Circuit()
        push!(ck, decls[end](α * λ), qubits...)
        push!(ck, decls[end](β * λ), qubits...)
        push!(ck, decls[end](α * λ), qubits...)

        push!(decls, GateDecl(Symbol("yoshidatrotter_$(2k)"), (Symbolics.value(λ),), ck))
    end

    for _ in 1:steps
        push!(circuit, decls[end](tstep), qubits...)
    end

    return circuit
end
