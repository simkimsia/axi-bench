# fixtures/

AXI tools wrap live services, so tasks cannot run fully offline. Each vendor
bench therefore owns a fixture that a script can recreate from nothing, and the
fixture exists only while agent runs are happening.

- `create.sh` builds the fixture with the vendor CLI: a dedicated project or
  repo, named resources, a fixed number of deployments or commits, one source
  of deterministic log lines. `destroy.sh` removes it.
- Task expectations in `tasks.yaml` must be invariant under recreation: names,
  counts, statuses, log contents, which resource is newest. Never IDs,
  timestamps, or generated URLs.
- Lifecycle per published run: create, run the matrix, destroy. Regrading reads
  saved trajectories and does not need the fixture.
- The published report records this script's commit hash and the vendor CLI
  version. State in the limitations section that the vendor's API output can
  drift between runs; the fixture pins your side of the contract, not theirs.

Upstream's published results became non-reproducible because tasks read
arbitrary live state with no fixture at all (kunchenguid/axi issue #117).
