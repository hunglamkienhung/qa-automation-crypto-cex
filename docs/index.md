# qa-automation-crypto-cex — docs

QA automation for a centralized-exchange domain — swap, transfer, bridge — with
one shared grading core and two stacks (Node + Python) that read one Gherkin set
and return the **same verdict for every case**.

→ **[The repository](https://github.com/hunglamkienhung/qa-automation-crypto-cex)** ·
[README](https://github.com/hunglamkienhung/qa-automation-crypto-cex#readme)

## Contents

- **[Architecture](ARCHITECTURE.md)** — one core, two stacks, why the domain
  pairs a live read-only exchange (Kraken) with a self-written mini-cex that has
  a real database, and the exact integer money model.
- **[Grading](GRADING.md)** — Failed > Blocked > Passed, why an outage is never
  a failure, and a gate that fails in both directions.
- **[Gherkin conventions](GHERKIN.md)** — one feature set bound in two stacks.
- **[Queue format](QUEUE-FORMAT.md)** — the append-only source of truth.
- **[Demo script](DEMO.md)** — a five-minute walkthrough, least-dependent first.

## At a glance

| Tier | Target | Cases |
|---|---|---|
| DB | mini-cex SQLite, opened directly | 14 |
| API | mini-cex REST (accounts, transfer, swap, bridge) | 18 |
| API | Kraken public API (read-only) | 6 |
| BOT | the pure risk gate | 10 |
| FE | mini-cex screens (Playwright) | 6 |
| | **Total** | **54** |
