# Phase 4 progress (money)

Working log started 2026-10-03. Plan: [inference-plan.md](inference-plan.md) §4 (metering and money), §11 row 4; metering review in [plan-review-2026-10-02.md](plan-review-2026-10-02.md). Rules: `phase-4` branches only (`usage`, `usage-service`, `gateway-service`, `billing`, `billing-service`, `back`); commit and push when green; PRs at the end; never merge or push to `main` without the user's go-ahead. New repos `billing`, `billing-service` must be added to `CARMONAI_TOKEN` by the user.

## Checklist

- [x] Repos `billing`, `billing-service` created, submodules added, `phase-4` branches
- [x] `usage` library + usage-service: internal `GET /usage/windows/next?after=` (all rows of the next sealed window), IT
- [x] `billing` library: `BillingController` (internal `POST /billing/grants`), `GrantIn`, `BalanceOut`, `UsageWindowOut` stays in `usage`
- [x] billing-service: schema `billing` (price, ledger_entry, balance, billing_cursor), seeded prototype prices, append-only triggers, DebitJob, grant, flag sync to Valkey, reconciliation; `BillingServiceIT` + cost unit test
- [x] gateway: `no_credit:{org}` flag → 402 on `/v1` (OpenAI shape, code `insufficient_balance`)
- [x] compose: `billing` service; short windows for the prototype (usage window 10 s, grace 2 s, seal every 2 s; debit every 2 s)
- [x] smoke: credit grant via an internal call, balance drops after usage, a second org drains a tiny grant → 402 → grant → 200; erasure section closes both orgs
- [x] `mvn clean verify` + CPU smoke green; logs clean
- [x] Docs: plan progress/deviations, skills, templates
- [x] Commit + push, PRs with merge order (libraries → services → back)

## Design decisions (keep consistent when resuming)

- **Money is `bigint` micro-BRL** (1 BRL = 1,000,000). Prices are micro-BRL per million tokens. Cost per window and (org, model, mode): `uncached = input − cached`; `Σ multiplyExact(tokens_k, price_k)`, divided by 1,000,000 with round-half-up, once per window. Zero-cost windows write nothing.
- **Prices** `price(model, mode, effective_from, input, cached_input, output)`: a window uses the price in effect at its start; append-only (trigger); new rows need `effective_from > now()` (trigger, installed after the seed). Seeded **placeholder** prices (not commercial): qwen3-0.6b sync 0.10 / 0.05 / 0.40 BRL per M tokens (input / cached / output); qwen3-4b sync 0.50 / 0.25 / 2.00.
- **Ledger** `ledger_entry(id, organization_id, amount, type, reference, idempotency_key UNIQUE, created_at)`; types grant, usage, refund, adjustment, top_up; **UPDATE/DELETE refused by a trigger** (instead of two DB roles: same guarantee without a second credential while the prototype shares one DB user; roles when a shared DB exists). Ids only, no personal data: kept for tax, never erased.
- **Balance** `balance(organization_id PK, amount, credit_limit default 0)`, updated in the ledger insert's transaction with `ON CONFLICT DO UPDATE SET amount = balance.amount + …` (row lock serialises writers; no version column).
- **DebitJob** (every `carmonai.billing.debit-every`): cursor `billing_cursor.last_window_start`; asks usage-service for the next sealed window after it; one transaction per window: for each (org, model, mode) insert the usage entry (`usage:{org}:{model}:{mode}:{window_start}`, `ON CONFLICT DO NOTHING RETURNING id`), update the balance only if inserted, advance the cursor. A missing price stops the job before writing (ERROR log, never bills at zero). After commit, sync the flags of the touched orgs.
- **Flag** `no_credit:{org}` in Valkey, no TTL: set when `amount + credit_limit ≤ 0` (floor 0, decided), deleted otherwise. Set after debits and grants; a reconciliation pass (every 10 min) re-syncs every flag and checks `balance = Σ ledger` (ERROR on mismatch, ids only). New orgs have no balance row and no flag until their first debit.
- **Grant** (internal, no gateway route): `POST /billing/grants {organizationId, amountMicroBrl > 0, reason, idempotencyKey}` → ledger `grant` + balance + flag; replaying the key returns the same balance without a second entry. Staff tooling later.
- **Gateway**: after the API key resolves, `no_credit:{org}` present → 402 `insufficient_balance` (not OpenAI's 429: SDKs retry 429). Valkey down → 503 as before.
- **No customer-facing balance endpoint yet** (no console): the smoke test reads balances with psql. Deviation to record.
- **Prototype windows**: compose runs 10 s windows (2 s grace) so billing is visible within seconds; the defaults stay 5 min / 60 s.

## Notes

- `@DateTimeFormat(iso = DATE_TIME)` on an `Instant` `@RequestParam` breaks the Feign client side (`UnsupportedTemporalTypeException`: Feign formats the Instant through the annotation, which needs a zone). Without it both sides use `Instant.toString()`/`Instant.parse`. Recorded in templates pitfalls.
- 2026-10-03: `mvn clean verify` green (billing-service: `PriceTest` 3, `BillingServiceIT` 6; usage-service IT 4 incl. next-window); CPU smoke green: R$10 grant, usage billed (balance 10,000,000 → 9,999,989 micro-BRL), balance = Σ ledger, a 1 micro-BRL org gets 402 after its first debit and 200 after a grant; canary absent from every log and the DB dump. Only WARNs in logs: Lettuce reconnects during the Valkey fail-closed step and the gateway's pre-existing validator notices.
