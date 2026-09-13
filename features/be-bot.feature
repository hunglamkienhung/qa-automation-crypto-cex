@module:04-bot @be @bot
Feature: The pure risk gate

  A client that sends transfers, swaps and bridge ops runs each past a pure
  gate first, so it never fires an operation it can already see will be
  refused. The gate is a pure function -- no network, no clock -- so these
  scenarios are deterministic and always graded, never Blocked.

  Background:
    Given a risk engine with the default configuration and a funded book

  @case:39 @priority:high
  Scenario: The kill switch blocks every operation
    Given the kill switch is on
    When the engine plans a transfer of 0.1 BTC
    Then the plan is refused for "the kill switch is on"

  @case:40 @priority:high
  Scenario: A zero amount is refused
    When the engine plans a transfer of 0.0 BTC
    Then the plan is refused for "amount must be positive"

  @case:41 @priority:high
  Scenario: A transfer within balance is allowed
    When the engine plans a transfer of 0.5 BTC
    Then the plan is allowed

  @case:42 @priority:high
  Scenario: A transfer over balance is refused
    When the engine plans a transfer of 5.0 BTC
    Then the plan is refused for "balance is below the amount"

  @case:43 @priority:high
  Scenario: A swap below the pair minimum is refused
    When the engine plans a swap of 0.00001 BTC to USD
    Then the plan is refused for "below the pair minimum"

  @case:44 @priority:high
  Scenario: A swap under the slippage floor is refused
    When the engine plans a swap of 0.5 BTC to USD demanding at least 1000000.0 USD
    Then the plan is refused for "quote is below the slippage floor"

  @case:45 @priority:high
  Scenario: A swap with no listed pair is refused
    When the engine plans a swap of 1.0 USD to SOL
    Then the plan is allowed
    When the engine plans a swap of 100.0 DOGE to USD
    Then the plan is refused for "no active pair for those assets"

  @case:46 @priority:high
  Scenario: A bridge to an unknown chain is refused
    When the engine plans a bridge of 0.1 BTC to chain "mars"
    Then the plan is refused for "destination chain is not supported"

  @case:47 @priority:high
  Scenario: A bridge over the cap is refused
    When the engine plans a bridge of 5.0 BTC to chain "ethereum"
    Then the plan is refused for "amount exceeds the bridge per-transaction cap"

  @case:48 @priority:high
  Scenario: A bridge within cap and balance is allowed
    When the engine plans a bridge of 0.5 BTC to chain "ethereum"
    Then the plan is allowed

  @case:99 @priority:high
  Scenario: A zero-size order is refused
    When the engine plans an order to sell 0.0 BTC at 60000 USD
    Then the plan is refused for "amount must be positive"

  @case:100 @priority:high
  Scenario: An order above the max size is refused
    When the engine plans an order to sell 200.0 BTC at 60000 USD
    Then the plan is refused for "order size exceeds the max"

  @case:101 @priority:high
  Scenario: The kill switch blocks an order too
    Given the kill switch is on
    When the engine plans an order to sell 0.1 BTC at 60000 USD
    Then the plan is refused for "the kill switch is on"
