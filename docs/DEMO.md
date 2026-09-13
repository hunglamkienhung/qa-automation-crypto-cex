# Demo script (about 5 minutes)

Ordered so the earliest step needs the least to be working. Each step stands on
its own; stop wherever your time runs out.

## 1. The grading core, offline (30 seconds)

Needs nothing external. Proves the rule that everything else rests on.

```bash
cd core/node && node --test "selftest/*.test.js"
cd ../python && pip install -e . && python -m pytest selftest -q
```

Point to make: `Failed > Blocked > Passed` is asserted in both proposition
orders, and the measurement controls (a clean sample must read clean, a
known-dirty sample must be flagged) run here — the tooling is tested before it
is trusted.

## 2. One spec, two stacks, one verdict (2 minutes)

Bring the exchange up and run the backend in each stack:

```bash
bash scripts/run-be.sh node
bash scripts/run-be.sh python
```

Point to make: both read the same `features/*.feature` and land on the same
verdict for every case — swap, transfer, bridge, the Kraken cross-check, and the
pure risk gate.

## 3. Real write paths with a real database (1 minute)

The heart of the exchange, all asserted from the SQLite rows, not the API's own
word:

- a **transfer** debits the sender and credits the recipient by the same amount,
  and the total is conserved;
- a **swap** debits the input and credits the net output, and the ledger sums to
  the running balance on both legs;
- a **bridge** withdrawal locks the balance, and a deposit credits exactly once
  even when its external tx is observed twice.

```bash
# already exercised by run-be.sh; to see the refusals:
#   an overdrawn transfer, a swap below the slippage floor, a bridge over the cap
```

## 4. The gate that fails both ways (30 seconds)

```bash
cd node && QA_DOMAIN_ROOT=.. npx qa-verify
```

Point to make: the gate checks the *shape* of the run against
`fixtures/expected-results.json`. It catches a Passed→Failed regression **and** a
Failed→Passed check that stopped checking; no live-source case is ever declared
`Failed`, so an outage cannot turn the build red.

## 5. The screens (if a browser is handy)

```bash
bash scripts/run-fe.sh node    # the mini-cex home and wallet pages
```

Point to make: the FE tier checks each figure on screen against the same API the
BE tier reads — the frontend is held to the backend's numbers. When the service
or browser is unavailable, those cases grade Blocked, never Failed.

## If nothing external is available

Step 1 and the pure risk gate stand alone — the bot tier touches no source, so
`bash scripts/run-be.sh node` grades it Passed even with no network. Everything
live-dependent (Kraken, a browser) grades Blocked with a reason, and the gate
stays green because Blocked is a declared, acceptable status.
