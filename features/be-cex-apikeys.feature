@module:07-cex-apikeys @be @minicex @api
Feature: Scoped API keys with rate limits

  A programmatic client authenticates with an API key in the X-API-Key header
  instead of the account's Bearer token. A key carries a scope -- read, trade or
  withdraw -- and a per-minute rate limit, so a leaked read key cannot move
  funds and a busy key cannot hammer the service.

  Background:
    Given the store is open and the service is reachable

  @case:79 @priority:high
  Scenario: Minting a key returns the key and its scope
    Given a fresh account "alice"
    When "alice" mints a "trade" API key
    Then the response status is 201
    And the minted key has scope "trade"

  @case:80 @priority:high
  Scenario: A read-scoped key cannot place an order
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" holds a "read" API key
    When the key places a limit sell of 0.5 BTC at 60000 USD
    Then the response status is 403
    And the response code is "wrong_scope"

  @case:81 @priority:high
  Scenario: A trade-scoped key can place an order
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" holds a "trade" API key
    When the key places a limit sell of 0.5 BTC at 60000 USD
    Then the response status is 201

  @case:82 @priority:high
  Scenario: A trade-scoped key cannot withdraw
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" holds a "trade" API key
    When the key withdraws 0.1 BTC
    Then the response status is 403
    And the response code is "wrong_scope"

  @case:83 @priority:high
  Scenario: A withdraw-scoped key can withdraw
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" holds a "withdraw" API key
    When the key withdraws 0.1 BTC
    Then the response status is 201

  @case:84 @priority:high
  Scenario: A revoked key is rejected
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" holds a "trade" API key
    And the key is revoked
    When the key places a limit sell of 0.5 BTC at 60000 USD
    Then the response status is 401

  @case:85 @priority:high
  Scenario: An unknown key is rejected
    When an unknown key places a limit sell of 0.5 BTC at 60000 USD
    Then the response status is 401

  @case:86 @priority:high
  Scenario: A key over its rate limit is throttled
    Given a fresh account "alice" funded with 100.0 BTC
    And "alice" holds a "trade" API key limited to 2 per minute
    When the key deposits 1.0 BTC three times
    Then the last response status is 429
    And the response code is "rate_limited"

  @case:87 @priority:medium
  Scenario: Minting a key requires the owner token, not a key
    Given a fresh account "alice"
    And "alice" holds a "trade" API key
    When the key tries to mint a "withdraw" API key
    Then the response status is 401

  @case:88 @priority:medium
  Scenario: A key is listed under its account
    Given a fresh account "alice"
    And "alice" holds a "read" API key
    When the keys of "alice" are read
    Then a listed key has scope "read"
