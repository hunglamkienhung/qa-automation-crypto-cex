# Crypto CEX — test cases

116 cases across a self-written mini-cex (with a real SQLite database) and the live Kraken public API. Generated from `../features/*.feature` by `build.js`; do not edit by hand.

## minicex-db (28)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 1 | BE/DB | High | The store has the documented tables |
| 2 | BE/DB | High | A balance can never be negative |
| 3 | BE/DB | High | A ledger movement is a real, non-zero change with a known reason |
| 4 | BE/DB | High | A balance references a real account and asset |
| 5 | BE/DB | High | A bridge op is unique per direction and external tx |
| 6 | BE/DB | Medium | A pair's two legs must differ |
| 7 | BE/DB | Medium | Seeding twice leaves the same rows |
| 8 | BE/DB | High | A deposit credits the balance and writes a matching ledger line |
| 9 | BE/DB | High | The ledger sum equals the running balance |
| 10 | BE/DB | High | An internal transfer conserves the total balance |
| 11 | BE/DB | High | A swap debits the input and credits the net output, both on the ledger |
| 12 | BE/DB | High | A bridge withdrawal locks the balance with a debit line |
| 13 | BE/DB | High | A bridge deposit credits once even when observed twice |
| 14 | BE/DB | High | An overdrawn transfer leaves both balances untouched |
| 59 | BE/DB | High | A balance's reserved part can never exceed its total |
| 60 | BE/DB | High | An order's filled amount can never exceed its size |
| 61 | BE/DB | High | A fill never has the same account on both sides |
| 64 | BE/DB | High | A crossing taker matches the maker at the maker's price |
| 65 | BE/DB | High | A match moves base to the taker and quote to the maker |
| 75 | BE/DB | High | A match conserves value across the two sides |
| 89 | BE/DB | High | A stake principal must be positive |
| 91 | BE/DB | High | The locked principal leaves a matching ledger line |
| 97 | BE/DB | High | A redeemed stake's ledger balances back to whole |
| 108 | BE/DB | High | A quote writes one open bid and one open ask |
| 109 | BE/DB | High | The bid reserves quote and the ask reserves base |
| 110 | BE/DB | High | A lifted ask writes a fill and advances the order |
| 111 | BE/DB | High | Repricing cancels the old orders and releases their reserve |
| 112 | BE/DB | High | The maker's ledger balances after quote, fill and reprice |

## minicex-api (55)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 15 | BE/API | High | The exchange lists its assets |
| 16 | BE/API | High | The exchange lists its tradable pairs |
| 17 | BE/API | High | A quote returns the net after fee |
| 18 | BE/API | High | Creating an account returns a handle and a token |
| 19 | BE/API | Medium | A duplicate handle is refused |
| 20 | BE/API | High | A deposit is accepted and shows in balances |
| 21 | BE/API | High | A swap moves balances by the quoted amounts |
| 22 | BE/API | High | A swap below the slippage floor is refused |
| 23 | BE/API | Medium | A swap of a delisted asset is refused |
| 24 | BE/API | High | A transfer moves funds between accounts |
| 25 | BE/API | High | A transfer over balance is refused |
| 26 | BE/API | High | A repeated deposit with the same idempotency key makes one credit |
| 27 | BE/API | High | An unauthenticated write is refused |
| 28 | BE/API | High | A bridge withdrawal locks and can be confirmed |
| 29 | BE/API | High | A bridge withdrawal over the cap is refused |
| 30 | BE/API | High | A bridge to an unknown chain is refused |
| 31 | BE/API | Medium | A bridge deposit is idempotent by external tx |
| 32 | BE/API | Medium | A swap of an unknown asset is not found |
| 62 | BE/API | High | A limit order that does not cross rests on the book |
| 63 | BE/API | High | Placing a sell reserves the base it offers |
| 66 | BE/API | High | The taker pays the taker fee and the maker pays the maker fee |
| 67 | BE/API | High | A partial fill leaves the remainder resting |
| 68 | BE/API | High | Matching takes the best price first |
| 69 | BE/API | High | A taker never matches its own resting order |
| 70 | BE/API | High | Cancelling an order releases its reserve |
| 71 | BE/API | High | A post-only order that would cross is rejected |
| 72 | BE/API | High | A fill-or-kill order that cannot fully fill is killed |
| 73 | BE/API | High | An IOC order fills what it can and cancels the rest |
| 74 | BE/API | Medium | A market buy sweeps the book at the resting price |
| 76 | BE/API | Medium | The fee schedule lists the maker-taker tiers |
| 77 | BE/API | Medium | A below-minimum order is refused |
| 78 | BE/API | Medium | A repeated order with the same idempotency key makes one order |
| 79 | BE/API | High | Minting a key returns the key and its scope |
| 80 | BE/API | High | A read-scoped key cannot place an order |
| 81 | BE/API | High | A trade-scoped key can place an order |
| 82 | BE/API | High | A trade-scoped key cannot withdraw |
| 83 | BE/API | High | A withdraw-scoped key can withdraw |
| 84 | BE/API | High | A revoked key is rejected |
| 85 | BE/API | High | An unknown key is rejected |
| 86 | BE/API | High | A key over its rate limit is throttled |
| 87 | BE/API | Medium | Minting a key requires the owner token, not a key |
| 88 | BE/API | Medium | A key is listed under its account |
| 90 | BE/API | High | Staking locks the principal out of the balance |
| 92 | BE/API | High | Accrual over a year equals the APR on the principal |
| 93 | BE/API | High | Accrual is proportional to the elapsed time |
| 94 | BE/API | High | Redeeming returns the principal plus the reward |
| 95 | BE/API | High | A stake cannot be redeemed twice |
| 96 | BE/API | High | Staking more than the balance is refused |
| 98 | BE/API | Medium | Staked funds are not available to withdraw |
| 102 | BE/API | High | The market maker posts a two-sided quote |
| 103 | BE/API | High | The quotes rest on the book without crossing |
| 104 | BE/API | High | Repricing replaces the quotes |
| 105 | BE/API | High | When a taker lifts the ask, the maker's ask fills |
| 106 | BE/API | High | The kill switch stops the maker from quoting |
| 107 | BE/API | High | Dry-run plans a quote without sending it |

