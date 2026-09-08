# 001: Harbor is the runtime and result format

Status: accepted 2026-09-08

## Context

Upstream `kunchenguid/axi` benchmarks with two hand-rolled TypeScript
harnesses, `bench-github` and `bench-browser`. They are copy-paste forks that
diverged, the Claude and Codex usage parsers were wrong twice, tool surfaces
were removed by prompt instruction rather than isolation, and the maintainer
has said the harness is a point-in-time snapshot that will not be maintained
(upstream PRs #28 and #94).

The numbers from vendor benches built on this framework are meant to be
cited, so a stranger must be able to reproduce them.

Alternatives considered: a lean YAML-driven TypeScript harness on the host
(bench-browser's better modules extracted into a package), Inspect AI, and
Harbor. Inspect is model-centric and can already consume Harbor datasets.
The lean harness keeps one language and a fast loop but leaves us owning the
usage parsers and gives prompt-based isolation only.

## Decision

Harbor (`harbor` >= 0.22, Docker) is the runtime and result format. Each
condition is one Harbor agent config with a distinct name. Per-trial
`result.json` and the ATIF trajectory are the source of truth for tokens,
cost, timing and turns. Verifiers write `reward.txt` or `reward.json`.
`harbor job regrade` re-judges saved trajectories.

## Consequences

- We stop owning agent adapters and usage parsing.
- Anyone with Harbor can rerun a vendor dataset with `harbor run`.
- Tool surfaces are installed in the image, so isolation is real.
- Docker per trial slows the authoring loop. Iterate on a tiny smoke matrix.
- Python lives alongside the TypeScript vendor tools, because condition
  subclasses and the generator are Python.
- Harbor has no condition concept and its job stats bucket by
  `agent__model__dataset`, so conditions need distinct agent names.
- Harbor's built-in metrics only see rewards. Cost, tokens and timing are
  aggregated by our own report layer from the per-trial files.
- Comparisons are within one vendor across conditions. Harbor does not make
  railway-axi comparable to cloudflare-axi, and nothing should imply it does.
