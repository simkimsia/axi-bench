# Project agent memory

Project-intrinsic knowledge for agents working on axi-bench.

## What this is

A benchmark harness framework for tool-interface comparisons (raw CLI vs AXI
wrapper vs MCP vs code-mode, same model, same tasks) built on the Harbor task
format. It replaces the copy-paste `bench-github/` and `bench-browser/`
harnesses in upstream `kunchenguid/axi`. Vendor `*-axi` repos ship their own
`bench/` directory (tasks + results); this repo ships the runner glue, judge,
stats, and report. See README "Ownership split".

## Decisions already made (do not relitigate)

- **Separate repo, not an upstream refactor.** Upstream declined to maintain the
  harness (PRs #28, #94) and its VISION.md caps shared infra. Do not propose
  Harbor adoption or harness consolidation upstream. Restore-class fixes only.
- **Harbor is the runtime and result format. YAML is the authoring format.**
  Vendors write `tasks.yaml` (prompt, category, verifier) plus one shared
  Dockerfile; `generate.py` compiles that into Harbor task directories under a
  git-ignored `generated/`. Never ask a vendor to hand-write `task.toml`.
  Python >= 3.12, `harbor` >= 0.22, Docker. No non-container runtime.
- **Comparisons are within one vendor, across conditions.** Different services
  have different tasks, so never build or imply a cross-vendor leaderboard.
  The framework standardizes method, not scores.
- **One Harbor agent per condition.** Harbor has no condition concept and its
  job stats bucket by `agent__model__dataset`. Conditions with the same agent
  name merge silently. Each condition is a thin subclass of the Claude Code or
  Codex installed agent with a distinct `name()`.
- **Judge never shares a model family with the agent.** Upstream used Sonnet 4.6
  for both. Preference leakage is a known bias.
- **Deterministic verifiers first.** `tests/test.sh` writes
  `/logs/verifier/reward.txt` or `reward.json`. Judge only for free-text answers.
- **No live-service fixtures.** Upstream tasks hit `openclaw/openclaw` live and
  three grading hints went stale (upstream issue #117). Pin fixtures in the
  image or in a dedicated fixture repo frozen at a commit.
- **Start from bench-browser, not bench-github.** Its grader (retries,
  truncation, system-reminder stripping), reporter (methodology and limitations
  sections), validation (`command_policy`), isolation (`--strict-mcp-config`,
  `execFileSync`) and per-run upsert are all better. bench-github contributes
  only the Codex JSONL parser and `--parallel`.

## Harbor facts that shape the code

- `task.toml` schema 1.4: `[task]`, `[environment]` (docker_image or Dockerfile,
  `env`, `mcp_servers`, `skills_dir`, `network_mode`), `[agent]`, `[verifier]`
  (`environment_mode = "shared"|"separate"`, `env` with `${HOST_VAR}`
  interpolation, `collect` hooks), `[solution]`, `[[steps]]`.
- Verifier exit code is not the signal; the reward file is.
- A trajectory judge needs `environment_mode = "separate"` plus `collect` hooks
  that copy `/logs/agent/` (ATIF `trajectory.json`) into the verifier.
  `harbor job regrade` re-judges without re-running agents.
- Built-in `MetricConfig` types compute only over rewards. Cost, tokens and
  timing are in per-trial `result.json` and must be aggregated by `report.py`.
- `job.yaml` accepts a list of `agents:`; Harbor runs agents × datasets ×
  `n_attempts` in one job.
- Unverified as of 2026-09-08: whether agent-level `mcp_servers` merge with or
  replace task-level ones. Test before relying on either.

## Methodology rules for any published result

Read `docs/methodology.md` before adding a task, a condition, or a report
section. The short form: k >= 5 repeats, CIs everywhere, paired differences
clustered by task, cost next to accuracy, every trajectory published, oracle
solution per task, trivial-agent baseline, limitations section.

## Conventions

- `uv` for Python, `pyproject.toml` at root, package under `src/axi_bench/`,
  tests under `tests/` with pytest.
- Conventional commit messages (`feat:`, `fix:`, `docs:`).
- Vendor bench directories are copied from `templates/vendor-bench/`; changes to
  the template or to the `tasks.yaml` schema are a contract change and need a
  note in the README. `docs/examples/generated-task/` must stay in sync with
  what `generate.py` emits.
- Prose in this repo: plain sentences, no em dashes.

## Maintaining this file

Keep entries concise and durable; point at the authoritative file rather than
restating what the code shows. Prefer rewriting or pruning over appending.
