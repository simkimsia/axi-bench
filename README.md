# axi-bench

A shared benchmark harness for comparing **agent tool interfaces**: the same
model, the same tasks, different ways of reaching the same service (raw vendor
CLI, an [AXI](https://axi.md) wrapper, an MCP server, code-execution wrappers).
Tasks are authored in YAML and compiled into the
[Harbor](https://harborframework.com) task format, so runs are containerized,
reproducible, and runnable by any Harbor-compatible runner.

Comparisons are **within one vendor**: railway-axi versus the Railway CLI, not
railway-axi versus cloudflare-axi. Different services have different tasks, so
cross-vendor numbers are not meaningful. What the framework standardizes is the
method, so each vendor's result can be trusted and re-run.

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

axi-bench takes the good parts of those harnesses (YAML task authoring,
condition matrix, usage parsing, command-policy validation, trajectory-based
judging) and puts them on a standard runtime with a methodology that holds up
to review.

## Ownership split

The framework owns the **how**. Each vendor repo owns the **what**.

| Lives in `axi-bench` (this repo)            | Lives in each `<vendor>-axi` repo under `bench/` |
| ------------------------------------------- | ------------------------------------------------ |
| YAML to Harbor task compiler (`axi-bench generate`) | `tasks.yaml`: prompt, category, verifier per task |
| Condition model (one Harbor agent config per tool surface) | `conditions.yaml` naming which surfaces to compare |
| Claude Code / Codex usage and cost parsing  | `environment/Dockerfile` installing every surface, pinned |
| Trajectory LLM judge and verifier helpers   | `fixtures/create.sh` and `destroy.sh` for the live-service fixture |
| Statistics and report generation (CIs, paired differences, cost Pareto) | `published-results/` with every trajectory and the rendered report |
| Command-policy validator                    | Oracle commands proving each task is solvable |
| Templates and the methodology checklist     | A limitations section specific to that vendor |

So yes: every `*-axi` ships its own tasks and results. The framework is what
makes each vendor's within-tool comparison use the same method.

## How a benchmark run works

1. A vendor repo's `bench/tasks.yaml` lists tasks the way upstream did: a
   prompt, a category, and a verifier (an expected value, a shell check, or a
   judge hint as a last resort). One shared `environment/Dockerfile` installs
   every tool surface being compared.
2. `axi-bench generate` compiles each YAML entry into a Harbor task directory
   (`instruction.md`, `task.toml`, `tests/test.sh`, `solution/solve.sh`) under
   a git-ignored `generated/`. Anyone with plain Harbor can run that output.
3. `conditions.yaml` lists the conditions. axi-bench turns each into a distinct
   Harbor agent config: same model, distinct agent name, condition-specific
   `env`, `mcp_servers`, and appended instructions.
4. Harbor runs the full conditions × tasks × repeats matrix, capturing tokens,
   cost, wall-clock, and the ATIF trajectory per trial.
5. The verifier runs in a separate container. Deterministic checks first. Where
   a judge is unavoidable it reads the trajectory and writes `reward.json`;
   `harbor job regrade` re-judges without re-running agents.
6. axi-bench aggregates the per-trial `result.json` files into a report with
   confidence intervals, paired differences clustered by task, pass^k, and an
   accuracy-versus-cost table.

## Mapping to Harbor

| axi-bench concept        | Harbor concept |
| ------------------------ | -------------- |
| Task set                 | `tasks.yaml` compiled to one dataset (`dataset.toml`) of task directories sharing one image |
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

## Decisions

The three agreements this framework rests on are recorded with context and
alternatives in [`docs/decisions/`](docs/decisions/): Harbor is the runtime
(001), YAML is the authoring surface (002), fixtures are seeded projects
created and destroyed by script (003).

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
- Recreatable fixtures. AXI tools wrap live services, so a task reads from a
  fixture the vendor bench creates by script before a run and destroys after.
  Expectations depend only on properties that survive recreation.
- A trivial-agent baseline and a limitations section in every published result.

## Planned layout

```
axi-bench/
  src/axi_bench/
    generate.py       tasks.yaml + Dockerfile → Harbor task dirs + dataset.toml
    conditions.py     conditions.yaml → Harbor AgentConfig list
    agents/           thin Claude Code / Codex subclasses, one per condition
    judge/            trajectory judge and reward.json writer
    policy.py         command-prefix policy validator
    stats.py          CIs, paired differences, pass^k
    report.py         markdown + CSV report from Harbor job results
  templates/vendor-bench/   copy into <vendor>-axi/bench/
  docs/methodology.md
  docs/decisions/           dated decision records
  docs/examples/generated-task/   what generate.py emits for one YAML entry
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
