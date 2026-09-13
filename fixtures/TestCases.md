# Crypto CEX — test cases

58 cases across a self-written mini-cex (with a real SQLite database) and the live Kraken public API. Generated from `../features/*.feature` by `build.js`; do not edit by hand.

## minicex-db (14)

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

## minicex-api (18)

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

## kraken-api (6)

| ID | Layer | Priority | Title |
|---|---|---|---|
| 33 | BE/API | Medium | Kraken lists its assets |
| 34 | BE/API | Medium | Kraken lists its asset pairs |
| 35 | BE/API | High | The mini-cex crypto assets trade on Kraken |
| 36 | BE/API | High | Kraken quotes a positive BTC price |
| 37 | BE/API | High | The mini-cex BTC price is the same order of magnitude as Kraken's |
| 38 | BE/API | Medium | Kraken quotes a positive ETH price |

## bot (10)

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
