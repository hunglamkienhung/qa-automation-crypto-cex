# Gherkin conventions

One feature set, in `features/*.feature`, read by both stacks. The conventions
exist so the same file binds cleanly in Cucumber and pytest-bdd and so the
catalogue can be generated from the features.

## Tags

- `@case:N` on every scenario. On a `Scenario Outline`, one `@case:N` per
  `Examples` block, so each parameterised row is its own catalogued ID. IDs are
  immutable; an `@case` with no catalogue entry is an error.
- `@module:NN-name`, and a tier tag: `@be`/`@fe` with `@db`/`@api`/`@bot`, plus a
  target tag (`@minicex`, `@kraken`). The two stacks select the same set —
  `cucumber-js --tags "@be and @db"` and `pytest -m "be and db"` — because the
  Python markers mirror the Cucumber tags.
- `@priority:high|medium|low`.

## Writing steps that bind in both stacks

- Prefer plain, quoted arguments. Cucumber Expressions treat `/` as
  **alternation** — "add/remove" silently becomes "add" or "remove"; avoid `/`
  in step text. pytest-bdd's `parse` will not match an empty `{string}`; give the
  empty case its own step ("... with no term") rather than passing `""`.
- Keep one definition per phrasing. In Cucumber, Given/When/Then share one
  registry, so the same text defined twice is an ambiguous-step error -- define
  it once (any keyword matches any usage). pytest-bdd is the opposite: it matches
  on the keyword, so a step used as both `And`(Given) and `When` must carry BOTH
  `@given` and `@when` decorators.
- pytest-bdd's `parse` fails to match a pattern with two typed float fields
  (`{a:f} ... {b:f}`); use the general-number type `{a:g}` instead.
- A step that reads a live source routes its named unreachable error into
  Blocked (see [GRADING.md](GRADING.md)); it never lets an outage become a
  Failed assertion.

## "This cannot be observed"

When something genuinely cannot be checked from where the test stands, say so in
Gherkin rather than asserting it anyway or deleting the line:

```gherkin
But "the live exchange's private balances" cannot be verified because
    "Kraken's public API exposes only market data, no accounts"
```

That records the gap as Blocked with a reason, which is honest, instead of a
false Passed that nothing tracks.

## The catalogue is generated

`testcases/build.js` derives `fixtures/testcases.json` and `TestCases.md` from
the feature files themselves, so the catalogue cannot drift from what runs — run
with `--check` in CI.
