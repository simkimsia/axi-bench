# fixtures/

AXI tools wrap live services, so tasks cannot run fully offline. Instead each
vendor bench owns a fixture the tasks read from and never changes it after the
first published run: a dedicated project, repo, or account created for the
benchmark. Record here what the fixture is, when it was frozen, and how to
recreate it. Upstream's published results became non-reproducible because
tasks read arbitrary live state (kunchenguid/axi issue #117).
