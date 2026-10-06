# Billing

## What it is

`billing-service` owns the `billing` schema and turns a sealed usage window into money. It holds the price
list, an append-only ledger, a running balance per organization, and the one flag the gateway reads before it
lets an organization spend anything.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="bill-title" aria-describedby="bill-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="bill-title">A sealed window priced into ledger entries, a balance, and the credit flag</title>
  <desc id="bill-desc">Billing pulls the next sealed usage window, prices it with the row in effect at the
  window's start, writes one ledger entry per organization, model and mode, adds the total to the balance in
  the same transaction, and sets the no_credit flag when the balance is used up. A reconciliation compares
  every balance with the sum of its ledger.</desc>
  <defs>
    <marker id="bill-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="bill-arrow-money" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: the window pulled, priced, written, summed, then the flag and the check. -->
  <g id="bill-hops">
    <path id="bill-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M158 68 H204" marker-end="url(#bill-arrow-flow)"/>
    <path id="bill-hop2" class="cmn-link cmn-link--money cmn-dash" d="M340 68 H386" marker-end="url(#bill-arrow-money)"/>
    <path id="bill-hop3" class="cmn-link cmn-link--money cmn-dash" d="M522 68 H572" marker-end="url(#bill-arrow-money)"/>
    <path id="bill-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M640 96 V130 H100 V176" marker-end="url(#bill-arrow-flow)"/>
    <path id="bill-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M454 96 V176" marker-end="url(#bill-arrow-flow)"/>
  </g>
  <g class="cmn-node cmn-node--entry cmn-node--flow" id="bill-window" aria-labelledby="bill-window-label"><rect x="20" y="40" width="138" height="56" rx="10"/><text id="bill-window-label" x="89" y="60">Sealed window</text><text class="cmn-sub" x="89" y="78">usage-service</text></g>
  <g class="cmn-node cmn-node--flow" id="bill-prices" aria-labelledby="bill-prices-label"><rect x="204" y="40" width="136" height="56" rx="10"/><text id="bill-prices-label" x="272" y="60">Prices</text><text class="cmn-sub" x="272" y="78">at the window's start</text></g>
  <g class="cmn-node cmn-node--money" id="bill-ledger" aria-labelledby="bill-ledger-label"><rect x="386" y="40" width="136" height="56" rx="10"/><text id="bill-ledger-label" x="454" y="60">Ledger</text><text class="cmn-sub" x="454" y="78">append-only</text></g>
  <g class="cmn-node cmn-node--money" id="bill-balance" aria-labelledby="bill-balance-label"><rect x="572" y="40" width="136" height="56" rx="10"/><text id="bill-balance-label" x="640" y="60">Balance</text><text class="cmn-sub" x="640" y="78">one transaction</text></g>
  <g class="cmn-node cmn-node--soft" id="bill-flag" aria-labelledby="bill-flag-label"><rect x="20" y="176" width="160" height="56" rx="10"/><text id="bill-flag-label" x="100" y="196">no_credit flag</text><text class="cmn-sub" x="100" y="214">read by the gateway</text></g>
  <g class="cmn-node cmn-node--flow" id="bill-reconcile" aria-labelledby="bill-reconcile-label"><rect x="386" y="176" width="136" height="56" rx="10"/><text id="bill-reconcile-label" x="454" y="196">Reconcile</text><text class="cmn-sub" x="454" y="214">FULL OUTER JOIN</text></g>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M158 68 H204'); --cmn-travel: 0.9s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="4.5" style="offset-path: path('M340 68 H386'); --cmn-travel: 0.9s; --cmn-delay: 0.25s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="4.5" style="offset-path: path('M522 68 H572'); --cmn-travel: 0.9s; --cmn-delay: 0.5s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M640 96 V130 H100 V176'); --cmn-travel: 1.4s; --cmn-delay: 0.85s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M454 96 V176'); --cmn-travel: 0.9s; --cmn-delay: 1.15s;"></circle>
  <rect class="cmn-label-plate" x="160" y="46" width="42" height="16" rx="4"/><text class="cmn-label" x="181" y="58">priced</text>
  <rect class="cmn-label-plate" x="342" y="46" width="42" height="16" rx="4"/><text class="cmn-label" x="363" y="58">written</text>
  <rect class="cmn-label-plate" x="526" y="46" width="42" height="16" rx="4"/><text class="cmn-label" x="547" y="58">summed</text>
  <rect class="cmn-label-plate" x="313" y="136" width="64" height="16" rx="4"/><text class="cmn-label" x="345" y="148">exhausted</text>
  <rect class="cmn-label-plate" x="460" y="136" width="70" height="16" rx="4"/><text class="cmn-label" x="495" y="148">compared</text>
