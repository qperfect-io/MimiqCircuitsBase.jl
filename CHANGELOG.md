# Changelog

All notable changes to `MimiqCircuitsBase.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.23.3] — 2026-06-01

### Fixed
- `Circuit`'s dependency graph now treats `BondDim`, `SchmidtRank`, and
  `VonNeumannEntropy` as depending on every qubit, so `traverse_by_bfs` /
  `traverse_by_dfs` keep them after the gates that affect the bond they probe.
  Like `Amplitude`, their value is set by the whole circuit history, so a
  topological traversal could previously float them ahead of those gates; they
  now act as full-register synchronisation points.

## [0.23.2] — 2026-06-01

### Fixed
- `Circuit`'s dependency graph now treats `Amplitude` as depending on every
  qubit, so `traverse_by_bfs` / `traverse_by_dfs` keep it after the gates whose
  state it reads. It reads `⟨bs|ψ⟩` over the whole register without declaring
  any qubit, so a topological traversal could previously float it ahead of
  those gates; it now acts as a full-register synchronisation point.

### CI
- The GitLab `register` job now fires only on `-private` tags. The
  bare public `vX.Y.Z` tag is registered into QPerfectRegistry by
  the GitHub Actions workflow on the public remote; the previous
  rule attempted both and could double-register.

## [0.23.1] — 2026-05-27

### Fixed
- `SetOperationInstanceQubitNoise` docstring doctest now binds
  `@variables a` via a proper `julia>` input line, so it no longer
  fails with `UndefVarError: a not defined` under Documenter.
- Several `jldoctests` blocks in `noisemodel.jl` (around
  `apply_noise_model`, `add_readout_noise!`, and the symbolic /
  qubit-specific `add_operation_noise!` examples) used bare
  `# comment` lines between `julia>` blocks. The current Documenter
  parser greedily folds them into the previous expected output, so
  the blocks were split into separate per-example jldoctest blocks
  with the prose moved to surrounding markdown.
- Updated the expected matrix output for `GateXXplusYY` and
  `GateXXminusYY` doctests to match the current Symbolics factor
  ordering (`sin(θ/2)*sin(-β)` instead of `sin(-β)*sin(θ/2)`).
- `docs/make.jl` now passes `repo=` to `makedocs` so doc builds
  succeed in GitLab CI where the shallow checkout has no `origin`
  set (Documenter no longer auto-detects).
- `makedocs` now passes `warnonly = [:missing_docs, :cross_references]`
  so the build doesn't bail on stale `@ref` links / orphan
  docstrings that have been broken for several releases. They
  still appear as warnings in the CI log for a follow-up cleanup.
- Disabled Documenter's HTML `size_threshold` checks because the
  autodocs index (`library/public.md`) renders to ~250 KiB —
  above the 200 KiB default. The page should be split, but until
  then the cap was the last blocker for the docs build.

### Build
- `docs/Project.toml` no longer depends on `MimiqCircuits` or
  `MimiqLink` — the documentation only references `MimiqCircuitsBase`,
  so the extra deps just made the docs build hostage to downstream
  release ordering in the registry.

### CI
- GitLab Pages is now deployed only from `main`, with no version
  path-prefix or per-version environment (the runner host doesn't
  support parallel deployments). `devel` and merge-request pipelines
  still build the docs in a new `docs` job so a broken build trips
  the pipeline, but they no longer try to publish.

## [0.23.0] — 2026-05-27

### Added
- `WIRE_FORMAT_VERSION` constant (initial value `v"1.0.0"`) declaring
  the version of the MIMIQ wire format — the union of the ProtoBuf
  schemas and the JSON request/response envelope — independently of
  the package's own release version. See `WIRE_FORMAT.md` for the
  full surface and the bump-trigger checklist.

## [0.22.0]

Changelog tracking begins with this version. See git history for prior changes.
