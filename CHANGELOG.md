# Changelog

All notable changes to `MimiqCircuitsBase.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.27.1] — 2026-10-24

### Fixed
- `OperationError` and `UndefinedValue` print their message, such as `QFT: Number of qubits must be ≥ 1.`, instead of the raw exception struct: their `showerror` methods were not methods of `Base.showerror`.
- `show_mimiq_hierarchy` no longer lists compiler-generated types such as `#319#val` on Julia 1.13.

### Docs
- `OperationError`, `UndefinedValue` and `DecompositionError` have docstrings saying when each is thrown.
- The documentation builds on Julia 1.13: doctests that print a `Set` of qubits no longer depend on the order of its elements.

## [0.27.0] — 2026-10-24

### Added
- `ParameterTable` holds the values of a parameter sweep: a fixed list of symbols and one row of values per point. It is built from a matrix, from one column per symbol (`ParameterTable(θ => xs, φ => ys)`), or from a vector of dictionaries.
- `gridtable(θ => xs, φ => ys)` builds the `ParameterTable` of every combination of the given values.
- Parameter tables compose: `a * b` is the Cartesian product, `hcat(a, b)` pairs the points of two tables of the same length, and `vcat(a, b)` appends the points of `b` after those of `a`.
- `SweepExperiment(circuit, table)` pairs a symbolic circuit with the table of values to run it with, and checks that the table binds exactly the free symbols of the circuit. `ex[i]` is the circuit evaluated at point `i`.
- `ParameterTable` and `SweepExperiment` support `t[end]` and range or vector indexing: `t[1:2]` is the table of the selected points and `ex[1:2]` the experiment over them.
- `ParameterTable` and `SweepExperiment` compare structurally with `==` and `isequal`, and hash consistently with them.
- `simplify(c)` reduces a circuit by running a list of passes until the number of two-qubit gates, then of instructions, stops going down; the unitary is kept exactly, global phase included, and `passes` selects which passes run.
- `remove_identities(c)` removes gates whose matrix is exactly the identity, such as `GateID` or `GateRZ(0)`.
- `cancel_inverses(c)` removes pairs of gates that multiply to the identity, such as `CX CX` or `S SDG`, including across gates that the second one commutes with.
- `merge_rotations(c)` adds up the angles of consecutive rotations of the same kind on the same qubits, `GateRZ(a) GateRZ(b)` into `GateRZ(a + b)`, across commuting gates and with symbolic angles.
- `merge_rotations(c)` also merges different single-qubit gates of one rotation family, Z/S/T/P/U1, X/SX or Y/SY and their inverses, into the named gate of the summed angle, so `T T` becomes `S`.
- `cancel_inverses` and `merge_rotations` move multi-controlled X gates (`GateCCX`, `GateC3X`, `Control(n, GateX())`) past each other, diagonal gates and X rotations by structural rules that hold at any width, and cancel pairs of them that differ only in the order of their controls.
- `resynthesize_1q(c)` replaces each run of single-qubit gates with one `GateU`, or removes it when it is the identity.
- `resynthesize_2q(c)` rewrites each two-qubit block with the minimal number of `GateCX`, from zero to three, found from its KAK decomposition, when that lowers its two-qubit gate count.
- `resynthesize_linear(c)` rewrites every block of `GateX`, `GateCX` and `GateSWAP`, of any width, from the affine map it computes, using Patel-Markov-Hayes synthesis, when that lowers its two-qubit gate count; it is not one of the default passes of `simplify`.

### Changed
- `PrepareMagic` is renamed `PrepareStateT`. `PrepareMagic` remains as a deprecated alias. The protobuf enum value keeps its number, so the wire format is unchanged.
- `evaluate` returns a `Control`, `Inverse`, `Power`, `Parallel`, `Repeat`, `IfStatement`, `WhileStatement` or `Block` without free symbols unchanged, and rebuilds one with free symbols through `control`, `inverse`, `power`, `parallel` and `repeat`, so `evaluate(Inverse(GateRX(θ)), Dict(θ => 0.3))` is `GateRX(-0.3)` while `evaluate(Inverse(GateRX(0.3)), Dict())` stays `Inverse(GateRX(0.3))`.
- `fuse` emits its blocks in the same order as `fuse_circuit` in the Python package; the circuit it returns has the same unitary as before.