</svg>
</div>
<figcaption>A sealed window is pulled by a cursor and priced with the price row in effect at the window's
start. One ledger entry is written per organization, model and mode, and the balance moves with them in the
same transaction — after which the credit flag is re-synced. Separately, a reconciliation compares every
balance with the sum of its ledger and never repairs one.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the window travelling, and the check (solid)</span>
  <span><i class="is-money"></i> money: entries written and the balance moved (dashed, gold)</span>
</div>

1. **Billing pulls the next sealed window.** It asks usage-service for everything starting after its cursor, so
   windows are billed in order and each one once.
2. **The window is priced**, with the price row in effect at the window's *start* — a later price change cannot
   move an old bill.
3. **One ledger entry per (organization, model, mode) is written**, under an idempotency key that contains the
   window's start, so a re-run writes nothing.
4. **The balance is updated in the same transaction as those entries**, and the cursor moves with them: a
   window is billed entirely or not at all.
5. **The flag follows the balance.** When `amount + credit_limit ≤ 0`, `no_credit:{organization}` is set and
   the gateway answers 402 on the next request.
6. **A reconciliation compares every balance with the sum of its ledger** and re-syncs every flag. It reports;
   it does not repair.

## Prices

```sql
CREATE TABLE price (
    model VARCHAR(128) NOT NULL, mode VARCHAR(8) NOT NULL CHECK (mode IN ('sync', 'batch')),
    effective_from TIMESTAMPTZ NOT NULL, PRIMARY KEY (model, mode, effective_from),
    input_per_million        BIGINT NOT NULL CHECK (input_per_million >= 0),
    cached_input_per_million BIGINT NOT NULL CHECK (cached_input_per_million >= 0),
    output_per_million       BIGINT NOT NULL CHECK (output_per_million >= 0));
```

Amounts are micro-BRL per million tokens (`1 BRL = 1,000,000`), and the seeded values are prototype
placeholders, not commercial ones: `carmonai/qwen3-0.6b` at 0.10 / 0.05 / 0.40 and `carmonai/qwen3-4b` at
0.50 / 0.25 / 2.00 (input / cached input / output), batch at half the sync price, from a second migration.

The arithmetic lives in the **library**, as `Price`, because both sides of the money need it: billing-service
bills a window with it, and usage-service explains the charge to the customer with it. `Price.cost` is exact
`long` arithmetic — `Math.addExact` and `Math.multiplyExact`, so overflow throws rather than wrapping —
rounded half up exactly once, and `Price.at` picks the latest `effective_from` that is not after the instant
asked about.

Two triggers guard the table. The first refuses `UPDATE`, `DELETE` and `TRUNCATE`. The second,
`price_starts_in_the_future`, refuses an insert whose `effective_from` is not in the future, so a price can
never be back-dated onto a window already billed. The batch seed turns that trigger off for its own insert and
back on, inside the migration's transaction.

## The ledger

```sql
CREATE TABLE ledger_entry (
    id UUID PRIMARY KEY, organization_id VARCHAR(36) NOT NULL,
    amount BIGINT NOT NULL CHECK (amount <> 0),
    type VARCHAR(16) NOT NULL CHECK (type IN ('grant', 'usage', 'refund', 'adjustment', 'top_up')),
    reference VARCHAR(256) NOT NULL, idempotency_key VARCHAR(256) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now());
```

**Append-only is enforced by the database, not by convention.** A `refuse_change()` trigger raises on `UPDATE`,
`DELETE` and `TRUNCATE` for `ledger_entry` and for `price`, so no code path — not a bug, not a migration, not a
psql session — can rewrite history. A correction is a new entry of type `adjustment`.

Every write goes through `insertEntry`, which is one statement:

```sql
INSERT INTO ledger_entry (...) VALUES (...)
ON CONFLICT (idempotency_key) DO NOTHING RETURNING id
```

An empty result means the key was already used, so nothing was written and the caller must not move the
balance. The keys make replays harmless: usage entries use
`usage:{organizationId}:{model}:{mode}:{windowStart}`, and grants use `grant:{organizationId}:{idempotencyKey}`.
`amount <> 0` is a constraint because a zero entry is a bug, not a fact — and `costs(...)` skips a zero cost
before it gets that far.

## Billing one window

`BillingJobs.debit` runs every `carmonai.billing.debit-every` (60 s) and calls `BillingService.debit()`, which
bills at most `MAX_WINDOWS_PER_RUN = 100` windows per run. For each window, `debitNextWindow()`:

1. reads the cursor — the last billed `window_start` — and asks usage-service for the rows of the first sealed
   window after it, stopping if there are none;
2. sums the tokens per `(organization, model, mode)` **across API keys**, so one organization's window becomes
   one entry per model and mode rather than one per key;
3. looks up `priceAt(model, mode, windowStart)` for each — and throws `MissingPriceException` if there is none,
   **before anything has been written**;
4. opens a transaction, re-reads the cursor `FOR UPDATE` and abandons the window if another instance already
   billed it, then writes every entry, updates every touched balance, and moves the cursor;
