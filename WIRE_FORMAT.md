# MIMIQ Wire Format

The wire format is the contract between MIMIQ clients
(`MimiqCircuits.jl`, `mimiqcircuits` Python) and the executor
(`MimiqExecutor.jl`). It is versioned independently of every package's
own release version so API-only changes never force a client/executor
upgrade.

The current version is declared in:

- Julia: `MimiqCircuitsBase.WIRE_FORMAT_VERSION` (in `src/proto/proto.jl`)
- Python: `mimiqcircuits.WIRE_FORMAT_VERSION` (in
  `src/mimiqcircuits/proto/__init__.py`)

The two constants must match.

## Wire surface

Everything that crosses between client and executor.

**Protobuf schemas** under `MimiqCircuitsBase.jl/src/proto/` and their
mirrors under `mimiqcircuits-python/src/mimiqcircuits/proto/`:
`circuit.proto`, `qcsresults.proto`, `optim.proto`, `circuitrules.proto`,
`bitvector.proto`, `pauli.proto`, `hamiltonian.proto`,
`noisemodel.proto`.

**JSON request envelope** built in
`MimiqCircuits.jl/src/execute.jl`, `MimiqCircuits.jl/src/optimization.jl`,
`mimiqcircuits-python/src/mimiqcircuits/remote.py`, and
`mimiqcircuits-python/src/mimiqcircuits/optimization_remote.py`. Keys:
`executor`, `timelimit`, `apilang`, `apiversion`, `circuitsapiversion`,
`wireformatversion`.

**JSON response envelope and result layout** — whatever the executor
writes into `output_dir` and the conventions clients use to read it.

**Transport layout** — input/output directory filename conventions
(`circuit.pb`, `noisemodel.pb`, `optim.pb`, the JSON manifests) and any
multipart encoding for large state vectors or streamed MPS tensors.

## Versioning rules

Semantic Versioning:

- **MAJOR** — incompatible change. A proto field is removed, renumbered,
  retyped, or given new semantics; an envelope key is renamed or its
  meaning changes; a transport filename changes.
- **MINOR** — additive change. A new optional proto field, enum variant,
  message type, or optional envelope key. Old decoders ignore unknown
  additions per proto3; new decoders read old payloads.
- **PATCH** — no schema change. Spec clarification, encoder bugfix,
  default-value correction.

## When to bump

If your PR touches the wire surface, bump `WIRE_FORMAT_VERSION` in both
the Julia and Python constants and add a CHANGELOG bullet under
`MimiqCircuitsBase.jl/CHANGELOG.md` describing the change. Trivial edits
that do not affect serialization (comments, formatting, renaming a
private helper) do not bump.

The major/minor/patch judgment is yours — CI cannot decide it for you.

## Compatibility check

The executor declares `WIRE_FORMAT_VERSION` (what it speaks) and
`MIN_SUPPORTED_WIRE_FORMAT` (the oldest client it accepts). When a
client sends version `c`:

| Condition | Outcome |
|---|---|
| `c.major != executor.major` | reject — schemas incompatible |
| `c < MIN_SUPPORTED` | reject — sunsetted |
| `c.minor > executor.minor` | reject — client may emit unknown fields |
| `c.minor < executor.minor`, same major | accept |
| `c.patch != executor.patch` | accept with debug log |
| equal | accept |

Clients predating `WIRE_FORMAT_VERSION` do not send the field. For
them, the executor falls back to a prior compatibility check
(`MimiqExecutor.jl/src/utils.jl::check_legacy_api_compatibility`)
against `pkgversion(MimiqCircuitsBase)`. The fallback is removed once
those clients are sunset.
