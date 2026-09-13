@module:08-cex-earn @be @minicex
Feature: Staking / earn

  An account can lock a principal into a stake that accrues a fixed APR and be
  redeemed for the principal plus its reward. Accrual is driven by explicit
  simulated seconds, so it is deterministic and independent of the wall clock.
  The mini-cex does each step in one transaction and the DB tier checks the
  ledger balances.

  Background:
    Given the store is open and the service is reachable

  @case:89 @priority:high @db
  Scenario: A stake principal must be positive
    Given a throwaway database with the schema applied
    Then inserting a stake with a non-positive principal fails a CHECK

  @case:90 @priority:high @api
  Scenario: Staking locks the principal out of the balance
    Given a fresh account "alice" funded with 1.0 BTC
    When "alice" stakes 0.6 BTC at 500 bps
    Then the response status is 201
    And the API balance for "alice" in BTC is 0.4 BTC

  @case:91 @priority:high @db
  Scenario: The locked principal leaves a matching ledger line
    Given a fresh account "alice" funded with 2.0 ETH
    When "alice" stakes 2.0 ETH at 800 bps
    Then a ledger line debits "alice" 2.0 ETH with reason "stake_lock"
    And the ledger sum for "alice" in ETH equals the balance row

  @case:92 @priority:high @api
  Scenario: Accrual over a year equals the APR on the principal
    Given a fresh account "alice" funded with 100.0 USDC
    And "alice" stakes 100.0 USDC at 1000 bps
    When the stake accrues 31536000 seconds
    Then the stake accrued is 10.0 USDC

  @case:93 @priority:high @api
  Scenario: Accrual is proportional to the elapsed time
    Given a fresh account "alice" funded with 100.0 USDC
    And "alice" stakes 100.0 USDC at 1000 bps
    When the stake accrues 15768000 seconds
    Then the stake accrued is 5.0 USDC

  @case:94 @priority:high @api
  Scenario: Redeeming returns the principal plus the reward
    Given a fresh account "alice" funded with 100.0 USDC
    And "alice" stakes 100.0 USDC at 1000 bps
    And the stake accrues 31536000 seconds
    When the stake is redeemed
    Then the API balance for "alice" in USDC is 110.0 USDC

  @case:95 @priority:high @api
  Scenario: A stake cannot be redeemed twice
    Given a fresh account "alice" funded with 100.0 USDC
    And "alice" stakes 100.0 USDC at 1000 bps
    And the stake accrues 31536000 seconds
    And the stake is redeemed
    When the stake is redeemed again
    Then the second redemption was an idempotent replay
    And the API balance for "alice" in USDC is 110.0 USDC

  @case:96 @priority:high @api
  Scenario: Staking more than the balance is refused
    Given a fresh account "alice" funded with 1.0 BTC
    When "alice" stakes 5.0 BTC at 500 bps
    Then the response status is 409
    And the response code is "insufficient_funds"

  @case:97 @priority:high @db
  Scenario: A redeemed stake's ledger balances back to whole
    Given a fresh account "alice" funded with 100.0 USDC
    And "alice" stakes 100.0 USDC at 1000 bps
    And the stake accrues 31536000 seconds
    And the stake is redeemed
    Then the ledger sum for "alice" in USDC equals the balance row

  @case:98 @priority:medium @api
  Scenario: Staked funds are not available to withdraw
    Given a fresh account "alice" funded with 1.0 BTC
    And "alice" stakes 0.8 BTC at 500 bps
    When "alice" tries to withdraw 0.5 BTC
    Then the response status is 409
    And the response code is "insufficient_funds"