### Deprecated
- `samplemixedunitaries(c, rng)` is deprecated in favour of `sample_mixedunitaries(c; rng, ids=true)`, and returns a `Circuit` instead of an iterator.
- `ParityCheck` is deprecated. `ParityCheck(N)` warns and returns `Xor(N)`, which computes the same parity and allows the target to be one of the inputs. Circuits saved with `ParityCheck` load as `Xor`, and new circuits never save it.

### Removed

The loss aliases deprecated in 0.24.0 are gone. Replace `LossErr(p)` with
`Loss(p)`, `QubitLoss()` with `Loss()`, `QubitReload()` with `Reload()`,
`CheckLoss()` with `Check()` and `MeasureCheckLoss()` with `MeasureCheck()`.
Circuits serialized with the old `QubitLoss` operation still decode, as `Loss()`.

- `LossErr`, `QubitLoss`, `QubitReload`, `CheckLoss` and `MeasureCheckLoss` are no longer defined.

### Fixed
- `listvars` and `issymbolic` look inside `Block`, and inside wrappers of a `Block` such as `Repeat`, `IfStatement` and `WhileStatement`, so `SweepExperiment` accepts a circuit whose symbols appear only inside a block.
- `evaluate` substitutes the parameters inside `Repeat`, `IfStatement` and `WhileStatement`, which it used to return unevaluated.
- The matrix of a `Power` is inferred as `Matrix{ComplexF64}` instead of a union of real and complex matrices.
- `evaluate(g, x => value, …)` with the substitutions given as pairs no longer throws.
- `lossmodel_rewrite` no longer requires the `rng` keyword; it defaults to `Random.default_rng()`, as in `lower_losses` and `sample_losses`.
- `DepthFirstIterator`, `BreadthFirstIterator` and `DecomposeIterator` are exported; the package exported the names `DepthFirstDAGIterator`, `BreadthFirstDAGIterator` and `DecompositionIterator`, which are not defined.
- `@on` is defined, so using it outside the top level of a `@circuit`, `@block` or `@gatedecl` block throws an error that says so instead of `UndefVarError`.
- `saveproto` on a `NoiseModel` containing a `CustomNoiseRule` throws an `ArgumentError` saying custom rules cannot be serialized, and `loadproto` refuses a stored custom rule instead of decoding it into a rule that matches every instruction.
- `haslossybranch` works on every Kraus channel: it is `true` when a `Kraus` channel has a `LossyOperator` branch and `false` for channels without loss branches, such as `PauliX(0.1)`, which used to throw a `MethodError`.
- `isunitary` is `true` for every annotation: `QubitCoordinates`, `Lost` and `Reloaded` reported `false`, so a circuit containing them was not considered unitary.
- `decompose_step!(container, x; rule=...)` on an operation, an instruction or a circuit accepts any `RewriteRule` and defaults to `CanonicalRewrite()`; it used to throw for the default and for every rule.
- `samplemixedunitaries` no longer throws a `MethodError` when it reaches a mixed-unitary channel such as `PauliX` or `MixedUnitary`, and emits the `Loss` of a lossy branch.
- `rescale!` on an `Operator` multiplies its matrix in place instead of throwing. On any other operation, such as a `RescaledGate`, a projector, a sigma or a `DiagonalOp`, it throws an `ArgumentError` that points to `rescale`, since those are immutable.
- `isvalid(::OptimizationExperiment)` extends `Base.isvalid` instead of defining a new function, so `isvalid` resolves after `using MimiqCircuitsBase` and its `Base` methods, such as `isvalid(::Char)`, keep working.
- `decompose(c; wrap=true)` no longer throws on a non-unitary operation that has a decomposition, such as `MeasureReset` or `MeasurePauli`. It is wrapped into a `Block` holding its decomposition, and the gates in it are wrapped into a `GateDecl` as usual.
- `QASMBasis` decomposes `MeasureReset` into `Measure` and `Reset`, so a circuit with `MeasureReset`, `MeasureResetX` or `MeasureResetY` can be written as OpenQASM 2.0 for any number of bits.
- `QASMBasis` throws `DecompositionError` on a `WhileStatement` instead of keeping it as terminal, since OpenQASM 2.0 has no loops.

### Build
- `CodecZlib` and `StaticArrays` are no longer dependencies.

### CI
- Tests run on Julia 1.13 as well as 1.12.