5. re-syncs the credit flag for every balance it touched, after the commit.

The consequence of step 3 is the rule worth remembering: **a missing price stops billing, it never bills at
zero.** `BillingJobs` logs that as an ERROR to act on, because a missing price is a configuration mistake; any
other failure is a WARN, and the next run picks up from the same cursor.

Step 4's balance update is a single upsert — `INSERT ... ON CONFLICT (organization_id) DO UPDATE SET
amount = balance.amount + EXCLUDED.amount` — which creates the row at zero on the first movement and takes the
row lock that serialises concurrent writers. Because the entry, the balance and the cursor are in one
transaction, a window is billed entirely or not at all, and a rerun after a crash changes nothing.

## The flag, and the 402

`CreditFlags.sync(balance)` writes `no_credit:{organizationId}` when the balance is exhausted and deletes it
when it is not. `Balance.exhausted()` is `amount + credit_limit <= 0`; `credit_limit` defaults to 0, so a
prepaid organization is out of credit at exactly zero.

The key has **no TTL**, and that is the point: it is state, not a cache. Its whole purpose is to keep the money
decision off the request path — the gateway reads one Valkey key after resolving an API key, and this service
is not called at all. The gateway turns its presence into 402 with OpenAI's `insufficient_quota` type and the
code `insufficient_balance`: deliberate rather than a retryable 429, because retrying cannot add credit. The
flag and the balance can disagree until the reconciliation re-syncs it, and `BalanceOut.noCredit` reports what
the gateway will do, not what the arithmetic says.

## Grants

`POST /billing/grants` is internal — no gateway route, and staff tooling will be its caller.
`GrantIn(organizationId, amountMicroBrl, reason, idempotencyKey)` with the amount between 1 and
1,000,000,000,000 micro-BRL. It writes one `grant` entry and moves the balance in one transaction, and a
replayed `idempotencyKey` returns the balance without a second entry. There is no payment rail behind it.

## Reconciliation

```sql
FROM balance b
FULL OUTER JOIN (SELECT organization_id, sum(amount) AS total FROM ledger_entry GROUP BY organization_id) l
    ON l.organization_id = b.organization_id
```

The `FULL OUTER JOIN` is the load-bearing part of that query, not a stylistic choice. A balance row is written
in the same transaction as its first ledger entry, so "ledger entries but no balance row" is a torn state — a
stray `DELETE`, a partial restore. An inner join would make exactly that case invisible; the outer join returns
it as a balance of 0 against its real ledger sum, which fails the check, and the flag sync that follows stops
spending for it instead of quietly allowing it.

`reconcile()` reads every row of that join, re-syncs every flag, and logs an ERROR naming each organization
whose balance differs from its ledger. It **never repairs a balance** — an automatic correction would hide the
bug that caused the drift. It runs every `carmonai.billing.reconcile-every` (10 minutes) and on demand at
`GET /actuator/reconcile`, on the management port (8081) only and never routed: it returns the counts plus up
to `MAX_CHECKS = 100` rows, drifted first. `docker/revenue-check.sh` runs the same comparison and exits
non-zero when the books disagree, which is what makes this a check rather than a dashboard.

## Why it is like this

**Append-only by trigger rather than by convention.** A rule that lives in a document is a rule a future
migration can break by accident. A trigger cannot be forgotten, and its cost is named below.

**Prices are history, not configuration.** Pricing a window at the row in effect at its start is what makes a
price change safe: yesterday's bill does not move, and a back-dated price is refused outright.

**One window, one transaction.** Entries, balances and the cursor move together, so the ledger and the balance
cannot disagree because of a crash between them — the drift the reconciliation exists to catch. And the money
decision lives in Valkey, because a balance check on the request path would put this service in front of every
token generated.

## What would change it

- **The append-only triggers hold for one database role.** Anything connecting as the owner can drop them;
  separate roles per service, with no `UPDATE`/`DELETE` grant on these tables, are what makes it real.
- **There is no payment rail.** Credit arrives through a staff grant; a customer topping up needs a provider, a
  webhook and a reconciliation against it.
- **A run bills at most 100 windows**, which is ample at five-minute windows and would not be at one-second
  windows and a backlog, and **the flag can be stale by up to one reconciliation period** if a balance is
  changed by something other than the two paths that call `sync`.

## Where to look

- [create_tables.sql](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql) — prices, the ledger, the balance and the triggers.
- [BillingService.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingService.java) — one window, one transaction, and the missing-price stop.
- [BillingRepository.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingRepository.java) — the idempotent insert, the balance upsert and the outer join.
- [CreditFlags.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/CreditFlags.java) — the flag the gateway reads.
- [Price.java](https://github.com/carmonai/back/blob/main/api/billing/src/main/java/ai/carmonai/billing/Price.java) — the one arithmetic both sides of the money use.
