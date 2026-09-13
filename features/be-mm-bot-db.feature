@module:10-cex-mm-bot-db @be @minicex @db
Feature: The market-maker bot, verified from the store

  The same market-maker, but every claim is checked against the SQLite rows the
  service wrote -- the resting orders, their reserved funds, the fills, and the
  ledger -- not the API's own word. This is the ground-truth tier for the bot.

  Background:
    Given the store is open and the service is reachable

  @case:108 @priority:high
  Scenario: A quote writes one open bid and one open ask
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    When the market maker quotes
    Then the store has one open bid and one open ask for the maker

  @case:109 @priority:high
  Scenario: The bid reserves quote and the ask reserves base
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    When the market maker quotes
    Then the maker's reserved BTC covers the ask and reserved USD covers the bid

  @case:110 @priority:high
  Scenario: A lifted ask writes a fill and advances the order
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    And the market maker quotes
    When a taker lifts the maker's ask
    Then a fill row records the ask size at the ask price
    And the maker's ask order filled equals its size in the store

  @case:111 @priority:high
  Scenario: Repricing cancels the old orders and releases their reserve
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    And the market maker quotes
    When the market maker reprices to 61000
    Then the maker has exactly two cancelled orders in the store
    And the maker's reserved funds cover only the new quote

  @case:112 @priority:high
  Scenario: The maker's ledger balances after quote, fill and reprice
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    And the market maker quotes
    And a taker lifts the maker's ask
    And the market maker reprices to 61000
    Then the ledger sum for the maker in BTC equals its balance row
    And the ledger sum for the maker in USD equals its balance row
