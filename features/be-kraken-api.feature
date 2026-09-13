@module:03-kraken-api @be @api @kraken
Feature: The live Kraken public API, read-only

  The exchange the mini-cex is modelled on. These read only public market data
  -- no key, no account -- and cross-check the mini-cex's listed assets and
  prices against a real venue. Kraken is not a system under test: when it is
  unreachable, rate-limited, or serves a challenge page, the case grades
  Blocked, never Failed.

  @case:33 @priority:medium
  Scenario: Kraken lists its assets
    When the Kraken asset list is read
    Then the Kraken asset list is non-empty

  @case:34 @priority:medium
  Scenario: Kraken lists its asset pairs
    When the Kraken pair list is read
    Then every Kraken pair name is a non-empty string

  @case:35 @priority:high
  Scenario: The mini-cex crypto assets trade on Kraken
    When the Kraken pair list is read
    Then a USD pair exists on Kraken for each of BTC, ETH, SOL

  @case:36 @priority:high
  Scenario: Kraken quotes a positive BTC price
    When the Kraken last price for "XBT/USD" is read
    Then the Kraken price is a positive number

  @case:37 @priority:high
  Scenario: The mini-cex BTC price is the same order of magnitude as Kraken's
    When the Kraken last price for "XBT/USD" is read
    Then the mini-cex BTC price is the same order of magnitude as Kraken's

  @case:38 @priority:medium
  Scenario: Kraken quotes a positive ETH price
    When the Kraken last price for "ETH/USD" is read
    Then the Kraken price is a positive number
