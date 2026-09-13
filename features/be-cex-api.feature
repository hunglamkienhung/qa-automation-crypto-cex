@module:02-cex-api @be @api @minicex
Feature: The mini-cex REST API over its store

  The same operations the DB tier verifies from the rows are exercised here
  through HTTP, and the responses are checked against what a client is
  promised: the right status, the quoted amounts, a refusal with the right
  code, an idempotent replay.

  Background:
    Given the store is open and the service is reachable

  @case:15 @priority:high
  Scenario: The exchange lists its assets
    When the assets are read
    Then the asset list includes BTC, ETH, SOL, USD
    And every listed asset has a name and a USD price

  @case:16 @priority:high
  Scenario: The exchange lists its tradable pairs
    When the pairs are read
    Then the pair list includes BTC/USD and ETH/USD
    And no pair has the same asset on both legs

  @case:17 @priority:high
  Scenario: A quote returns the net after fee
    When a quote of 1.0 BTC to USD is requested
    Then the quote net equals the gross minus the fee
    And the quote fee matches the pair fee in basis points

  @case:18 @priority:high
  Scenario: Creating an account returns a handle and a token
    When a fresh account "alice" is created
    Then the response status is 201
    And the response has a token

  @case:19 @priority:medium
  Scenario: A duplicate handle is refused
    Given a fresh account "alice"
    When an account is created with the same handle as "alice"
    Then the response status is 409
    And the response code is "handle_taken"

  @case:20 @priority:high
  Scenario: A deposit is accepted and shows in balances
    Given a fresh account "alice"
    When "alice" deposits 1.0 BTC
    Then the response status is 201
    And the API balance for "alice" in BTC is 1.0 BTC

  @case:21 @priority:high
  Scenario: A swap moves balances by the quoted amounts
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" swaps 0.5 BTC to USD
    Then the response status is 201
    And the swap response output equals the quote for 0.5 BTC to USD

  @case:22 @priority:high
  Scenario: A swap below the slippage floor is refused
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" swaps 0.5 BTC to USD demanding at least 1000000.0 USD out
    Then the response status is 409
    And the response code is "slippage"

  @case:23 @priority:medium
  Scenario: A swap of a delisted asset is refused
    Given a fresh account "alice"
    And "alice" deposits 100.0 DOGE
    When "alice" swaps 10.0 DOGE to USD
    Then the response status is 409
    And the response code is "asset_inactive"

  @case:24 @priority:high
  Scenario: A transfer moves funds between accounts
    Given a fresh account "alice"
    And a fresh account "bob"
    And "alice" deposits 1.0 ETH
    When "alice" transfers 0.4 ETH to "bob"
    Then the response status is 201
    And the API balance for "bob" in ETH is 0.4 ETH

  @case:25 @priority:high
  Scenario: A transfer over balance is refused
    Given a fresh account "alice"
    And a fresh account "bob"
    And "alice" deposits 0.1 ETH
    When "alice" tries to transfer 9.0 ETH to "bob"
    Then the response status is 409
    And the response code is "insufficient_funds"

  @case:26 @priority:high
  Scenario: A repeated deposit with the same idempotency key makes one credit
    Given a fresh account "alice"
    When "alice" deposits 1.0 BTC with key "dep-1"
    And "alice" deposits 1.0 BTC with key "dep-1"
    Then the API balance for "alice" in BTC is 1.0 BTC
    And the second deposit was an idempotent replay

  @case:27 @priority:high
  Scenario: An unauthenticated write is refused
    When a deposit is attempted with no token
    Then the response status is 401

  @case:28 @priority:high
  Scenario: A bridge withdrawal locks and can be confirmed
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" bridge-withdraws 0.3 BTC to chain "ethereum"
    Then the response status is 201
    And the bridge op is in status "locked"
    When the bridge op is confirmed
    Then the bridge op is in status "credited"

  @case:29 @priority:high
  Scenario: A bridge withdrawal over the cap is refused
    Given a fresh account "alice"
    And "alice" deposits 10.0 BTC
    When "alice" bridge-withdraws 5.0 BTC to chain "ethereum"
    Then the response status is 409
    And the response code is "over_cap"

  @case:30 @priority:high
  Scenario: A bridge to an unknown chain is refused
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" bridge-withdraws 0.1 BTC to chain "mars"
    Then the response status is 400
    And the response code is "unknown_chain"

  @case:31 @priority:medium
  Scenario: A bridge deposit is idempotent by external tx
    Given a fresh account "alice"
    When a bridge deposit of 2.0 ETH for "alice" from chain "ethereum" with tx "dep-y" is observed
    And the same bridge deposit is observed again
    Then the API balance for "alice" in ETH is 2.0 ETH
    And the second bridge deposit was an idempotent replay

  @case:32 @priority:medium
  Scenario: A swap of an unknown asset is not found
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" swaps 0.1 BTC to ZZZ
    Then the response status is 404