### Docs
- `listvars` has a docstring: what it takes, how it looks into wrappers and blocks, and what it returns.
- `RescaledGate`, `getscale`, `graph`, `evaluate!`, `histsamples`, `getnotes`, `getbitstring`, `AbstractMeasurement`, `add_terms!`, `getcoefficient`, `specify_operations` and the `OptimizationExperiment`/`OptimizationResults` accessors (`changeparameters`, `changelistofparameters`, `getcost`, `getbest`, `getresultofbest`, `getresultsofhistory`, `costhistory`) have docstrings, and the package has a module docstring.
- The docstrings of `AbstractCircuit`, `push_yoshidatrotter!` and `insert!` for operations show up in the help; a blank line kept them from attaching.
- `IdleNoise`, `SetIdleQubitNoise` and `add_idle_noise!` say that they replace explicit `Delay` instructions with noise, rather than adding noise to qubits that are idle.
- The `QCSResults` docstring and its HTML display spell the name correctly, and the `rescale` docstring names the function it documents.

## [0.26.1] — 2026-10-20

### Fixed
- `using MimiqCircuitsBase` no longer fails with `UndefRefError` on Julia 1.13.
- `power(GateDCX(), n)` with `n` a multiple of 3 returns a 2-qubit identity, so its `matrix` no longer throws `DimensionMismatch`.

### Docs
- `matrix` and `unwrappedmatrix` warn that the matrix of an operator without parameters is shared between calls and must be copied before mutating.

## [0.26.0] — 2026-10-19

