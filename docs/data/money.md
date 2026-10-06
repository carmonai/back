# Money

Carmonai sells prepaid credit, so the money model has one job: the number a customer sees must be the sum of
the events that produced it, exactly, forever. Everything here follows from that — the unit, the price table's
shape, where rounding is allowed to happen, and why the ledger refuses to be edited.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dmoney-title" aria-describedby="dmoney-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dmoney-title">A sealed window becoming ledger entries and a balance</title>
  <desc id="dmoney-desc">A sealed five-minute usage window goes to the billing debit job. The job reads the
  price row in effect at the window's start, prices the window once, and writes one ledger entry per
  organization, model and mode. The balance is updated in the same transaction, and when it is exhausted a
  flag is set in Valkey so the gateway answers that organization's next request with 402.</desc>

  <defs>
    <marker id="dmoney-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1 the window, 2 the price lookup, 3-5 the entry, the balance, the flag. -->
  <g id="dmoney-hops">
    <path id="dmoney-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M140 98 H170" marker-end="url(#dmoney-arrow)"/>
    <path id="dmoney-hop2" class="cmn-link cmn-link--quiet"
          d="M245 190 V126" marker-end="url(#dmoney-arrow)"/>
    <path id="dmoney-hop3" class="cmn-link cmn-link--flow cmn-dash"
          d="M300 98 H330" marker-end="url(#dmoney-arrow)"/>
    <path id="dmoney-hop4" class="cmn-link cmn-link--flow cmn-dash"
          d="M450 98 H480" marker-end="url(#dmoney-arrow)"/>
    <path id="dmoney-hop5" class="cmn-link cmn-link--flow cmn-dash"
          d="M590 98 H620" marker-end="url(#dmoney-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="dmoney-window"
     aria-labelledby="dmoney-window-label">
    <rect x="20" y="70" width="120" height="56" rx="10"/>
    <text id="dmoney-window-label" x="80" y="90">Sealed window</text>
    <text class="cmn-sub" x="80" y="108">5-minute sums</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dmoney-debit" aria-labelledby="dmoney-debit-label">
    <rect x="170" y="70" width="130" height="56" rx="10"/>
    <text id="dmoney-debit-label" x="235" y="90">debit job</text>
    <text class="cmn-sub" x="235" y="108">BillingService</text>
  </g>

  <g class="cmn-node cmn-node--money" id="dmoney-ledger" aria-labelledby="dmoney-ledger-label">
    <rect x="330" y="70" width="120" height="56" rx="10"/>
    <text id="dmoney-ledger-label" x="390" y="90">Ledger</text>
    <text class="cmn-sub" x="390" y="108">append-only</text>
  </g>

  <g class="cmn-node cmn-node--money" id="dmoney-balance" aria-labelledby="dmoney-balance-label">
    <rect x="480" y="70" width="110" height="56" rx="10"/>
    <text id="dmoney-balance-label" x="535" y="90">Balance</text>
    <text class="cmn-sub" x="535" y="108">same transaction</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dmoney-flag" aria-labelledby="dmoney-flag-label">
    <rect x="620" y="70" width="120" height="56" rx="10"/>
    <text id="dmoney-flag-label" x="680" y="90">no_credit</text>
    <text class="cmn-sub" x="680" y="108">Valkey → 402</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dmoney-price" aria-labelledby="dmoney-price-label">
    <rect x="170" y="190" width="150" height="56" rx="10"/>
    <text id="dmoney-price-label" x="245" y="210">Price row</text>
    <text class="cmn-sub" x="245" y="228">at the window's start</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M140 98 H170'); --cmn-travel: 0.8s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M245 190 V126'); --cmn-travel: 1.1s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="5"
          style="offset-path: path('M300 98 H330'); --cmn-travel: 0.8s; --cmn-delay: 0.55s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="5"
          style="offset-path: path('M450 98 H480'); --cmn-travel: 0.8s; --cmn-delay: 0.85s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M590 98 H620'); --cmn-travel: 0.8s; --cmn-delay: 1.1s;"></circle>

  <rect class="cmn-label-plate" x="96" y="46" width="118" height="16" rx="4"/>
  <text class="cmn-label" x="155" y="58">the next window</text>
  <rect class="cmn-label-plate" x="256" y="150" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="331" y="162">price at the window's start</text>
