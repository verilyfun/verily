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

## Server gateway

The server reaches the program only through the `RewardEscrowGateway`
interface (`verily_server/lib/src/rewards/reward_escrow_gateway.dart`).
`VERILY_REWARD_ESCROW_MODE` picks the implementation:

| Mode                | Gateway                                  | Where                               |
| ------------------- | ---------------------------------------- | ----------------------------------- |
| `disabled`          | Refuses every call; rewards fail closed  | The default everywhere              |
| `local-development` | A labelled simulation that moves nothing | Development and test only, devnet   |
| `solana`            | `SolanaRewardEscrowGateway`              | Devnet; mainnet only as noted below |

`SolanaRewardEscrowGateway` (`solana_reward_escrow_gateway.dart`) is built on
the generated `verily_escrow_client` codecs, instruction builders, PDA helper,
error table, and event parser, and on `solana_kit`. Startup
(`solana_reward_escrow_configuration.dart`) connects it before the server
accepts traffic; any failure stops startup.

### Keys

Two Verily keys sign, and they must be different keys:

- The **arbiter** signs only `ReleasePayout`. It is recorded in every escrow.
- The **fee payer** pays transaction fees and the recipient's token-account
  rent, so a participant never needs SOL to be paid.

Creators sign their own `OpenEscrow` and `EndEarly`: the server builds an
unsigned v0 transaction with the creator as fee payer and only signer, and
the app signs and sends it through Mobile Wallet Adapter. Verily's keys never
appear in a creator's transaction.

| `VERILY_REWARD_SIGNER` | Custody                                                              | Allowed                                                          |
| ---------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `kms`                  | Cloud KMS Ed25519 key versions; the key bytes never reach the server | Every run mode; the only option for staging, production, mainnet |
| `local-keypair`        | Solana CLI keypair JSON from Monosecret secrets                      | Development and test, devnet                                     |

Both modes pin each key's public address. A local keypair must be internally
consistent and match its pinned address. A KMS key must report the pinned
public key, prove possession by signing a fresh random challenge at startup,
and every signature KMS returns is verified locally before it is attached.

### Configuration

| Variable                                                                              | Meaning                                                                                                                                                 |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `VERILY_REWARD_ESCROW_MODE=solana`                                                    | Selects the Solana gateway.                                                                                                                             |
| `VERILY_REWARD_CLUSTER`                                                               | `devnet` or `mainnet`.                                                                                                                                  |
| `VERILY_REWARD_SOLANA_RPC_URL` (secret)                                               | HTTPS without credentials in the authority; plain HTTP only for a loopback validator in development and test. Never logged: providers embed keys in it. |
| `VERILY_REWARD_ARBITER_ADDRESS`, `VERILY_REWARD_FEE_PAYER_ADDRESS`                    | Pinned public keys.                                                                                                                                     |
| `VERILY_REWARD_SIGNER`                                                                | `kms` or `local-keypair`.                                                                                                                               |
| `VERILY_REWARD_ARBITER_KEYPAIR`, `VERILY_REWARD_FEE_PAYER_KEYPAIR` (secrets)          | Local keypairs, development and test only.                                                                                                              |
| `VERILY_REWARD_KMS_ARBITER_KEY`, `VERILY_REWARD_KMS_FEE_PAYER_KEY`                    | `projects/…/cryptoKeyVersions/N` resource names; different keys.                                                                                        |
| `VERILY_REWARD_KMS_CREDENTIALS_FILE` or `VERILY_REWARD_KMS_CREDENTIALS_JSON` (secret) | Exactly one service-account source; a file must be `0600`.                                                                                              |
| `VERILY_REWARD_SOLANA_GENESIS_HASH`                                                   | Development and test only, for a local validator on devnet settings. Otherwise the cluster's pinned genesis hash is required.                           |
| `VERILY_REWARD_ESCROW_PROGRAM_ID`                                                     | Optional. Anything other than the generated client's program id is refused outside development and test.                                                |
| `VERILY_REWARD_MAINNET_ENABLED`                                                       | Exactly `true` to allow mainnet, and only in the production run mode with KMS custody.                                                                  |

**Mainnet has not been reviewed for real money.** The program, this gateway,
and its custody have had no external audit; the mainnet flag exists so that
enabling it is a reviewed, deliberate deployment change, not a default.

### What is verified from chain

- **At startup**, at `finalized`: the RPC endpoint's genesis hash is the
  cluster's pinned hash, the escrow program account is executable, and the
  reward mint is a classic SPL Token mint (owner, exact size, initialized)
  with the expected decimals. Mints come only from the per-cluster allow-list
  (devnet and mainnet USDC); a pool for another mint or cluster is refused.
- **Funding**, at `finalized`, because a published reward cannot be taken back
  from participants if its funding block were dropped: the escrow is read at
  the address the server derives itself; its owner must be the program; the
  data must be exactly 435 bytes with the `RewardEscrow` discriminator and
  schema version; the address must re-derive from the stored creator and pool
  id with the stored, canonical bump; and the stored invariants must hold
  (`released_count ≤ max_payouts`, `refund_after = expires_at + refund_delay`,
  bounds). The pool service then compares creator, arbiter, mint, pool id,
  amount, payout count, expiry, refund window, refund delay, and
  `released_count = 0`, and requires the vault balance to cover the whole
  budget. The reported balance is what the escrow can actually pay: zero when
  the vault is missing, is not the escrow's associated token account for its
  mint, is not an SPL Token account of that mint owned by the escrow, or is
  frozen.
