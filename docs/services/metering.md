# Metering

## What it is

`usage-service` owns the `usage` schema and turns finished requests into a number that can be billed. It
receives events from inference-service, stores them in daily partitions, seals arrival-time windows of five
minutes into permanent totals, and hands those totals to billing in order.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="usage-title" aria-describedby="usage-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="usage-title">An event stored in a daily partition, and sealed into a five-minute window</title>
  <desc id="usage-desc">A relay posts events to usage-service, which stores them in a daily partition of
  usage_event. A seal job sums whole five-minute windows by arrival time after a grace period and writes
  them to usage_window, which billing pulls in order; partitions older than 90 days are dropped.</desc>
  <defs>
    <marker id="usage-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="usage-arrow-quiet" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: the batch in, the row stored, the seal, the sealed total, the pull, the prune. -->
  <g id="usage-hops">
    <path id="usage-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M140 68 H190" marker-end="url(#usage-arrow-flow)"/>
    <path id="usage-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M360 68 H410" marker-end="url(#usage-arrow-flow)"/>
    <path id="usage-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M560 68 H610" marker-end="url(#usage-arrow-flow)"/>
    <path id="usage-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M675 96 V140 H550 V176" marker-end="url(#usage-arrow-flow)"/>
    <path id="usage-hop5" class="cmn-link cmn-link--money cmn-dash" d="M560 204 H610" marker-end="url(#usage-arrow-flow)"/>
    <path id="usage-hop6" class="cmn-link cmn-link--quiet" d="M485 96 V140 H95 V176" marker-end="url(#usage-arrow-quiet)"/>
  </g>
  <g class="cmn-node cmn-node--entry cmn-node--soft" id="usage-relay" aria-labelledby="usage-relay-label"><rect x="20" y="40" width="120" height="56" rx="10"/><text id="usage-relay-label" x="80" y="60">Relay</text><text class="cmn-sub" x="80" y="78">inference-service</text></g>
  <g class="cmn-node cmn-node--flow" id="usage-ingest" aria-labelledby="usage-ingest-label"><rect x="190" y="40" width="170" height="56" rx="10"/><text id="usage-ingest-label" x="275" y="60">Ingest</text><text class="cmn-sub" x="275" y="78">POST /usage/events, 1 to 1000</text></g>
  <g class="cmn-node cmn-node--flow" id="usage-event" aria-labelledby="usage-event-label"><rect x="410" y="40" width="150" height="56" rx="10"/><text id="usage-event-label" x="485" y="60">usage_event</text><text class="cmn-sub" x="485" y="78">one daily partition</text></g>
  <g class="cmn-node cmn-node--flow" id="usage-seal" aria-labelledby="usage-seal-label"><rect x="610" y="40" width="130" height="56" rx="10"/><text id="usage-seal-label" x="675" y="60">SealJob</text><text class="cmn-sub" x="675" y="78">every 60 s</text></g>
  <g class="cmn-node cmn-node--soft" id="usage-pruned" aria-labelledby="usage-pruned-label"><rect x="20" y="176" width="150" height="56" rx="10"/><text id="usage-pruned-label" x="95" y="196">Dropped</text><text class="cmn-sub" x="95" y="214">past 90 days</text></g>
  <g class="cmn-node cmn-node--flow" id="usage-window" aria-labelledby="usage-window-label"><rect x="410" y="176" width="150" height="56" rx="10"/><text id="usage-window-label" x="485" y="196">usage_window</text><text class="cmn-sub" x="485" y="214">five minutes, sealed</text></g>
  <g class="cmn-node cmn-node--money" id="usage-billing" aria-labelledby="usage-billing-label"><rect x="610" y="176" width="130" height="56" rx="10"/><text id="usage-billing-label" x="675" y="196">Billing pulls</text><text class="cmn-sub" x="675" y="214">in cursor order</text></g>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M140 68 H190'); --cmn-travel: 0.9s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M360 68 H410'); --cmn-travel: 0.9s; --cmn-delay: 0.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M560 68 H610'); --cmn-travel: 0.9s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M675 96 V140 H550 V176'); --cmn-travel: 1.3s; --cmn-delay: 0.5s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="4.5" style="offset-path: path('M560 204 H610'); --cmn-travel: 0.9s; --cmn-delay: 0.8s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M485 96 V140 H95 V176'); --cmn-travel: 1.5s; --cmn-delay: 1.1s;"></circle>
  <rect class="cmn-label-plate" x="144" y="46" width="42" height="16" rx="4"/><text class="cmn-label" x="165" y="58">batch</text>
  <rect class="cmn-label-plate" x="392" y="108" width="88" height="16" rx="4"/><text class="cmn-label" x="436" y="120">after 90 days</text>
  <rect class="cmn-label-plate" x="567" y="182" width="42" height="16" rx="4"/><text class="cmn-label" x="588" y="194">cost</text>
