#!/usr/bin/env bash
# Seed a fresh mini-cex, then run the BE tiers (DB + mini-cex API + live Kraken
# API + the pure risk gate) for one stack and gate on the shape of the run. No
# browser.
set -euo pipefail
STACK="${1:-node}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export MINI_CEX_DB="${MINI_CEX_DB:-/tmp/mini-cex/mini-cex.db}"
( cd services/mini-cex && bash serve.sh up )
if [ "$STACK" = node ]; then
  ( cd node && npm install --no-audit --no-fund )
  ( cd node && QA_DOMAIN_ROOT=.. npx cucumber-js --tags "@be" )
  ( cd node && QA_DOMAIN_ROOT=.. npx qa-report )
else
  python -m venv .venv-ci && . .venv-ci/bin/activate
  ( cd python && pip install -q -r requirements.txt )
  ( cd python && QA_DOMAIN_ROOT=.. python -m pytest -m "be" -q ) || true
  ( cd python && QA_DOMAIN_ROOT=.. qa-report )
fi