### Added
- `GridSynthRewrite(; epsilon=1e-10, seed=0)` approximates `GateRZ` with Clifford+T gates to operator-norm error `epsilon`, from `1e-100` up to `1`, using the Ross-Selinger gridsynth algorithm.
- `CliffordTBasis(; rotations=rule)` selects the rule that synthesizes the remaining Z-rotations.
- `MeasurePauli(pauli)` measures an `N`-qubit Pauli product observable into one classical bit, and decomposes into `GateH`, `GateS`, `GateSDG`, `GateCX` and one `Measure`, so `QASMBasis` can decompose it.
- `PrepareMagic()` prepares one qubit in the magic state `T|+⟩` and decomposes into `Reset`, `GateH`, `GateT`.
- `pauli_based_computation(c)` rewrites a Clifford+T circuit into `π/8` Pauli rotations and `MeasurePauli`, reproducing the measurement statistics of `c` but not its final state.
- `pauli_based_computation(c; magic_states=true)` replaces each `π/8` rotation by magic-state injection with `PrepareMagic`, `MeasurePauli` and classical feed-forward, tracking the Pauli frame with 3-bit `Xor` operations only.
- Wire format 1.3.0 adds the `MeasurePauli` operation and the `PrepareMagic` Kraus channel type to `circuit.proto`; clients send this version with every request, so a release carrying it cannot submit any job until the executor speaks 1.3.0. It also writes symbolic parameters as exact expression trees instead of rounded numbers, a patch-level change that older decoders read to the same values.
- `CliffordTBasis`, `FlattenedBasis` and `RuleBasis` decompose the operation inside an `IfStatement` with their own rules and put each resulting instruction under the same condition, so classically controlled gates no longer raise `DecompositionError`.
- `pauli_based_computation` supports a classically controlled Pauli operator, or a `PauliString`, `Block`, `Parallel`, `Repeat` or `GateCall` made only of Paulis, as one conditional `PauliString`, folded into the Pauli frame with `magic_states=true`.
- `pauli_based_computation` supports `Reset`, `ResetX`, `ResetY`, `MeasureReset`, `MeasureResetX` and `MeasureResetY` as a measurement followed by a conditional Pauli, each reset writing its outcome to a new bit after the circuit's bits.
- `pauli_based_computation` turns a classically controlled T or T† gate into a conditional `RPauli`, and refuses it with `magic_states=true`.
- `pauli_based_computation` handles `MeasureX`, `MeasureY`, `MeasureXX`, `MeasureYY`, `MeasureZZ` and `MeasurePauli` itself, whatever `basis` does with them.
- `pauli_based_computation` explains in its error why it refuses a classically controlled Clifford gate: the Clifford after it would depend on the condition bits.
- `StimBasis` keeps `MeasurePauli`, `MeasureXX`, `MeasureYY`, `MeasureZZ`, `PauliNoise`, `GateHXY` and `GateHYZ` as terminal, since Stim has them natively.
- `StimBasis` keeps `GateRXX`, `GateRYY`, `GateRZZ` and `RPauli` at ±π/2 as terminal (Stim's `SQRT_XX`, `SQRT_YY`, `SQRT_ZZ`, `SPP`) and decomposes them at other angles.
- `StimBasis` keeps `IfStatement` of `GateX`, `GateY` or `GateZ` on one bit equal to 1 as terminal (Stim's feedback `CX rec[-k] q`), rewrites the same gate conditioned on 0 as the gate followed by that conditional, and throws a `DecompositionError` for any other conditional operation.

### Changed
- `draw` packs instructions on disjoint wires into shared columns, so independent gates are drawn side by side instead of one per column. Instructions that read or write the classical or Z register keep their circuit order and are never drawn in parallel with each other. Consecutive instructions of the same operation type on disjoint wires, such as those from one broadcast push, start in the same column.
- `draw(c; compact=false)` keeps the previous layout, with every instruction in its own column.
- `draw` labels an operation on classical bits or z-variables only with its targets, such as `c[1] = c[2] ⊻ c[3]`, instead of a list of indices followed by the operation's placeholders, such as `1,2,3 c[?1] = ⊻ @ c[?2:?N]`.
- An `Xor`, `And` or `Or` instruction whose target is also an input prints in compound form, such as `c[3] ⊻= c[2]` for `c[3] = c[3] ⊻ c[2]`.
- Circuit listings and `draw` mark numbers shortened for display with an ellipsis, e.g. `Depolarizing(1,0.0123457…)`; numbers shown exactly are unchanged.
- Decompositions use exact fractions of π instead of floating-point values, as in mimiqcircuits.
- `Control` decomposes one canonical step of its target instead of its full canonical decomposition, as in mimiqcircuits, so `Control(1, QFT(2))` gives 31 canonical gates instead of 65.
- `GateCCP` orders its decomposition as mimiqcircuits does, and `GateU2` decomposes directly into `GateU`.
- `CliffordTBasis()` synthesizes arbitrary rotations with `GridSynthRewrite()`, and `CliffordTBasis(sk_depth=d)` with `SolovayKitaevRewrite(d)`.
- `CliffordTBasis` is now parametric, `CliffordTBasis{R}`, with the rotation rule in its `rotations` field.
- `MeasureReset` decomposes into `Measure` followed by `IfStatement(GateX(), bs"1")` on the measured bit instead of `Measure` followed by `Reset`, as in `mimiqcircuits`.
- `CliffordTBasis` keeps as terminal every operation that `StimBasis` keeps, plus `GateT`, `GateTDG`, classical operations and any conditional of its terminal operations, so measurements and resets in every Pauli basis, Pauli noise, `GateHXY`, `GateHYZ` and Pauli rotations by ±π/2 are no longer expanded.
- A floating-point exponent that is exactly a fraction with denominator at most 1000 is stored as that fraction, or as an integer, so `Power(GateX(), 0.5)` is `GateSX()` and `power(g, 0.5)` builds the same operation as `power(g, 1//2)`, as in mimiqcircuits.
- `inverse(GateU)` returns `+0.0` instead of `-0.0` for a zero angle, as in mimiqcircuits.

### Removed
- The `sk_depth` field of `CliffordTBasis` is removed; use `basis.rotations.depth` instead.

### Fixed
- `matrix(::RPauli)` with a symbolic angle no longer prints the angle's symbols to standard output.
- `PhaseGradient` and its powers decompose into phase gates, where they raised `DecompositionError`.
- `Inverse(GateU(...))` decomposes into the inverted `GateU`, where it raised an error.
- `Power(Control(n, U), p)` decomposes into `Control(n, Power(U, p))`, where it raised an error.
- A `Power` whose base does not decompose into a single gate raises `DecompositionError` rather than a generic error.
- `SolovayKitaevRewrite` rules with the same settings compare equal and have the same hash.
- `SpecialAngleRewrite` treats a non-finite angle as not special instead of throwing an `InexactError`.
- Symbolic parameters built from integers, rationals, `π` and `ℯ`, such as `π/4`, `2π/3` or `x*π/4`, are saved to protobuf exactly and with the same bytes in Julia and Python, so a loaded circuit equals the saved one.
- `StimBasis` drops a phase-only `GateU(0, 0, 0, γ)`, such as the one `RPauli("II", θ)` decomposes into, instead of throwing a `DecompositionError`, as `CliffordTBasis` does.
- `getparams` and `parnames` of a `Repeat` return the parameters of the repeated operation instead of throwing a `MethodError`.

### Docs
- The `MeasureXX` and `MeasureYY` docstrings describe the circuits their decompositions apply.
- The API reference documents the decomposition bases and rewrite rules.

### Performance
- `unwrapvalue` evaluates constant expressions such as `π/2` about 18x faster.

### Migration
Decomposed circuits now hold exact angles such as `π/2` where they held `1.5707963267948966`. Code that compares their parameters with `==` against floats should compare `unwrapvalue(p)` with `≈` instead.

`CliffordTBasis()` now approximates arbitrary rotations with `GridSynthRewrite()` instead of Solovay-Kitaev, so decomposed circuits change: they are shorter and more accurate. Pass `sk_depth=3` to get the previous output.

The output of `CliffordTBasis` can now contain the Stim operations listed under **Changed**; code that expects only the elementary Clifford+T gates must expand them itself.

`Power` types with a floating-point exponent that is a small fraction, such as `Power{0.5}`, are no longer built: methods dispatching on them should dispatch on `Power{1//2}` instead.

## [0.25.0] — 2026-08-19

### Added
- `GateCustomDiagonal(d)`, an `N`-qubit gate given by the `2^N` entries of its diagonal, as `GateCustom` is given by a full matrix. Storing only the diagonal keeps a wide diagonal block at `2^N` numbers rather than `4^N`; entries must be phases. The canonical rewrite expands its phases in the Walsh basis into parity rotations (`GateRNZ`/`GateRZ`), exactly and without densifying, so backends that do not know the gate still decompose it.
- `fuse` takes `max_diagonal_support` (default: `max_support`), the width budget for runs where every gate is diagonal in the computational basis. Such runs now fuse into a `GateCustomDiagonal` and are composed by multiplying diagonals elementwise, never building the dense block. A cluster keeps the diagonal budget only while all of its gates are diagonal; the first dense gate joining it brings it back under `max_support`. With the default budget the emitted blocks cover the same gates as before, but an all-diagonal block comes out as `GateCustomDiagonal` rather than `GateCustom`.
- Wire format 1.2.0: the `circuit.proto` schema gains a `CustomDiagonalGate` message, carried by the `Gate`, `Operator` and `Operation` oneofs. Additive, so an older decoder ignores it and a newer one still reads old payloads; a client emitting `GateCustomDiagonal` needs an executor speaking 1.2.0.

### Fixed
- The canonical rewrite of `GateCustom` is exact: it used to drop a global phase and, on matrices with degenerate singular values such as diagonal ones, could put a wrong phase on a single amplitude (fidelity as low as 0.53).

## [0.24.6] — 2026-08-18

### Fixed
- `matrix(::Vector{Instruction})` and `matrix(::Circuit)` evaluate the product numerically when no gate carries a symbolic parameter, converting once at the end, instead of putting every intermediate through SymbolicUtils. The return type is unchanged — still `Matrix{Complex{Num}}` in every case, so callers see no difference other than speed. Folding a 51-gate 6-qubit circuit drops from 124 s to 4.2 ms. Circuits containing a symbolic parameter take the symbolic path exactly as before.
- `fuse` builds each block with a `ComplexF64` fold rather than through `matrix(::Vector{Instruction})`, which is where it previously spent essentially all of its time: a 590-gate bricklayer circuit on 20 qubits at `max_support = 5` drops from 141 s to 28 ms, and a 20-qubit QFT at `max_support = 3` from 1.76 s to 3.8 ms. `fuse` only ever fuses gates with concrete numeric matrices, so this changes no results.

### Performance
- `_reorder_qubits_matrix!` derives its index permutation from the `nq` basis indices and inverts it by scatter, instead of building all `2^nq` images as `BigInt`s through `BitString` and recovering the permutation with `sortperm`. Worth a further 1.07–1.31x on `fuse`. The permutation itself was verified against the previous expression over every qubit subset and ordering for `nq` up to 6.

## [0.24.5] — 2026-08-18

### Fixed
- `fuse` merges the clusters owning a gate's wires instead of only extending a single one, so `max_support` above 2 now produces wider blocks. On entangling circuits every wire is owned after the first layer, which made every later gate start a fresh cluster and pinned the output at the `max_support = 2` result. A quantum volume circuit on 30 qubits at depth 30 now fuses to 426 blocks at `max_support = 2` and 151 at `max_support = 4`, where before it gave 456 at every setting.

## [0.24.4] — 2026-08-05

### Docs
- Condensed the changelog entries for earlier releases.

## [0.24.3] — 2026-07-23

### Added
- `fuse(circuit; max_support=2)` replaces runs of adjacent unitary gates with a single `GateCustom` block, preserving the circuit unitary. Measurements, resets, noise channels, `Barrier`, control flow, and gates with symbolic parameters act as fusion boundaries. `max_support` caps the block width.

### Fixed
- `power(GateU(θ, ϕ, λ, γ), p)` no longer drops the phase of diagonal gates (`θ = 0`), which broke the decomposition of multi-controlled gates with a diagonal target.
- `evaluate!` now works and is exported.
- `evaluate` substitutes parameters inside `Block`.
- `copy(Circuit)` now uses a valid constructor.

## [0.24.2] — 2026-07-07

### Fixed
- `saveproto` is now linear in circuit size instead of quadratic. Large circuits save in a fraction of the time.

## [0.24.1] — 2026-06-28

### Fixed
- `lower_losses` now writes the classical bit for every single-qubit measurement on a lost qubit (`MeasureX`, `MeasureY`, `MeasureReset`, …), not just `Measure`/`MeasureZ`.

## [0.24.0] — 2026-06-22

### Added
- `Loss(p)` operation for qubit loss (`Loss()` means certain loss), plus `Reload`, `Check`, and `MeasureCheck`.
- `Lost` and `Reloaded` annotations, which record loss and reload events without affecting execution.
- Loss resolution split into three functions: `sample_losses` draws the random `Loss(p)` events, `lower_losses` rewrites loss bookkeeping into primitives, and `resolve_losses` runs both to produce a circuit that runs on any backend.
- `lossmodel_rewrite` exposes the per-instruction `LossModel` decision, so backends can apply the same loss rules at runtime as `lower_losses` does offline.
- `MixedUnitary` accepts a `lossy` keyword marking which qubits leak in each branch. `sample_mixedunitaries` then emits a `Loss` on those qubits when a lossy branch is drawn.

### Changed
- Protobuf serialization renames the loss operations and adds the `Lost` / `Reloaded` annotations. The old `QubitLoss` tag still decodes as `Loss()`, so circuits saved by older versions keep loading. `WIRE_FORMAT_VERSION` is now `1.1.0`.
- `MixedUnitaryChannel` gains an optional `lossy_masks` field. Circuits without lossy branches serialize unchanged.

### Deprecated
- `LossErr`, `QubitLoss`, `QubitReload`, `CheckLoss`, and `MeasureCheckLoss` are aliases for the new operations and will be removed in a future release.

### Fixed
- `issymbolic` no longer errors on a circuit containing an `IfStatement`, or on a `Kraus` channel.

## [0.23.3] — 2026-06-01

### Fixed
- `BondDim`, `SchmidtRank`, and `VonNeumannEntropy` now depend on every qubit in the dependency graph, so `traverse_by_bfs` / `traverse_by_dfs` keep them after the gates that affect the bond they probe.

## [0.23.2] — 2026-06-01

### Fixed
- `Amplitude` now depends on every qubit in the dependency graph, so `traverse_by_bfs` / `traverse_by_dfs` keep it after the gates whose state it reads.

### CI
- The `register` job now fires only on `-private` tags, to avoid double-registering public tags.

## [0.23.1] — 2026-05-27

### Docs
- Fixed the documentation build: doctest failures, stale `@ref` links, and the autodocs page size limit.
- `docs/Project.toml` no longer depends on `MimiqCircuits` or `MimiqLink`.

### CI
- GitLab Pages is now deployed only from `main`. Other pipelines still build the docs.

## [0.23.0] — 2026-05-27

### Added
- `WIRE_FORMAT_VERSION` constant (initial value `v"1.0.0"`) declaring the version of the MIMIQ wire format, independently of the package version. See `WIRE_FORMAT.md`.

## [0.22.0]

Changelog tracking begins with this version. See git history for prior changes.
