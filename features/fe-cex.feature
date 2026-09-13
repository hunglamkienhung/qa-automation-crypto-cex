@module:05-cex-fe @fe @minicex
Feature: The mini-cex screens

  The mini-cex serves small labelled HTML pages. Playwright drives them and
  each figure on screen is checked against the same API the BE tier reads --
  the frontend is held to the backend's numbers. The mini-cex is local and
  deterministic, so these grade strictly; they Block only if the service or the
  browser is unavailable.

  Background:
    Given the service is reachable and the home page is open

  @case:49 @priority:high
  Scenario: The home page lists the exchange's assets
    Then the assets on screen include BTC, ETH, SOL, USD
    And every asset row on screen shows a symbol and a USD price

  @case:50 @priority:medium
  Scenario: A delisted asset is marked so on screen
    Then the DOGE row on screen is marked delisted

  @case:51 @priority:high
  Scenario: The number of assets on screen equals the API asset count
    Then the number of assets on screen equals the API asset count

  @case:52 @priority:high
  Scenario: A funded wallet shows its balance on screen
    Given a fresh account "alice" funded with 1.0 BTC
    When the wallet page for "alice" is opened
    Then the BTC balance on screen is 1.0

  @case:53 @priority:high
  Scenario: The wallet balances on screen match the API balances
    Given a fresh account "alice" funded with 2.0 ETH
    When the wallet page for "alice" is opened
    Then every balance on screen matches the API balance for "alice"

  @case:54 @priority:medium
  Scenario: A bridge op page shows its status
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" bridge-withdraws 0.2 BTC to chain "ethereum"
    When the op page for that bridge op is opened
    Then the op status on screen is "locked"

  # ---------------------------------------------------------------- interactive forms

  @case:55 @priority:high
  Scenario: The transfer form moves funds between accounts
    Given a fresh account "alice" funded with 1.0 BTC
    And a fresh account "bob"
    When the transfer form is submitted moving 0.4 BTC from "alice" to "bob"
    Then the form result status is 201
    And the API balance for "bob" in BTC is 0.4 BTC

  @case:56 @priority:high
  Scenario: The swap form converts one asset to another
    Given a fresh account "alice" funded with 1.0 BTC
    When the swap form is submitted converting 0.5 BTC to USD for "alice"
    Then the form result status is 201
    And the API balance for "alice" in USD is above zero

  @case:57 @priority:high
  Scenario: The bridge form locks a withdrawal
    Given a fresh account "alice" funded with 1.0 BTC
    When the bridge form is submitted withdrawing 0.3 BTC to chain "ethereum" for "alice"
    Then the form result status is 201
    And the form result code is "ok"

  @case:58 @priority:high
  Scenario: The transfer form refuses an overdraw
    Given a fresh account "alice" funded with 0.1 BTC
    And a fresh account "bob"
    When the transfer form is submitted moving 9.0 BTC from "alice" to "bob"
    Then the form result status is 409
    And the form result code is "insufficient_funds"