- **Release**, against `confirmed` state: the escrow must still be the pool's
  (same creator, arbiter, mint, vault, pool id, and immutable terms) and must
  never show fewer releases than the server recorded, which would mean a
  fresh escrow was opened at the same address after this one closed. An index
  already set is settled without sending. Otherwise the gateway sends
  `[CreateIdempotent(recipient ATA, payer = fee payer), ReleasePayout(index)]`
  signed by the fee payer and the arbiter, with preflight, and reports
  `RewardReleased` once that signature is `confirmed` without error, within a
  bounded wait.
- **The released bitmap** (`isPayoutReleased`) is read at `finalized`, because
  the payout job marks a payout paid on it without a signature of its own.
  When the escrow account is gone, the answer is unknown and the call throws:
  the final bitmap lives only in the `EscrowClosed` event, which the server
  does not record yet, and the payout job never marks a payout paid on an
  unknown.
- Custom error codes are attributed through the logs: the escrow's codes
  overlap SPL Token's, so a code counts as the escrow's only when the
  innermost failing program in the logs is the escrow program. Events are
  decoded only through `parseVerilyEscrowEventsFromLogs` over complete logs,
  which follows the runtime's invoke frames.

### Release outcomes

`PayoutAlreadyReleased` becomes `RewardAlreadyReleased` only after the
finalized bitmap confirms the bit. Every other failure is a
`RewardReleaseFailed` with a stable code and never RPC or provider text. A
retry always uses the same index.

| Code                                         | Retryable | Meaning                                                                                        |
| -------------------------------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| `release_pending_finality`                   | yes       | The bit is set at `confirmed` but not yet at `finalized`.                                      |
| `release_unconfirmed`                        | yes       | Sent, but not confirmed within the bounded wait. The bitmap makes the retry safe.              |
| `blockhash_expired`                          | yes       | The transaction can no longer land.                                                            |
| `fee_payer_underfunded`                      | yes       | The fee payer cannot pay fees or rent.                                                         |
| `recipient_account_failed`                   | yes       | The recipient's token account could not be created.                                            |
| `rpc_unavailable`, `rpc_invalid_response`    | yes       | The RPC endpoint failed or answered malformed data.                                            |
| `signer_unavailable`                         | yes       | KMS (or the local signer) could not sign.                                                      |
| `escrow_replaced`                            | yes       | Fewer releases on chain than recorded: a fresh escrow, or a lagging RPC node. Never paid from. |
| `refund_window_reached`                      | no        | `ReleaseWindowClosed`: the refund window opened.                                               |
| `escrow_closed`                              | no        | The escrow account is gone.                                                                    |
| `escrow_mismatch`, `arbiter_mismatch`        | no        | The escrow is not this pool's, or not Verily's arbiter's.                                      |
| `invalid_recipient`                          | no        | The wallet is not an address, or is the escrow itself.                                         |
| `payout_index_out_of_range`                  | no        | The index is outside the escrow.                                                               |
| `token_account_frozen`                       | no        | The vault or the recipient's token account is frozen (USDC has a freeze authority).            |
| `vault_underfunded`, `token_transfer_failed` | no        | SPL Token refused the transfer.                                                                |
| `release_rejected`                           | varies    | Any other rejection; retryable only for transaction-level errors.                              |

### Testing

- Unit tests (`verily_server/test/unit/rewards/solana_*`, `custody/`) run every
  method against an in-memory JSON-RPC endpoint behind the real `solana_kit`
  client, with no network. PDA and vault vectors come from Agave's Rust
  derivation (`solana find-program-derived-address`), and account and event
  bytes from the program crate's own `initialize`.
- `devenv shell test:escrow:e2e` builds the program, starts a throwaway
  `solana-test-validator` with it at its reviewed address and a test-controlled
  mint at the devnet USDC address, and runs the server end to end: startup
  verification, a creator-signed `OpenEscrow` confirmed from finalized state,
  two releases (one lost and retried, settled from the bitmap without paying
  twice), event attribution from the real logs, and `EndEarly`. `CloseEscrow`
  needs at least the three-day refund delay, so it stays in the Mollusk suite.

### Before devnet and before mainnet

Before devnet:

- Deploy the program with `pina deploy` and record the publication.
- Provision devnet arbiter and fee-payer keys (KMS for any shared
  deployment), fund the fee payer with devnet SOL, and choose an RPC
  provider.
- Wire the app's Mobile Wallet Adapter flow to sign and send the funding and
  end-early transactions, then call `confirmRewardFunding`.

Before mainnet:

- An external audit of the program, the gateway, and the custody setup.
- Production KMS keys (HSM protection level) provisioned, pinned, and covered
  by IAM that only the server's service account holds; the program's upgrade
  authority held by a reviewed multisig.
- A watcher that records every `EscrowClosed` final bitmap (so
  `isPayoutReleased` can settle payouts after a close) and compares every
  `PayoutReleased` event with the database by escrow address and index,
  alerting on any release the server did not record.
- Frozen-account handling: USDC's freeze authority can freeze a vault or a
  recipient account. Releases then fail with `token_account_frozen` and need an
  operator flow.
- Priority fees and compute-budget limits for congested slots, RPC redundancy,
  and fee-payer balance monitoring.
- Setting `VERILY_REWARD_MAINNET_ENABLED=true` only after that review.

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
