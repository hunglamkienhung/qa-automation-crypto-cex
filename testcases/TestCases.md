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
| 317 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 318 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 319 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 320 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 321 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 322 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 323 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 324 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 325 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 326 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 327 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 328 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 329 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 330 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 331 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 332 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 333 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 334 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 335 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 336 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 337 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 338 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 339 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 340 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 341 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 342 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 343 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 344 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 345 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 346 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 347 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 348 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 349 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 350 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 351 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 352 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 353 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 354 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 355 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 356 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 357 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 358 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 359 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 360 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 361 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 362 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 363 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 364 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 365 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 366 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 367 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 368 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 369 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 370 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 371 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 372 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 373 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 374 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 375 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 376 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 377 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 378 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 379 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 380 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 381 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 382 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 383 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 384 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 385 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 386 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 387 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 388 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 389 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 390 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 391 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 392 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 393 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 394 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 395 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 396 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 397 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 398 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 399 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 400 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 401 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 402 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 403 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 404 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 405 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 406 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 407 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 408 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 409 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 410 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 411 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 412 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 413 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 414 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 415 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 416 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 417 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 418 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 419 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 420 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 421 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 422 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 423 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 424 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 425 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 426 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 427 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 428 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 429 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 430 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 431 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 432 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 433 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 434 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 435 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 436 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 437 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 438 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 439 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 440 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 441 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 442 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 443 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 444 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 445 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 446 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 447 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 448 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 449 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 450 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 451 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 452 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 453 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 454 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 455 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 456 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 457 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 458 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 459 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 460 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 461 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 462 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 463 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 464 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 465 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 466 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 467 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 468 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 469 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 470 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 471 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 472 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 473 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 474 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 475 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 476 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 477 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 478 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 479 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 480 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 481 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 482 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 483 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 484 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 485 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 486 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 487 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 488 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 489 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 490 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 491 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 492 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 493 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 494 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 495 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 496 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 497 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 498 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 499 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 500 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 501 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 502 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 503 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 504 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 505 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 506 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 507 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 508 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 509 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 510 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 511 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 512 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 513 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 514 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 515 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 516 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 517 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 518 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 519 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 520 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 521 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 522 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 523 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 524 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 525 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 526 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 527 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 528 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 529 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 530 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 531 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 532 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 533 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 534 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 535 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 536 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 537 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 538 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 539 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 540 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 541 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 542 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 543 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 544 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 545 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 546 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 547 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 548 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 549 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 550 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 551 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 552 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 553 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 554 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 555 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 556 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 557 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 558 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 559 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 560 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 561 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 562 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 563 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 564 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 565 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 566 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 567 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 568 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 569 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 570 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 571 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 572 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 573 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 574 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 575 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 576 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 577 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 578 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 579 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 580 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 581 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 582 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 583 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 584 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 585 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 586 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 587 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 588 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 589 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 590 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 591 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 592 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 593 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 594 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 595 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 596 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 597 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 598 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 599 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 600 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 601 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 602 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 603 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 604 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 605 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 606 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 607 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 608 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 609 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 610 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 611 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 612 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 613 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 614 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 615 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 616 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 617 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 618 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 619 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 620 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 621 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 622 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 623 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 624 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 625 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 626 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 627 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 628 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 629 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 630 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 631 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 632 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 633 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 634 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 635 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 636 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 637 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 638 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 639 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 640 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 641 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 642 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 643 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 644 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 645 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 646 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 647 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 648 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 649 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 650 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 651 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 652 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 653 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 654 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 655 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 656 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 657 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 658 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 659 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 660 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 661 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 662 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 663 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 664 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 665 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 666 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 667 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 668 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 669 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 670 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 671 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 672 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 673 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 674 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 675 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 676 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 677 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 678 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 679 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 680 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 681 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 682 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 683 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 684 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 685 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 686 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 687 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 688 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 689 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 690 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 691 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 692 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 693 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 694 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 695 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 696 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 697 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 698 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 699 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 700 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 701 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 702 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 703 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 704 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 705 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 706 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 707 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 708 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 709 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 710 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 711 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 712 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 713 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 714 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 715 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 716 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 717 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 718 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 719 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 720 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 721 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 722 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 723 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 724 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 725 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 726 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 727 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 728 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 729 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 730 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 731 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 732 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 733 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 734 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 735 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 736 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 737 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 738 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 739 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 740 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 741 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 742 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 743 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 744 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 745 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 746 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 747 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 748 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 749 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 750 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 751 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 752 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 753 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 754 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 755 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 756 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 757 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 758 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 759 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 760 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 761 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 762 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 763 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 764 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 765 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 766 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 767 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 768 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 769 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 770 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 771 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 772 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 773 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 774 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 775 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 776 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 777 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 778 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 779 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 780 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 781 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 782 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 783 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 784 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 785 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 786 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 787 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 788 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 789 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 790 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 791 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 792 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 793 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 794 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 795 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 796 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 797 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 798 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 799 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 800 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 801 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 802 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 803 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 804 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 805 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 806 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 807 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 808 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 809 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 810 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 811 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 812 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 813 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 814 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 815 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 816 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 817 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 818 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 819 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 820 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 821 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 822 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 823 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 824 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 825 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 826 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 827 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 828 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 829 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 830 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 831 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 832 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 833 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 834 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 835 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 836 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 837 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 838 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 839 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 840 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 841 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 842 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 843 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 844 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 845 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 846 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 847 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 848 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 849 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 850 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 851 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 852 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 853 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 854 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 855 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 856 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 857 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 858 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 859 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 860 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 861 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 862 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 863 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 864 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 865 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 866 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 867 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 868 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 869 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 870 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 871 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 872 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 873 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 874 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 875 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 876 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 877 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 878 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 879 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 880 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 881 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 882 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 883 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 884 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 885 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 886 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 887 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 888 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 889 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 890 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 891 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 892 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 893 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 894 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 895 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 896 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 897 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 898 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 899 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 900 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 901 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 902 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 903 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 904 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 905 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 906 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 907 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 908 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 909 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 910 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 911 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 912 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 913 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 914 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 915 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 916 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 917 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 918 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 919 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 920 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 921 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 922 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 923 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 924 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 925 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 926 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 927 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 928 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 929 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 930 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 931 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 932 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 933 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 934 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 935 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 936 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 937 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 938 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 939 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 940 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 941 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 942 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 943 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 944 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 945 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 946 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 947 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 948 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 949 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 950 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 951 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 952 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 953 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 954 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 955 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 956 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 957 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 958 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 959 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 960 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 961 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 962 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 963 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 964 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 965 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 966 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 967 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 968 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 969 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 970 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 971 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 972 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 973 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 974 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 975 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 976 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 977 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 978 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 979 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 980 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 981 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 982 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 983 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 984 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 985 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 986 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 987 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 988 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 989 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 990 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 991 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 992 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 993 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 994 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 995 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 996 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 997 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 998 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 999 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |
| 1000 | BE/API | Medium | A quote of <amt> <base> to <quote> nets the gross minus the fee |

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
