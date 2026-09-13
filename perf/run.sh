#!/usr/bin/env bash
# Load-test mini-cex with Locust, headless, with a pass/fail gate.
#
#   bash perf/run.sh [users] [spawn-rate] [duration]
#
# Seeds a fresh mini-cex, then drives the market-data reads, quoting, and a
# fund+rest-an-order trade flow under concurrency. The locustfile's `quitting`
# hook exits non-zero if the error ratio or p95 latency crosses
# PERF_MAX_FAIL_RATIO / PERF_MAX_P95_MS, so this doubles as a CI perf gate.
set -euo pipefail
USERS="${1:-40}"
RATE="${2:-10}"
DUR="${3:-30s}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export MINI_CEX_DB="${MINI_CEX_DB:-/tmp/mini-cex-perf/mini-cex.db}"
export MINI_CEX_PORT="${MINI_CEX_PORT:-8110}"
HOST="http://127.0.0.1:${MINI_CEX_PORT}"

( cd services/mini-cex && bash serve.sh up )

python -m pip install -q -r perf/requirements.txt
locust -f perf/locustfile.py --headless -u "$USERS" -r "$RATE" -t "$DUR" --host "$HOST" --only-summary