</svg>
</div>
<figcaption>Step 1 hands the debit job the next sealed window in cursor order; step 2 is the price lookup —
one row, the one in effect at the window's start, whatever rows were added after it. Steps 3 and 4 turn the
window into ledger entries and a new balance in one transaction; step 5 is the consequence, and the gateway
turns the organization's next request into a 402 while that flag is set.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a value travelling (solid)</span>
  <span><i class="is-money"></i> money moving (dashed, gold)</span>
  <span><i class="is-async"></i> a read, or a scheduled pass (dotted)</span>
</div>

1. **Usage windows are sealed by arrival time**, and billing pulls the next one after its cursor.
2. **The job reads the price in effect at the window's start** — `Price.at`, the latest `effective_from` that
   is not after `windowStart`. A price added later never re-prices an earlier window.
3. **The window is priced once per organization, model and mode**, in exact `long` arithmetic, rounded half up
   exactly once.
4. **One ledger entry per charge is inserted, and the balance moves in the same transaction**, with the cursor
   advance. A window is billed entirely or not at all.
5. **If `balance + credit_limit ≤ 0`, the job sets `no_credit:{org}` in Valkey** — no TTL, cleared by the next
   grant or by the reconciliation. The gateway answers **402** `insufficient_balance` while it is set.
6. **Every 10 minutes, `reconcile()` compares each balance with the sum of its ledger** and re-syncs every
   flag. It reports; it never repairs.

## What it is

Money is an integer count of micro-BRL moved by append-only rows: one price table, one ledger, one balance per
organization, and one implementation of the arithmetic — `Price`, in the `billing` **library**, so
billing-service and usage-service cannot drift apart on it.

## The unit is a bigint, never a float

`1 BRL = 1,000,000` micro-BRL, and every amount in the `billing` schema is `BIGINT`: the three price columns,
`ledger_entry.amount`, `balance.amount` and `balance.credit_limit`. A `double` cannot hold `0.1 + 0.2` exactly,
and a money system that stores one has to decide, somewhere, which comparison is allowed to be approximate.
Rather than make that decision, storage is an integer and `Price.cost` is integer arithmetic with the overflow
checks on: the three token counts are multiplied by their prices with `multiplyExact`, added with `addExact`,
and divided by a million once. `multiplyExact` throws instead of wrapping — a token count large enough to
overflow a `long` at these prices is not a rounding question, it is a bug, and the cost is to fail loudly.
`NUMERIC` would also have been exact; it was not used because these values are integers by construction, and a
decimal type invites a scale to be chosen per column, which is the drift this design avoids.

## A price is a row with an effective-from instant

`price` is keyed `(model, mode, effective_from)` — a history, not a current-value table. Changing a price
inserts a row, and the newest row whose `effective_from` is not after the window's start is the one that
applies; `Price.at` implements that rule once, for the debit job that charges with it and the customer summary
that explains the charge. Two triggers keep the history honest: `refuse_change()` makes `price` append-only
like the ledger, and `refuse_past_price()` refuses an `INSERT` whose `effective_from` is not in the future, so
a price cannot be back-dated into a window already billed.

The seeded prices are **placeholders, not commercial ones**, in BRL per million tokens (input / cached input /
output): `carmonai/qwen3-0.6b` sync 0.10 / 0.05 / 0.40, `carmonai/qwen3-4b` sync 0.50 / 0.25 / 2.00, and half
of each for the `batch` mode.

## Rounding happens once, per window

`cost()` rounds half up — `floorDiv(scaled + 500_000, 1_000_000)` — and is called exactly once per
(organization, model, mode) per window, after the tokens of every API key in that window have been summed.
Rounding per event and then adding would accumulate a fraction of a micro-BRL per request, and the balance
would stop being the sum of anything anyone can reconstruct. Cached input is a subset of input, not an
addition: the formula charges `(input − cached) × input_price + cached × cached_price`, and the
`cached_input_tokens BETWEEN 0 AND input_tokens` check constraint keeps that subtraction from needing a guard.

The honest edge is the customer summary, which prices per (model, mode, UTC day) rather than per window,
because one row per 5-minute window is 267k rows a month at the prototype's window size. Per-day rounding can
differ from the per-window charge by under one micro-BRL, and a price that changed inside a day misprices that
day's earlier tokens. The ledger stays exact either way; the summary is an explanation, not the books.

## The ledger is append-only, enforced by the database

`ledger_entry` and `price` carry `BEFORE UPDATE OR DELETE … FOR EACH ROW` and `BEFORE TRUNCATE … FOR EACH
STATEMENT` triggers calling `refuse_change()`, which raises. A correction is a new entry of type `refund` or
`adjustment`, never an edit. The trigger is on the table, so it applies to a migration, a `psql` session and a
future service alike — a convention that only holds in Java is not a guarantee.

