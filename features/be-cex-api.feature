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

  Scenario Outline: A quote of <amt> <base> to <quote> nets the gross minus the fee
    When a quote of <amt> <base> to <quote> is requested
    Then the quote net equals the gross minus the fee
    And the quote fee matches the pair fee in basis points

    @case:117
    Examples:
      | amt | base | quote |
      | 0.25 | BTC | USD |
    @case:118
    Examples:
      | amt | base | quote |
      | 0.25 | ETH | USD |
    @case:119
    Examples:
      | amt | base | quote |
      | 0.25 | SOL | USD |
    @case:120
    Examples:
      | amt | base | quote |
      | 0.25 | BTC | USDC |
    @case:121
    Examples:
      | amt | base | quote |
      | 0.25 | ETH | USDC |
    @case:122
    Examples:
      | amt | base | quote |
      | 0.25 | SOL | USDC |
    @case:123
    Examples:
      | amt | base | quote |
      | 0.25 | ETH | BTC |
    @case:124
    Examples:
      | amt | base | quote |
      | 0.25 | SOL | ETH |
    @case:125
    Examples:
      | amt | base | quote |
      | 0.25 | USDC | USD |
    @case:126
    Examples:
      | amt | base | quote |
      | 0.50 | BTC | USD |
    @case:127
    Examples:
      | amt | base | quote |
      | 0.50 | ETH | USD |
    @case:128
    Examples:
      | amt | base | quote |
      | 0.50 | SOL | USD |
    @case:129
    Examples:
      | amt | base | quote |
      | 0.50 | BTC | USDC |
    @case:130
    Examples:
      | amt | base | quote |
      | 0.50 | ETH | USDC |
    @case:131
    Examples:
      | amt | base | quote |
      | 0.50 | SOL | USDC |
    @case:132
    Examples:
      | amt | base | quote |
      | 0.50 | ETH | BTC |
    @case:133
    Examples:
      | amt | base | quote |
      | 0.50 | SOL | ETH |
    @case:134
    Examples:
      | amt | base | quote |
      | 0.50 | USDC | USD |
    @case:135
    Examples:
      | amt | base | quote |
      | 0.75 | BTC | USD |
    @case:136
    Examples:
      | amt | base | quote |
      | 0.75 | ETH | USD |
    @case:137
    Examples:
      | amt | base | quote |
      | 0.75 | SOL | USD |
    @case:138
    Examples:
      | amt | base | quote |
      | 0.75 | BTC | USDC |
    @case:139
    Examples:
      | amt | base | quote |
      | 0.75 | ETH | USDC |
    @case:140
    Examples:
      | amt | base | quote |
      | 0.75 | SOL | USDC |
    @case:141
    Examples:
      | amt | base | quote |
      | 0.75 | ETH | BTC |
    @case:142
    Examples:
      | amt | base | quote |
      | 0.75 | SOL | ETH |
    @case:143
    Examples:
      | amt | base | quote |
      | 0.75 | USDC | USD |
    @case:144
    Examples:
      | amt | base | quote |
      | 1.00 | BTC | USD |
    @case:145
    Examples:
      | amt | base | quote |
      | 1.00 | ETH | USD |
    @case:146
    Examples:
      | amt | base | quote |
      | 1.00 | SOL | USD |
    @case:147
    Examples:
      | amt | base | quote |
      | 1.00 | BTC | USDC |
    @case:148
    Examples:
      | amt | base | quote |
      | 1.00 | ETH | USDC |
    @case:149
    Examples:
      | amt | base | quote |
      | 1.00 | SOL | USDC |
    @case:150
    Examples:
      | amt | base | quote |
      | 1.00 | ETH | BTC |
    @case:151
    Examples:
      | amt | base | quote |
      | 1.00 | SOL | ETH |
    @case:152
    Examples:
      | amt | base | quote |
      | 1.00 | USDC | USD |
    @case:153
    Examples:
      | amt | base | quote |
      | 1.25 | BTC | USD |
    @case:154
    Examples:
      | amt | base | quote |
      | 1.25 | ETH | USD |
    @case:155
    Examples:
      | amt | base | quote |
      | 1.25 | SOL | USD |
    @case:156
    Examples:
      | amt | base | quote |
      | 1.25 | BTC | USDC |
    @case:157
    Examples:
      | amt | base | quote |
      | 1.25 | ETH | USDC |
    @case:158
    Examples:
      | amt | base | quote |
      | 1.25 | SOL | USDC |
    @case:159
    Examples:
      | amt | base | quote |
      | 1.25 | ETH | BTC |
    @case:160
    Examples:
      | amt | base | quote |
      | 1.25 | SOL | ETH |
    @case:161
    Examples:
      | amt | base | quote |
      | 1.25 | USDC | USD |
    @case:162
    Examples:
      | amt | base | quote |
      | 1.50 | BTC | USD |
    @case:163
    Examples:
      | amt | base | quote |
      | 1.50 | ETH | USD |
    @case:164
    Examples:
      | amt | base | quote |
      | 1.50 | SOL | USD |
    @case:165
    Examples:
      | amt | base | quote |
      | 1.50 | BTC | USDC |
    @case:166
    Examples:
      | amt | base | quote |
      | 1.50 | ETH | USDC |
    @case:167
    Examples:
      | amt | base | quote |
      | 1.50 | SOL | USDC |
    @case:168
    Examples:
      | amt | base | quote |
      | 1.50 | ETH | BTC |
    @case:169
    Examples:
      | amt | base | quote |
      | 1.50 | SOL | ETH |
    @case:170
    Examples:
      | amt | base | quote |
      | 1.50 | USDC | USD |
    @case:171
    Examples:
      | amt | base | quote |
      | 1.75 | BTC | USD |
    @case:172
    Examples:
      | amt | base | quote |
      | 1.75 | ETH | USD |
    @case:173
    Examples:
      | amt | base | quote |
      | 1.75 | SOL | USD |
    @case:174
    Examples:
      | amt | base | quote |
      | 1.75 | BTC | USDC |
    @case:175
    Examples:
      | amt | base | quote |
      | 1.75 | ETH | USDC |
    @case:176
    Examples:
      | amt | base | quote |
      | 1.75 | SOL | USDC |
    @case:177
    Examples:
      | amt | base | quote |
      | 1.75 | ETH | BTC |
    @case:178
    Examples:
      | amt | base | quote |
      | 1.75 | SOL | ETH |
    @case:179
    Examples:
      | amt | base | quote |
      | 1.75 | USDC | USD |
    @case:180
    Examples:
      | amt | base | quote |
      | 2.00 | BTC | USD |
    @case:181
    Examples:
      | amt | base | quote |
      | 2.00 | ETH | USD |
    @case:182
    Examples:
      | amt | base | quote |
      | 2.00 | SOL | USD |
    @case:183
    Examples:
      | amt | base | quote |
      | 2.00 | BTC | USDC |
    @case:184
    Examples:
      | amt | base | quote |
      | 2.00 | ETH | USDC |
    @case:185
    Examples:
      | amt | base | quote |
      | 2.00 | SOL | USDC |
    @case:186
    Examples:
      | amt | base | quote |
      | 2.00 | ETH | BTC |
    @case:187
    Examples:
      | amt | base | quote |
      | 2.00 | SOL | ETH |
    @case:188
    Examples:
      | amt | base | quote |
      | 2.00 | USDC | USD |
    @case:189
    Examples:
      | amt | base | quote |
      | 2.25 | BTC | USD |
    @case:190
    Examples:
      | amt | base | quote |
      | 2.25 | ETH | USD |
    @case:191
    Examples:
      | amt | base | quote |
      | 2.25 | SOL | USD |
    @case:192
    Examples:
      | amt | base | quote |
      | 2.25 | BTC | USDC |
    @case:193
    Examples:
      | amt | base | quote |
      | 2.25 | ETH | USDC |
    @case:194
    Examples:
      | amt | base | quote |
      | 2.25 | SOL | USDC |
    @case:195
    Examples:
      | amt | base | quote |
      | 2.25 | ETH | BTC |
    @case:196
    Examples:
      | amt | base | quote |
      | 2.25 | SOL | ETH |
    @case:197
    Examples:
      | amt | base | quote |
      | 2.25 | USDC | USD |
    @case:198
    Examples:
      | amt | base | quote |
      | 2.50 | BTC | USD |
    @case:199
    Examples:
      | amt | base | quote |
      | 2.50 | ETH | USD |
    @case:200
    Examples:
      | amt | base | quote |
      | 2.50 | SOL | USD |
    @case:201
    Examples:
      | amt | base | quote |
      | 2.50 | BTC | USDC |
    @case:202
    Examples:
      | amt | base | quote |
      | 2.50 | ETH | USDC |
    @case:203
    Examples:
      | amt | base | quote |
      | 2.50 | SOL | USDC |
    @case:204
    Examples:
      | amt | base | quote |
      | 2.50 | ETH | BTC |
    @case:205
    Examples:
      | amt | base | quote |
      | 2.50 | SOL | ETH |
    @case:206
    Examples:
      | amt | base | quote |
      | 2.50 | USDC | USD |
    @case:207
    Examples:
      | amt | base | quote |
      | 2.75 | BTC | USD |
    @case:208
    Examples:
      | amt | base | quote |
      | 2.75 | ETH | USD |
    @case:209
    Examples:
      | amt | base | quote |
      | 2.75 | SOL | USD |
    @case:210
    Examples:
      | amt | base | quote |
      | 2.75 | BTC | USDC |
    @case:211
    Examples:
      | amt | base | quote |
      | 2.75 | ETH | USDC |
    @case:212
    Examples:
      | amt | base | quote |
      | 2.75 | SOL | USDC |
    @case:213
    Examples:
      | amt | base | quote |
      | 2.75 | ETH | BTC |
    @case:214
    Examples:
      | amt | base | quote |
      | 2.75 | SOL | ETH |
    @case:215
    Examples:
      | amt | base | quote |
      | 2.75 | USDC | USD |
    @case:216
    Examples:
      | amt | base | quote |
      | 3.00 | BTC | USD |
    @case:217
    Examples:
      | amt | base | quote |
      | 3.00 | ETH | USD |
    @case:218
    Examples:
      | amt | base | quote |
      | 3.00 | SOL | USD |
    @case:219
    Examples:
      | amt | base | quote |
      | 3.00 | BTC | USDC |
    @case:220
    Examples:
      | amt | base | quote |
      | 3.00 | ETH | USDC |
    @case:221
    Examples:
      | amt | base | quote |
      | 3.00 | SOL | USDC |
    @case:222
    Examples:
      | amt | base | quote |
      | 3.00 | ETH | BTC |
    @case:223
    Examples:
      | amt | base | quote |
      | 3.00 | SOL | ETH |
    @case:224
    Examples:
      | amt | base | quote |
      | 3.00 | USDC | USD |
    @case:225
    Examples:
      | amt | base | quote |
      | 3.25 | BTC | USD |
    @case:226
    Examples:
      | amt | base | quote |
      | 3.25 | ETH | USD |
    @case:227
    Examples:
      | amt | base | quote |
      | 3.25 | SOL | USD |
    @case:228
    Examples:
      | amt | base | quote |
      | 3.25 | BTC | USDC |
    @case:229
    Examples:
      | amt | base | quote |
      | 3.25 | ETH | USDC |
    @case:230
    Examples:
      | amt | base | quote |
      | 3.25 | SOL | USDC |
    @case:231
    Examples:
      | amt | base | quote |
      | 3.25 | ETH | BTC |
    @case:232
    Examples:
      | amt | base | quote |
      | 3.25 | SOL | ETH |
    @case:233
    Examples:
      | amt | base | quote |
      | 3.25 | USDC | USD |
    @case:234
    Examples:
      | amt | base | quote |
      | 3.50 | BTC | USD |
    @case:235
    Examples:
      | amt | base | quote |
      | 3.50 | ETH | USD |
    @case:236
    Examples:
      | amt | base | quote |
      | 3.50 | SOL | USD |
    @case:237
    Examples:
      | amt | base | quote |
      | 3.50 | BTC | USDC |
    @case:238
    Examples:
      | amt | base | quote |
      | 3.50 | ETH | USDC |
    @case:239
    Examples:
      | amt | base | quote |
      | 3.50 | SOL | USDC |
    @case:240
    Examples:
      | amt | base | quote |
      | 3.50 | ETH | BTC |
    @case:241
    Examples:
      | amt | base | quote |
      | 3.50 | SOL | ETH |
    @case:242
    Examples:
      | amt | base | quote |
      | 3.50 | USDC | USD |
    @case:243
    Examples:
      | amt | base | quote |
      | 3.75 | BTC | USD |
    @case:244
    Examples:
      | amt | base | quote |
      | 3.75 | ETH | USD |
    @case:245
    Examples:
      | amt | base | quote |
      | 3.75 | SOL | USD |
    @case:246
    Examples:
      | amt | base | quote |
      | 3.75 | BTC | USDC |
    @case:247
    Examples:
      | amt | base | quote |
      | 3.75 | ETH | USDC |
    @case:248
    Examples:
      | amt | base | quote |
      | 3.75 | SOL | USDC |
    @case:249
    Examples:
      | amt | base | quote |
      | 3.75 | ETH | BTC |
    @case:250
    Examples:
      | amt | base | quote |
      | 3.75 | SOL | ETH |
    @case:251
    Examples:
      | amt | base | quote |
      | 3.75 | USDC | USD |
    @case:252
    Examples:
      | amt | base | quote |
      | 4.00 | BTC | USD |
    @case:253
    Examples:
      | amt | base | quote |
      | 4.00 | ETH | USD |
    @case:254
    Examples:
      | amt | base | quote |
      | 4.00 | SOL | USD |
    @case:255
    Examples:
      | amt | base | quote |
      | 4.00 | BTC | USDC |
    @case:256
    Examples:
      | amt | base | quote |
      | 4.00 | ETH | USDC |
    @case:257
    Examples:
      | amt | base | quote |
      | 4.00 | SOL | USDC |
    @case:258
    Examples:
      | amt | base | quote |
      | 4.00 | ETH | BTC |
    @case:259
    Examples:
      | amt | base | quote |
      | 4.00 | SOL | ETH |
    @case:260
    Examples:
      | amt | base | quote |
      | 4.00 | USDC | USD |
    @case:261
    Examples:
      | amt | base | quote |
      | 4.25 | BTC | USD |
    @case:262
    Examples:
      | amt | base | quote |
      | 4.25 | ETH | USD |
    @case:263
    Examples:
      | amt | base | quote |
      | 4.25 | SOL | USD |
    @case:264
    Examples:
      | amt | base | quote |
      | 4.25 | BTC | USDC |
    @case:265
    Examples:
      | amt | base | quote |
      | 4.25 | ETH | USDC |
    @case:266
    Examples:
      | amt | base | quote |
      | 4.25 | SOL | USDC |
    @case:267
    Examples:
      | amt | base | quote |
      | 4.25 | ETH | BTC |
    @case:268
    Examples:
      | amt | base | quote |
      | 4.25 | SOL | ETH |
    @case:269
    Examples:
      | amt | base | quote |
      | 4.25 | USDC | USD |
    @case:270
    Examples:
      | amt | base | quote |
      | 4.50 | BTC | USD |
    @case:271
    Examples:
      | amt | base | quote |
      | 4.50 | ETH | USD |
    @case:272
    Examples:
      | amt | base | quote |
      | 4.50 | SOL | USD |
    @case:273
    Examples:
      | amt | base | quote |
      | 4.50 | BTC | USDC |
    @case:274
    Examples:
      | amt | base | quote |
      | 4.50 | ETH | USDC |
    @case:275
    Examples:
      | amt | base | quote |
      | 4.50 | SOL | USDC |
    @case:276
    Examples:
      | amt | base | quote |
      | 4.50 | ETH | BTC |
    @case:277
    Examples:
      | amt | base | quote |
      | 4.50 | SOL | ETH |
    @case:278
    Examples:
      | amt | base | quote |
      | 4.50 | USDC | USD |
    @case:279
    Examples:
      | amt | base | quote |
      | 4.75 | BTC | USD |
    @case:280
    Examples:
      | amt | base | quote |
      | 4.75 | ETH | USD |
    @case:281
    Examples:
      | amt | base | quote |
      | 4.75 | SOL | USD |
    @case:282
    Examples:
      | amt | base | quote |
      | 4.75 | BTC | USDC |
    @case:283
    Examples:
      | amt | base | quote |
      | 4.75 | ETH | USDC |
    @case:284
    Examples:
      | amt | base | quote |
      | 4.75 | SOL | USDC |
    @case:285
    Examples:
      | amt | base | quote |
      | 4.75 | ETH | BTC |
    @case:286
    Examples:
      | amt | base | quote |
      | 4.75 | SOL | ETH |
    @case:287
    Examples:
      | amt | base | quote |
      | 4.75 | USDC | USD |
    @case:288
    Examples:
      | amt | base | quote |
      | 5.00 | BTC | USD |
    @case:289
    Examples:
      | amt | base | quote |
      | 5.00 | ETH | USD |
    @case:290
    Examples:
      | amt | base | quote |
      | 5.00 | SOL | USD |
    @case:291
    Examples:
      | amt | base | quote |
      | 5.00 | BTC | USDC |
    @case:292
    Examples:
      | amt | base | quote |
      | 5.00 | ETH | USDC |
    @case:293
    Examples:
      | amt | base | quote |
      | 5.00 | SOL | USDC |
    @case:294
    Examples:
      | amt | base | quote |
      | 5.00 | ETH | BTC |
    @case:295
    Examples:
      | amt | base | quote |
      | 5.00 | SOL | ETH |
    @case:296
    Examples:
      | amt | base | quote |
      | 5.00 | USDC | USD |
    @case:297
    Examples:
      | amt | base | quote |
      | 5.25 | BTC | USD |
    @case:298
    Examples:
      | amt | base | quote |
      | 5.25 | ETH | USD |
    @case:299
    Examples:
      | amt | base | quote |
      | 5.25 | SOL | USD |
    @case:300
    Examples:
      | amt | base | quote |
      | 5.25 | BTC | USDC |
    @case:301
    Examples:
      | amt | base | quote |
      | 5.25 | ETH | USDC |
    @case:302
    Examples:
      | amt | base | quote |
      | 5.25 | SOL | USDC |
    @case:303
    Examples:
      | amt | base | quote |
      | 5.25 | ETH | BTC |
    @case:304
    Examples:
      | amt | base | quote |
      | 5.25 | SOL | ETH |
    @case:305
    Examples:
      | amt | base | quote |
      | 5.25 | USDC | USD |
    @case:306
    Examples:
      | amt | base | quote |
      | 5.50 | BTC | USD |
    @case:307
    Examples:
      | amt | base | quote |
      | 5.50 | ETH | USD |
    @case:308
    Examples:
      | amt | base | quote |
      | 5.50 | SOL | USD |
    @case:309
    Examples:
      | amt | base | quote |
      | 5.50 | BTC | USDC |
    @case:310
    Examples:
      | amt | base | quote |
      | 5.50 | ETH | USDC |
    @case:311
    Examples:
      | amt | base | quote |
      | 5.50 | SOL | USDC |
    @case:312
    Examples:
      | amt | base | quote |
      | 5.50 | ETH | BTC |
    @case:313
    Examples:
      | amt | base | quote |
      | 5.50 | SOL | ETH |
    @case:314
    Examples:
      | amt | base | quote |
      | 5.50 | USDC | USD |
    @case:315
    Examples:
      | amt | base | quote |
      | 5.75 | BTC | USD |
    @case:316
    Examples:
      | amt | base | quote |
      | 5.75 | ETH | USD |
    @case:317
    Examples:
      | amt | base | quote |
      | 5.75 | SOL | USD |
    @case:318
    Examples:
      | amt | base | quote |
      | 5.75 | BTC | USDC |
    @case:319
    Examples:
      | amt | base | quote |
      | 5.75 | ETH | USDC |
    @case:320
    Examples:
      | amt | base | quote |
      | 5.75 | SOL | USDC |
    @case:321
    Examples:
      | amt | base | quote |
      | 5.75 | ETH | BTC |
    @case:322
    Examples:
      | amt | base | quote |
      | 5.75 | SOL | ETH |
    @case:323
    Examples:
      | amt | base | quote |
      | 5.75 | USDC | USD |
    @case:324
    Examples:
      | amt | base | quote |
      | 6.00 | BTC | USD |
    @case:325
    Examples:
      | amt | base | quote |
      | 6.00 | ETH | USD |
    @case:326
    Examples:
      | amt | base | quote |
      | 6.00 | SOL | USD |
    @case:327
    Examples:
      | amt | base | quote |
      | 6.00 | BTC | USDC |
    @case:328
    Examples:
      | amt | base | quote |
      | 6.00 | ETH | USDC |
    @case:329
    Examples:
      | amt | base | quote |
      | 6.00 | SOL | USDC |
    @case:330
    Examples:
      | amt | base | quote |
      | 6.00 | ETH | BTC |
    @case:331
    Examples:
      | amt | base | quote |
      | 6.00 | SOL | ETH |
    @case:332
    Examples:
      | amt | base | quote |
      | 6.00 | USDC | USD |
    @case:333
    Examples:
      | amt | base | quote |
      | 6.25 | BTC | USD |
    @case:334
    Examples:
      | amt | base | quote |
      | 6.25 | ETH | USD |
    @case:335
    Examples:
      | amt | base | quote |
      | 6.25 | SOL | USD |
    @case:336
    Examples:
      | amt | base | quote |
      | 6.25 | BTC | USDC |
    @case:337
    Examples:
      | amt | base | quote |
      | 6.25 | ETH | USDC |
    @case:338
    Examples:
      | amt | base | quote |
      | 6.25 | SOL | USDC |
    @case:339
    Examples:
      | amt | base | quote |
      | 6.25 | ETH | BTC |
    @case:340
    Examples:
      | amt | base | quote |
      | 6.25 | SOL | ETH |
    @case:341
    Examples:
      | amt | base | quote |
      | 6.25 | USDC | USD |
    @case:342
    Examples:
      | amt | base | quote |
      | 6.50 | BTC | USD |
    @case:343
    Examples:
      | amt | base | quote |
      | 6.50 | ETH | USD |
    @case:344
    Examples:
      | amt | base | quote |
      | 6.50 | SOL | USD |
    @case:345
    Examples:
      | amt | base | quote |
      | 6.50 | BTC | USDC |
    @case:346
    Examples:
      | amt | base | quote |
      | 6.50 | ETH | USDC |
    @case:347
    Examples:
      | amt | base | quote |
      | 6.50 | SOL | USDC |
    @case:348
    Examples:
      | amt | base | quote |
      | 6.50 | ETH | BTC |
    @case:349
    Examples:
      | amt | base | quote |
      | 6.50 | SOL | ETH |
    @case:350
    Examples:
      | amt | base | quote |
      | 6.50 | USDC | USD |
    @case:351
    Examples:
      | amt | base | quote |
      | 6.75 | BTC | USD |
    @case:352
    Examples:
      | amt | base | quote |
      | 6.75 | ETH | USD |
    @case:353
    Examples:
      | amt | base | quote |
      | 6.75 | SOL | USD |
    @case:354
    Examples:
      | amt | base | quote |
      | 6.75 | BTC | USDC |
    @case:355
    Examples:
      | amt | base | quote |
      | 6.75 | ETH | USDC |
    @case:356
    Examples:
      | amt | base | quote |
      | 6.75 | SOL | USDC |
    @case:357
    Examples:
      | amt | base | quote |
      | 6.75 | ETH | BTC |
    @case:358
    Examples:
      | amt | base | quote |
      | 6.75 | SOL | ETH |
    @case:359
    Examples:
      | amt | base | quote |
      | 6.75 | USDC | USD |
    @case:360
    Examples:
      | amt | base | quote |
      | 7.00 | BTC | USD |
    @case:361
    Examples:
      | amt | base | quote |
      | 7.00 | ETH | USD |
    @case:362
    Examples:
      | amt | base | quote |
      | 7.00 | SOL | USD |
    @case:363
    Examples:
      | amt | base | quote |
      | 7.00 | BTC | USDC |
    @case:364
    Examples:
      | amt | base | quote |
      | 7.00 | ETH | USDC |
    @case:365
    Examples:
      | amt | base | quote |
      | 7.00 | SOL | USDC |
    @case:366
    Examples:
      | amt | base | quote |
      | 7.00 | ETH | BTC |
    @case:367
    Examples:
      | amt | base | quote |
      | 7.00 | SOL | ETH |
    @case:368
    Examples:
      | amt | base | quote |
      | 7.00 | USDC | USD |
    @case:369
    Examples:
      | amt | base | quote |
      | 7.25 | BTC | USD |
    @case:370
    Examples:
      | amt | base | quote |
      | 7.25 | ETH | USD |
    @case:371
    Examples:
      | amt | base | quote |
      | 7.25 | SOL | USD |
    @case:372
    Examples:
      | amt | base | quote |
      | 7.25 | BTC | USDC |
    @case:373
    Examples:
      | amt | base | quote |
      | 7.25 | ETH | USDC |
    @case:374
    Examples:
      | amt | base | quote |
      | 7.25 | SOL | USDC |
    @case:375
    Examples:
      | amt | base | quote |
      | 7.25 | ETH | BTC |
    @case:376
    Examples:
      | amt | base | quote |
      | 7.25 | SOL | ETH |
    @case:377
    Examples:
      | amt | base | quote |
      | 7.25 | USDC | USD |
    @case:378
    Examples:
      | amt | base | quote |
      | 7.50 | BTC | USD |
    @case:379
    Examples:
      | amt | base | quote |
      | 7.50 | ETH | USD |
    @case:380
    Examples:
      | amt | base | quote |
      | 7.50 | SOL | USD |
    @case:381
    Examples:
      | amt | base | quote |
      | 7.50 | BTC | USDC |
    @case:382
    Examples:
      | amt | base | quote |
      | 7.50 | ETH | USDC |
    @case:383
    Examples:
      | amt | base | quote |
      | 7.50 | SOL | USDC |
    @case:384
    Examples:
      | amt | base | quote |
      | 7.50 | ETH | BTC |
    @case:385
    Examples:
      | amt | base | quote |
      | 7.50 | SOL | ETH |
    @case:386
    Examples:
      | amt | base | quote |
      | 7.50 | USDC | USD |
    @case:387
    Examples:
      | amt | base | quote |
      | 7.75 | BTC | USD |
    @case:388
    Examples:
      | amt | base | quote |
      | 7.75 | ETH | USD |
    @case:389
    Examples:
      | amt | base | quote |
      | 7.75 | SOL | USD |
    @case:390
    Examples:
      | amt | base | quote |
      | 7.75 | BTC | USDC |
    @case:391
    Examples:
      | amt | base | quote |
      | 7.75 | ETH | USDC |
    @case:392
    Examples:
      | amt | base | quote |
      | 7.75 | SOL | USDC |
    @case:393
    Examples:
      | amt | base | quote |
      | 7.75 | ETH | BTC |
    @case:394
    Examples:
      | amt | base | quote |
      | 7.75 | SOL | ETH |
    @case:395
    Examples:
      | amt | base | quote |
      | 7.75 | USDC | USD |
    @case:396
    Examples:
      | amt | base | quote |
      | 8.00 | BTC | USD |
    @case:397
    Examples:
      | amt | base | quote |
      | 8.00 | ETH | USD |
    @case:398
    Examples:
      | amt | base | quote |
      | 8.00 | SOL | USD |
    @case:399
    Examples:
      | amt | base | quote |
      | 8.00 | BTC | USDC |
    @case:400
    Examples:
      | amt | base | quote |
      | 8.00 | ETH | USDC |
    @case:401
    Examples:
      | amt | base | quote |
      | 8.00 | SOL | USDC |
    @case:402
    Examples:
      | amt | base | quote |
      | 8.00 | ETH | BTC |
    @case:403
    Examples:
      | amt | base | quote |
      | 8.00 | SOL | ETH |
    @case:404
    Examples:
      | amt | base | quote |
      | 8.00 | USDC | USD |
    @case:405
    Examples:
      | amt | base | quote |
      | 8.25 | BTC | USD |
    @case:406
    Examples:
      | amt | base | quote |
      | 8.25 | ETH | USD |
    @case:407
    Examples:
      | amt | base | quote |
      | 8.25 | SOL | USD |
    @case:408
    Examples:
      | amt | base | quote |
      | 8.25 | BTC | USDC |
    @case:409
    Examples:
      | amt | base | quote |
      | 8.25 | ETH | USDC |
    @case:410
    Examples:
      | amt | base | quote |
      | 8.25 | SOL | USDC |
    @case:411
    Examples:
      | amt | base | quote |
      | 8.25 | ETH | BTC |
    @case:412
    Examples:
      | amt | base | quote |
      | 8.25 | SOL | ETH |
    @case:413
    Examples:
      | amt | base | quote |
      | 8.25 | USDC | USD |
    @case:414
    Examples:
      | amt | base | quote |
      | 8.50 | BTC | USD |
    @case:415
    Examples:
      | amt | base | quote |
      | 8.50 | ETH | USD |
    @case:416
    Examples:
      | amt | base | quote |
      | 8.50 | SOL | USD |
    @case:417
    Examples:
      | amt | base | quote |
      | 8.50 | BTC | USDC |
    @case:418
    Examples:
      | amt | base | quote |
      | 8.50 | ETH | USDC |
    @case:419
    Examples:
      | amt | base | quote |
      | 8.50 | SOL | USDC |
    @case:420
    Examples:
      | amt | base | quote |
      | 8.50 | ETH | BTC |
    @case:421
    Examples:
      | amt | base | quote |
      | 8.50 | SOL | ETH |
    @case:422
    Examples:
      | amt | base | quote |
      | 8.50 | USDC | USD |
    @case:423
    Examples:
      | amt | base | quote |
      | 8.75 | BTC | USD |
    @case:424
    Examples:
      | amt | base | quote |
      | 8.75 | ETH | USD |
    @case:425
    Examples:
      | amt | base | quote |
      | 8.75 | SOL | USD |
    @case:426
    Examples:
      | amt | base | quote |
      | 8.75 | BTC | USDC |
    @case:427
    Examples:
      | amt | base | quote |
      | 8.75 | ETH | USDC |
    @case:428
    Examples:
      | amt | base | quote |
      | 8.75 | SOL | USDC |
    @case:429
    Examples:
      | amt | base | quote |
      | 8.75 | ETH | BTC |
    @case:430
    Examples:
      | amt | base | quote |
      | 8.75 | SOL | ETH |
    @case:431
    Examples:
      | amt | base | quote |
      | 8.75 | USDC | USD |
    @case:432
    Examples:
      | amt | base | quote |
      | 9.00 | BTC | USD |
    @case:433
    Examples:
      | amt | base | quote |
      | 9.00 | ETH | USD |
    @case:434
    Examples:
      | amt | base | quote |
      | 9.00 | SOL | USD |
    @case:435
    Examples:
      | amt | base | quote |
      | 9.00 | BTC | USDC |
    @case:436
    Examples:
      | amt | base | quote |
      | 9.00 | ETH | USDC |
    @case:437
    Examples:
      | amt | base | quote |
      | 9.00 | SOL | USDC |
    @case:438
    Examples:
      | amt | base | quote |
      | 9.00 | ETH | BTC |
    @case:439
    Examples:
      | amt | base | quote |
      | 9.00 | SOL | ETH |
    @case:440
    Examples:
      | amt | base | quote |
      | 9.00 | USDC | USD |
    @case:441
    Examples:
      | amt | base | quote |
      | 9.25 | BTC | USD |
    @case:442
    Examples:
      | amt | base | quote |
      | 9.25 | ETH | USD |
    @case:443
    Examples:
      | amt | base | quote |
      | 9.25 | SOL | USD |
    @case:444
    Examples:
      | amt | base | quote |
      | 9.25 | BTC | USDC |
    @case:445
    Examples:
      | amt | base | quote |
      | 9.25 | ETH | USDC |
    @case:446
    Examples:
      | amt | base | quote |
      | 9.25 | SOL | USDC |
    @case:447
    Examples:
      | amt | base | quote |
      | 9.25 | ETH | BTC |
    @case:448
    Examples:
      | amt | base | quote |
      | 9.25 | SOL | ETH |
    @case:449
    Examples:
      | amt | base | quote |
      | 9.25 | USDC | USD |
    @case:450
    Examples:
      | amt | base | quote |
      | 9.50 | BTC | USD |
    @case:451
    Examples:
      | amt | base | quote |
      | 9.50 | ETH | USD |
    @case:452
    Examples:
      | amt | base | quote |
      | 9.50 | SOL | USD |
    @case:453
    Examples:
      | amt | base | quote |
      | 9.50 | BTC | USDC |
    @case:454
    Examples:
      | amt | base | quote |
      | 9.50 | ETH | USDC |
    @case:455
    Examples:
      | amt | base | quote |
      | 9.50 | SOL | USDC |
    @case:456
    Examples:
      | amt | base | quote |
      | 9.50 | ETH | BTC |
    @case:457
    Examples:
      | amt | base | quote |
      | 9.50 | SOL | ETH |
    @case:458
    Examples:
      | amt | base | quote |
      | 9.50 | USDC | USD |
    @case:459
    Examples:
      | amt | base | quote |
      | 9.75 | BTC | USD |
    @case:460
    Examples:
      | amt | base | quote |
      | 9.75 | ETH | USD |
    @case:461
    Examples:
      | amt | base | quote |
      | 9.75 | SOL | USD |
    @case:462
    Examples:
      | amt | base | quote |
      | 9.75 | BTC | USDC |
    @case:463
    Examples:
      | amt | base | quote |
      | 9.75 | ETH | USDC |
    @case:464
    Examples:
      | amt | base | quote |
      | 9.75 | SOL | USDC |
    @case:465
    Examples:
      | amt | base | quote |
      | 9.75 | ETH | BTC |
    @case:466
    Examples:
      | amt | base | quote |
      | 9.75 | SOL | ETH |
    @case:467
    Examples:
      | amt | base | quote |
      | 9.75 | USDC | USD |
    @case:468
    Examples:
      | amt | base | quote |
      | 10.00 | BTC | USD |
    @case:469
    Examples:
      | amt | base | quote |
      | 10.00 | ETH | USD |
    @case:470
    Examples:
      | amt | base | quote |
      | 10.00 | SOL | USD |
    @case:471
    Examples:
      | amt | base | quote |
      | 10.00 | BTC | USDC |
    @case:472
    Examples:
      | amt | base | quote |
      | 10.00 | ETH | USDC |
    @case:473
    Examples:
      | amt | base | quote |
      | 10.00 | SOL | USDC |
    @case:474
    Examples:
      | amt | base | quote |
      | 10.00 | ETH | BTC |
    @case:475
    Examples:
      | amt | base | quote |
      | 10.00 | SOL | ETH |
    @case:476
    Examples:
      | amt | base | quote |
      | 10.00 | USDC | USD |
    @case:477
    Examples:
      | amt | base | quote |
      | 10.25 | BTC | USD |
    @case:478
    Examples:
      | amt | base | quote |
      | 10.25 | ETH | USD |
    @case:479
    Examples:
      | amt | base | quote |
      | 10.25 | SOL | USD |
    @case:480
    Examples:
      | amt | base | quote |
      | 10.25 | BTC | USDC |
    @case:481
    Examples:
      | amt | base | quote |
      | 10.25 | ETH | USDC |
    @case:482
    Examples:
      | amt | base | quote |
      | 10.25 | SOL | USDC |
    @case:483
    Examples:
      | amt | base | quote |
      | 10.25 | ETH | BTC |
    @case:484
    Examples:
      | amt | base | quote |
      | 10.25 | SOL | ETH |
    @case:485
    Examples:
      | amt | base | quote |
      | 10.25 | USDC | USD |
    @case:486
    Examples:
      | amt | base | quote |
      | 10.50 | BTC | USD |
    @case:487
    Examples:
      | amt | base | quote |
      | 10.50 | ETH | USD |
    @case:488
    Examples:
      | amt | base | quote |
      | 10.50 | SOL | USD |
    @case:489
    Examples:
      | amt | base | quote |
      | 10.50 | BTC | USDC |
    @case:490
    Examples:
      | amt | base | quote |
      | 10.50 | ETH | USDC |
    @case:491
    Examples:
      | amt | base | quote |
      | 10.50 | SOL | USDC |
    @case:492
    Examples:
      | amt | base | quote |
      | 10.50 | ETH | BTC |
    @case:493
    Examples:
      | amt | base | quote |
      | 10.50 | SOL | ETH |
    @case:494
    Examples:
      | amt | base | quote |
      | 10.50 | USDC | USD |
    @case:495
    Examples:
      | amt | base | quote |
      | 10.75 | BTC | USD |
    @case:496
    Examples:
      | amt | base | quote |
      | 10.75 | ETH | USD |
    @case:497
    Examples:
      | amt | base | quote |
      | 10.75 | SOL | USD |
    @case:498
    Examples:
      | amt | base | quote |
      | 10.75 | BTC | USDC |
    @case:499
    Examples:
      | amt | base | quote |
      | 10.75 | ETH | USDC |
    @case:500
    Examples:
      | amt | base | quote |
      | 10.75 | SOL | USDC |
    @case:501
    Examples:
      | amt | base | quote |
      | 10.75 | ETH | BTC |
    @case:502
    Examples:
      | amt | base | quote |
      | 10.75 | SOL | ETH |
    @case:503
    Examples:
      | amt | base | quote |
      | 10.75 | USDC | USD |
    @case:504
    Examples:
      | amt | base | quote |
      | 11.00 | BTC | USD |
    @case:505
    Examples:
      | amt | base | quote |
      | 11.00 | ETH | USD |
    @case:506
    Examples:
      | amt | base | quote |
      | 11.00 | SOL | USD |
    @case:507
    Examples:
      | amt | base | quote |
      | 11.00 | BTC | USDC |
    @case:508
    Examples:
      | amt | base | quote |
      | 11.00 | ETH | USDC |
    @case:509
    Examples:
      | amt | base | quote |
      | 11.00 | SOL | USDC |
    @case:510
    Examples:
      | amt | base | quote |
      | 11.00 | ETH | BTC |
    @case:511
    Examples:
      | amt | base | quote |
      | 11.00 | SOL | ETH |
    @case:512
    Examples:
      | amt | base | quote |
      | 11.00 | USDC | USD |
    @case:513
    Examples:
      | amt | base | quote |
      | 11.25 | BTC | USD |
    @case:514
    Examples:
      | amt | base | quote |
      | 11.25 | ETH | USD |
    @case:515
    Examples:
      | amt | base | quote |
      | 11.25 | SOL | USD |
    @case:516
    Examples:
      | amt | base | quote |
      | 11.25 | BTC | USDC |
    @case:517
    Examples:
      | amt | base | quote |
      | 11.25 | ETH | USDC |
    @case:518
    Examples:
      | amt | base | quote |
      | 11.25 | SOL | USDC |
    @case:519
    Examples:
      | amt | base | quote |
      | 11.25 | ETH | BTC |
    @case:520
    Examples:
      | amt | base | quote |
      | 11.25 | SOL | ETH |
    @case:521
    Examples:
      | amt | base | quote |
      | 11.25 | USDC | USD |
    @case:522
    Examples:
      | amt | base | quote |
      | 11.50 | BTC | USD |
    @case:523
    Examples:
      | amt | base | quote |
      | 11.50 | ETH | USD |
    @case:524
    Examples:
      | amt | base | quote |
      | 11.50 | SOL | USD |
    @case:525
    Examples:
      | amt | base | quote |
      | 11.50 | BTC | USDC |
    @case:526
    Examples:
      | amt | base | quote |
      | 11.50 | ETH | USDC |
    @case:527
    Examples:
      | amt | base | quote |
      | 11.50 | SOL | USDC |
    @case:528
    Examples:
      | amt | base | quote |
      | 11.50 | ETH | BTC |
    @case:529
    Examples:
      | amt | base | quote |
      | 11.50 | SOL | ETH |
    @case:530
    Examples:
      | amt | base | quote |
      | 11.50 | USDC | USD |
    @case:531
    Examples:
      | amt | base | quote |
      | 11.75 | BTC | USD |
    @case:532
    Examples:
      | amt | base | quote |
      | 11.75 | ETH | USD |
    @case:533
    Examples:
      | amt | base | quote |
      | 11.75 | SOL | USD |
    @case:534
    Examples:
      | amt | base | quote |
      | 11.75 | BTC | USDC |
    @case:535
    Examples:
      | amt | base | quote |
      | 11.75 | ETH | USDC |
    @case:536
    Examples:
      | amt | base | quote |
      | 11.75 | SOL | USDC |
    @case:537
    Examples:
      | amt | base | quote |
      | 11.75 | ETH | BTC |
    @case:538
    Examples:
      | amt | base | quote |
      | 11.75 | SOL | ETH |
    @case:539
    Examples:
      | amt | base | quote |
      | 11.75 | USDC | USD |
    @case:540
    Examples:
      | amt | base | quote |
      | 12.00 | BTC | USD |
    @case:541
    Examples:
      | amt | base | quote |
      | 12.00 | ETH | USD |
    @case:542
    Examples:
      | amt | base | quote |
      | 12.00 | SOL | USD |
    @case:543
    Examples:
      | amt | base | quote |
      | 12.00 | BTC | USDC |
    @case:544
    Examples:
      | amt | base | quote |
      | 12.00 | ETH | USDC |
    @case:545
    Examples:
      | amt | base | quote |
      | 12.00 | SOL | USDC |
    @case:546
    Examples:
      | amt | base | quote |
      | 12.00 | ETH | BTC |
    @case:547
    Examples:
      | amt | base | quote |
      | 12.00 | SOL | ETH |
    @case:548
    Examples:
      | amt | base | quote |
      | 12.00 | USDC | USD |
    @case:549
    Examples:
      | amt | base | quote |
      | 12.25 | BTC | USD |
    @case:550
    Examples:
      | amt | base | quote |
      | 12.25 | ETH | USD |
    @case:551
    Examples:
      | amt | base | quote |
      | 12.25 | SOL | USD |
    @case:552
    Examples:
      | amt | base | quote |
      | 12.25 | BTC | USDC |
    @case:553
    Examples:
      | amt | base | quote |
      | 12.25 | ETH | USDC |
    @case:554
    Examples:
      | amt | base | quote |
      | 12.25 | SOL | USDC |
    @case:555
    Examples:
      | amt | base | quote |
      | 12.25 | ETH | BTC |
    @case:556
    Examples:
      | amt | base | quote |
      | 12.25 | SOL | ETH |
    @case:557
    Examples:
      | amt | base | quote |
      | 12.25 | USDC | USD |
    @case:558
    Examples:
      | amt | base | quote |
      | 12.50 | BTC | USD |
    @case:559
    Examples:
      | amt | base | quote |
      | 12.50 | ETH | USD |
    @case:560
    Examples:
      | amt | base | quote |
      | 12.50 | SOL | USD |
    @case:561
    Examples:
      | amt | base | quote |
      | 12.50 | BTC | USDC |
    @case:562
    Examples:
      | amt | base | quote |
      | 12.50 | ETH | USDC |
    @case:563
    Examples:
      | amt | base | quote |
      | 12.50 | SOL | USDC |
    @case:564
    Examples:
      | amt | base | quote |
      | 12.50 | ETH | BTC |
    @case:565
    Examples:
      | amt | base | quote |
      | 12.50 | SOL | ETH |
    @case:566
    Examples:
      | amt | base | quote |
      | 12.50 | USDC | USD |
    @case:567
    Examples:
      | amt | base | quote |
      | 12.75 | BTC | USD |
    @case:568
    Examples:
      | amt | base | quote |
      | 12.75 | ETH | USD |
    @case:569
    Examples:
      | amt | base | quote |
      | 12.75 | SOL | USD |
    @case:570
    Examples:
      | amt | base | quote |
      | 12.75 | BTC | USDC |
    @case:571
    Examples:
      | amt | base | quote |
      | 12.75 | ETH | USDC |
    @case:572
    Examples:
      | amt | base | quote |
      | 12.75 | SOL | USDC |
    @case:573
    Examples:
      | amt | base | quote |
      | 12.75 | ETH | BTC |
    @case:574
    Examples:
      | amt | base | quote |
      | 12.75 | SOL | ETH |
    @case:575
    Examples:
      | amt | base | quote |
      | 12.75 | USDC | USD |
    @case:576
    Examples:
      | amt | base | quote |
      | 13.00 | BTC | USD |
    @case:577
    Examples:
      | amt | base | quote |
      | 13.00 | ETH | USD |
    @case:578
    Examples:
      | amt | base | quote |
      | 13.00 | SOL | USD |
    @case:579
    Examples:
      | amt | base | quote |
      | 13.00 | BTC | USDC |
    @case:580
    Examples:
      | amt | base | quote |
      | 13.00 | ETH | USDC |
    @case:581
    Examples:
      | amt | base | quote |
      | 13.00 | SOL | USDC |
    @case:582
    Examples:
      | amt | base | quote |
      | 13.00 | ETH | BTC |
    @case:583
    Examples:
      | amt | base | quote |
      | 13.00 | SOL | ETH |
    @case:584
    Examples:
      | amt | base | quote |
      | 13.00 | USDC | USD |
    @case:585
    Examples:
      | amt | base | quote |
      | 13.25 | BTC | USD |
    @case:586
    Examples:
      | amt | base | quote |
      | 13.25 | ETH | USD |
    @case:587
    Examples:
      | amt | base | quote |
      | 13.25 | SOL | USD |
    @case:588
    Examples:
      | amt | base | quote |
      | 13.25 | BTC | USDC |
    @case:589
    Examples:
      | amt | base | quote |
      | 13.25 | ETH | USDC |
    @case:590
    Examples:
      | amt | base | quote |
      | 13.25 | SOL | USDC |
    @case:591
    Examples:
      | amt | base | quote |
      | 13.25 | ETH | BTC |
    @case:592
    Examples:
      | amt | base | quote |
      | 13.25 | SOL | ETH |
    @case:593
    Examples:
      | amt | base | quote |
      | 13.25 | USDC | USD |
    @case:594
    Examples:
      | amt | base | quote |
      | 13.50 | BTC | USD |
    @case:595
    Examples:
      | amt | base | quote |
      | 13.50 | ETH | USD |
    @case:596
    Examples:
      | amt | base | quote |
      | 13.50 | SOL | USD |
    @case:597
    Examples:
      | amt | base | quote |
      | 13.50 | BTC | USDC |
    @case:598
    Examples:
      | amt | base | quote |
      | 13.50 | ETH | USDC |
    @case:599
    Examples:
      | amt | base | quote |
      | 13.50 | SOL | USDC |
    @case:600
    Examples:
      | amt | base | quote |
      | 13.50 | ETH | BTC |
    @case:601
    Examples:
      | amt | base | quote |
      | 13.50 | SOL | ETH |
    @case:602
    Examples:
      | amt | base | quote |
      | 13.50 | USDC | USD |
    @case:603
    Examples:
      | amt | base | quote |
      | 13.75 | BTC | USD |
    @case:604
    Examples:
      | amt | base | quote |
      | 13.75 | ETH | USD |
    @case:605
    Examples:
      | amt | base | quote |
      | 13.75 | SOL | USD |
    @case:606
    Examples:
      | amt | base | quote |
      | 13.75 | BTC | USDC |
    @case:607
    Examples:
      | amt | base | quote |
      | 13.75 | ETH | USDC |
    @case:608
    Examples:
      | amt | base | quote |
      | 13.75 | SOL | USDC |
    @case:609
    Examples:
      | amt | base | quote |
      | 13.75 | ETH | BTC |
    @case:610
    Examples:
      | amt | base | quote |
      | 13.75 | SOL | ETH |
    @case:611
    Examples:
      | amt | base | quote |
      | 13.75 | USDC | USD |
    @case:612
    Examples:
      | amt | base | quote |
      | 14.00 | BTC | USD |
    @case:613
    Examples:
      | amt | base | quote |
      | 14.00 | ETH | USD |
    @case:614
    Examples:
      | amt | base | quote |
      | 14.00 | SOL | USD |
    @case:615
    Examples:
      | amt | base | quote |
      | 14.00 | BTC | USDC |
    @case:616
    Examples:
      | amt | base | quote |
      | 14.00 | ETH | USDC |
    @case:617
    Examples:
      | amt | base | quote |
      | 14.00 | SOL | USDC |
    @case:618
    Examples:
      | amt | base | quote |
      | 14.00 | ETH | BTC |
    @case:619
    Examples:
      | amt | base | quote |
      | 14.00 | SOL | ETH |
    @case:620
    Examples:
      | amt | base | quote |
      | 14.00 | USDC | USD |
    @case:621
    Examples:
      | amt | base | quote |
      | 14.25 | BTC | USD |
    @case:622
    Examples:
      | amt | base | quote |
      | 14.25 | ETH | USD |
    @case:623
    Examples:
      | amt | base | quote |
      | 14.25 | SOL | USD |
    @case:624
    Examples:
      | amt | base | quote |
      | 14.25 | BTC | USDC |
    @case:625
    Examples:
      | amt | base | quote |
      | 14.25 | ETH | USDC |
    @case:626
    Examples:
      | amt | base | quote |
      | 14.25 | SOL | USDC |
    @case:627
    Examples:
      | amt | base | quote |
      | 14.25 | ETH | BTC |
    @case:628
    Examples:
      | amt | base | quote |
      | 14.25 | SOL | ETH |
    @case:629
    Examples:
      | amt | base | quote |
      | 14.25 | USDC | USD |
    @case:630
    Examples:
      | amt | base | quote |
      | 14.50 | BTC | USD |
    @case:631
    Examples:
      | amt | base | quote |
      | 14.50 | ETH | USD |
    @case:632
    Examples:
      | amt | base | quote |
      | 14.50 | SOL | USD |
    @case:633
    Examples:
      | amt | base | quote |
      | 14.50 | BTC | USDC |
    @case:634
    Examples:
      | amt | base | quote |
      | 14.50 | ETH | USDC |
    @case:635
    Examples:
      | amt | base | quote |
      | 14.50 | SOL | USDC |
    @case:636
    Examples:
      | amt | base | quote |
      | 14.50 | ETH | BTC |
    @case:637
    Examples:
      | amt | base | quote |
      | 14.50 | SOL | ETH |
    @case:638
    Examples:
      | amt | base | quote |
      | 14.50 | USDC | USD |
    @case:639
    Examples:
      | amt | base | quote |
      | 14.75 | BTC | USD |
    @case:640
    Examples:
      | amt | base | quote |
      | 14.75 | ETH | USD |
    @case:641
    Examples:
      | amt | base | quote |
      | 14.75 | SOL | USD |
    @case:642
    Examples:
      | amt | base | quote |
      | 14.75 | BTC | USDC |
    @case:643
    Examples:
      | amt | base | quote |
      | 14.75 | ETH | USDC |
    @case:644
    Examples:
      | amt | base | quote |
      | 14.75 | SOL | USDC |
    @case:645
    Examples:
      | amt | base | quote |
      | 14.75 | ETH | BTC |
    @case:646
    Examples:
      | amt | base | quote |
      | 14.75 | SOL | ETH |
    @case:647
    Examples:
      | amt | base | quote |
      | 14.75 | USDC | USD |
    @case:648
    Examples:
      | amt | base | quote |
      | 15.00 | BTC | USD |
    @case:649
    Examples:
      | amt | base | quote |
      | 15.00 | ETH | USD |
    @case:650
    Examples:
      | amt | base | quote |
      | 15.00 | SOL | USD |
    @case:651
    Examples:
      | amt | base | quote |
      | 15.00 | BTC | USDC |
    @case:652
    Examples:
      | amt | base | quote |
      | 15.00 | ETH | USDC |
    @case:653
    Examples:
      | amt | base | quote |
      | 15.00 | SOL | USDC |
    @case:654
    Examples:
      | amt | base | quote |
      | 15.00 | ETH | BTC |
    @case:655
    Examples:
      | amt | base | quote |
      | 15.00 | SOL | ETH |
    @case:656
    Examples:
      | amt | base | quote |
      | 15.00 | USDC | USD |
    @case:657
    Examples:
      | amt | base | quote |
      | 15.25 | BTC | USD |
    @case:658
    Examples:
      | amt | base | quote |
      | 15.25 | ETH | USD |
    @case:659
    Examples:
      | amt | base | quote |
      | 15.25 | SOL | USD |
    @case:660
    Examples:
      | amt | base | quote |
      | 15.25 | BTC | USDC |
    @case:661
    Examples:
      | amt | base | quote |
      | 15.25 | ETH | USDC |
    @case:662
    Examples:
      | amt | base | quote |
      | 15.25 | SOL | USDC |
    @case:663
    Examples:
      | amt | base | quote |
      | 15.25 | ETH | BTC |
    @case:664
    Examples:
      | amt | base | quote |
      | 15.25 | SOL | ETH |
    @case:665
    Examples:
      | amt | base | quote |
      | 15.25 | USDC | USD |
    @case:666
    Examples:
      | amt | base | quote |
      | 15.50 | BTC | USD |
    @case:667
    Examples:
      | amt | base | quote |
      | 15.50 | ETH | USD |
    @case:668
    Examples:
      | amt | base | quote |
      | 15.50 | SOL | USD |
    @case:669
    Examples:
      | amt | base | quote |
      | 15.50 | BTC | USDC |
    @case:670
    Examples:
      | amt | base | quote |
      | 15.50 | ETH | USDC |
    @case:671
    Examples:
      | amt | base | quote |
      | 15.50 | SOL | USDC |
    @case:672
    Examples:
      | amt | base | quote |
      | 15.50 | ETH | BTC |
    @case:673
    Examples:
      | amt | base | quote |
      | 15.50 | SOL | ETH |
    @case:674
    Examples:
      | amt | base | quote |
      | 15.50 | USDC | USD |
    @case:675
    Examples:
      | amt | base | quote |
      | 15.75 | BTC | USD |
    @case:676
    Examples:
      | amt | base | quote |
      | 15.75 | ETH | USD |
    @case:677
    Examples:
      | amt | base | quote |
      | 15.75 | SOL | USD |
    @case:678
    Examples:
      | amt | base | quote |
      | 15.75 | BTC | USDC |
    @case:679
    Examples:
      | amt | base | quote |
      | 15.75 | ETH | USDC |
    @case:680
    Examples:
      | amt | base | quote |
      | 15.75 | SOL | USDC |
    @case:681
    Examples:
      | amt | base | quote |
      | 15.75 | ETH | BTC |
    @case:682
    Examples:
      | amt | base | quote |
      | 15.75 | SOL | ETH |
    @case:683
    Examples:
      | amt | base | quote |
      | 15.75 | USDC | USD |
    @case:684
    Examples:
      | amt | base | quote |
      | 16.00 | BTC | USD |
    @case:685
    Examples:
      | amt | base | quote |
      | 16.00 | ETH | USD |
    @case:686
    Examples:
      | amt | base | quote |
      | 16.00 | SOL | USD |
    @case:687
    Examples:
      | amt | base | quote |
      | 16.00 | BTC | USDC |
    @case:688
    Examples:
      | amt | base | quote |
      | 16.00 | ETH | USDC |
    @case:689
    Examples:
      | amt | base | quote |
      | 16.00 | SOL | USDC |
    @case:690
    Examples:
      | amt | base | quote |
      | 16.00 | ETH | BTC |
    @case:691
    Examples:
      | amt | base | quote |
      | 16.00 | SOL | ETH |
    @case:692
    Examples:
      | amt | base | quote |
      | 16.00 | USDC | USD |
    @case:693
    Examples:
      | amt | base | quote |
      | 16.25 | BTC | USD |
    @case:694
    Examples:
      | amt | base | quote |
      | 16.25 | ETH | USD |
    @case:695
    Examples:
      | amt | base | quote |
      | 16.25 | SOL | USD |
    @case:696
    Examples:
      | amt | base | quote |
      | 16.25 | BTC | USDC |
    @case:697
    Examples:
      | amt | base | quote |
      | 16.25 | ETH | USDC |
    @case:698
    Examples:
      | amt | base | quote |
      | 16.25 | SOL | USDC |
    @case:699
    Examples:
      | amt | base | quote |
      | 16.25 | ETH | BTC |
    @case:700
    Examples:
      | amt | base | quote |
      | 16.25 | SOL | ETH |
    @case:701
    Examples:
      | amt | base | quote |
      | 16.25 | USDC | USD |
    @case:702
    Examples:
      | amt | base | quote |
      | 16.50 | BTC | USD |
    @case:703
    Examples:
      | amt | base | quote |
      | 16.50 | ETH | USD |
    @case:704
    Examples:
      | amt | base | quote |
      | 16.50 | SOL | USD |
    @case:705
    Examples:
      | amt | base | quote |
      | 16.50 | BTC | USDC |
    @case:706
    Examples:
      | amt | base | quote |
      | 16.50 | ETH | USDC |
    @case:707
    Examples:
      | amt | base | quote |
      | 16.50 | SOL | USDC |
    @case:708
    Examples:
      | amt | base | quote |
      | 16.50 | ETH | BTC |
    @case:709
    Examples:
      | amt | base | quote |
      | 16.50 | SOL | ETH |
    @case:710
    Examples:
      | amt | base | quote |
      | 16.50 | USDC | USD |
    @case:711
    Examples:
      | amt | base | quote |
      | 16.75 | BTC | USD |
    @case:712
    Examples:
      | amt | base | quote |
      | 16.75 | ETH | USD |
    @case:713
    Examples:
      | amt | base | quote |
      | 16.75 | SOL | USD |
    @case:714
    Examples:
      | amt | base | quote |
      | 16.75 | BTC | USDC |
    @case:715
    Examples:
      | amt | base | quote |
      | 16.75 | ETH | USDC |
    @case:716
    Examples:
      | amt | base | quote |
      | 16.75 | SOL | USDC |
    @case:717
    Examples:
      | amt | base | quote |
      | 16.75 | ETH | BTC |
    @case:718
    Examples:
      | amt | base | quote |
      | 16.75 | SOL | ETH |
    @case:719
    Examples:
      | amt | base | quote |
      | 16.75 | USDC | USD |
    @case:720
    Examples:
      | amt | base | quote |
      | 17.00 | BTC | USD |
    @case:721
    Examples:
      | amt | base | quote |
      | 17.00 | ETH | USD |
    @case:722
    Examples:
      | amt | base | quote |
      | 17.00 | SOL | USD |
    @case:723
    Examples:
      | amt | base | quote |
      | 17.00 | BTC | USDC |
    @case:724
    Examples:
      | amt | base | quote |
      | 17.00 | ETH | USDC |
    @case:725
    Examples:
      | amt | base | quote |
      | 17.00 | SOL | USDC |
    @case:726
    Examples:
      | amt | base | quote |
      | 17.00 | ETH | BTC |
    @case:727
    Examples:
      | amt | base | quote |
      | 17.00 | SOL | ETH |
    @case:728
    Examples:
      | amt | base | quote |
      | 17.00 | USDC | USD |
    @case:729
    Examples:
      | amt | base | quote |
      | 17.25 | BTC | USD |
    @case:730
    Examples:
      | amt | base | quote |
      | 17.25 | ETH | USD |
    @case:731
    Examples:
      | amt | base | quote |
      | 17.25 | SOL | USD |
    @case:732
    Examples:
      | amt | base | quote |
      | 17.25 | BTC | USDC |
    @case:733
    Examples:
      | amt | base | quote |
      | 17.25 | ETH | USDC |
    @case:734
    Examples:
      | amt | base | quote |
      | 17.25 | SOL | USDC |
    @case:735
    Examples:
      | amt | base | quote |
      | 17.25 | ETH | BTC |
    @case:736
    Examples:
      | amt | base | quote |
      | 17.25 | SOL | ETH |
    @case:737
    Examples:
      | amt | base | quote |
      | 17.25 | USDC | USD |
    @case:738
    Examples:
      | amt | base | quote |
      | 17.50 | BTC | USD |
    @case:739
    Examples:
      | amt | base | quote |
      | 17.50 | ETH | USD |
    @case:740
    Examples:
      | amt | base | quote |
      | 17.50 | SOL | USD |
    @case:741
    Examples:
      | amt | base | quote |
      | 17.50 | BTC | USDC |
    @case:742
    Examples:
      | amt | base | quote |
      | 17.50 | ETH | USDC |
    @case:743
    Examples:
      | amt | base | quote |
      | 17.50 | SOL | USDC |
    @case:744
    Examples:
      | amt | base | quote |
      | 17.50 | ETH | BTC |
    @case:745
    Examples:
      | amt | base | quote |
      | 17.50 | SOL | ETH |
    @case:746
    Examples:
      | amt | base | quote |
      | 17.50 | USDC | USD |
    @case:747
    Examples:
      | amt | base | quote |
      | 17.75 | BTC | USD |
    @case:748
    Examples:
      | amt | base | quote |
      | 17.75 | ETH | USD |
    @case:749
    Examples:
      | amt | base | quote |
      | 17.75 | SOL | USD |
    @case:750
    Examples:
      | amt | base | quote |
      | 17.75 | BTC | USDC |
    @case:751
    Examples:
      | amt | base | quote |
      | 17.75 | ETH | USDC |
    @case:752
    Examples:
      | amt | base | quote |
      | 17.75 | SOL | USDC |
    @case:753
    Examples:
      | amt | base | quote |
      | 17.75 | ETH | BTC |
    @case:754
    Examples:
      | amt | base | quote |
      | 17.75 | SOL | ETH |
    @case:755
    Examples:
      | amt | base | quote |
      | 17.75 | USDC | USD |
    @case:756
    Examples:
      | amt | base | quote |
      | 18.00 | BTC | USD |
    @case:757
    Examples:
      | amt | base | quote |
      | 18.00 | ETH | USD |
    @case:758
    Examples:
      | amt | base | quote |
      | 18.00 | SOL | USD |
    @case:759
    Examples:
      | amt | base | quote |
      | 18.00 | BTC | USDC |
    @case:760
    Examples:
      | amt | base | quote |
      | 18.00 | ETH | USDC |
    @case:761
    Examples:
      | amt | base | quote |
      | 18.00 | SOL | USDC |
    @case:762
    Examples:
      | amt | base | quote |
      | 18.00 | ETH | BTC |
    @case:763
    Examples:
      | amt | base | quote |
      | 18.00 | SOL | ETH |
    @case:764
    Examples:
      | amt | base | quote |
      | 18.00 | USDC | USD |
    @case:765
    Examples:
      | amt | base | quote |
      | 18.25 | BTC | USD |
    @case:766
    Examples:
      | amt | base | quote |
      | 18.25 | ETH | USD |
    @case:767
    Examples:
      | amt | base | quote |
      | 18.25 | SOL | USD |
    @case:768
    Examples:
      | amt | base | quote |
      | 18.25 | BTC | USDC |
    @case:769
    Examples:
      | amt | base | quote |
      | 18.25 | ETH | USDC |
    @case:770
    Examples:
      | amt | base | quote |
      | 18.25 | SOL | USDC |
    @case:771
    Examples:
      | amt | base | quote |
      | 18.25 | ETH | BTC |
    @case:772
    Examples:
      | amt | base | quote |
      | 18.25 | SOL | ETH |
    @case:773
    Examples:
      | amt | base | quote |
      | 18.25 | USDC | USD |
    @case:774
    Examples:
      | amt | base | quote |
      | 18.50 | BTC | USD |
    @case:775
    Examples:
      | amt | base | quote |
      | 18.50 | ETH | USD |
    @case:776
    Examples:
      | amt | base | quote |
      | 18.50 | SOL | USD |
    @case:777
    Examples:
      | amt | base | quote |
      | 18.50 | BTC | USDC |
    @case:778
    Examples:
      | amt | base | quote |
      | 18.50 | ETH | USDC |
    @case:779
    Examples:
      | amt | base | quote |
      | 18.50 | SOL | USDC |
    @case:780
    Examples:
      | amt | base | quote |
      | 18.50 | ETH | BTC |
    @case:781
    Examples:
      | amt | base | quote |
      | 18.50 | SOL | ETH |
    @case:782
    Examples:
      | amt | base | quote |
      | 18.50 | USDC | USD |
    @case:783
    Examples:
      | amt | base | quote |
      | 18.75 | BTC | USD |
    @case:784
    Examples:
      | amt | base | quote |
      | 18.75 | ETH | USD |
    @case:785
    Examples:
      | amt | base | quote |
      | 18.75 | SOL | USD |
    @case:786
    Examples:
      | amt | base | quote |
      | 18.75 | BTC | USDC |
    @case:787
    Examples:
      | amt | base | quote |
      | 18.75 | ETH | USDC |
    @case:788
    Examples:
      | amt | base | quote |
      | 18.75 | SOL | USDC |
    @case:789
    Examples:
      | amt | base | quote |
      | 18.75 | ETH | BTC |
    @case:790
    Examples:
      | amt | base | quote |
      | 18.75 | SOL | ETH |
    @case:791
    Examples:
      | amt | base | quote |
      | 18.75 | USDC | USD |
    @case:792
    Examples:
      | amt | base | quote |
      | 19.00 | BTC | USD |
    @case:793
    Examples:
      | amt | base | quote |
      | 19.00 | ETH | USD |
    @case:794
    Examples:
      | amt | base | quote |
      | 19.00 | SOL | USD |
    @case:795
    Examples:
      | amt | base | quote |
      | 19.00 | BTC | USDC |
    @case:796
    Examples:
      | amt | base | quote |
      | 19.00 | ETH | USDC |
    @case:797
    Examples:
      | amt | base | quote |
      | 19.00 | SOL | USDC |
    @case:798
    Examples:
      | amt | base | quote |
      | 19.00 | ETH | BTC |
    @case:799
    Examples:
      | amt | base | quote |
      | 19.00 | SOL | ETH |
    @case:800
    Examples:
      | amt | base | quote |
      | 19.00 | USDC | USD |
    @case:801
    Examples:
      | amt | base | quote |
      | 19.25 | BTC | USD |
    @case:802
    Examples:
      | amt | base | quote |
      | 19.25 | ETH | USD |
    @case:803
    Examples:
      | amt | base | quote |
      | 19.25 | SOL | USD |
    @case:804
    Examples:
      | amt | base | quote |
      | 19.25 | BTC | USDC |
    @case:805
    Examples:
      | amt | base | quote |
      | 19.25 | ETH | USDC |
    @case:806
    Examples:
      | amt | base | quote |
      | 19.25 | SOL | USDC |
    @case:807
    Examples:
      | amt | base | quote |
      | 19.25 | ETH | BTC |
    @case:808
    Examples:
      | amt | base | quote |
      | 19.25 | SOL | ETH |
    @case:809
    Examples:
      | amt | base | quote |
      | 19.25 | USDC | USD |
    @case:810
    Examples:
      | amt | base | quote |
      | 19.50 | BTC | USD |
    @case:811
    Examples:
      | amt | base | quote |
      | 19.50 | ETH | USD |
    @case:812
    Examples:
      | amt | base | quote |
      | 19.50 | SOL | USD |
    @case:813
    Examples:
      | amt | base | quote |
      | 19.50 | BTC | USDC |
    @case:814
    Examples:
      | amt | base | quote |
      | 19.50 | ETH | USDC |
    @case:815
    Examples:
      | amt | base | quote |
      | 19.50 | SOL | USDC |
    @case:816
    Examples:
      | amt | base | quote |
      | 19.50 | ETH | BTC |
    @case:817
    Examples:
      | amt | base | quote |
      | 19.50 | SOL | ETH |
    @case:818
    Examples:
      | amt | base | quote |
      | 19.50 | USDC | USD |
    @case:819
    Examples:
      | amt | base | quote |
      | 19.75 | BTC | USD |
    @case:820
    Examples:
      | amt | base | quote |
      | 19.75 | ETH | USD |
    @case:821
    Examples:
      | amt | base | quote |
      | 19.75 | SOL | USD |
    @case:822
    Examples:
      | amt | base | quote |
      | 19.75 | BTC | USDC |
    @case:823
    Examples:
      | amt | base | quote |
      | 19.75 | ETH | USDC |
    @case:824
    Examples:
      | amt | base | quote |
      | 19.75 | SOL | USDC |
    @case:825
    Examples:
      | amt | base | quote |
      | 19.75 | ETH | BTC |
    @case:826
    Examples:
      | amt | base | quote |
      | 19.75 | SOL | ETH |
    @case:827
    Examples:
      | amt | base | quote |
      | 19.75 | USDC | USD |
    @case:828
    Examples:
      | amt | base | quote |
      | 20.00 | BTC | USD |
    @case:829
    Examples:
      | amt | base | quote |
      | 20.00 | ETH | USD |
    @case:830
    Examples:
      | amt | base | quote |
      | 20.00 | SOL | USD |
    @case:831
    Examples:
      | amt | base | quote |
      | 20.00 | BTC | USDC |
    @case:832
    Examples:
      | amt | base | quote |
      | 20.00 | ETH | USDC |
    @case:833
    Examples:
      | amt | base | quote |
      | 20.00 | SOL | USDC |
    @case:834
    Examples:
      | amt | base | quote |
      | 20.00 | ETH | BTC |
    @case:835
    Examples:
      | amt | base | quote |
      | 20.00 | SOL | ETH |
    @case:836
    Examples:
      | amt | base | quote |
      | 20.00 | USDC | USD |
    @case:837
    Examples:
      | amt | base | quote |
      | 20.25 | BTC | USD |
    @case:838
    Examples:
      | amt | base | quote |
      | 20.25 | ETH | USD |
    @case:839
    Examples:
      | amt | base | quote |
      | 20.25 | SOL | USD |
    @case:840
    Examples:
      | amt | base | quote |
      | 20.25 | BTC | USDC |
    @case:841
    Examples:
      | amt | base | quote |
      | 20.25 | ETH | USDC |
    @case:842
    Examples:
      | amt | base | quote |
      | 20.25 | SOL | USDC |
    @case:843
    Examples:
      | amt | base | quote |
      | 20.25 | ETH | BTC |
    @case:844
    Examples:
      | amt | base | quote |
      | 20.25 | SOL | ETH |
    @case:845
    Examples:
      | amt | base | quote |
      | 20.25 | USDC | USD |
    @case:846
    Examples:
      | amt | base | quote |
      | 20.50 | BTC | USD |
    @case:847
    Examples:
      | amt | base | quote |
      | 20.50 | ETH | USD |
    @case:848
    Examples:
      | amt | base | quote |
      | 20.50 | SOL | USD |
    @case:849
    Examples:
      | amt | base | quote |
      | 20.50 | BTC | USDC |
    @case:850
    Examples:
      | amt | base | quote |
      | 20.50 | ETH | USDC |
    @case:851
    Examples:
      | amt | base | quote |
      | 20.50 | SOL | USDC |
    @case:852
    Examples:
      | amt | base | quote |
      | 20.50 | ETH | BTC |
    @case:853
    Examples:
      | amt | base | quote |
      | 20.50 | SOL | ETH |
    @case:854
    Examples:
      | amt | base | quote |
      | 20.50 | USDC | USD |
    @case:855
    Examples:
      | amt | base | quote |
      | 20.75 | BTC | USD |
    @case:856
    Examples:
      | amt | base | quote |
      | 20.75 | ETH | USD |
    @case:857
    Examples:
      | amt | base | quote |
      | 20.75 | SOL | USD |
    @case:858
    Examples:
      | amt | base | quote |
      | 20.75 | BTC | USDC |
    @case:859
    Examples:
      | amt | base | quote |
      | 20.75 | ETH | USDC |
    @case:860
    Examples:
      | amt | base | quote |
      | 20.75 | SOL | USDC |
    @case:861
    Examples:
      | amt | base | quote |
      | 20.75 | ETH | BTC |
    @case:862
    Examples:
      | amt | base | quote |
      | 20.75 | SOL | ETH |
    @case:863
    Examples:
      | amt | base | quote |
      | 20.75 | USDC | USD |
    @case:864
    Examples:
      | amt | base | quote |
      | 21.00 | BTC | USD |
    @case:865
    Examples:
      | amt | base | quote |
      | 21.00 | ETH | USD |
    @case:866
    Examples:
      | amt | base | quote |
      | 21.00 | SOL | USD |
    @case:867
    Examples:
      | amt | base | quote |
      | 21.00 | BTC | USDC |
    @case:868
    Examples:
      | amt | base | quote |
      | 21.00 | ETH | USDC |
    @case:869
    Examples:
      | amt | base | quote |
      | 21.00 | SOL | USDC |
    @case:870
    Examples:
      | amt | base | quote |
      | 21.00 | ETH | BTC |
    @case:871
    Examples:
      | amt | base | quote |
      | 21.00 | SOL | ETH |
    @case:872
    Examples:
      | amt | base | quote |
      | 21.00 | USDC | USD |
    @case:873
    Examples:
      | amt | base | quote |
      | 21.25 | BTC | USD |
    @case:874
    Examples:
      | amt | base | quote |
      | 21.25 | ETH | USD |
    @case:875
    Examples:
      | amt | base | quote |
      | 21.25 | SOL | USD |
    @case:876
    Examples:
      | amt | base | quote |
      | 21.25 | BTC | USDC |
    @case:877
    Examples:
      | amt | base | quote |
      | 21.25 | ETH | USDC |
    @case:878
    Examples:
      | amt | base | quote |
      | 21.25 | SOL | USDC |
    @case:879
    Examples:
      | amt | base | quote |
      | 21.25 | ETH | BTC |
    @case:880
    Examples:
      | amt | base | quote |
      | 21.25 | SOL | ETH |
    @case:881
    Examples:
      | amt | base | quote |
      | 21.25 | USDC | USD |
    @case:882
    Examples:
      | amt | base | quote |
      | 21.50 | BTC | USD |
    @case:883
    Examples:
      | amt | base | quote |
      | 21.50 | ETH | USD |
    @case:884
    Examples:
      | amt | base | quote |
      | 21.50 | SOL | USD |
    @case:885
    Examples:
      | amt | base | quote |
      | 21.50 | BTC | USDC |
    @case:886
    Examples:
      | amt | base | quote |
      | 21.50 | ETH | USDC |
    @case:887
    Examples:
      | amt | base | quote |
      | 21.50 | SOL | USDC |
    @case:888
    Examples:
      | amt | base | quote |
      | 21.50 | ETH | BTC |
    @case:889
    Examples:
      | amt | base | quote |
      | 21.50 | SOL | ETH |
    @case:890
    Examples:
      | amt | base | quote |
      | 21.50 | USDC | USD |
    @case:891
    Examples:
      | amt | base | quote |
      | 21.75 | BTC | USD |
    @case:892
    Examples:
      | amt | base | quote |
      | 21.75 | ETH | USD |
    @case:893
    Examples:
      | amt | base | quote |
      | 21.75 | SOL | USD |
    @case:894
    Examples:
      | amt | base | quote |
      | 21.75 | BTC | USDC |
    @case:895
    Examples:
      | amt | base | quote |
      | 21.75 | ETH | USDC |
    @case:896
    Examples:
      | amt | base | quote |
      | 21.75 | SOL | USDC |
    @case:897
    Examples:
      | amt | base | quote |
      | 21.75 | ETH | BTC |
    @case:898
    Examples:
      | amt | base | quote |
      | 21.75 | SOL | ETH |
    @case:899
    Examples:
      | amt | base | quote |
      | 21.75 | USDC | USD |
    @case:900
    Examples:
      | amt | base | quote |
      | 22.00 | BTC | USD |
    @case:901
    Examples:
      | amt | base | quote |
      | 22.00 | ETH | USD |
    @case:902
    Examples:
      | amt | base | quote |
      | 22.00 | SOL | USD |
    @case:903
    Examples:
      | amt | base | quote |
      | 22.00 | BTC | USDC |
    @case:904
    Examples:
      | amt | base | quote |
      | 22.00 | ETH | USDC |
    @case:905
    Examples:
      | amt | base | quote |
      | 22.00 | SOL | USDC |
    @case:906
    Examples:
      | amt | base | quote |
      | 22.00 | ETH | BTC |
    @case:907
    Examples:
      | amt | base | quote |
      | 22.00 | SOL | ETH |
    @case:908
    Examples:
      | amt | base | quote |
      | 22.00 | USDC | USD |
    @case:909
    Examples:
      | amt | base | quote |
      | 22.25 | BTC | USD |
    @case:910
    Examples:
      | amt | base | quote |
      | 22.25 | ETH | USD |
    @case:911
    Examples:
      | amt | base | quote |
      | 22.25 | SOL | USD |
    @case:912
    Examples:
      | amt | base | quote |
      | 22.25 | BTC | USDC |
    @case:913
    Examples:
      | amt | base | quote |
      | 22.25 | ETH | USDC |
    @case:914
    Examples:
      | amt | base | quote |
      | 22.25 | SOL | USDC |
    @case:915
    Examples:
      | amt | base | quote |
      | 22.25 | ETH | BTC |
    @case:916
    Examples:
      | amt | base | quote |
      | 22.25 | SOL | ETH |
    @case:917
    Examples:
      | amt | base | quote |
      | 22.25 | USDC | USD |
    @case:918
    Examples:
      | amt | base | quote |
      | 22.50 | BTC | USD |
    @case:919
    Examples:
      | amt | base | quote |
      | 22.50 | ETH | USD |
    @case:920
    Examples:
      | amt | base | quote |
      | 22.50 | SOL | USD |
    @case:921
    Examples:
      | amt | base | quote |
      | 22.50 | BTC | USDC |
    @case:922
    Examples:
      | amt | base | quote |
      | 22.50 | ETH | USDC |
    @case:923
    Examples:
      | amt | base | quote |
      | 22.50 | SOL | USDC |
    @case:924
    Examples:
      | amt | base | quote |
      | 22.50 | ETH | BTC |
    @case:925
    Examples:
      | amt | base | quote |
      | 22.50 | SOL | ETH |
    @case:926
    Examples:
      | amt | base | quote |
      | 22.50 | USDC | USD |
    @case:927
    Examples:
      | amt | base | quote |
      | 22.75 | BTC | USD |
    @case:928
    Examples:
      | amt | base | quote |
      | 22.75 | ETH | USD |
    @case:929
    Examples:
      | amt | base | quote |
      | 22.75 | SOL | USD |
    @case:930
    Examples:
      | amt | base | quote |
      | 22.75 | BTC | USDC |
    @case:931
    Examples:
      | amt | base | quote |
      | 22.75 | ETH | USDC |
    @case:932
    Examples:
      | amt | base | quote |
      | 22.75 | SOL | USDC |
    @case:933
    Examples:
      | amt | base | quote |
      | 22.75 | ETH | BTC |
    @case:934
    Examples:
      | amt | base | quote |
      | 22.75 | SOL | ETH |
    @case:935
    Examples:
      | amt | base | quote |
      | 22.75 | USDC | USD |
    @case:936
    Examples:
      | amt | base | quote |
      | 23.00 | BTC | USD |
    @case:937
    Examples:
      | amt | base | quote |
      | 23.00 | ETH | USD |
    @case:938
    Examples:
      | amt | base | quote |
      | 23.00 | SOL | USD |
    @case:939
    Examples:
      | amt | base | quote |
      | 23.00 | BTC | USDC |
    @case:940
    Examples:
      | amt | base | quote |
      | 23.00 | ETH | USDC |
    @case:941
    Examples:
      | amt | base | quote |
      | 23.00 | SOL | USDC |
    @case:942
    Examples:
      | amt | base | quote |
      | 23.00 | ETH | BTC |
    @case:943
    Examples:
      | amt | base | quote |
      | 23.00 | SOL | ETH |
    @case:944
    Examples:
      | amt | base | quote |
      | 23.00 | USDC | USD |
    @case:945
    Examples:
      | amt | base | quote |
      | 23.25 | BTC | USD |
    @case:946
    Examples:
      | amt | base | quote |
      | 23.25 | ETH | USD |
    @case:947
    Examples:
      | amt | base | quote |
      | 23.25 | SOL | USD |
    @case:948
    Examples:
      | amt | base | quote |
      | 23.25 | BTC | USDC |
    @case:949
    Examples:
      | amt | base | quote |
      | 23.25 | ETH | USDC |
    @case:950
    Examples:
      | amt | base | quote |
      | 23.25 | SOL | USDC |
    @case:951
    Examples:
      | amt | base | quote |
      | 23.25 | ETH | BTC |
    @case:952
    Examples:
      | amt | base | quote |
      | 23.25 | SOL | ETH |
    @case:953
    Examples:
      | amt | base | quote |
      | 23.25 | USDC | USD |
    @case:954
    Examples:
      | amt | base | quote |
      | 23.50 | BTC | USD |
    @case:955
    Examples:
      | amt | base | quote |
      | 23.50 | ETH | USD |
    @case:956
    Examples:
      | amt | base | quote |
      | 23.50 | SOL | USD |
    @case:957
    Examples:
      | amt | base | quote |
      | 23.50 | BTC | USDC |
    @case:958
    Examples:
      | amt | base | quote |
      | 23.50 | ETH | USDC |
    @case:959
    Examples:
      | amt | base | quote |
      | 23.50 | SOL | USDC |
    @case:960
    Examples:
      | amt | base | quote |
      | 23.50 | ETH | BTC |
    @case:961
    Examples:
      | amt | base | quote |
      | 23.50 | SOL | ETH |
    @case:962
    Examples:
      | amt | base | quote |
      | 23.50 | USDC | USD |
    @case:963
    Examples:
      | amt | base | quote |
      | 23.75 | BTC | USD |
    @case:964
    Examples:
      | amt | base | quote |
      | 23.75 | ETH | USD |
    @case:965
    Examples:
      | amt | base | quote |
      | 23.75 | SOL | USD |
    @case:966
    Examples:
      | amt | base | quote |
      | 23.75 | BTC | USDC |
    @case:967
    Examples:
      | amt | base | quote |
      | 23.75 | ETH | USDC |
    @case:968
    Examples:
      | amt | base | quote |
      | 23.75 | SOL | USDC |
    @case:969
    Examples:
      | amt | base | quote |
      | 23.75 | ETH | BTC |
    @case:970
    Examples:
      | amt | base | quote |
      | 23.75 | SOL | ETH |
    @case:971
    Examples:
      | amt | base | quote |
      | 23.75 | USDC | USD |
    @case:972
    Examples:
      | amt | base | quote |
      | 24.00 | BTC | USD |
    @case:973
    Examples:
      | amt | base | quote |
      | 24.00 | ETH | USD |
    @case:974
    Examples:
      | amt | base | quote |
      | 24.00 | SOL | USD |
    @case:975
    Examples:
      | amt | base | quote |
      | 24.00 | BTC | USDC |
    @case:976
    Examples:
      | amt | base | quote |
      | 24.00 | ETH | USDC |
    @case:977
    Examples:
      | amt | base | quote |
      | 24.00 | SOL | USDC |
    @case:978
    Examples:
      | amt | base | quote |
      | 24.00 | ETH | BTC |
    @case:979
    Examples:
      | amt | base | quote |
      | 24.00 | SOL | ETH |
    @case:980
    Examples:
      | amt | base | quote |
      | 24.00 | USDC | USD |
    @case:981
    Examples:
      | amt | base | quote |
      | 24.25 | BTC | USD |
    @case:982
    Examples:
      | amt | base | quote |
      | 24.25 | ETH | USD |
    @case:983
    Examples:
      | amt | base | quote |
      | 24.25 | SOL | USD |
    @case:984
    Examples:
      | amt | base | quote |
      | 24.25 | BTC | USDC |
    @case:985
    Examples:
      | amt | base | quote |
      | 24.25 | ETH | USDC |
    @case:986
    Examples:
      | amt | base | quote |
      | 24.25 | SOL | USDC |
    @case:987
    Examples:
      | amt | base | quote |
      | 24.25 | ETH | BTC |
    @case:988
    Examples:
      | amt | base | quote |
      | 24.25 | SOL | ETH |
    @case:989
    Examples:
      | amt | base | quote |
      | 24.25 | USDC | USD |
    @case:990
    Examples:
      | amt | base | quote |
      | 24.50 | BTC | USD |
    @case:991
    Examples:
      | amt | base | quote |
      | 24.50 | ETH | USD |
    @case:992
    Examples:
      | amt | base | quote |
      | 24.50 | SOL | USD |
    @case:993
    Examples:
      | amt | base | quote |
      | 24.50 | BTC | USDC |
    @case:994
    Examples:
      | amt | base | quote |
      | 24.50 | ETH | USDC |
    @case:995
    Examples:
      | amt | base | quote |
      | 24.50 | SOL | USDC |
    @case:996
    Examples:
      | amt | base | quote |
      | 24.50 | ETH | BTC |
    @case:997
    Examples:
      | amt | base | quote |
      | 24.50 | SOL | ETH |
    @case:998
    Examples:
      | amt | base | quote |
      | 24.50 | USDC | USD |
    @case:999
    Examples:
      | amt | base | quote |
      | 24.75 | BTC | USD |
    @case:1000
    Examples:
      | amt | base | quote |
      | 24.75 | ETH | USD |
