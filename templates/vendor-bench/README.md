# bench/

Benchmark for this AXI tool, in the axi-bench layout. Copy this directory into
`<vendor>-axi/bench/` and replace the example task.

```
bench/
  dataset.toml          Harbor dataset manifest
  conditions.yaml       tool surfaces to compare (axi-bench turns each into a Harbor agent)
  tasks/<task>/         one Harbor task per directory
    task.toml
    instruction.md
    environment/Dockerfile
    tests/test.sh       writes /logs/verifier/reward.txt or reward.json
    solution/solve.sh   oracle, proves the task is solvable
  published-results/    rendered report + every trajectory of a published run
```

Rules: pinned fixtures only, an oracle per task, a limitations section in every
published report. See axi-bench `docs/methodology.md`.
