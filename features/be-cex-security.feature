@module:11-cex-security @be @minicex @api @security
Feature: The mini-cex authentication surface, probed like an attacker

  The scoped-key and rate-limit tier (module 07) already proves what a key may
  and may not do. This tier adds the adversarial edges around it: a garbage
  bearer token, one account reaching for another's key, and the secret-hygiene
  invariants -- a minted key is shown once and only a prefix is ever listed
  again, and no credential appears in a public response.

  Background:
    Given the store is open and the service is reachable

  @case:113 @priority:high
  Scenario: A garbage bearer token is refused on a write
    When a write is attempted with a garbage bearer token
    Then the response status is 401
    And the response code is "unauthenticated"

  @case:114 @priority:high
  Scenario: One account cannot revoke another account's API key
    Given a fresh account "alice"
    And "alice" holds a "trade" API key
    When another account tries to revoke that key
    Then the response status is 403
    And the response code is "forbidden"

  @case:115 @priority:high
  Scenario: The key list exposes only a prefix, never the full key
    Given a fresh account "alice"
    And "alice" holds a "trade" API key
    When "alice"'s API keys are listed
    Then the key list shows a prefix but not the full key

  @case:116 @priority:medium
  Scenario: A public market-data response carries no credential
    Given a fresh account "alice"
    And "alice" holds a "trade" API key
    When the listed assets are read
    Then the response carries no account token or API key
