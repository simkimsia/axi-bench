# axi-bench

A shared benchmark harness for comparing **agent tool interfaces**: the same
model, the same tasks, different ways of reaching the same service (raw vendor
CLI, an [AXI](https://axi.md) wrapper, an MCP server, code-execution wrappers).
Built on the [Harbor](https://harborframework.com) task format so tasks are
containerized, reproducible, and runnable by any Harbor-compatible runner.

## Status

Design stage (v0). No runnable code yet. The README and `docs/` are the plan;
`templates/vendor-bench/` shows the directory every `*-axi` repo will ship.

## Why this exists

The upstream [`kunchenguid/axi`](https://github.com/kunchenguid/axi) monorepo
carries two harnesses, `bench-github/` and `bench-browser/`. They are copy-paste
forks of each other that have diverged, and the maintainer has said the harness
is a point-in-time snapshot that will not be maintained, and invited independent
benchmarks instead. Meanwhile no tool in the community catalog ships a benchmark
of its own.

axi-bench takes the good parts of those harnesses (condition matrix, usage
parsing, command-policy validation, trajectory-based judging) and puts them on a
standard task format with a methodology that holds up to review.

## Ownership split

The framework owns the **how**. Each vendor repo owns the **what**.

| Lives in `axi-bench` (this repo)            | Lives in each `<vendor>-axi` repo under `bench/` |
| ------------------------------------------- | ------------------------------------------------ |
| Condition model (one Harbor agent config per tool surface) | `dataset.toml` and `tasks/` in Harbor format |
| Claude Code / Codex usage and cost parsing  | `conditions.yaml` naming which surfaces to compare |
| Trajectory LLM judge and verifier helpers   | Per-task deterministic verifiers (`tests/test.sh`) |
| Statistics and report generation (CIs, paired differences, cost Pareto) | `published-results/` with every trajectory and the rendered report |
| Command-policy validator                    | Oracle solutions proving each task is solvable |
| Templates and the methodology checklist     | A limitations section specific to that vendor |

So yes: every `*-axi` ships its own tasks and results. The framework is what
makes those results comparable across tools.

## How a benchmark run works

1. A vendor repo's `bench/tasks/<task>/` holds `instruction.md`, `task.toml`,
   `environment/Dockerfile`, `tests/test.sh`, and optionally `solution/solve.sh`.
   The Docker image installs every tool surface being compared.
2. `conditions.yaml` lists the conditions. axi-bench turns each into a distinct
   Harbor agent config: same model, distinct agent name, condition-specific
   `env`, `mcp_servers`, and appended instructions.
3. Harbor runs the full conditions × tasks × repeats matrix, capturing tokens,
   cost, wall-clock, and the ATIF trajectory per trial.
4. The verifier runs in a separate container. Deterministic checks first. Where
   a judge is unavoidable it reads the trajectory and writes `reward.json`;
   `harbor job regrade` re-judges without re-running agents.
5. axi-bench aggregates the per-trial `result.json` files into a report with
   confidence intervals, paired differences clustered by task, pass^k, and an
   accuracy-versus-cost table.

## Mapping to Harbor

| axi-bench concept        | Harbor concept |
| ------------------------ | -------------- |
| Task set                 | One dataset (`dataset.toml`), tasks with `environment/Dockerfile` |
| Condition                | One `AgentConfig` in `job.yaml`, distinct `name`, same `model_name` |
| Same agent everywhere    | Identical `model_name`; `import_path` differs per condition |
| Judge over trajectory    | Verifier in `environment_mode = "separate"` with `collect` hooks copying `/logs/agent/` |
| Cost and tokens          | `result.json` → `agent_result.{n_input_tokens,n_cache_tokens,n_output_tokens,cost_usd}` |
| Turns                    | ATIF `trajectory.json` → `final_metrics.total_steps` |
| Wall-clock               | `result.json` → `agent_execution.{started_at,finished_at}` |
| Repeats                  | `n_attempts`; `pass_at_k` in the job result |

Two Harbor gotchas drive the design. Harbor has no native "condition" concept,
and job-level stats bucket by `agent__model__dataset`, so two conditions with
the same agent name silently merge. Every condition therefore gets its own agent
name. And Harbor's built-in metrics only see rewards, not cost or tokens, so the
aggregation layer here reads the per-trial files directly.

## Methodology

The full checklist with sources is in [`docs/methodology.md`](docs/methodology.md).
The non-negotiables:

- Deterministic verifiers by default. A judge only for free-text answers, from a
  different model family than the agent, piloted against human labels.
- At least 5 repeats per task per condition. Report mean pass@1, pass^k, and
  per-task spread.
- Confidence intervals on every headline number. Paired differences between
  conditions, clustered by task.
- Cost, tokens, turns, and wall-clock next to accuracy, never instead of it.
- Every trajectory and verifier output published.
- Pinned fixtures. No task may depend on live state of a third-party service.
- A trivial-agent baseline and a limitations section in every published result.

## Planned layout

```
axi-bench/
  src/axi_bench/
    conditions.py     conditions.yaml → Harbor AgentConfig list
    agents/           thin Claude Code / Codex subclasses, one per condition
    judge/            trajectory judge and reward.json writer
    policy.py         command-prefix policy validator
    stats.py          CIs, paired differences, pass^k
    report.py         markdown + CSV report from Harbor job results
  templates/vendor-bench/   copy into <vendor>-axi/bench/
  docs/methodology.md
```

## Requirements (planned)

- Python >= 3.12, managed with `uv`
- `harbor` >= 0.22
- Docker
- Claude Code and/or Codex CLI on PATH for the agent conditions

## Related

- [kunchenguid/axi](https://github.com/kunchenguid/axi): the AXI spec, SDK, and
  the original harnesses this replaces.
- [Harbor](https://harborframework.com): task format and runner.
- [Terminal-Bench](https://www.tbench.ai): the largest Harbor-native benchmark.

## License

MIT
