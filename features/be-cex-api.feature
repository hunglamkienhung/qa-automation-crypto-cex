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

  Scenario Outline: The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points
    When a quote of <amt> <base> to <quote> is requested
    Then the quote fee matches the pair fee in basis points

    @case:317
    Examples:
      | amt | base | quote |
      | 0.25 | BTC | USD |
    @case:318
    Examples:
      | amt | base | quote |
      | 0.25 | ETH | USD |
    @case:319
    Examples:
      | amt | base | quote |
      | 0.25 | SOL | USD |
    @case:320
    Examples:
      | amt | base | quote |
      | 0.25 | BTC | USDC |
    @case:321
    Examples:
      | amt | base | quote |
      | 0.25 | ETH | USDC |
    @case:322
    Examples:
      | amt | base | quote |
      | 0.25 | SOL | USDC |
    @case:323
    Examples:
      | amt | base | quote |
      | 0.25 | ETH | BTC |
    @case:324
    Examples:
      | amt | base | quote |
      | 0.25 | SOL | ETH |
    @case:325
    Examples:
      | amt | base | quote |
      | 0.25 | USDC | USD |
    @case:326
    Examples:
      | amt | base | quote |
      | 0.50 | BTC | USD |
    @case:327
    Examples:
      | amt | base | quote |
      | 0.50 | ETH | USD |
    @case:328
    Examples:
      | amt | base | quote |
      | 0.50 | SOL | USD |
    @case:329
    Examples:
      | amt | base | quote |
      | 0.50 | BTC | USDC |
    @case:330
    Examples:
      | amt | base | quote |
      | 0.50 | ETH | USDC |
    @case:331
    Examples:
      | amt | base | quote |
      | 0.50 | SOL | USDC |
    @case:332
    Examples:
      | amt | base | quote |
      | 0.50 | ETH | BTC |
    @case:333
    Examples:
      | amt | base | quote |
      | 0.50 | SOL | ETH |
    @case:334
    Examples:
      | amt | base | quote |
      | 0.50 | USDC | USD |
    @case:335
    Examples:
      | amt | base | quote |
      | 0.75 | BTC | USD |
    @case:336
    Examples:
      | amt | base | quote |
      | 0.75 | ETH | USD |
    @case:337
    Examples:
      | amt | base | quote |
      | 0.75 | SOL | USD |
    @case:338
    Examples:
      | amt | base | quote |
      | 0.75 | BTC | USDC |
    @case:339
    Examples:
      | amt | base | quote |
      | 0.75 | ETH | USDC |
    @case:340
    Examples:
      | amt | base | quote |
      | 0.75 | SOL | USDC |
    @case:341
    Examples:
      | amt | base | quote |
      | 0.75 | ETH | BTC |
    @case:342
    Examples:
      | amt | base | quote |
      | 0.75 | SOL | ETH |
    @case:343
    Examples:
      | amt | base | quote |
      | 0.75 | USDC | USD |
    @case:344
    Examples:
      | amt | base | quote |
      | 1.00 | BTC | USD |
    @case:345
    Examples:
      | amt | base | quote |
      | 1.00 | ETH | USD |
    @case:346
    Examples:
      | amt | base | quote |
      | 1.00 | SOL | USD |
    @case:347
    Examples:
      | amt | base | quote |
      | 1.00 | BTC | USDC |
    @case:348
    Examples:
      | amt | base | quote |
      | 1.00 | ETH | USDC |
    @case:349
    Examples:
      | amt | base | quote |
      | 1.00 | SOL | USDC |
    @case:350
    Examples:
      | amt | base | quote |
      | 1.00 | ETH | BTC |
    @case:351
    Examples:
      | amt | base | quote |
      | 1.00 | SOL | ETH |
    @case:352
    Examples:
      | amt | base | quote |
      | 1.00 | USDC | USD |
    @case:353
    Examples:
      | amt | base | quote |
      | 1.25 | BTC | USD |
    @case:354
    Examples:
      | amt | base | quote |
      | 1.25 | ETH | USD |
    @case:355
    Examples:
      | amt | base | quote |
      | 1.25 | SOL | USD |
    @case:356
    Examples:
      | amt | base | quote |
      | 1.25 | BTC | USDC |
    @case:357
    Examples:
      | amt | base | quote |
      | 1.25 | ETH | USDC |
    @case:358
    Examples:
      | amt | base | quote |
      | 1.25 | SOL | USDC |
    @case:359
    Examples:
      | amt | base | quote |
      | 1.25 | ETH | BTC |
    @case:360
    Examples:
      | amt | base | quote |
      | 1.25 | SOL | ETH |
    @case:361
    Examples:
      | amt | base | quote |
      | 1.25 | USDC | USD |
    @case:362
    Examples:
      | amt | base | quote |
      | 1.50 | BTC | USD |
    @case:363
    Examples:
      | amt | base | quote |
      | 1.50 | ETH | USD |
    @case:364
    Examples:
      | amt | base | quote |
      | 1.50 | SOL | USD |
    @case:365
    Examples:
      | amt | base | quote |
      | 1.50 | BTC | USDC |
    @case:366
    Examples:
      | amt | base | quote |
      | 1.50 | ETH | USDC |
    @case:367
    Examples:
      | amt | base | quote |
      | 1.50 | SOL | USDC |
    @case:368
    Examples:
      | amt | base | quote |
      | 1.50 | ETH | BTC |
    @case:369
    Examples:
      | amt | base | quote |
      | 1.50 | SOL | ETH |
    @case:370
    Examples:
      | amt | base | quote |
      | 1.50 | USDC | USD |
    @case:371
    Examples:
      | amt | base | quote |
      | 1.75 | BTC | USD |
    @case:372
    Examples:
      | amt | base | quote |
      | 1.75 | ETH | USD |
    @case:373
    Examples:
      | amt | base | quote |
      | 1.75 | SOL | USD |
    @case:374
    Examples:
      | amt | base | quote |
      | 1.75 | BTC | USDC |
    @case:375
    Examples:
      | amt | base | quote |
      | 1.75 | ETH | USDC |
    @case:376
    Examples:
      | amt | base | quote |
      | 1.75 | SOL | USDC |
    @case:377
    Examples:
      | amt | base | quote |
      | 1.75 | ETH | BTC |
    @case:378
    Examples:
      | amt | base | quote |
      | 1.75 | SOL | ETH |
    @case:379
    Examples:
      | amt | base | quote |
      | 1.75 | USDC | USD |
    @case:380
    Examples:
      | amt | base | quote |
      | 2.00 | BTC | USD |
    @case:381
    Examples:
      | amt | base | quote |
      | 2.00 | ETH | USD |
    @case:382
    Examples:
      | amt | base | quote |
      | 2.00 | SOL | USD |
    @case:383
    Examples:
      | amt | base | quote |
      | 2.00 | BTC | USDC |
    @case:384
    Examples:
      | amt | base | quote |
      | 2.00 | ETH | USDC |
    @case:385
    Examples:
      | amt | base | quote |
      | 2.00 | SOL | USDC |
    @case:386
    Examples:
      | amt | base | quote |
      | 2.00 | ETH | BTC |
    @case:387
    Examples:
      | amt | base | quote |
      | 2.00 | SOL | ETH |
    @case:388
    Examples:
      | amt | base | quote |
      | 2.00 | USDC | USD |
    @case:389
    Examples:
      | amt | base | quote |
      | 2.25 | BTC | USD |
    @case:390
    Examples:
      | amt | base | quote |
      | 2.25 | ETH | USD |
    @case:391
    Examples:
      | amt | base | quote |
      | 2.25 | SOL | USD |
    @case:392
    Examples:
      | amt | base | quote |
      | 2.25 | BTC | USDC |
    @case:393
    Examples:
      | amt | base | quote |
      | 2.25 | ETH | USDC |
    @case:394
    Examples:
      | amt | base | quote |
      | 2.25 | SOL | USDC |
    @case:395
    Examples:
      | amt | base | quote |
      | 2.25 | ETH | BTC |
    @case:396
    Examples:
      | amt | base | quote |
      | 2.25 | SOL | ETH |
    @case:397
    Examples:
      | amt | base | quote |
      | 2.25 | USDC | USD |
    @case:398
    Examples:
      | amt | base | quote |
      | 2.50 | BTC | USD |
    @case:399
    Examples:
      | amt | base | quote |
      | 2.50 | ETH | USD |
    @case:400
    Examples:
      | amt | base | quote |
      | 2.50 | SOL | USD |
    @case:401
    Examples:
      | amt | base | quote |
      | 2.50 | BTC | USDC |
    @case:402
    Examples:
      | amt | base | quote |
      | 2.50 | ETH | USDC |
    @case:403
    Examples:
      | amt | base | quote |
      | 2.50 | SOL | USDC |
    @case:404
    Examples:
      | amt | base | quote |
      | 2.50 | ETH | BTC |
    @case:405
    Examples:
      | amt | base | quote |
      | 2.50 | SOL | ETH |
    @case:406
    Examples:
      | amt | base | quote |
      | 2.50 | USDC | USD |
    @case:407
    Examples:
      | amt | base | quote |
      | 2.75 | BTC | USD |
    @case:408
    Examples:
      | amt | base | quote |
      | 2.75 | ETH | USD |
    @case:409
    Examples:
      | amt | base | quote |
      | 2.75 | SOL | USD |
    @case:410
    Examples:
      | amt | base | quote |
      | 2.75 | BTC | USDC |
    @case:411
    Examples:
      | amt | base | quote |
      | 2.75 | ETH | USDC |
    @case:412
    Examples:
      | amt | base | quote |
      | 2.75 | SOL | USDC |
    @case:413
    Examples:
      | amt | base | quote |
      | 2.75 | ETH | BTC |
    @case:414
    Examples:
      | amt | base | quote |
      | 2.75 | SOL | ETH |
    @case:415
    Examples:
      | amt | base | quote |
      | 2.75 | USDC | USD |
    @case:416
    Examples:
      | amt | base | quote |
      | 3.00 | BTC | USD |
    @case:417
    Examples:
      | amt | base | quote |
      | 3.00 | ETH | USD |
    @case:418
    Examples:
      | amt | base | quote |
      | 3.00 | SOL | USD |
    @case:419
    Examples:
      | amt | base | quote |
      | 3.00 | BTC | USDC |
    @case:420
    Examples:
      | amt | base | quote |
      | 3.00 | ETH | USDC |
    @case:421
    Examples:
      | amt | base | quote |
      | 3.00 | SOL | USDC |
    @case:422
    Examples:
      | amt | base | quote |
      | 3.00 | ETH | BTC |
    @case:423
    Examples:
      | amt | base | quote |
      | 3.00 | SOL | ETH |
    @case:424
    Examples:
      | amt | base | quote |
      | 3.00 | USDC | USD |
    @case:425
    Examples:
      | amt | base | quote |
      | 3.25 | BTC | USD |
    @case:426
    Examples:
      | amt | base | quote |
      | 3.25 | ETH | USD |
    @case:427
    Examples:
      | amt | base | quote |
      | 3.25 | SOL | USD |
    @case:428
    Examples:
      | amt | base | quote |
      | 3.25 | BTC | USDC |
    @case:429
    Examples:
      | amt | base | quote |
      | 3.25 | ETH | USDC |
    @case:430
    Examples:
      | amt | base | quote |
      | 3.25 | SOL | USDC |
    @case:431
    Examples:
      | amt | base | quote |
      | 3.25 | ETH | BTC |
    @case:432
    Examples:
      | amt | base | quote |
      | 3.25 | SOL | ETH |
    @case:433
    Examples:
      | amt | base | quote |
      | 3.25 | USDC | USD |
    @case:434
    Examples:
      | amt | base | quote |
      | 3.50 | BTC | USD |
    @case:435
    Examples:
      | amt | base | quote |
      | 3.50 | ETH | USD |
    @case:436
    Examples:
      | amt | base | quote |
      | 3.50 | SOL | USD |
    @case:437
    Examples:
      | amt | base | quote |
      | 3.50 | BTC | USDC |
    @case:438
    Examples:
      | amt | base | quote |
      | 3.50 | ETH | USDC |
    @case:439
    Examples:
      | amt | base | quote |
      | 3.50 | SOL | USDC |
    @case:440
    Examples:
      | amt | base | quote |
      | 3.50 | ETH | BTC |
    @case:441
    Examples:
      | amt | base | quote |
      | 3.50 | SOL | ETH |
    @case:442
    Examples:
      | amt | base | quote |
      | 3.50 | USDC | USD |
    @case:443
    Examples:
      | amt | base | quote |
      | 3.75 | BTC | USD |
    @case:444
    Examples:
      | amt | base | quote |
      | 3.75 | ETH | USD |
    @case:445
    Examples:
      | amt | base | quote |
      | 3.75 | SOL | USD |
    @case:446
    Examples:
      | amt | base | quote |
      | 3.75 | BTC | USDC |
    @case:447
    Examples:
      | amt | base | quote |
      | 3.75 | ETH | USDC |
    @case:448
    Examples:
      | amt | base | quote |
      | 3.75 | SOL | USDC |
    @case:449
    Examples:
      | amt | base | quote |
      | 3.75 | ETH | BTC |
    @case:450
    Examples:
      | amt | base | quote |
      | 3.75 | SOL | ETH |
    @case:451
    Examples:
      | amt | base | quote |
      | 3.75 | USDC | USD |
    @case:452
    Examples:
      | amt | base | quote |
      | 4.00 | BTC | USD |
    @case:453
    Examples:
      | amt | base | quote |
      | 4.00 | ETH | USD |
    @case:454
    Examples:
      | amt | base | quote |
      | 4.00 | SOL | USD |
    @case:455
    Examples:
      | amt | base | quote |
      | 4.00 | BTC | USDC |
    @case:456
    Examples:
      | amt | base | quote |
      | 4.00 | ETH | USDC |
    @case:457
    Examples:
      | amt | base | quote |
      | 4.00 | SOL | USDC |
    @case:458
    Examples:
      | amt | base | quote |
      | 4.00 | ETH | BTC |
    @case:459
    Examples:
      | amt | base | quote |
      | 4.00 | SOL | ETH |
    @case:460
    Examples:
      | amt | base | quote |
      | 4.00 | USDC | USD |
    @case:461
    Examples:
      | amt | base | quote |
      | 4.25 | BTC | USD |
    @case:462
    Examples:
      | amt | base | quote |
      | 4.25 | ETH | USD |
    @case:463
    Examples:
      | amt | base | quote |
      | 4.25 | SOL | USD |
    @case:464
    Examples:
      | amt | base | quote |
      | 4.25 | BTC | USDC |
    @case:465
    Examples:
      | amt | base | quote |
      | 4.25 | ETH | USDC |
    @case:466
    Examples:
      | amt | base | quote |
      | 4.25 | SOL | USDC |
    @case:467
    Examples:
      | amt | base | quote |
      | 4.25 | ETH | BTC |
    @case:468
    Examples:
      | amt | base | quote |
      | 4.25 | SOL | ETH |
    @case:469
    Examples:
      | amt | base | quote |
      | 4.25 | USDC | USD |
    @case:470
    Examples:
      | amt | base | quote |
      | 4.50 | BTC | USD |
    @case:471
    Examples:
      | amt | base | quote |
      | 4.50 | ETH | USD |
    @case:472
    Examples:
      | amt | base | quote |
      | 4.50 | SOL | USD |
    @case:473
    Examples:
      | amt | base | quote |
      | 4.50 | BTC | USDC |
    @case:474
    Examples:
      | amt | base | quote |
      | 4.50 | ETH | USDC |
    @case:475
    Examples:
      | amt | base | quote |
      | 4.50 | SOL | USDC |
    @case:476
    Examples:
      | amt | base | quote |
      | 4.50 | ETH | BTC |
    @case:477
    Examples:
      | amt | base | quote |
      | 4.50 | SOL | ETH |
    @case:478
    Examples:
      | amt | base | quote |
      | 4.50 | USDC | USD |
    @case:479
    Examples:
      | amt | base | quote |
      | 4.75 | BTC | USD |
    @case:480
    Examples:
      | amt | base | quote |
      | 4.75 | ETH | USD |
    @case:481
    Examples:
      | amt | base | quote |
      | 4.75 | SOL | USD |
    @case:482
    Examples:
      | amt | base | quote |
      | 4.75 | BTC | USDC |
    @case:483
    Examples:
      | amt | base | quote |
      | 4.75 | ETH | USDC |
    @case:484
    Examples:
      | amt | base | quote |
      | 4.75 | SOL | USDC |
    @case:485
    Examples:
      | amt | base | quote |
      | 4.75 | ETH | BTC |
    @case:486
    Examples:
      | amt | base | quote |
      | 4.75 | SOL | ETH |
    @case:487
    Examples:
      | amt | base | quote |
      | 4.75 | USDC | USD |
    @case:488
    Examples:
      | amt | base | quote |
      | 5.00 | BTC | USD |
    @case:489
    Examples:
      | amt | base | quote |
      | 5.00 | ETH | USD |
    @case:490
    Examples:
      | amt | base | quote |
      | 5.00 | SOL | USD |
    @case:491
    Examples:
      | amt | base | quote |
      | 5.00 | BTC | USDC |
    @case:492
    Examples:
      | amt | base | quote |
      | 5.00 | ETH | USDC |
    @case:493
    Examples:
      | amt | base | quote |
      | 5.00 | SOL | USDC |
    @case:494
    Examples:
      | amt | base | quote |
      | 5.00 | ETH | BTC |
    @case:495
    Examples:
      | amt | base | quote |
      | 5.00 | SOL | ETH |
    @case:496
    Examples:
      | amt | base | quote |
      | 5.00 | USDC | USD |

  Scenario Outline: A fresh account funded with <amt> <asset> shows that balance
    Given a fresh account "<who>" funded with <amt> <asset>
    Then the API balance for "<who>" in <asset> is <amt> <asset>

    @case:497
    Examples:
      | who | amt | asset |
      | pad1 | 0.25 | BTC |
    @case:498
    Examples:
      | who | amt | asset |
      | pad2 | 0.25 | ETH |
    @case:499
    Examples:
      | who | amt | asset |
      | pad3 | 0.25 | SOL |
    @case:500
    Examples:
      | who | amt | asset |
      | pad4 | 0.25 | USDC |
    @case:501
    Examples:
      | who | amt | asset |
      | pad5 | 0.50 | BTC |
    @case:502
    Examples:
      | who | amt | asset |
      | pad6 | 0.50 | ETH |
    @case:503
    Examples:
      | who | amt | asset |
      | pad7 | 0.50 | SOL |
    @case:504
    Examples:
      | who | amt | asset |
      | pad8 | 0.50 | USDC |
    @case:505
    Examples:
      | who | amt | asset |
      | pad9 | 0.75 | BTC |
    @case:506
    Examples:
      | who | amt | asset |
      | pad10 | 0.75 | ETH |
    @case:507
    Examples:
      | who | amt | asset |
      | pad11 | 0.75 | SOL |
    @case:508
    Examples:
      | who | amt | asset |
      | pad12 | 0.75 | USDC |
    @case:509
    Examples:
      | who | amt | asset |
      | pad13 | 1.00 | BTC |
    @case:510
    Examples:
      | who | amt | asset |
      | pad14 | 1.00 | ETH |
    @case:511
    Examples:
      | who | amt | asset |
      | pad15 | 1.00 | SOL |
    @case:512
    Examples:
      | who | amt | asset |
      | pad16 | 1.00 | USDC |
    @case:513
    Examples:
      | who | amt | asset |
      | pad17 | 1.25 | BTC |
    @case:514
    Examples:
      | who | amt | asset |
      | pad18 | 1.25 | ETH |
    @case:515
    Examples:
      | who | amt | asset |
      | pad19 | 1.25 | SOL |
    @case:516
    Examples:
      | who | amt | asset |
      | pad20 | 1.25 | USDC |
    @case:517
    Examples:
      | who | amt | asset |
      | pad21 | 1.50 | BTC |
    @case:518
    Examples:
      | who | amt | asset |
      | pad22 | 1.50 | ETH |
    @case:519
    Examples:
      | who | amt | asset |
      | pad23 | 1.50 | SOL |
    @case:520
    Examples:
      | who | amt | asset |
      | pad24 | 1.50 | USDC |
    @case:521
    Examples:
      | who | amt | asset |
      | pad25 | 1.75 | BTC |
    @case:522
    Examples:
      | who | amt | asset |
      | pad26 | 1.75 | ETH |
    @case:523
    Examples:
      | who | amt | asset |
      | pad27 | 1.75 | SOL |
    @case:524
    Examples:
      | who | amt | asset |
      | pad28 | 1.75 | USDC |
    @case:525
    Examples:
      | who | amt | asset |
      | pad29 | 2.00 | BTC |
    @case:526
    Examples:
      | who | amt | asset |
      | pad30 | 2.00 | ETH |
    @case:527
    Examples:
      | who | amt | asset |
      | pad31 | 2.00 | SOL |
    @case:528
    Examples:
      | who | amt | asset |
      | pad32 | 2.00 | USDC |
    @case:529
    Examples:
      | who | amt | asset |
      | pad33 | 2.25 | BTC |
    @case:530
    Examples:
      | who | amt | asset |
      | pad34 | 2.25 | ETH |
    @case:531
    Examples:
      | who | amt | asset |
      | pad35 | 2.25 | SOL |
    @case:532
    Examples:
      | who | amt | asset |
      | pad36 | 2.25 | USDC |
    @case:533
    Examples:
      | who | amt | asset |
      | pad37 | 2.50 | BTC |
    @case:534
    Examples:
      | who | amt | asset |
      | pad38 | 2.50 | ETH |
    @case:535
    Examples:
      | who | amt | asset |
      | pad39 | 2.50 | SOL |
    @case:536
    Examples:
      | who | amt | asset |
      | pad40 | 2.50 | USDC |
    @case:537
    Examples:
      | who | amt | asset |
      | pad41 | 2.75 | BTC |
    @case:538
    Examples:
      | who | amt | asset |
      | pad42 | 2.75 | ETH |
    @case:539
    Examples:
      | who | amt | asset |
      | pad43 | 2.75 | SOL |
    @case:540
    Examples:
      | who | amt | asset |
      | pad44 | 2.75 | USDC |
    @case:541
    Examples:
      | who | amt | asset |
      | pad45 | 3.00 | BTC |
    @case:542
    Examples:
      | who | amt | asset |
      | pad46 | 3.00 | ETH |
    @case:543
    Examples:
      | who | amt | asset |
      | pad47 | 3.00 | SOL |
    @case:544
    Examples:
      | who | amt | asset |
      | pad48 | 3.00 | USDC |
    @case:545
    Examples:
      | who | amt | asset |
      | pad49 | 3.25 | BTC |
    @case:546
    Examples:
      | who | amt | asset |
      | pad50 | 3.25 | ETH |
    @case:547
    Examples:
      | who | amt | asset |
      | pad51 | 3.25 | SOL |
    @case:548
    Examples:
      | who | amt | asset |
      | pad52 | 3.25 | USDC |
    @case:549
    Examples:
      | who | amt | asset |
      | pad53 | 3.50 | BTC |
    @case:550
    Examples:
      | who | amt | asset |
      | pad54 | 3.50 | ETH |
    @case:551
    Examples:
      | who | amt | asset |
      | pad55 | 3.50 | SOL |
    @case:552
    Examples:
      | who | amt | asset |
      | pad56 | 3.50 | USDC |
    @case:553
    Examples:
      | who | amt | asset |
      | pad57 | 3.75 | BTC |
    @case:554
    Examples:
      | who | amt | asset |
      | pad58 | 3.75 | ETH |
    @case:555
    Examples:
      | who | amt | asset |
      | pad59 | 3.75 | SOL |
    @case:556
    Examples:
      | who | amt | asset |
      | pad60 | 3.75 | USDC |
    @case:557
    Examples:
      | who | amt | asset |
      | pad61 | 4.00 | BTC |
    @case:558
    Examples:
      | who | amt | asset |
      | pad62 | 4.00 | ETH |
    @case:559
    Examples:
      | who | amt | asset |
      | pad63 | 4.00 | SOL |
    @case:560
    Examples:
      | who | amt | asset |
      | pad64 | 4.00 | USDC |
    @case:561
    Examples:
      | who | amt | asset |
      | pad65 | 4.25 | BTC |
    @case:562
    Examples:
      | who | amt | asset |
      | pad66 | 4.25 | ETH |
    @case:563
    Examples:
      | who | amt | asset |
      | pad67 | 4.25 | SOL |
    @case:564
    Examples:
      | who | amt | asset |
      | pad68 | 4.25 | USDC |
    @case:565
    Examples:
      | who | amt | asset |
      | pad69 | 4.50 | BTC |
    @case:566
    Examples:
      | who | amt | asset |
      | pad70 | 4.50 | ETH |
    @case:567
    Examples:
      | who | amt | asset |
      | pad71 | 4.50 | SOL |
    @case:568
    Examples:
      | who | amt | asset |
      | pad72 | 4.50 | USDC |
    @case:569
    Examples:
      | who | amt | asset |
      | pad73 | 4.75 | BTC |
    @case:570
    Examples:
      | who | amt | asset |
      | pad74 | 4.75 | ETH |
    @case:571
    Examples:
      | who | amt | asset |
      | pad75 | 4.75 | SOL |
    @case:572
    Examples:
      | who | amt | asset |
      | pad76 | 4.75 | USDC |
    @case:573
    Examples:
      | who | amt | asset |
      | pad77 | 5.00 | BTC |
    @case:574
    Examples:
      | who | amt | asset |
      | pad78 | 5.00 | ETH |
    @case:575
    Examples:
      | who | amt | asset |
      | pad79 | 5.00 | SOL |
    @case:576
    Examples:
      | who | amt | asset |
      | pad80 | 5.00 | USDC |
    @case:577
    Examples:
      | who | amt | asset |
      | pad81 | 5.25 | BTC |
    @case:578
    Examples:
      | who | amt | asset |
      | pad82 | 5.25 | ETH |
    @case:579
    Examples:
      | who | amt | asset |
      | pad83 | 5.25 | SOL |
    @case:580
    Examples:
      | who | amt | asset |
      | pad84 | 5.25 | USDC |
    @case:581
    Examples:
      | who | amt | asset |
      | pad85 | 5.50 | BTC |
    @case:582
    Examples:
      | who | amt | asset |
      | pad86 | 5.50 | ETH |
    @case:583
    Examples:
      | who | amt | asset |
      | pad87 | 5.50 | SOL |
    @case:584
    Examples:
      | who | amt | asset |
      | pad88 | 5.50 | USDC |
    @case:585
    Examples:
      | who | amt | asset |
      | pad89 | 5.75 | BTC |
    @case:586
    Examples:
      | who | amt | asset |
      | pad90 | 5.75 | ETH |
    @case:587
    Examples:
      | who | amt | asset |
      | pad91 | 5.75 | SOL |
    @case:588
    Examples:
      | who | amt | asset |
      | pad92 | 5.75 | USDC |
    @case:589
    Examples:
      | who | amt | asset |
      | pad93 | 6.00 | BTC |
    @case:590
    Examples:
      | who | amt | asset |
      | pad94 | 6.00 | ETH |
    @case:591
    Examples:
      | who | amt | asset |
      | pad95 | 6.00 | SOL |
    @case:592
    Examples:
      | who | amt | asset |
      | pad96 | 6.00 | USDC |
    @case:593
    Examples:
      | who | amt | asset |
      | pad97 | 6.25 | BTC |
    @case:594
    Examples:
      | who | amt | asset |
      | pad98 | 6.25 | ETH |
    @case:595
    Examples:
      | who | amt | asset |
      | pad99 | 6.25 | SOL |
    @case:596
    Examples:
      | who | amt | asset |
      | pad100 | 6.25 | USDC |
    @case:597
    Examples:
      | who | amt | asset |
      | pad101 | 6.50 | BTC |
    @case:598
    Examples:
      | who | amt | asset |
      | pad102 | 6.50 | ETH |
    @case:599
    Examples:
      | who | amt | asset |
      | pad103 | 6.50 | SOL |
    @case:600
    Examples:
      | who | amt | asset |
      | pad104 | 6.50 | USDC |
    @case:601
    Examples:
      | who | amt | asset |
      | pad105 | 6.75 | BTC |
    @case:602
    Examples:
      | who | amt | asset |
      | pad106 | 6.75 | ETH |
    @case:603
    Examples:
      | who | amt | asset |
      | pad107 | 6.75 | SOL |
    @case:604
    Examples:
      | who | amt | asset |
      | pad108 | 6.75 | USDC |
    @case:605
    Examples:
      | who | amt | asset |
      | pad109 | 7.00 | BTC |
    @case:606
    Examples:
      | who | amt | asset |
      | pad110 | 7.00 | ETH |
    @case:607
    Examples:
      | who | amt | asset |
      | pad111 | 7.00 | SOL |
    @case:608
    Examples:
      | who | amt | asset |
      | pad112 | 7.00 | USDC |
    @case:609
    Examples:
      | who | amt | asset |
      | pad113 | 7.25 | BTC |
    @case:610
    Examples:
      | who | amt | asset |
      | pad114 | 7.25 | ETH |
    @case:611
    Examples:
      | who | amt | asset |
      | pad115 | 7.25 | SOL |
    @case:612
    Examples:
      | who | amt | asset |
      | pad116 | 7.25 | USDC |
    @case:613
    Examples:
      | who | amt | asset |
      | pad117 | 7.50 | BTC |
    @case:614
    Examples:
      | who | amt | asset |
      | pad118 | 7.50 | ETH |
    @case:615
    Examples:
      | who | amt | asset |
      | pad119 | 7.50 | SOL |
    @case:616
    Examples:
      | who | amt | asset |
      | pad120 | 7.50 | USDC |
    @case:617
    Examples:
      | who | amt | asset |
      | pad121 | 7.75 | BTC |
    @case:618
    Examples:
      | who | amt | asset |
      | pad122 | 7.75 | ETH |
    @case:619
    Examples:
      | who | amt | asset |
      | pad123 | 7.75 | SOL |
    @case:620
    Examples:
      | who | amt | asset |
      | pad124 | 7.75 | USDC |
    @case:621
    Examples:
      | who | amt | asset |
      | pad125 | 8.00 | BTC |
    @case:622
    Examples:
      | who | amt | asset |
      | pad126 | 8.00 | ETH |
    @case:623
    Examples:
      | who | amt | asset |
      | pad127 | 8.00 | SOL |
    @case:624
    Examples:
      | who | amt | asset |
      | pad128 | 8.00 | USDC |
    @case:625
    Examples:
      | who | amt | asset |
      | pad129 | 8.25 | BTC |
    @case:626
    Examples:
      | who | amt | asset |
      | pad130 | 8.25 | ETH |
    @case:627
    Examples:
      | who | amt | asset |
      | pad131 | 8.25 | SOL |
    @case:628
    Examples:
      | who | amt | asset |
      | pad132 | 8.25 | USDC |
    @case:629
    Examples:
      | who | amt | asset |
      | pad133 | 8.50 | BTC |
    @case:630
    Examples:
      | who | amt | asset |
      | pad134 | 8.50 | ETH |
    @case:631
    Examples:
      | who | amt | asset |
      | pad135 | 8.50 | SOL |
    @case:632
    Examples:
      | who | amt | asset |
      | pad136 | 8.50 | USDC |
    @case:633
    Examples:
      | who | amt | asset |
      | pad137 | 8.75 | BTC |
    @case:634
    Examples:
      | who | amt | asset |
      | pad138 | 8.75 | ETH |
    @case:635
    Examples:
      | who | amt | asset |
      | pad139 | 8.75 | SOL |
    @case:636
    Examples:
      | who | amt | asset |
      | pad140 | 8.75 | USDC |
    @case:637
    Examples:
      | who | amt | asset |
      | pad141 | 9.00 | BTC |
    @case:638
    Examples:
      | who | amt | asset |
      | pad142 | 9.00 | ETH |
    @case:639
    Examples:
      | who | amt | asset |
      | pad143 | 9.00 | SOL |
    @case:640
    Examples:
      | who | amt | asset |
      | pad144 | 9.00 | USDC |
    @case:641
    Examples:
      | who | amt | asset |
      | pad145 | 9.25 | BTC |
    @case:642
    Examples:
      | who | amt | asset |
      | pad146 | 9.25 | ETH |
    @case:643
    Examples:
      | who | amt | asset |
      | pad147 | 9.25 | SOL |
    @case:644
    Examples:
      | who | amt | asset |
      | pad148 | 9.25 | USDC |
    @case:645
    Examples:
      | who | amt | asset |
      | pad149 | 9.50 | BTC |
    @case:646
    Examples:
      | who | amt | asset |
      | pad150 | 9.50 | ETH |
    @case:647
    Examples:
      | who | amt | asset |
      | pad151 | 9.50 | SOL |
    @case:648
    Examples:
      | who | amt | asset |
      | pad152 | 9.50 | USDC |
    @case:649
    Examples:
      | who | amt | asset |
      | pad153 | 9.75 | BTC |
    @case:650
    Examples:
      | who | amt | asset |
      | pad154 | 9.75 | ETH |
    @case:651
    Examples:
      | who | amt | asset |
      | pad155 | 9.75 | SOL |
    @case:652
    Examples:
      | who | amt | asset |
      | pad156 | 9.75 | USDC |
    @case:653
    Examples:
      | who | amt | asset |
      | pad157 | 10.00 | BTC |
    @case:654
    Examples:
      | who | amt | asset |
      | pad158 | 10.00 | ETH |
    @case:655
    Examples:
      | who | amt | asset |
      | pad159 | 10.00 | SOL |
    @case:656
    Examples:
      | who | amt | asset |
      | pad160 | 10.00 | USDC |
    @case:657
    Examples:
      | who | amt | asset |
      | pad161 | 10.25 | BTC |
    @case:658
    Examples:
      | who | amt | asset |
      | pad162 | 10.25 | ETH |
    @case:659
    Examples:
      | who | amt | asset |
      | pad163 | 10.25 | SOL |
    @case:660
    Examples:
      | who | amt | asset |
      | pad164 | 10.25 | USDC |
    @case:661
    Examples:
      | who | amt | asset |
      | pad165 | 10.50 | BTC |
    @case:662
    Examples:
      | who | amt | asset |
      | pad166 | 10.50 | ETH |
    @case:663
    Examples:
      | who | amt | asset |
      | pad167 | 10.50 | SOL |
    @case:664
    Examples:
      | who | amt | asset |
      | pad168 | 10.50 | USDC |
    @case:665
    Examples:
      | who | amt | asset |
      | pad169 | 10.75 | BTC |
    @case:666
    Examples:
      | who | amt | asset |
      | pad170 | 10.75 | ETH |
    @case:667
    Examples:
      | who | amt | asset |
      | pad171 | 10.75 | SOL |
    @case:668
    Examples:
      | who | amt | asset |
      | pad172 | 10.75 | USDC |
    @case:669
    Examples:
      | who | amt | asset |
      | pad173 | 11.00 | BTC |
    @case:670
    Examples:
      | who | amt | asset |
      | pad174 | 11.00 | ETH |
    @case:671
    Examples:
      | who | amt | asset |
      | pad175 | 11.00 | SOL |
    @case:672
    Examples:
      | who | amt | asset |
      | pad176 | 11.00 | USDC |
    @case:673
    Examples:
      | who | amt | asset |
      | pad177 | 11.25 | BTC |
    @case:674
    Examples:
      | who | amt | asset |
      | pad178 | 11.25 | ETH |
    @case:675
    Examples:
      | who | amt | asset |
      | pad179 | 11.25 | SOL |
    @case:676
    Examples:
      | who | amt | asset |
      | pad180 | 11.25 | USDC |

  Scenario Outline: A swap of <swap> <base> to <quote> outputs the quoted amount
    Given a fresh account "<who>" funded with 1000 <base>
    When "<who>" swaps <swap> <base> to <quote>
    Then the swap response output equals the quote for <swap> <base> to <quote>

    @case:677
    Examples:
      | who | base | swap | quote |
      | pad181 | BTC | 0.25 | USD |
    @case:678
    Examples:
      | who | base | swap | quote |
      | pad182 | ETH | 0.25 | USD |
    @case:679
    Examples:
      | who | base | swap | quote |
      | pad183 | SOL | 0.25 | USD |
    @case:680
    Examples:
      | who | base | swap | quote |
      | pad184 | BTC | 0.25 | USDC |
    @case:681
    Examples:
      | who | base | swap | quote |
      | pad185 | ETH | 0.25 | USDC |
    @case:682
    Examples:
      | who | base | swap | quote |
      | pad186 | SOL | 0.25 | USDC |
    @case:683
    Examples:
      | who | base | swap | quote |
      | pad187 | ETH | 0.25 | BTC |
    @case:684
    Examples:
      | who | base | swap | quote |
      | pad188 | SOL | 0.25 | ETH |
    @case:685
    Examples:
      | who | base | swap | quote |
      | pad189 | USDC | 0.25 | USD |
    @case:686
    Examples:
      | who | base | swap | quote |
      | pad190 | BTC | 0.50 | USD |
    @case:687
    Examples:
      | who | base | swap | quote |
      | pad191 | ETH | 0.50 | USD |
    @case:688
    Examples:
      | who | base | swap | quote |
      | pad192 | SOL | 0.50 | USD |
    @case:689
    Examples:
      | who | base | swap | quote |
      | pad193 | BTC | 0.50 | USDC |
    @case:690
    Examples:
      | who | base | swap | quote |
      | pad194 | ETH | 0.50 | USDC |
    @case:691
    Examples:
      | who | base | swap | quote |
      | pad195 | SOL | 0.50 | USDC |
    @case:692
    Examples:
      | who | base | swap | quote |
      | pad196 | ETH | 0.50 | BTC |
    @case:693
    Examples:
      | who | base | swap | quote |
      | pad197 | SOL | 0.50 | ETH |
    @case:694
    Examples:
      | who | base | swap | quote |
      | pad198 | USDC | 0.50 | USD |
    @case:695
    Examples:
      | who | base | swap | quote |
      | pad199 | BTC | 0.75 | USD |
    @case:696
    Examples:
      | who | base | swap | quote |
      | pad200 | ETH | 0.75 | USD |
    @case:697
    Examples:
      | who | base | swap | quote |
      | pad201 | SOL | 0.75 | USD |
    @case:698
    Examples:
      | who | base | swap | quote |
      | pad202 | BTC | 0.75 | USDC |
    @case:699
    Examples:
      | who | base | swap | quote |
      | pad203 | ETH | 0.75 | USDC |
    @case:700
    Examples:
      | who | base | swap | quote |
      | pad204 | SOL | 0.75 | USDC |
    @case:701
    Examples:
      | who | base | swap | quote |
      | pad205 | ETH | 0.75 | BTC |
    @case:702
    Examples:
      | who | base | swap | quote |
      | pad206 | SOL | 0.75 | ETH |
    @case:703
    Examples:
      | who | base | swap | quote |
      | pad207 | USDC | 0.75 | USD |
    @case:704
    Examples:
      | who | base | swap | quote |
      | pad208 | BTC | 1.00 | USD |
    @case:705
    Examples:
      | who | base | swap | quote |
      | pad209 | ETH | 1.00 | USD |
    @case:706
    Examples:
      | who | base | swap | quote |
      | pad210 | SOL | 1.00 | USD |
    @case:707
    Examples:
      | who | base | swap | quote |
      | pad211 | BTC | 1.00 | USDC |
    @case:708
    Examples:
      | who | base | swap | quote |
      | pad212 | ETH | 1.00 | USDC |
    @case:709
    Examples:
      | who | base | swap | quote |
      | pad213 | SOL | 1.00 | USDC |
    @case:710
    Examples:
      | who | base | swap | quote |
      | pad214 | ETH | 1.00 | BTC |
    @case:711
    Examples:
      | who | base | swap | quote |
      | pad215 | SOL | 1.00 | ETH |
    @case:712
    Examples:
      | who | base | swap | quote |
      | pad216 | USDC | 1.00 | USD |
    @case:713
    Examples:
      | who | base | swap | quote |
      | pad217 | BTC | 1.25 | USD |
    @case:714
    Examples:
      | who | base | swap | quote |
      | pad218 | ETH | 1.25 | USD |
    @case:715
    Examples:
      | who | base | swap | quote |
      | pad219 | SOL | 1.25 | USD |
    @case:716
    Examples:
      | who | base | swap | quote |
      | pad220 | BTC | 1.25 | USDC |
    @case:717
    Examples:
      | who | base | swap | quote |
      | pad221 | ETH | 1.25 | USDC |
    @case:718
    Examples:
      | who | base | swap | quote |
      | pad222 | SOL | 1.25 | USDC |
    @case:719
    Examples:
      | who | base | swap | quote |
      | pad223 | ETH | 1.25 | BTC |
    @case:720
    Examples:
      | who | base | swap | quote |
      | pad224 | SOL | 1.25 | ETH |
    @case:721
    Examples:
      | who | base | swap | quote |
      | pad225 | USDC | 1.25 | USD |
    @case:722
    Examples:
      | who | base | swap | quote |
      | pad226 | BTC | 1.50 | USD |
    @case:723
    Examples:
      | who | base | swap | quote |
      | pad227 | ETH | 1.50 | USD |
    @case:724
    Examples:
      | who | base | swap | quote |
      | pad228 | SOL | 1.50 | USD |
    @case:725
    Examples:
      | who | base | swap | quote |
      | pad229 | BTC | 1.50 | USDC |
    @case:726
    Examples:
      | who | base | swap | quote |
      | pad230 | ETH | 1.50 | USDC |
    @case:727
    Examples:
      | who | base | swap | quote |
      | pad231 | SOL | 1.50 | USDC |
    @case:728
    Examples:
      | who | base | swap | quote |
      | pad232 | ETH | 1.50 | BTC |
    @case:729
    Examples:
      | who | base | swap | quote |
      | pad233 | SOL | 1.50 | ETH |
    @case:730
    Examples:
      | who | base | swap | quote |
      | pad234 | USDC | 1.50 | USD |
    @case:731
    Examples:
      | who | base | swap | quote |
      | pad235 | BTC | 1.75 | USD |
    @case:732
    Examples:
      | who | base | swap | quote |
      | pad236 | ETH | 1.75 | USD |
    @case:733
    Examples:
      | who | base | swap | quote |
      | pad237 | SOL | 1.75 | USD |
    @case:734
    Examples:
      | who | base | swap | quote |
      | pad238 | BTC | 1.75 | USDC |
    @case:735
    Examples:
      | who | base | swap | quote |
      | pad239 | ETH | 1.75 | USDC |
    @case:736
    Examples:
      | who | base | swap | quote |
      | pad240 | SOL | 1.75 | USDC |
    @case:737
    Examples:
      | who | base | swap | quote |
      | pad241 | ETH | 1.75 | BTC |
    @case:738
    Examples:
      | who | base | swap | quote |
      | pad242 | SOL | 1.75 | ETH |
    @case:739
    Examples:
      | who | base | swap | quote |
      | pad243 | USDC | 1.75 | USD |
    @case:740
    Examples:
      | who | base | swap | quote |
      | pad244 | BTC | 2.00 | USD |
    @case:741
    Examples:
      | who | base | swap | quote |
      | pad245 | ETH | 2.00 | USD |
    @case:742
    Examples:
      | who | base | swap | quote |
      | pad246 | SOL | 2.00 | USD |
    @case:743
    Examples:
      | who | base | swap | quote |
      | pad247 | BTC | 2.00 | USDC |
    @case:744
    Examples:
      | who | base | swap | quote |
      | pad248 | ETH | 2.00 | USDC |
    @case:745
    Examples:
      | who | base | swap | quote |
      | pad249 | SOL | 2.00 | USDC |
    @case:746
    Examples:
      | who | base | swap | quote |
      | pad250 | ETH | 2.00 | BTC |
    @case:747
    Examples:
      | who | base | swap | quote |
      | pad251 | SOL | 2.00 | ETH |
    @case:748
    Examples:
      | who | base | swap | quote |
      | pad252 | USDC | 2.00 | USD |
    @case:749
    Examples:
      | who | base | swap | quote |
      | pad253 | BTC | 2.25 | USD |
    @case:750
    Examples:
      | who | base | swap | quote |
      | pad254 | ETH | 2.25 | USD |
    @case:751
    Examples:
      | who | base | swap | quote |
      | pad255 | SOL | 2.25 | USD |
    @case:752
    Examples:
      | who | base | swap | quote |
      | pad256 | BTC | 2.25 | USDC |
    @case:753
    Examples:
      | who | base | swap | quote |
      | pad257 | ETH | 2.25 | USDC |
    @case:754
    Examples:
      | who | base | swap | quote |
      | pad258 | SOL | 2.25 | USDC |
    @case:755
    Examples:
      | who | base | swap | quote |
      | pad259 | ETH | 2.25 | BTC |
    @case:756
    Examples:
      | who | base | swap | quote |
      | pad260 | SOL | 2.25 | ETH |
    @case:757
    Examples:
      | who | base | swap | quote |
      | pad261 | USDC | 2.25 | USD |
    @case:758
    Examples:
      | who | base | swap | quote |
      | pad262 | BTC | 2.50 | USD |
    @case:759
    Examples:
      | who | base | swap | quote |
      | pad263 | ETH | 2.50 | USD |
    @case:760
    Examples:
      | who | base | swap | quote |
      | pad264 | SOL | 2.50 | USD |
    @case:761
    Examples:
      | who | base | swap | quote |
      | pad265 | BTC | 2.50 | USDC |
    @case:762
    Examples:
      | who | base | swap | quote |
      | pad266 | ETH | 2.50 | USDC |
    @case:763
    Examples:
      | who | base | swap | quote |
      | pad267 | SOL | 2.50 | USDC |
    @case:764
    Examples:
      | who | base | swap | quote |
      | pad268 | ETH | 2.50 | BTC |
    @case:765
    Examples:
      | who | base | swap | quote |
      | pad269 | SOL | 2.50 | ETH |
    @case:766
    Examples:
      | who | base | swap | quote |
      | pad270 | USDC | 2.50 | USD |
    @case:767
    Examples:
      | who | base | swap | quote |
      | pad271 | BTC | 2.75 | USD |
    @case:768
    Examples:
      | who | base | swap | quote |
      | pad272 | ETH | 2.75 | USD |
    @case:769
    Examples:
      | who | base | swap | quote |
      | pad273 | SOL | 2.75 | USD |
    @case:770
    Examples:
      | who | base | swap | quote |
      | pad274 | BTC | 2.75 | USDC |
    @case:771
    Examples:
      | who | base | swap | quote |
      | pad275 | ETH | 2.75 | USDC |
    @case:772
    Examples:
      | who | base | swap | quote |
      | pad276 | SOL | 2.75 | USDC |
    @case:773
    Examples:
      | who | base | swap | quote |
      | pad277 | ETH | 2.75 | BTC |
    @case:774
    Examples:
      | who | base | swap | quote |
      | pad278 | SOL | 2.75 | ETH |
    @case:775
    Examples:
      | who | base | swap | quote |
      | pad279 | USDC | 2.75 | USD |
    @case:776
    Examples:
      | who | base | swap | quote |
      | pad280 | BTC | 3.00 | USD |
    @case:777
    Examples:
      | who | base | swap | quote |
      | pad281 | ETH | 3.00 | USD |
    @case:778
    Examples:
      | who | base | swap | quote |
      | pad282 | SOL | 3.00 | USD |
    @case:779
    Examples:
      | who | base | swap | quote |
      | pad283 | BTC | 3.00 | USDC |
    @case:780
    Examples:
      | who | base | swap | quote |
      | pad284 | ETH | 3.00 | USDC |
    @case:781
    Examples:
      | who | base | swap | quote |
      | pad285 | SOL | 3.00 | USDC |
    @case:782
    Examples:
      | who | base | swap | quote |
      | pad286 | ETH | 3.00 | BTC |
    @case:783
    Examples:
      | who | base | swap | quote |
      | pad287 | SOL | 3.00 | ETH |
    @case:784
    Examples:
      | who | base | swap | quote |
      | pad288 | USDC | 3.00 | USD |
    @case:785
    Examples:
      | who | base | swap | quote |
      | pad289 | BTC | 3.25 | USD |
    @case:786
    Examples:
      | who | base | swap | quote |
      | pad290 | ETH | 3.25 | USD |
    @case:787
    Examples:
      | who | base | swap | quote |
      | pad291 | SOL | 3.25 | USD |
    @case:788
    Examples:
      | who | base | swap | quote |
      | pad292 | BTC | 3.25 | USDC |
    @case:789
    Examples:
      | who | base | swap | quote |
      | pad293 | ETH | 3.25 | USDC |
    @case:790
    Examples:
      | who | base | swap | quote |
      | pad294 | SOL | 3.25 | USDC |
    @case:791
    Examples:
      | who | base | swap | quote |
      | pad295 | ETH | 3.25 | BTC |
    @case:792
    Examples:
      | who | base | swap | quote |
      | pad296 | SOL | 3.25 | ETH |
    @case:793
    Examples:
      | who | base | swap | quote |
      | pad297 | USDC | 3.25 | USD |
    @case:794
    Examples:
      | who | base | swap | quote |
      | pad298 | BTC | 3.50 | USD |
    @case:795
    Examples:
      | who | base | swap | quote |
      | pad299 | ETH | 3.50 | USD |
    @case:796
    Examples:
      | who | base | swap | quote |
      | pad300 | SOL | 3.50 | USD |
    @case:797
    Examples:
      | who | base | swap | quote |
      | pad301 | BTC | 3.50 | USDC |
    @case:798
    Examples:
      | who | base | swap | quote |
      | pad302 | ETH | 3.50 | USDC |
    @case:799
    Examples:
      | who | base | swap | quote |
      | pad303 | SOL | 3.50 | USDC |
    @case:800
    Examples:
      | who | base | swap | quote |
      | pad304 | ETH | 3.50 | BTC |
    @case:801
    Examples:
      | who | base | swap | quote |
      | pad305 | SOL | 3.50 | ETH |
    @case:802
    Examples:
      | who | base | swap | quote |
      | pad306 | USDC | 3.50 | USD |
    @case:803
    Examples:
      | who | base | swap | quote |
      | pad307 | BTC | 3.75 | USD |
    @case:804
    Examples:
      | who | base | swap | quote |
      | pad308 | ETH | 3.75 | USD |
    @case:805
    Examples:
      | who | base | swap | quote |
      | pad309 | SOL | 3.75 | USD |
    @case:806
    Examples:
      | who | base | swap | quote |
      | pad310 | BTC | 3.75 | USDC |
    @case:807
    Examples:
      | who | base | swap | quote |
      | pad311 | ETH | 3.75 | USDC |
    @case:808
    Examples:
      | who | base | swap | quote |
      | pad312 | SOL | 3.75 | USDC |
    @case:809
    Examples:
      | who | base | swap | quote |
      | pad313 | ETH | 3.75 | BTC |
    @case:810
    Examples:
      | who | base | swap | quote |
      | pad314 | SOL | 3.75 | ETH |
    @case:811
    Examples:
      | who | base | swap | quote |
      | pad315 | USDC | 3.75 | USD |
    @case:812
    Examples:
      | who | base | swap | quote |
      | pad316 | BTC | 4.00 | USD |
    @case:813
    Examples:
      | who | base | swap | quote |
      | pad317 | ETH | 4.00 | USD |
    @case:814
    Examples:
      | who | base | swap | quote |
      | pad318 | SOL | 4.00 | USD |
    @case:815
    Examples:
      | who | base | swap | quote |
      | pad319 | BTC | 4.00 | USDC |
    @case:816
    Examples:
      | who | base | swap | quote |
      | pad320 | ETH | 4.00 | USDC |
    @case:817
    Examples:
      | who | base | swap | quote |
      | pad321 | SOL | 4.00 | USDC |
    @case:818
    Examples:
      | who | base | swap | quote |
      | pad322 | ETH | 4.00 | BTC |
    @case:819
    Examples:
      | who | base | swap | quote |
      | pad323 | SOL | 4.00 | ETH |
    @case:820
    Examples:
      | who | base | swap | quote |
      | pad324 | USDC | 4.00 | USD |
    @case:821
    Examples:
      | who | base | swap | quote |
      | pad325 | BTC | 4.25 | USD |
    @case:822
    Examples:
      | who | base | swap | quote |
      | pad326 | ETH | 4.25 | USD |
    @case:823
    Examples:
      | who | base | swap | quote |
      | pad327 | SOL | 4.25 | USD |
    @case:824
    Examples:
      | who | base | swap | quote |
      | pad328 | BTC | 4.25 | USDC |
    @case:825
    Examples:
      | who | base | swap | quote |
      | pad329 | ETH | 4.25 | USDC |
    @case:826
    Examples:
      | who | base | swap | quote |
      | pad330 | SOL | 4.25 | USDC |
    @case:827
    Examples:
      | who | base | swap | quote |
      | pad331 | ETH | 4.25 | BTC |
    @case:828
    Examples:
      | who | base | swap | quote |
      | pad332 | SOL | 4.25 | ETH |
    @case:829
    Examples:
      | who | base | swap | quote |
      | pad333 | USDC | 4.25 | USD |
    @case:830
    Examples:
      | who | base | swap | quote |
      | pad334 | BTC | 4.50 | USD |
    @case:831
    Examples:
      | who | base | swap | quote |
      | pad335 | ETH | 4.50 | USD |
    @case:832
    Examples:
      | who | base | swap | quote |
      | pad336 | SOL | 4.50 | USD |
    @case:833
    Examples:
      | who | base | swap | quote |
      | pad337 | BTC | 4.50 | USDC |
    @case:834
    Examples:
      | who | base | swap | quote |
      | pad338 | ETH | 4.50 | USDC |
    @case:835
    Examples:
      | who | base | swap | quote |
      | pad339 | SOL | 4.50 | USDC |
    @case:836
    Examples:
      | who | base | swap | quote |
      | pad340 | ETH | 4.50 | BTC |

  Scenario Outline: A transfer of <amt> <asset> reaches the recipient
    Given a fresh account "<from>" funded with 1000 <asset>
    And a fresh account "<to>"
    When "<from>" transfers <amt> <asset> to "<to>"
    Then the API balance for "<to>" in <asset> is <amt> <asset>

    @case:837
    Examples:
      | from | to | amt | asset |
      | pad341 | pad342 | 0.25 | BTC |
    @case:838
    Examples:
      | from | to | amt | asset |
      | pad343 | pad344 | 0.25 | ETH |
    @case:839
    Examples:
      | from | to | amt | asset |
      | pad345 | pad346 | 0.25 | SOL |
    @case:840
    Examples:
      | from | to | amt | asset |
      | pad347 | pad348 | 0.25 | USDC |
    @case:841
    Examples:
      | from | to | amt | asset |
      | pad349 | pad350 | 0.50 | BTC |
    @case:842
    Examples:
      | from | to | amt | asset |
      | pad351 | pad352 | 0.50 | ETH |
    @case:843
    Examples:
      | from | to | amt | asset |
      | pad353 | pad354 | 0.50 | SOL |
    @case:844
    Examples:
      | from | to | amt | asset |
      | pad355 | pad356 | 0.50 | USDC |
    @case:845
    Examples:
      | from | to | amt | asset |
      | pad357 | pad358 | 0.75 | BTC |
    @case:846
    Examples:
      | from | to | amt | asset |
      | pad359 | pad360 | 0.75 | ETH |
    @case:847
    Examples:
      | from | to | amt | asset |
      | pad361 | pad362 | 0.75 | SOL |
    @case:848
    Examples:
      | from | to | amt | asset |
      | pad363 | pad364 | 0.75 | USDC |
    @case:849
    Examples:
      | from | to | amt | asset |
      | pad365 | pad366 | 1.00 | BTC |
    @case:850
    Examples:
      | from | to | amt | asset |
      | pad367 | pad368 | 1.00 | ETH |
    @case:851
    Examples:
      | from | to | amt | asset |
      | pad369 | pad370 | 1.00 | SOL |
    @case:852
    Examples:
      | from | to | amt | asset |
      | pad371 | pad372 | 1.00 | USDC |
    @case:853
    Examples:
      | from | to | amt | asset |
      | pad373 | pad374 | 1.25 | BTC |
    @case:854
    Examples:
      | from | to | amt | asset |
      | pad375 | pad376 | 1.25 | ETH |
    @case:855
    Examples:
      | from | to | amt | asset |
      | pad377 | pad378 | 1.25 | SOL |
    @case:856
    Examples:
      | from | to | amt | asset |
      | pad379 | pad380 | 1.25 | USDC |
    @case:857
    Examples:
      | from | to | amt | asset |
      | pad381 | pad382 | 1.50 | BTC |
    @case:858
    Examples:
      | from | to | amt | asset |
      | pad383 | pad384 | 1.50 | ETH |
    @case:859
    Examples:
      | from | to | amt | asset |
      | pad385 | pad386 | 1.50 | SOL |
    @case:860
    Examples:
      | from | to | amt | asset |
      | pad387 | pad388 | 1.50 | USDC |
    @case:861
    Examples:
      | from | to | amt | asset |
      | pad389 | pad390 | 1.75 | BTC |
    @case:862
    Examples:
      | from | to | amt | asset |
      | pad391 | pad392 | 1.75 | ETH |
    @case:863
    Examples:
      | from | to | amt | asset |
      | pad393 | pad394 | 1.75 | SOL |
    @case:864
    Examples:
      | from | to | amt | asset |
      | pad395 | pad396 | 1.75 | USDC |
    @case:865
    Examples:
      | from | to | amt | asset |
      | pad397 | pad398 | 2.00 | BTC |
    @case:866
    Examples:
      | from | to | amt | asset |
      | pad399 | pad400 | 2.00 | ETH |
    @case:867
    Examples:
      | from | to | amt | asset |
      | pad401 | pad402 | 2.00 | SOL |
    @case:868
    Examples:
      | from | to | amt | asset |
      | pad403 | pad404 | 2.00 | USDC |
    @case:869
    Examples:
      | from | to | amt | asset |
      | pad405 | pad406 | 2.25 | BTC |
    @case:870
    Examples:
      | from | to | amt | asset |
      | pad407 | pad408 | 2.25 | ETH |
    @case:871
    Examples:
      | from | to | amt | asset |
      | pad409 | pad410 | 2.25 | SOL |
    @case:872
    Examples:
      | from | to | amt | asset |
      | pad411 | pad412 | 2.25 | USDC |
    @case:873
    Examples:
      | from | to | amt | asset |
      | pad413 | pad414 | 2.50 | BTC |
    @case:874
    Examples:
      | from | to | amt | asset |
      | pad415 | pad416 | 2.50 | ETH |
    @case:875
    Examples:
      | from | to | amt | asset |
      | pad417 | pad418 | 2.50 | SOL |
    @case:876
    Examples:
      | from | to | amt | asset |
      | pad419 | pad420 | 2.50 | USDC |
    @case:877
    Examples:
      | from | to | amt | asset |
      | pad421 | pad422 | 2.75 | BTC |
    @case:878
    Examples:
      | from | to | amt | asset |
      | pad423 | pad424 | 2.75 | ETH |
    @case:879
    Examples:
      | from | to | amt | asset |
      | pad425 | pad426 | 2.75 | SOL |
    @case:880
    Examples:
      | from | to | amt | asset |
      | pad427 | pad428 | 2.75 | USDC |
    @case:881
    Examples:
      | from | to | amt | asset |
      | pad429 | pad430 | 3.00 | BTC |
    @case:882
    Examples:
      | from | to | amt | asset |
      | pad431 | pad432 | 3.00 | ETH |
    @case:883
    Examples:
      | from | to | amt | asset |
      | pad433 | pad434 | 3.00 | SOL |
    @case:884
    Examples:
      | from | to | amt | asset |
      | pad435 | pad436 | 3.00 | USDC |
    @case:885
    Examples:
      | from | to | amt | asset |
      | pad437 | pad438 | 3.25 | BTC |
    @case:886
    Examples:
      | from | to | amt | asset |
      | pad439 | pad440 | 3.25 | ETH |
    @case:887
    Examples:
      | from | to | amt | asset |
      | pad441 | pad442 | 3.25 | SOL |
    @case:888
    Examples:
      | from | to | amt | asset |
      | pad443 | pad444 | 3.25 | USDC |
    @case:889
    Examples:
      | from | to | amt | asset |
      | pad445 | pad446 | 3.50 | BTC |
    @case:890
    Examples:
      | from | to | amt | asset |
      | pad447 | pad448 | 3.50 | ETH |
    @case:891
    Examples:
      | from | to | amt | asset |
      | pad449 | pad450 | 3.50 | SOL |
    @case:892
    Examples:
      | from | to | amt | asset |
      | pad451 | pad452 | 3.50 | USDC |
    @case:893
    Examples:
      | from | to | amt | asset |
      | pad453 | pad454 | 3.75 | BTC |
    @case:894
    Examples:
      | from | to | amt | asset |
      | pad455 | pad456 | 3.75 | ETH |
    @case:895
    Examples:
      | from | to | amt | asset |
      | pad457 | pad458 | 3.75 | SOL |
    @case:896
    Examples:
      | from | to | amt | asset |
      | pad459 | pad460 | 3.75 | USDC |
    @case:897
    Examples:
      | from | to | amt | asset |
      | pad461 | pad462 | 4.00 | BTC |
    @case:898
    Examples:
      | from | to | amt | asset |
      | pad463 | pad464 | 4.00 | ETH |
    @case:899
    Examples:
      | from | to | amt | asset |
      | pad465 | pad466 | 4.00 | SOL |
    @case:900
    Examples:
      | from | to | amt | asset |
      | pad467 | pad468 | 4.00 | USDC |
    @case:901
    Examples:
      | from | to | amt | asset |
      | pad469 | pad470 | 4.25 | BTC |
    @case:902
    Examples:
      | from | to | amt | asset |
      | pad471 | pad472 | 4.25 | ETH |
    @case:903
    Examples:
      | from | to | amt | asset |
      | pad473 | pad474 | 4.25 | SOL |
    @case:904
    Examples:
      | from | to | amt | asset |
      | pad475 | pad476 | 4.25 | USDC |
    @case:905
    Examples:
      | from | to | amt | asset |
      | pad477 | pad478 | 4.50 | BTC |
    @case:906
    Examples:
      | from | to | amt | asset |
      | pad479 | pad480 | 4.50 | ETH |
    @case:907
    Examples:
      | from | to | amt | asset |
      | pad481 | pad482 | 4.50 | SOL |
    @case:908
    Examples:
      | from | to | amt | asset |
      | pad483 | pad484 | 4.50 | USDC |
    @case:909
    Examples:
      | from | to | amt | asset |
      | pad485 | pad486 | 4.75 | BTC |
    @case:910
    Examples:
      | from | to | amt | asset |
      | pad487 | pad488 | 4.75 | ETH |
    @case:911
    Examples:
      | from | to | amt | asset |
      | pad489 | pad490 | 4.75 | SOL |
    @case:912
    Examples:
      | from | to | amt | asset |
      | pad491 | pad492 | 4.75 | USDC |
    @case:913
    Examples:
      | from | to | amt | asset |
      | pad493 | pad494 | 5.00 | BTC |
    @case:914
    Examples:
      | from | to | amt | asset |
      | pad495 | pad496 | 5.00 | ETH |
    @case:915
    Examples:
      | from | to | amt | asset |
      | pad497 | pad498 | 5.00 | SOL |
    @case:916
    Examples:
      | from | to | amt | asset |
      | pad499 | pad500 | 5.00 | USDC |
    @case:917
    Examples:
      | from | to | amt | asset |
      | pad501 | pad502 | 5.25 | BTC |
    @case:918
    Examples:
      | from | to | amt | asset |
      | pad503 | pad504 | 5.25 | ETH |
    @case:919
    Examples:
      | from | to | amt | asset |
      | pad505 | pad506 | 5.25 | SOL |
    @case:920
    Examples:
      | from | to | amt | asset |
      | pad507 | pad508 | 5.25 | USDC |
    @case:921
    Examples:
      | from | to | amt | asset |
      | pad509 | pad510 | 5.50 | BTC |
    @case:922
    Examples:
      | from | to | amt | asset |
      | pad511 | pad512 | 5.50 | ETH |
    @case:923
    Examples:
      | from | to | amt | asset |
      | pad513 | pad514 | 5.50 | SOL |
    @case:924
    Examples:
      | from | to | amt | asset |
      | pad515 | pad516 | 5.50 | USDC |
    @case:925
    Examples:
      | from | to | amt | asset |
      | pad517 | pad518 | 5.75 | BTC |
    @case:926
    Examples:
      | from | to | amt | asset |
      | pad519 | pad520 | 5.75 | ETH |
    @case:927
    Examples:
      | from | to | amt | asset |
      | pad521 | pad522 | 5.75 | SOL |
    @case:928
    Examples:
      | from | to | amt | asset |
      | pad523 | pad524 | 5.75 | USDC |
    @case:929
    Examples:
      | from | to | amt | asset |
      | pad525 | pad526 | 6.00 | BTC |
    @case:930
    Examples:
      | from | to | amt | asset |
      | pad527 | pad528 | 6.00 | ETH |
    @case:931
    Examples:
      | from | to | amt | asset |
      | pad529 | pad530 | 6.00 | SOL |
    @case:932
    Examples:
      | from | to | amt | asset |
      | pad531 | pad532 | 6.00 | USDC |
    @case:933
    Examples:
      | from | to | amt | asset |
      | pad533 | pad534 | 6.25 | BTC |
    @case:934
    Examples:
      | from | to | amt | asset |
      | pad535 | pad536 | 6.25 | ETH |
    @case:935
    Examples:
      | from | to | amt | asset |
      | pad537 | pad538 | 6.25 | SOL |
    @case:936
    Examples:
      | from | to | amt | asset |
      | pad539 | pad540 | 6.25 | USDC |
    @case:937
    Examples:
      | from | to | amt | asset |
      | pad541 | pad542 | 6.50 | BTC |
    @case:938
    Examples:
      | from | to | amt | asset |
      | pad543 | pad544 | 6.50 | ETH |
    @case:939
    Examples:
      | from | to | amt | asset |
      | pad545 | pad546 | 6.50 | SOL |
    @case:940
    Examples:
      | from | to | amt | asset |
      | pad547 | pad548 | 6.50 | USDC |
    @case:941
    Examples:
      | from | to | amt | asset |
      | pad549 | pad550 | 6.75 | BTC |
    @case:942
    Examples:
      | from | to | amt | asset |
      | pad551 | pad552 | 6.75 | ETH |
    @case:943
    Examples:
      | from | to | amt | asset |
      | pad553 | pad554 | 6.75 | SOL |
    @case:944
    Examples:
      | from | to | amt | asset |
      | pad555 | pad556 | 6.75 | USDC |
    @case:945
    Examples:
      | from | to | amt | asset |
      | pad557 | pad558 | 7.00 | BTC |
    @case:946
    Examples:
      | from | to | amt | asset |
      | pad559 | pad560 | 7.00 | ETH |
    @case:947
    Examples:
      | from | to | amt | asset |
      | pad561 | pad562 | 7.00 | SOL |
    @case:948
    Examples:
      | from | to | amt | asset |
      | pad563 | pad564 | 7.00 | USDC |
    @case:949
    Examples:
      | from | to | amt | asset |
      | pad565 | pad566 | 7.25 | BTC |
    @case:950
    Examples:
      | from | to | amt | asset |
      | pad567 | pad568 | 7.25 | ETH |
    @case:951
    Examples:
      | from | to | amt | asset |
      | pad569 | pad570 | 7.25 | SOL |
    @case:952
    Examples:
      | from | to | amt | asset |
      | pad571 | pad572 | 7.25 | USDC |
    @case:953
    Examples:
      | from | to | amt | asset |
      | pad573 | pad574 | 7.50 | BTC |
    @case:954
    Examples:
      | from | to | amt | asset |
      | pad575 | pad576 | 7.50 | ETH |
    @case:955
    Examples:
      | from | to | amt | asset |
      | pad577 | pad578 | 7.50 | SOL |
    @case:956
    Examples:
      | from | to | amt | asset |
      | pad579 | pad580 | 7.50 | USDC |
    @case:957
    Examples:
      | from | to | amt | asset |
      | pad581 | pad582 | 7.75 | BTC |
    @case:958
    Examples:
      | from | to | amt | asset |
      | pad583 | pad584 | 7.75 | ETH |
    @case:959
    Examples:
      | from | to | amt | asset |
      | pad585 | pad586 | 7.75 | SOL |
    @case:960
    Examples:
      | from | to | amt | asset |
      | pad587 | pad588 | 7.75 | USDC |
    @case:961
    Examples:
      | from | to | amt | asset |
      | pad589 | pad590 | 8.00 | BTC |
    @case:962
    Examples:
      | from | to | amt | asset |
      | pad591 | pad592 | 8.00 | ETH |
    @case:963
    Examples:
      | from | to | amt | asset |
      | pad593 | pad594 | 8.00 | SOL |
    @case:964
    Examples:
      | from | to | amt | asset |
      | pad595 | pad596 | 8.00 | USDC |
    @case:965
    Examples:
      | from | to | amt | asset |
      | pad597 | pad598 | 8.25 | BTC |
    @case:966
    Examples:
      | from | to | amt | asset |
      | pad599 | pad600 | 8.25 | ETH |
    @case:967
    Examples:
      | from | to | amt | asset |
      | pad601 | pad602 | 8.25 | SOL |
    @case:968
    Examples:
      | from | to | amt | asset |
      | pad603 | pad604 | 8.25 | USDC |
    @case:969
    Examples:
      | from | to | amt | asset |
      | pad605 | pad606 | 8.50 | BTC |
    @case:970
    Examples:
      | from | to | amt | asset |
      | pad607 | pad608 | 8.50 | ETH |
    @case:971
    Examples:
      | from | to | amt | asset |
      | pad609 | pad610 | 8.50 | SOL |
    @case:972
    Examples:
      | from | to | amt | asset |
      | pad611 | pad612 | 8.50 | USDC |
    @case:973
    Examples:
      | from | to | amt | asset |
      | pad613 | pad614 | 8.75 | BTC |
    @case:974
    Examples:
      | from | to | amt | asset |
      | pad615 | pad616 | 8.75 | ETH |
    @case:975
    Examples:
      | from | to | amt | asset |
      | pad617 | pad618 | 8.75 | SOL |
    @case:976
    Examples:
      | from | to | amt | asset |
      | pad619 | pad620 | 8.75 | USDC |
    @case:977
    Examples:
      | from | to | amt | asset |
      | pad621 | pad622 | 9.00 | BTC |
    @case:978
    Examples:
      | from | to | amt | asset |
      | pad623 | pad624 | 9.00 | ETH |
    @case:979
    Examples:
      | from | to | amt | asset |
      | pad625 | pad626 | 9.00 | SOL |
    @case:980
    Examples:
      | from | to | amt | asset |
      | pad627 | pad628 | 9.00 | USDC |
    @case:981
    Examples:
      | from | to | amt | asset |
      | pad629 | pad630 | 9.25 | BTC |
    @case:982
    Examples:
      | from | to | amt | asset |
      | pad631 | pad632 | 9.25 | ETH |
    @case:983
    Examples:
      | from | to | amt | asset |
      | pad633 | pad634 | 9.25 | SOL |
    @case:984
    Examples:
      | from | to | amt | asset |
      | pad635 | pad636 | 9.25 | USDC |
    @case:985
    Examples:
      | from | to | amt | asset |
      | pad637 | pad638 | 9.50 | BTC |
    @case:986
    Examples:
      | from | to | amt | asset |
      | pad639 | pad640 | 9.50 | ETH |
    @case:987
    Examples:
      | from | to | amt | asset |
      | pad641 | pad642 | 9.50 | SOL |
    @case:988
    Examples:
      | from | to | amt | asset |
      | pad643 | pad644 | 9.50 | USDC |
    @case:989
    Examples:
      | from | to | amt | asset |
      | pad645 | pad646 | 9.75 | BTC |
    @case:990
    Examples:
      | from | to | amt | asset |
      | pad647 | pad648 | 9.75 | ETH |
    @case:991
    Examples:
      | from | to | amt | asset |
      | pad649 | pad650 | 9.75 | SOL |
    @case:992
    Examples:
      | from | to | amt | asset |
      | pad651 | pad652 | 9.75 | USDC |
    @case:993
    Examples:
      | from | to | amt | asset |
      | pad653 | pad654 | 10.00 | BTC |
    @case:994
    Examples:
      | from | to | amt | asset |
      | pad655 | pad656 | 10.00 | ETH |
    @case:995
    Examples:
      | from | to | amt | asset |
      | pad657 | pad658 | 10.00 | SOL |
    @case:996
    Examples:
      | from | to | amt | asset |
      | pad659 | pad660 | 10.00 | USDC |
    @case:997
    Examples:
      | from | to | amt | asset |
      | pad661 | pad662 | 10.25 | BTC |
    @case:998
    Examples:
      | from | to | amt | asset |
      | pad663 | pad664 | 10.25 | ETH |
    @case:999
    Examples:
      | from | to | amt | asset |
      | pad665 | pad666 | 10.25 | SOL |
    @case:1000
    Examples:
      | from | to | amt | asset |
      | pad667 | pad668 | 10.25 | USDC |