**What it does not protect.** The trigger runs for the application's own database user, which can
`ALTER TABLE … DISABLE TRIGGER`; there is one role in the prototype, so the ledger is protected against
mistakes and not against a determined operator. And a trigger cannot tell a correct entry from an incorrect
one — a wrong amount, inserted once, is append-only history forever, which is what the reconciliation is for.
`idempotency_key` is `UNIQUE` and the insert is `ON CONFLICT (idempotency_key) DO NOTHING RETURNING id`, so a
replayed key writes nothing; a usage entry's key is `usage:{organizationId}:{model}:{mode}:{windowStart}`.

## The balance moves in the same transaction

The cursor row is taken with `FOR UPDATE`, so two replicas take turns billing, and the cursor is re-read inside
that lock: an instance that lost the race sees a different value and writes nothing. The balance is updated by
an upsert — `ON CONFLICT (organization_id) DO UPDATE SET amount = balance.amount + EXCLUDED.amount` — which
takes the row lock and serialises concurrent writers, so there is no `version` column. Entries, balance updates
and the cursor move all happen in one `transaction.execute`; a window is billed entirely or not at all. The
ledger is the truth and the balance is a cache of it, which is acceptable only because the two are written
together: if the transaction rolls back, both do.

## Reconciliation: a balance against the sum of its ledger

`ledgerBalances()` joins `balance` to the per-organization sum of `ledger_entry` with a **`FULL OUTER JOIN`**,
and that is the load-bearing part. A `balance` row is written in the same transaction as its first ledger
entry, so entries without a balance row can only be a torn state — a stray `DELETE`, a partial restore. An
inner or `LEFT JOIN` would report nothing for exactly that case; the outer join makes it a row that reads 0
against a real ledger sum and fails the check.

`reconcile()` runs every `carmonai.billing.reconcile-every` (10 minutes; compose runs the debit job every 2 s
rather than 60 s so billing is visible within seconds). It re-syncs every `no_credit` flag, logs the
organizations whose balance differs from their ledger at ERROR with ids only, and **fixes nothing** — an
automatic repair would erase the evidence of whatever produced the drift. Ask on demand at
`GET /actuator/reconcile` on billing's management port (8081, never published, never routed), or run
[revenue-check.sh](https://github.com/carmonai/back/blob/main/docker/revenue-check.sh), which calls it from
inside the compose network and exits non-zero so cron or CI can fail on drift.

## Why it is like this

**One arithmetic, in the library.** The summary a customer reads is computed by the same code that charged
them. The alternative — a second implementation, or a SQL-shaped one — is how a customer ends up able to
reproduce every number except the one on the invoice.

**A missing price stops billing rather than billing at zero.** `costs()` throws `MissingPriceException` before
anything is written and the job logs it at ERROR, so the window stays unbilled and the cursor does not move;
it is billed correctly the moment a price row exists. Billing at zero and reconciling later turns a
configuration mistake into revenue that has silently disappeared.

**The flag, not the balance, is what the gateway reads.** A balance read on the request path would be a
database round trip per request and would make the 402 depend on the database being up. The cost is that a
grant and a flag can disagree for a moment, which is why the customer-facing balance endpoint returns
`noCredit` next to the amount.

## What would change it

- **A shared database, or a second role.** Two roles turn "append-only by convention plus a trigger" into
  "append-only because the writer cannot do anything else".
- **A price change that must apply mid-day.** The summary prices per UTC day, so a mid-day change misprices
  that day's earlier tokens *in the summary*. Per-window pricing is the upgrade.
- **A payment rail.** Credit arrives from a staff grant (`POST /billing/grants`, idempotent by
  `idempotencyKey`, at most R$1,000,000 a call); the PSP choice is an open decision.
- **More than a hundred windows behind.** `MAX_WINDOWS_PER_RUN = 100` bounds one debit run, so a backlog
  drains over several runs rather than in one long transaction.

## Where to look

- [billing V2026.10.03.001](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql)
  — the four tables, the seeded placeholder prices, and both triggers.
- [Price.java](https://github.com/carmonai/back/blob/main/api/billing/src/main/java/ai/carmonai/billing/Price.java)
  — the unit, `cost()`'s rounding, and `at()`, the rule both services share.
- [BillingService.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingService.java)
  — one window, one transaction, the cursor, and `reconcile()`.
- [BillingRepository.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingRepository.java)
  — the idempotent insert, the balance upsert and the `FULL OUTER JOIN`.
