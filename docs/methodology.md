# Methodology

What a published axi-bench result must satisfy, and why. Compiled 2026-09-08
from the sources below. Each item names the source so the rule can be revisited
if the field moves.

## Checklist

1. **Freeze everything.** Pin model, prompt, harness, tool versions, and the
   container image. Record them in the report. (ABC checklist items T.1, T.6;
   Harbor `task.toml`.)
2. **Deterministic verifier per task.** State checks or scripts, not a judge.
   If a judge is unavoidable, pilot it against human labels and use a different
   model family from the agent. (ABC O.c.1; tau2-bench DB-hash grading;
   preference-leakage paper arXiv 2502.01534.)
3. **Trivial-agent baseline.** Report what a do-nothing agent and the raw
   vendor CLI score. (ABC R.12, R.13.)
4. **k >= 5 repeats per task per condition.** Report mean pass@1, pass^k, and
   per-task spread. (Terminal-Bench `-k 5`; MCPMark; tau-bench pass^k.)
5. **Confidence intervals on every headline number.** Paired-difference CI or
   p-value between conditions, clustered by task because repeats of one task
   are not independent. (Miller, "Adding Error Bars to Evals", arXiv 2411.00640;
   ABC R.10.)
6. **Cost next to accuracy.** Input and output tokens, turns, wall-clock, and
   dollars, plus an accuracy-versus-cost table or Pareto plot. (Kapoor et al.
   "AI Agents That Matter", arXiv 2407.01502; HAL, arXiv 2510.11977.)
7. **Publish every trajectory and verifier output** in a standard log format.
   (SWE-bench trace rule; HAL; Inspect `.eval` logs.)
8. **Held-out tasks.** Written by someone other than the tool author, or at
   minimum written before the tool. (Kapoor holdout finding; ABC T.5.)
9. **Explicit construct statement.** Say which capability the interface delta
   is claimed to affect. (ABC R.5, R.6; arXiv 2606.17799.)
10. **Oracle solution per task** proving solvability. (ABC T.9; Harbor
    `solution/solve.sh`.)
11. **Cross-model replication** of at least one condition. Format effects are
    model-dependent; TOON saved tokens on some models and cost accuracy on
    others. (Notation Matters, arXiv 2605.29676.)
12. **Limitations section** naming known biases: single developer, author-built
    tool, judge choice, task count. (ABC R.7 to R.9.)

## Weaknesses of the upstream AXI study to avoid repeating

The upstream `bench-github` study (425 runs, 2026-03-21) is the prior art this
framework replaces. Its known problems:

- Judge and agent were the same model (Sonnet 4.6).
- Point estimates only. Per-task cells are n=5 with no intervals.
- Three grading hints pinned live facts about `openclaw/openclaw`. A re-run
  four months later scored the axi condition at 83.5% instead of the published
  100%. (Upstream issue #117.)
- Cost accounting undercounted unpriced models as $0 until upstream PR #177.
  The published tables predate the fix.
- Tasks were written by the author of the tool under test.
- Per-condition prompts were asymmetric (the axi prompt said `gh` was
  unavailable; the cli prompt listed examples).
- No limitations section.

## Sources

- ABC checklist: Zhu et al., "Establishing Best Practices for Building Rigorous
  Agentic Benchmarks", NeurIPS 2025, arXiv 2507.02825.
- Miller, "Adding Error Bars to Evals", arXiv 2411.00640.
- Kapoor et al., "AI Agents That Matter", arXiv 2407.01502.
- HAL: Holistic Agent Leaderboard, ICLR 2026, arXiv 2510.11977.
- tau-bench arXiv 2406.12045; tau2-bench evaluation docs.
- MCPMark arXiv 2509.24002; MCP-Universe arXiv 2508.14704.
- Preference leakage arXiv 2502.01534; self-preference bias arXiv 2410.21819.
- Notation Matters arXiv 2605.29676.
- "Coding Benchmarks Are Misaligned with Agentic SE", arXiv 2606.17799.
- Harbor docs: https://harborframework.com/docs/tasks
- Terminal-Bench 3.0: https://www.tbench.ai/news/terminal-bench-3-0