</svg>
</div>
<figcaption>Events arrive in batches from the relay and are stored in the day's partition. A seal job sums
whole five-minute windows by arrival time, a grace period after they end, and writes them as permanent totals;
billing reads those totals in order. The raw events are dropped once they are ninety days old, because the
windows already hold what was billed.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> data travelling inward, then to billing (solid)</span>
  <span><i class="is-async"></i> the scheduled retention job (dotted)</span>
  <span><i class="is-money"></i> what billing reads as money (dashed, gold)</span>
</div>

1. **The relay posts a batch of events** — at most 1000 — to `POST /usage/events`, which answers 202 once they
   are stored.
2. **The whole batch is validated first.** One bad event rejects the batch with 400 and stores nothing.
3. **Each event lands in the day's partition** of `usage_event`, keyed by `(event_id, started_at)`, so a
   resend is a duplicate rather than a second row.
4. **`SealJob` sums complete windows.** Every 60 s it takes every whole five-minute window that ended at least
   60 s ago and writes one row per `(organization, API key, model, mode)` into `usage_window`.
5. **Billing pulls the sealed rows** in cursor order, so a window is billed once and in sequence.
6. **`PartitionJob` drops raw partitions older than 90 days**, which loses no money: the sealed windows keep
   the totals.

## Ingestion, and what idempotent means here

`POST /usage/events` takes a list of 1 to 1000 events. `UsageService.record` validates **every** event in the
batch before inserting any of them: a single bad one rejects the whole request with 400 and the table is
untouched. The insert is then a batch insert.

Idempotency is the primary key, not a dedupe table: `PRIMARY KEY (event_id, started_at)` on a table
`PARTITION BY RANGE (started_at)`. Because `started_at` is fixed for a given event — for a batch line it is the
batch's creation time — a resend lands in the same partition and collides on the same key. The relay can
therefore retry as naively as it likes.

A `DEFAULT` partition exists as a safety net, so an event whose timestamp falls outside every daily partition
still lands instead of failing the batch. Partitions are created a week ahead, so that should never be needed.

Validation is narrow and explicit: `eventId` must parse as a UUID; `requestId` (≤ 64), `organizationId`
(≤ 36), `apiKeyId` (≤ 36) and `model` (≤ 128) must be non-blank; `mode`, `tier` and `status` must be one of the
known words; token counts must be non-negative with `cachedInputTokens ≤ inputTokens`; `startedAt` must be
present, `durationMs` non-negative and `ttftMs` either absent or non-negative.

## What an event carries

| Field | Example | Note |
|---|---|---|
| `eventId` | a UUID | name-based for a batch line, so a re-run is one event |
| `requestId` | a UUID | the gateway's, the same one in the access log |
| `organizationId`, `apiKeyId` | ids | who spent |
| `model`, `mode`, `tier` | `carmonai/qwen3-4b`, `sync`, `standard` | `mode` is `sync` or `batch` |
| `inputTokens` | 812 | includes the cached ones |
| `cachedInputTokens` | 640 | priced separately |
| `outputTokens` | 233 | what the customer read |
| `status` | `ok` | `ok`, `error` (ours, not billed), `cancelled` |
| `startedAt`, `ttftMs`, `durationMs` | instants and milliseconds | latency, not content |

And what it deliberately never carries: **no prompt, no answer, no client address, no headers.** The columns
are ids, counts and timings, and the three word columns are `CHECK`-constrained so a typo becomes a rejected
batch rather than a row that breaks the pricing. This is the platform's standing rule rather than a
preference — ids and counts only, and a smoke test greps every log, the access log and a database dump for a
canary string to prove it.

## Partitions and retention

`PartitionJob` runs at startup and then daily at 00:05 UTC. It creates one partition per day from yesterday to
seven days ahead, and drops any partition older than 90 days. A Postgres advisory lock (`7514215`) means only
one instance does the work; the rest return immediately.

Ninety days of raw events is what the retention rule asks for, and dropping a partition is one statement rather
than a delete that has to find rows. The totals survive it: `usage_window` is not partitioned and holds what
billing actually consumed. The code notes the one way this can fail: if a row is already sitting in the
`DEFAULT` partition for a day being created, Postgres refuses to attach the new partition and the whole run
fails — which takes a badly wrong clock, and would need the rows moved by hand.

