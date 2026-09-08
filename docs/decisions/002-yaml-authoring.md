# 002: YAML is the authoring surface, compiled to Harbor

Status: accepted 2026-09-08

## Context

A Harbor task is five files in a directory. Upstream's task is six lines of
YAML. Vendor benches will have ten to twenty tasks each, written by the tool
author, and the per-task authoring cost decides whether the bench gets
written at all. Harbor's own adapters already take this shape: they compile
external datasets into task directories rather than asking authors to write
them by hand.

## Decision

Vendors author `bench/tasks.yaml` (prompt, category, verifier, oracle per
task) and `bench/conditions.yaml`, plus one shared `bench/environment/
Dockerfile` that installs every surface under test, pinned. `axi-bench
generate` compiles that into Harbor task directories and a `dataset.toml`
under a git-ignored `generated/`. The generated output is plain Harbor and
runs without axi-bench.

A verifier in `tasks.yaml` is one of `expected` (last line of the answer
must equal a value), `check` (a shell command in the verifier container), or
`judge_hint` (LLM judge over the trajectory, last resort, different model
family from the agent).

For a vendor's first run the Harbor directories are hand-written from the
YAML, and the generator is extracted afterwards from what that run needed.
No framework code is written before a first real run.

## Consequences

- Per-task authoring cost matches upstream.
- `docs/examples/generated-task/` is the contract for what the generator
  emits and must stay in sync with it.
- Changing the `tasks.yaml` schema is a contract change and needs a README
  note.
- Vendors never hand-edit `task.toml`; fixes go into the YAML or the
  generator.
