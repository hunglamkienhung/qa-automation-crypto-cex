@module:09-cex-mm-bot @be @minicex @api
Feature: The market-maker bot on the spot order book

  A market-maker quotes a two-sided spread on BTC/USD: a post-only bid below a
  reference price and a post-only ask above it, each passed through the pure risk
  gate before it is sent. It refreshes by cancelling and replacing, fills when a
  taker lifts a quote, and never lets its token leak. This tier drives the bot
  against the running mini-cex and checks the API view.

  Background:
    Given the store is open and the service is reachable

  @case:102 @priority:high
  Scenario: The market maker posts a two-sided quote
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    When the market maker quotes
    Then the quote is placed
    And the bid is below the reference and the ask is above it

  @case:103 @priority:high
  Scenario: The quotes rest on the book without crossing
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    When the market maker quotes
    Then the order book shows the maker's bid and ask
    And the maker has exactly one bid and one ask resting

  @case:104 @priority:high
  Scenario: Repricing replaces the quotes
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    And the market maker quotes
    When the market maker reprices to 61000
    Then the maker has exactly one bid and one ask resting
    And the resting ask is at the new ask price

  @case:105 @priority:high
  Scenario: When a taker lifts the ask, the maker's ask fills
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread
    And the market maker quotes
    When a taker lifts the maker's ask
    Then the maker's ask order is filled

  @case:106 @priority:high
  Scenario: The kill switch stops the maker from quoting
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread with the kill switch on
    When the market maker quotes
    Then the quote is refused for "kill switch"
    And the maker has no resting quotes

  @case:107 @priority:high
  Scenario: Dry-run plans a quote without sending it
    Given a funded market maker on BTC/USD at reference 60000 with 50 bps spread in dry-run mode
    When the market maker quotes
    Then the quote is a dry run
    And the maker has no resting quotes
    And the maker's token does not leak into a log line