## Sealing by arrival

`SealJob` turns events into money. Its settings are `carmonai.usage.window` (5 minutes),
`carmonai.usage.grace` (60 seconds) and `carmonai.usage.seal-every` (60 seconds); the compose stack uses 10
second windows and a 2 second grace so billing shows up within seconds of a request.

The rule is: **every whole window that ended at least `grace` ago is summed once.** In one transaction it locks
the single row of `usage_seal`, reads `sealed_until` as `from`, computes `to = floor(now - grace)`, writes the
windows in `[from, to)` and moves `sealed_until` to `to`. Windows are aligned to
`date_bin(window, t, TIMESTAMPTZ '2000-01-01')`, so they are stable across instances and restarts.

**By arrival time, not by event time.** The seal reads `received_at`. A late event therefore falls into the
next open window instead of reopening a closed one — and that matters more than it looks: a sealed window has
already been billed, so reopening one would mean billing it twice or correcting a ledger that is append-only
by database trigger. The cost is that a request's cost lands in the window it was *reported* in, not the one it
started in.

The row lock on `usage_seal` is what makes the job safe to run on every replica: instances take turns, and a
re-run of an already-sealed range writes nothing.

`usage_window` is keyed by `(organization_id, api_key_id, model, mode, window_start)`, with an index on
`window_start` because billing walks it in that order. Failed requests are counted in `errors` and left out of
the token sums, because an error of ours is not billed.

## The customer-facing summary

`GET /usage/organizations/{id}/summary` is the one endpoint here a customer reaches, through the gateway's
`usage-summary` route, with a console session rather than an API key.

It does three things in a fixed order. First it requires `id-account` — a caller that forgets it gets 401
rather than everybody's numbers. Then it calls organization-service's `member(id, idAccount)`, so a stranger
reads exactly the 404 organization-service gives and never discovers that an organization exists. Only then
does it read `dailySums` for a period of at most 31 days, grouped by `model` or by `day`, capped at 100 groups.

The prices come from billing-service's `GET /billing/prices` and the arithmetic from the library's `Price`
record — `Price.at` picks the row in effect, `Price.cost` does the rounding — so the number a customer reads is
produced by the same code as the number in the ledger. If pricing cannot be reached, every cost comes back
`null`: the customer still reads their tokens, and never a number the platform made up. One unpriced row makes
its whole group's cost `null` rather than a partial sum, because a partial sum understates a bill.

## Why it is like this

**Arrival time is the billing clock.** It is the only clock all parties agree on: an event carries the engine's
timestamps, but what billing can act on is when the platform learned about it. Sealing a range that can never
receive another event is what makes a window safe to bill.

**The grace period exists for the relay, not for the engine.** A window is sealed a minute after it ends, so a
batch already in flight when the window closes still lands inside it.

**Ninety days of events, and totals forever.** Raw events exist to explain a charge and to reconcile the
engines' counters. Once a window is sealed, the totals are the record.

**Errors are counted, not summed.** A request that failed inside the platform cost tokens and earned nothing,
so it appears in `errors` and stays out of the token columns. Keeping it in the table at all is what makes the
failure rate readable.

## What would change it

- **The summary prices per UTC day, not per billing window.** That is a shortcut with a known ceiling: a price
  that changed inside a day misprices that day's earlier tokens, and per-day rounding can differ from the
  per-window charge by under one micro-BRL. The ledger itself stays exact. Pricing per window, with a cursor,
  is the upgrade.
- **The relay is a Valkey stream, not Kafka**, which carries one consumer comfortably. A second consumer of
  usage events is the trigger to move.
- **Retention is a constant, 90 days**, and the summary's range is capped at 31 days with 100 groups.
- **Reconciliation is a comparison, not a repair.** `Reconciler` in inference-service compares the engines' own
  token counters with what was stored and warns past a threshold; nothing is corrected automatically.

## Where to look

- [UsageController.java](https://github.com/carmonai/back/blob/main/api/usage/src/main/java/ai/carmonai/usage/UsageController.java) — the four endpoints, internal and customer-facing.
- [UsageService.java](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/java/ai/carmonai/usage/UsageService.java) — validation, the summary and its pricing.
- [SealJob.java](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/java/ai/carmonai/usage/SealJob.java) — the window, the grace and the cursor lock.
- [PartitionJob.java](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/java/ai/carmonai/usage/PartitionJob.java) — partition creation, retention and the advisory lock.
- [create_tables.sql](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql) — the partitioned table and the seal cursor.
