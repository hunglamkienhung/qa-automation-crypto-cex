@module:01-cex-db @be @db @minicex
Feature: The mini-cex store, read directly

  Both stacks open the SQLite file the mini-cex service writes and assert on its
  rows. The service is driven through its HTTP API to create state -- a deposit,
  a transfer, a swap, a bridge op -- and the rows are then read straight from
  the file.

  Balances are shared state, so the assertions are on DELTAS and on fresh
  accounts: each scenario creates its own accounts, acts, and checks what
  changed. That keeps every scenario independent of the order they run in.

  Background:
    Given the store is open and the service is reachable

  # ---------------------------------------------------------------- schema (throwaway db)

  @case:1 @priority:high
  Scenario: The store has the documented tables
    Then the store has tables assets, pairs, accounts, balances, ledger, transfers, swaps, bridge_ops

  @case:2 @priority:high
  Scenario: A balance can never be negative
    Given a throwaway database with the schema applied
    Then inserting a balance with a negative amount fails a CHECK

  @case:3 @priority:high
  Scenario: A ledger movement is a real, non-zero change with a known reason
    Given a throwaway database with the schema applied
    Then inserting a ledger row with zero delta fails a CHECK
    And inserting a ledger row with reason "bogus" fails a CHECK

  @case:4 @priority:high
  Scenario: A balance references a real account and asset
    Given a throwaway database with the schema applied
    Then inserting a balance for a missing account fails a FOREIGN KEY

  @case:5 @priority:high
  Scenario: A bridge op is unique per direction and external tx
    Given a throwaway database with the schema applied
    Then inserting two deposit bridge ops with the same external tx fails on the second

  @case:6 @priority:medium
  Scenario: A pair's two legs must differ
    Given a throwaway database with the schema applied
    Then inserting a pair whose base equals its quote fails a CHECK

  @case:7 @priority:medium
  Scenario: Seeding twice leaves the same rows
    Given a throwaway database with the schema and seed applied
    Then applying the seed again changes no row counts

  # ---------------------------------------------------------------- ledger invariants after API ops

  @case:8 @priority:high
  Scenario: A deposit credits the balance and writes a matching ledger line
    Given a fresh account "alice"
    When "alice" deposits 1.0 BTC
    Then the balance row for "alice" in BTC is 1.0 BTC
    And a ledger line credits "alice" 1.0 BTC with reason "deposit"

  @case:9 @priority:high
  Scenario: The ledger sum equals the running balance
    Given a fresh account "alice"
    When "alice" deposits 2.0 ETH
    And "alice" withdraws 0.5 ETH
    Then the ledger sum for "alice" in ETH equals the balance row

  @case:10 @priority:high
  Scenario: An internal transfer conserves the total balance
    Given a fresh account "alice"
    And a fresh account "bob"
    And "alice" deposits 1.0 BTC
    When "alice" transfers 0.4 BTC to "bob"
    Then the balance row for "alice" in BTC is 0.6 BTC
    And the balance row for "bob" in BTC is 0.4 BTC
    And the total BTC across "alice" and "bob" is unchanged

  @case:11 @priority:high
  Scenario: A swap debits the input and credits the net output, both on the ledger
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" swaps 0.5 BTC to USD
    Then the ledger sum for "alice" in BTC equals the balance row
    And the ledger sum for "alice" in USD equals the balance row
    And "alice" has a swap row from BTC to USD

  @case:12 @priority:high
  Scenario: A bridge withdrawal locks the balance with a debit line
    Given a fresh account "alice"
    And "alice" deposits 1.0 BTC
    When "alice" bridge-withdraws 0.3 BTC to chain "ethereum"
    Then the balance row for "alice" in BTC is 0.7 BTC
    And a ledger line debits "alice" 0.3 BTC with reason "bridge_debit"
    And the bridge op for "alice" is in status "locked"

  @case:13 @priority:high
  Scenario: A bridge deposit credits once even when observed twice
    Given a fresh account "alice"
    When a bridge deposit of 1.0 ETH for "alice" from chain "ethereum" with tx "dep-x" is observed
    And the same bridge deposit is observed again
    Then the balance row for "alice" in ETH is 1.0 ETH
    And "alice" has exactly one bridge op with external tx "dep-x"

  @case:14 @priority:high
  Scenario: An overdrawn transfer leaves both balances untouched
    Given a fresh account "alice"
    And a fresh account "bob"
    And "alice" deposits 0.2 BTC
    When "alice" tries to transfer 5.0 BTC to "bob"
    Then the transfer is refused with code "insufficient_funds"
    And the balance row for "alice" in BTC is 0.2 BTC
    And "bob" has no BTC balance row
