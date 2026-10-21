# Reward escrow

Verily lets a creator attach a reward to an action. The reward must exist
before anyone starts working for it, so it lives in escrow: the creator locks
the whole budget up front, and it can only leave escrow in two ways.

1. **To a participant**, one fixed payout per verified completion, released by
   Verily after the proof is accepted.
2. **Back to the creator**, but only after the action has ended and a refund
   delay has passed, so proof that is still in review or appeal can be paid.

Rewards are paid in a Solana SPL token (USDC by default). Paying out crypto
from an on-chain escrow avoids holding customer money, card chargebacks, and
payout rails, and makes the "the reward really exists" promise checkable by
anyone. Verily has no NFTs, no project token, and no trading: the token is only
the unit the reward is paid in.

## Roles

| Role        | Who                                     | Can                                                                |
| ----------- | --------------------------------------- | ------------------------------------------------------------------ |
| Creator     | The person who publishes the action     | Open an escrow, end it early, close it after the refund window     |
| Arbiter     | Verily's server key (Cloud KMS in prod) | Release one fixed payout per payout index, until the refund window |
| Participant | Anyone with a verified completion       | Receive a payout to their linked wallet                            |

The arbiter never holds funds and cannot change the payout amount, the token,
or the number of payouts. Each payout index can be paid once, enforced on
chain by a bitmap, so a retried or duplicated release can never pay twice.

## Program: `verily_escrow`

