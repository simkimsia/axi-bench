#!/bin/bash
# Deterministic verifier. Copied to /tests/test.sh and run after the agent.
# The exit code is NOT the signal. Write the reward to
#   /logs/verifier/reward.txt   (single number), or
#   /logs/verifier/reward.json  (named metrics, e.g. {"correct": 1, "turns_ok": 1})
set -euo pipefail
EXPECTED=42
mkdir -p /logs/verifier
# Replace with a real check against the agent's final answer or workspace state.
ANSWER=$(tail -n 1 /logs/agent/final_answer.txt 2>/dev/null || echo "")
if [ "$ANSWER" = "$EXPECTED" ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
