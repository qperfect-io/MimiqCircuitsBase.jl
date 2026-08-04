# Changelog

All notable changes to `MimiqCircuitsBase.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
