# 003: Fixtures are seeded projects created and destroyed by script

Status: accepted 2026-09-08

## Context

AXI tools wrap live services (Railway, GitHub, Cloudflare), so tasks cannot
run offline and a task must read something real. Upstream's tasks read
arbitrary live state of a public repo; three grading hints went stale and a
re-run four months later scored the axi condition at 83.5% instead of the
published 100% (upstream issue #117).

Alternatives considered: a permanently running fixture project that is
frozen after the first run (recurring cost, an account dependency, one
accidental change away from wrong answers, and reproducible only by its
owner), and record-and-replay of the vendor API (pins both sides of the
contract, but real work not needed for a first citation).

## Decision

Each vendor bench owns `bench/fixtures/create.sh` and `destroy.sh`.
`create.sh` builds a seeded project from nothing with the vendor CLI: named
resources, a fixed number of deployments or commits, one source of
deterministic log lines, more than one environment where the vendor has
them. A blank project is not a fixture; there is nothing to ask about.

Lifecycle per published run: create, run the matrix, destroy. Nothing stays
alive between runs. Regrading reads saved trajectories and needs no fixture.

Task expectations depend only on properties that survive recreation: names,
counts, statuses, log contents, which resource is newest. Never IDs,
timestamps or generated domains.

The published report records the fixture script's commit hash and the vendor
CLI version.

## Consequences

- No recurring cost and no long-lived account state.
- The fixture is in the repo, so reproduction is by anyone, not by the owner.
- The fixture script is written first, because task expectations are
  derived from what it can build deterministically.
- The vendor's API output can still drift between our run and a reader's.
  The fixture pins our side of the contract only; every limitations section
  says so. Record-and-replay is the later hardening if drift becomes a
  problem.
- `create.sh` and `destroy.sh` are the only things in a bench allowed to
  mutate vendor infrastructure. Tasks stay read-only.