## kraken-api (6)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 33 | BE/API | Medium | Kraken lists its assets |
| 34 | BE/API | Medium | Kraken lists its asset pairs |
| 35 | BE/API | High | The mini-cex crypto assets trade on Kraken |
| 36 | BE/API | High | Kraken quotes a positive BTC price |
| 37 | BE/API | High | The mini-cex BTC price is the same order of magnitude as Kraken's |
| 38 | BE/API | Medium | Kraken quotes a positive ETH price |

## bot (13)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 39 | BE/BOT | High | The kill switch blocks every operation |
| 40 | BE/BOT | High | A zero amount is refused |
| 41 | BE/BOT | High | A transfer within balance is allowed |
| 42 | BE/BOT | High | A transfer over balance is refused |
| 43 | BE/BOT | High | A swap below the pair minimum is refused |
| 44 | BE/BOT | High | A swap under the slippage floor is refused |
| 45 | BE/BOT | High | A swap with no listed pair is refused |
| 46 | BE/BOT | High | A bridge to an unknown chain is refused |
| 47 | BE/BOT | High | A bridge over the cap is refused |
| 48 | BE/BOT | High | A bridge within cap and balance is allowed |
| 99 | BE/BOT | High | A zero-size order is refused |
| 100 | BE/BOT | High | An order above the max size is refused |
| 101 | BE/BOT | High | The kill switch blocks an order too |

## minicex-fe (10)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 49 | FE/UI | High | The home page lists the exchange's assets |
| 50 | FE/UI | Medium | A delisted asset is marked so on screen |
| 51 | FE/UI | High | The number of assets on screen equals the API asset count |
| 52 | FE/UI | High | A funded wallet shows its balance on screen |
| 53 | FE/UI | High | The wallet balances on screen match the API balances |
| 54 | FE/UI | Medium | A bridge op page shows its status |
| 55 | FE/UI | High | The transfer form moves funds between accounts |
| 56 | FE/UI | High | The swap form converts one asset to another |
| 57 | FE/UI | High | The bridge form locks a withdrawal |
| 58 | FE/UI | High | The transfer form refuses an overdraw |

## minicex-security (4)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 113 | BE/API | High | A garbage bearer token is refused on a write |
| 114 | BE/API | High | One account cannot revoke another account's API key |
| 115 | BE/API | High | The key list exposes only a prefix, never the full key |
| 116 | BE/API | Medium | A public market-data response carries no credential |