Built with [Pina](https://github.com/pina-rs/pina). Classic SPL Token only in
v1 (USDC is a classic token); Token-2022 extensions such as transfer fees and
hooks are out of scope until reviewed.

### Account: `RewardEscrow`

PDA with seeds `["reward-escrow", creator, pool_id]`, where `pool_id` is the
16-byte UUID of the server's reward pool row. The account starts with Pina's
one-byte `RewardEscrow` discriminator (`1`) and one-byte schema version, then
the fields below, packed in order (435 bytes in all).

| Field               | Type        | Notes                                                              |
| ------------------- | ----------- | ------------------------------------------------------------------ |
| `creator`           | Address     | Funds the escrow and receives refunds                              |
| `arbiter`           | Address     | The only key that can release payouts                              |
| `mint`              | Address     | Reward token                                                       |
| `vault`             | Address     | The escrow PDA's associated token account for `mint`               |
| `pool_id`           | `[u8; 16]`  | Server reward pool id                                              |
| `amount_per_payout` | `u64`       | Token atoms per verified completion; at least 1                    |
| `max_payouts`       | `u16`       | `1..=MAX_PAYOUTS` (2048)                                           |
| `released_count`    | `u16`       | Payouts released so far                                            |
| `expires_at`        | `i64`       | Unix seconds; no new completions are paid after this               |
| `refund_after`      | `i64`       | `expires_at + refund_delay`; creator may close from here           |
| `refund_delay`      | `u32`       | Seconds, `MIN_REFUND_DELAY..=MAX_REFUND_DELAY` (3 to 30 days)      |
| `bump`              | `u8`        | Canonical bump                                                     |
| `released`          | `[u8; 256]` | Bitmap: bit `i % 8` of byte `i / 8` set once index `i` is released |

### Instructions

| Instruction     | Signer  | Effect                                                                                                                                              |
| --------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `OpenEscrow`    | creator | Creates the escrow PDA and, idempotently, its vault ATA, then transfers `amount_per_payout × max_payouts` from the creator with `transfer_checked`. |
| `ReleasePayout` | arbiter | Requires `index < max_payouts`, the bit unset, and `now < refund_after`. Sets the bit, increments `released_count`, transfers one payout.           |
| `EndEarly`      | creator | Moves `expires_at` to `min(expires_at, now)` and recomputes `refund_after`. It can never extend an escrow.                                          |
| `CloseEscrow`   | creator | Allowed when `now >= refund_after` or every payout is released. Returns the vault balance, closes the vault, and closes the escrow (rent back).     |

`OpenEscrow` also requires `expires_at` to be in the future, `refund_after` to
fit in an `i64`, `amount_per_payout × max_payouts` to fit in a `u64`, and the
arbiter to be a real key other than the creator. An escrow that is already
expired, or whose creator can release its own payouts, does not lock a reward
anyone can rely on.

The vault is created with the associated token account program's idempotent
instruction. Its address is derivable by anyone, so a plain create could be
front-run by someone creating the vault first, which would block that escrow
permanently. An existing vault is accepted only when it is that address's SPL
Token account for `mint`, owned by the escrow PDA, which only this program can
sign for; tokens already in it simply join the budget.

`ReleasePayout` takes the recipient's token account, which must hold `mint`
and must not be owned by the escrow itself (a payout there could never leave,
and its index would be spent without paying anyone). The server prepends an
idempotent associated-token-account creation for the recipient, paid by
Verily's fee payer, so a participant never needs SOL to be paid. A release of
an index that is already set fails with `PayoutAlreadyReleased` even after the
refund window opens, so a retried job always learns the index was paid.

`CloseEscrow` returns the vault's whole balance, including anything sent to the
vault on top of the budget.

Events:

- `EscrowOpened { escrow, creator, arbiter, mint, vault, pool_id, amount_per_payout, max_payouts, expires_at, refund_after }`
- `PayoutReleased { escrow, pool_id, index, recipient, amount }`, where
  `recipient` is the recipient token account
- `EscrowEnded { escrow, pool_id, expires_at, refund_after }`
- `EscrowClosed { escrow, pool_id, refunded, released_count, released }`, with
  the final bitmap, so a payout job can still tell which indexes were paid
  after the account is gone

Every event names its `escrow` address. A `pool_id` is not unique on chain:
anyone can open an escrow under their own creator key with any pool id, even
with Verily's arbiter key, so a watcher must match the escrow address the
server derived, never the pool id alone.

### Invariants

- `vault` balance ≥ `amount_per_payout × (max_payouts − released_count)` while
  the escrow is open (nothing but `ReleasePayout` and `CloseEscrow` moves it).
- A payout index is released at most once.
- No payout is released at or after `refund_after`, so a creator's close can
  never race a release.
- `refund_after − expires_at ≥ MIN_REFUND_DELAY`, so proof submitted just
  before the end still has days for review and appeal.
- Every account is validated for owner, address, signer, writability, and
  mint before any transfer.

## Server flow

```mermaid
sequenceDiagram
  actor C as Creator
  participant App as Verily app
  participant API as Serverpod
  participant Chain as Solana
  actor P as Participant

  C->>App: Add a reward to the action
  App->>API: prepareRewardFunding(actionId)
  API-->>App: unsigned OpenEscrow transaction
  App->>Chain: sign and send with the creator's wallet
  App->>API: confirmRewardFunding(actionId, signature)
  API->>Chain: read escrow: owner, creator, arbiter, mint, amount, expiry
  API-->>App: funded, action can publish
  P->>API: completes the action, proof verified
  API->>API: reserve the next payout index (row-locked)
  API->>Chain: ReleasePayout(index) signed by the arbiter
  Chain-->>API: confirmed; record signature
  API-->>P: reward paid
```

- **Funding is verified from chain state, never from the client.** The
  server derives the escrow address itself and checks every field against the
  pool row before the action can publish.
- **Payout indexes are assigned in the database** in the same transaction that
  completes the attempt, under the pool row lock, so two completions can never
  take the same index and no account exceeds `maxWinsPerAccount`.
- **Release is a durable, idempotent job.** A retry of the same index either
  succeeds or fails with `PayoutAlreadyReleased`, which the job resolves by
  reading the bitmap. It never pays twice. Once the escrow is closed, the job
  reads the final bitmap from its `EscrowClosed` event instead.
- **One escrow per pool row.** Closing removes the escrow account, so the same
  creator and pool id can open a fresh escrow with an empty bitmap. The server
  never funds a pool id twice, and it stops a pool's release jobs once it has
  seen `EscrowClosed`, so a stale retry can never pay from a later escrow.
- **No wallet, no loss.** A verified participant without a linked wallet keeps
  a reserved payout; it is released when they link one, until the refund
  window closes.
- **Valuable payouts need a person.** A payout above the configured review
  threshold is only released on proof a person accepted.

## Trust and limits

Escrow protects participants from a creator who never pays, and protects
creators from paying more than they budgeted. It does not remove trust in
Verily's verification: the arbiter decides which completions are real. A
compromised arbiter key could release the remaining payouts of open escrows to
accounts it controls. Mitigations:

- The arbiter key lives in Cloud KMS and never exists as bytes on the server.
- Per-escrow exposure is capped by its own budget; there is no shared vault.
- A watcher compares every on-chain `PayoutReleased` event with the database,
  keyed by escrow address and index, and alerts on any release the server did
  not record.

Future work: arbiter rotation, a creator-visible dispute window before large
payouts, Token-2022 support, and native SOL rewards.
