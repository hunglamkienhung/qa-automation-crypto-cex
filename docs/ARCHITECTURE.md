# Architecture

## Shape

```
core/                         one grading/queue/report/bugflow core
  node/  python/              same architecture, one per stack
services/
  mini-cex/                   SQLite + REST + HTML custodial exchange -- an object of test
features/*.feature            one Gherkin set, shared by both stacks
fixtures/                     testcases.json (IDs) · expected-results.json (shape)
node/   python/               the two stacks: be/{db,api,bot} fe/ui
testcases/                    catalogue generated from the features
scripts/                      the exact commands CI runs
```

Dependency direction is one way: `the domain → core`. The core knows nothing
about the domain. The domain links the core without publishing it — Node via
`"@portfolio/core": "file:../core/node"`, Python via `pip install -e ../core/python`.

## Why a self-written exchange next to a real one

Reading a live exchange's public data proves you can measure the real world; it
cannot prove you can test a **write** path, because you cannot safely move funds
on someone else's exchange. So the domain pairs a live read-only venue with a
self-written one you fully control:

```
Kraken public API (read)  +  mini-cex (read/write, own DB)
```

The self-written mini-cex is where a transfer refuses to overdraw, a swap
conserves value at the quoted rate and honours a slippage floor, a bridge op is
applied at most once per external tx and never exceeds its cap. Kraken is where
the listed assets and prices are checked against a venue nobody here can tune to
pass.

## The money model

Every amount is an integer in **base units**: 1e8 per whole coin, the same scale
for every asset, so comparisons are exact and there is no float in the money
path. Prices are USD per whole coin in **micro-dollars** (1e6). A swap's
cross-asset arithmetic is done in big integers and stored as the integers the
schema constrains (`amount >= 0`, `delta <> 0`, a bounded set of ledger reasons).

Each account+asset has a running `balances.amount` and an append-only `ledger`;
the invariant the DB tier checks is that the ledger's movements sum to the
running balance. A transfer, swap or bridge op writes its balance change and its
ledger line in one transaction — any failure rolls back the whole thing.

## Data flows the tests follow

```
HTTP --> mini-cex --> SQLite
         the DB tier reads the SQLite directly; the API tier checks each
         response against it; the FE tier checks the screen against the API.
Kraken public API --> the API tier cross-checks mini-cex's assets and prices.
```

Each cross-check compares exactly one pair, so a divergence names one layer:
DB ↔ API is the REST layer; screen ↔ API is the FE; mini-cex ↔ Kraken is the
listing/price sanity.

## One feature set, two stacks

A feature file is authored once. Cucumber (Node) and pytest-bdd (Python) each
bind their own step definitions to it and file results to their own queue under
the same immutable case IDs. The gate then requires the run to match
`expected-results.json`. Executed two independent ways, the same specification
lands on the same verdict — or the build stops.

See [GRADING.md](GRADING.md) for how a verdict is decided and
[GHERKIN.md](GHERKIN.md) for the feature conventions.
