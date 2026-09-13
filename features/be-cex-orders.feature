@module:06-cex-orders @be @minicex
Feature: The mini-cex spot order book

  A real spot exchange matches orders on a book, price-time priority, and takes
  a maker-taker fee. The mini-cex does it in one transaction: a resting order
  holds its funds in reserve, a taker crosses the book at the maker's price, and
  every match moves base and quote between the two sides and records a fill.
  Both stacks drive it and assert on the rows.

  Background:
    Given the store is open and the service is reachable

  # ---------------------------------------------------------------- schema

  @case:59 @priority:high @db
  Scenario: A balance's reserved part can never exceed its total
    Given a throwaway database with the schema applied
    Then inserting a balance whose reserved exceeds its amount fails a CHECK

  @case:60 @priority:high @db
  Scenario: An order's filled amount can never exceed its size
    Given a throwaway database with the schema applied
    Then inserting an order whose filled exceeds its size fails a CHECK

  @case:61 @priority:high @db
  Scenario: A fill never has the same account on both sides
    Given a throwaway database with the schema applied
    Then inserting a fill whose taker and maker are the same account fails a CHECK

  # ---------------------------------------------------------------- resting + matching

  @case:62 @priority:high @api
  Scenario: A limit order that does not cross rests on the book
    Given a fresh account "maker" funded with 1.0 BTC
    When "maker" places a limit sell of 0.5 BTC at 60000 USD
    Then the order status is "open"
    And the order book has an ask of 0.5 BTC at 60000 USD

  @case:63 @priority:high @api
  Scenario: Placing a sell reserves the base it offers
    Given a fresh account "maker" funded with 1.0 BTC
    When "maker" places a limit sell of 0.4 BTC at 60000 USD
    Then the reserved BTC of "maker" is 0.4

  @case:64 @priority:high @db
  Scenario: A crossing taker matches the maker at the maker's price
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places a limit buy of 0.5 BTC at 61000 USD
    Then the order status is "filled"
    And a fill records 0.5 BTC at 60000 USD

  @case:65 @priority:high @db
  Scenario: A match moves base to the taker and quote to the maker
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places a limit buy of 0.5 BTC at 60000 USD
    Then the ledger sum for "taker" in BTC equals the balance row
    And the ledger sum for "maker" in USD equals the balance row
    And the API balance for "maker" in BTC is 0.5 BTC

  @case:66 @priority:high @api
  Scenario: The taker pays the taker fee and the maker pays the maker fee
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 1.0 BTC at 60000 USD
    When "taker" places a limit buy of 1.0 BTC at 60000 USD
    Then the last fill taker fee is 20 basis points of 1.0 BTC
    And the last fill maker fee is 10 basis points of 60000.0 USD

  @case:67 @priority:high @api
  Scenario: A partial fill leaves the remainder resting
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 1.0 BTC at 60000 USD
    When "taker" places a limit buy of 0.3 BTC at 60000 USD
    Then the taker order status is "filled"
    And the maker order for "maker" is "partial" with filled 0.3 BTC

  @case:68 @priority:high @api
  Scenario: Matching takes the best price first
    Given a fresh account "m1" funded with 1.0 BTC
    And a fresh account "m2" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "m1" places a limit sell of 0.5 BTC at 61000 USD
    And "m2" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places a limit buy of 0.5 BTC at 61000 USD
    Then a fill records 0.5 BTC at 60000 USD

  @case:69 @priority:high @api
  Scenario: A taker never matches its own resting order
    Given a fresh account "trader" funded with 100000.0 USD
    And "trader" places a limit buy of 0.1 BTC at 60000 USD
    And "trader" is funded with 1.0 BTC
    When "trader" places a limit sell of 0.1 BTC at 60000 USD
    Then the order status is "open"
    And the order filled is 0.0 BTC

  @case:70 @priority:high @api
  Scenario: Cancelling an order releases its reserve
    Given a fresh account "maker" funded with 1.0 BTC
    And "maker" places a limit sell of 0.6 BTC at 60000 USD
    When "maker" cancels the order
    Then the order status is "cancelled"
    And the reserved BTC of "maker" is 0.0

  # ---------------------------------------------------------------- time in force

  @case:71 @priority:high @api
  Scenario: A post-only order that would cross is rejected
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places a post-only buy of 0.5 BTC at 60000 USD
    Then the response status is 409
    And the response code is "would_cross"

  @case:72 @priority:high @api
  Scenario: A fill-or-kill order that cannot fully fill is killed
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 200000.0 USD
    And "maker" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places a FOK buy of 2.0 BTC at 60000 USD
    Then the response status is 409
    And the response code is "fok_unfilled"

  @case:73 @priority:high @api
  Scenario: An IOC order fills what it can and cancels the rest
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 200000.0 USD
    And "maker" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places an IOC buy of 2.0 BTC at 60000 USD
    Then the order status is "cancelled"
    And the order filled is 0.5 BTC

  @case:74 @priority:medium @api
  Scenario: A market buy sweeps the book at the resting price
    Given a fresh account "maker" funded with 1.0 BTC
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 0.5 BTC at 60000 USD
    When "taker" places a market buy of 0.5 BTC paying USD
    Then the order status is "filled"
    And a fill records 0.5 BTC at 60000 USD

  # ---------------------------------------------------------------- fees / value

  @case:75 @priority:high @db
  Scenario: A match conserves value across the two sides
    Given a fresh account "maker" funded with 2.0 ETH
    And a fresh account "taker" funded with 100000.0 USD
    And "maker" places a limit sell of 2.0 ETH at 2500 USD
    When "taker" places a limit buy of 2.0 ETH at 2500 USD
    Then the base leaving the maker equals the base reaching the taker plus the taker fee
    And the quote leaving the taker equals the quote reaching the maker plus the maker fee

  @case:76 @priority:medium @api
  Scenario: The fee schedule lists the maker-taker tiers
    When the fee schedule is read
    Then the entry tier charges 20 basis points taker and 10 maker
    And a higher tier pays the maker a rebate

  @case:77 @priority:medium @api
  Scenario: A below-minimum order is refused
    Given a fresh account "maker" funded with 1.0 BTC
    When "maker" places a limit sell of 0.00001 BTC at 60000 USD
    Then the response status is 400
    And the response code is "below_min"

  @case:78 @priority:medium @api
  Scenario: A repeated order with the same idempotency key makes one order
    Given a fresh account "maker" funded with 1.0 BTC
    When "maker" places a limit sell of 0.5 BTC at 60000 USD with key "ord-1"
    And "maker" places a limit sell of 0.5 BTC at 60000 USD with key "ord-1"
    Then the second order was an idempotent replay
    And the open orders of "maker" number 1
