# Performance tests (Locust)

Load tests for the **mini-cex** service — the performance counterpart to the
functional BDD suite. They drive the same REST API under concurrency, validating
every response so a wrong status is a failure, not just a slow success. Amounts
are in base units (1e8 per whole coin), the same convention the service uses.

## Run

```bash
pip install -r perf/requirements.txt
bash perf/run.sh                 # 40 users, spawn 10/s, 30s, against a fresh mini-cex
bash perf/run.sh 100 20 60s      # heavier
```

An interactive web UI (charts, live control):

```bash
( cd services/mini-cex && MINI_CEX_DB=/tmp/mini-cex-perf/mini-cex.db bash serve.sh up )
locust -f perf/locustfile.py --host http://127.0.0.1:8110      # then open http://localhost:8089
```

## The traffic model

| Class | Weight | What it does |
|---|---|---|
| `MarketData` | 5 | Reads `/assets`, `/orderbook/BTC/USD`, `/fees`. |
| `Quoter` | 2 | Prices a swap via `/quote` (pure pricing). |
| `Trader` | 2 | Opens an account, deposits, rests a small limit buy, reads its orders. |

## The pass/fail gate

The locustfile's `quitting` hook exits **non-zero** when a run breaches either
threshold, so `run.sh` doubles as a CI performance gate:

- error ratio > `PERF_MAX_FAIL_RATIO` (default `0.01` — 1%)
- p95 latency > `PERF_MAX_P95_MS` (default `750` ms)

Override per environment, e.g. `PERF_MAX_P95_MS=400 bash perf/run.sh`.
