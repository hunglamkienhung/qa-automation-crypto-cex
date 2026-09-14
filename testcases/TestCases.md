# Crypto CEX — test cases

1000 cases across a self-written mini-cex (with a real SQLite database) and the live Kraken public API. Generated from `../features/*.feature` by `build.js`; do not edit by hand.

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

## minicex-api (939)

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
| 117 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 118 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 119 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 120 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 121 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 122 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 123 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 124 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 125 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 126 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 127 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 128 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 129 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 130 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 131 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 132 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 133 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 134 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 135 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 136 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 137 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 138 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 139 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 140 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 141 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 142 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 143 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 144 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 145 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 146 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 147 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 148 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 149 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 150 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 151 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 152 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 153 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 154 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 155 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 156 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 157 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 158 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 159 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 160 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 161 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 162 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 163 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 164 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 165 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 166 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 167 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 168 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 169 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 170 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 171 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 172 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 173 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 174 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 175 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 176 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 177 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 178 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 179 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 180 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 181 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 182 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 183 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 184 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 185 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 186 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 187 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 188 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 189 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 190 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 191 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 192 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 193 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 194 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 195 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 196 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 197 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 198 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 199 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 200 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 201 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 202 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 203 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 204 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 205 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 206 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 207 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 208 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 209 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 210 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 211 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 212 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 213 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 214 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 215 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 216 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 217 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 218 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 219 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 220 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 221 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 222 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 223 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 224 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 225 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 226 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 227 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 228 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 229 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 230 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 231 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 232 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 233 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 234 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 235 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 236 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 237 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 238 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 239 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 240 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 241 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 242 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 243 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 244 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 245 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 246 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 247 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 248 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 249 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 250 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 251 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 252 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 253 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 254 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 255 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 256 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 257 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 258 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 259 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 260 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 261 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 262 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 263 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 264 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 265 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 266 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 267 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 268 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 269 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 270 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 271 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 272 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 273 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 274 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 275 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 276 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 277 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 278 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 279 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 280 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 281 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 282 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 283 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 284 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 285 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 286 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 287 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 288 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 289 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 290 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 291 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 292 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 293 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 294 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 295 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 296 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 297 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 298 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 299 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 300 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 301 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 302 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 303 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 304 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 305 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 306 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 307 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 308 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 309 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 310 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 311 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 312 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 313 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 314 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 315 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 316 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 317 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 318 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 319 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 320 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 321 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 322 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 323 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 324 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 325 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 326 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 327 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 328 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 329 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 330 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 331 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 332 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 333 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 334 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 335 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 336 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 337 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 338 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 339 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 340 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 341 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 342 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 343 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 344 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 345 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 346 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 347 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 348 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 349 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 350 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 351 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 352 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 353 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 354 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 355 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 356 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 357 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 358 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 359 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 360 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 361 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 362 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 363 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 364 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 365 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 366 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 367 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 368 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 369 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 370 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 371 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 372 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 373 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 374 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 375 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 376 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 377 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 378 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 379 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 380 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 381 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 382 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 383 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 384 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 385 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 386 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 387 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 388 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 389 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 390 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 391 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 392 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 393 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 394 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 395 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 396 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 397 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 398 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 399 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 400 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 401 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 402 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 403 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 404 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 405 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 406 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 407 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 408 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 409 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 410 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 411 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 412 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 413 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 414 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 415 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 416 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 417 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 418 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 419 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 420 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 421 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 422 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 423 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 424 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 425 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 426 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 427 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 428 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 429 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 430 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 431 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 432 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 433 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 434 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 435 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 436 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 437 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 438 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 439 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 440 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 441 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 442 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 443 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 444 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 445 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 446 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 447 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 448 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 449 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 450 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 451 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 452 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 453 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 454 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 455 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 456 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 457 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 458 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 459 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 460 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 461 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 462 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 463 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 464 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 465 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 466 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 467 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 468 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 469 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 470 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 471 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 472 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 473 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 474 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 475 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 476 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 477 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 478 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 479 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 480 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 481 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 482 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 483 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 484 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 485 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 486 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 487 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 488 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 489 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 490 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 491 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 492 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 493 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 494 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 495 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 496 | BE/API | Medium | The fee on a quote of <amt> <base> to <quote> matches the pair fee in basis points |
| 497 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 498 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 499 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 500 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 501 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 502 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 503 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 504 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 505 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 506 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 507 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 508 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 509 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 510 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 511 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 512 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 513 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 514 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 515 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 516 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 517 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 518 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 519 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 520 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 521 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 522 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 523 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 524 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 525 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 526 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 527 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 528 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 529 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 530 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 531 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 532 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 533 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 534 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 535 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 536 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 537 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 538 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 539 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 540 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 541 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 542 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 543 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 544 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 545 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 546 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 547 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 548 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 549 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 550 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 551 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 552 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 553 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 554 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 555 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 556 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 557 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 558 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 559 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 560 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 561 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 562 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 563 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 564 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 565 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 566 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 567 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 568 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 569 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 570 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 571 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 572 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 573 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 574 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 575 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 576 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 577 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 578 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 579 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 580 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 581 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 582 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 583 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 584 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 585 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 586 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 587 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 588 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 589 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 590 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 591 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 592 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 593 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 594 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 595 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 596 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 597 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 598 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 599 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 600 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 601 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 602 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 603 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 604 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 605 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 606 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 607 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 608 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 609 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 610 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 611 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 612 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 613 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 614 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 615 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 616 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 617 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 618 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 619 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 620 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 621 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 622 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 623 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 624 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 625 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 626 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 627 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 628 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 629 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 630 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 631 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 632 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 633 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 634 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 635 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 636 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 637 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 638 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 639 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 640 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 641 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 642 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 643 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 644 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 645 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 646 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 647 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 648 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 649 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 650 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 651 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 652 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 653 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 654 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 655 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 656 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 657 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 658 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 659 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 660 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 661 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 662 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 663 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 664 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 665 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 666 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 667 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 668 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 669 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 670 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 671 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 672 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 673 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 674 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 675 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 676 | BE/API | Medium | A fresh account funded with <amt> <asset> shows that balance |
| 677 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 678 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 679 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 680 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 681 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 682 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 683 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 684 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 685 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 686 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 687 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 688 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 689 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 690 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 691 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 692 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 693 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 694 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 695 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 696 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 697 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 698 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 699 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 700 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 701 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 702 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 703 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 704 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 705 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 706 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 707 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 708 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 709 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 710 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 711 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 712 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 713 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 714 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 715 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 716 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 717 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 718 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 719 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 720 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 721 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 722 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 723 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 724 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 725 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 726 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 727 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 728 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 729 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 730 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 731 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 732 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 733 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 734 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 735 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 736 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 737 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 738 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 739 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 740 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 741 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 742 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 743 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 744 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 745 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 746 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 747 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 748 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 749 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 750 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 751 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 752 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 753 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 754 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 755 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 756 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 757 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 758 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 759 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 760 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 761 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 762 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 763 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 764 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 765 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 766 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 767 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 768 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 769 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 770 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 771 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 772 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 773 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 774 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 775 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 776 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 777 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 778 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 779 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 780 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 781 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 782 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 783 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 784 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 785 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 786 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 787 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 788 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 789 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 790 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 791 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 792 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 793 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 794 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 795 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 796 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 797 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 798 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 799 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 800 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 801 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 802 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 803 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 804 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 805 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 806 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 807 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 808 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 809 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 810 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 811 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 812 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 813 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 814 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 815 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 816 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 817 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 818 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 819 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 820 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 821 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 822 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 823 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 824 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 825 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 826 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 827 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 828 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 829 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 830 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 831 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 832 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 833 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 834 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 835 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 836 | BE/API | Medium | A swap of <swap> <base> to <quote> outputs the quoted amount |
| 837 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 838 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 839 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 840 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 841 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 842 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 843 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 844 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 845 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 846 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 847 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 848 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 849 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 850 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 851 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 852 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 853 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 854 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 855 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 856 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 857 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 858 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 859 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 860 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 861 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 862 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 863 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 864 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 865 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 866 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 867 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 868 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 869 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 870 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 871 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 872 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 873 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 874 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 875 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 876 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 877 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 878 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 879 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 880 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 881 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 882 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 883 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 884 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 885 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 886 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 887 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 888 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 889 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 890 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 891 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 892 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 893 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 894 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 895 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 896 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 897 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 898 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 899 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 900 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 901 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 902 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 903 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 904 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 905 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 906 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 907 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 908 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 909 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 910 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 911 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 912 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 913 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 914 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 915 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 916 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 917 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 918 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 919 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 920 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 921 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 922 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 923 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 924 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 925 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 926 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 927 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 928 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 929 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 930 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 931 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 932 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 933 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 934 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 935 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 936 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 937 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 938 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 939 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 940 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 941 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 942 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 943 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 944 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 945 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 946 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 947 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 948 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 949 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 950 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 951 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 952 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 953 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 954 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 955 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 956 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 957 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 958 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 959 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 960 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 961 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 962 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 963 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 964 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 965 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 966 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 967 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 968 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 969 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 970 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 971 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 972 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 973 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 974 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 975 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 976 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 977 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 978 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 979 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 980 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 981 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 982 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 983 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 984 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 985 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 986 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 987 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 988 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 989 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 990 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 991 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 992 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 993 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 994 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 995 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 996 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 997 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 998 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 999 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |
| 1000 | BE/API | Medium | A transfer of <amt> <asset> reaches the recipient |

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
