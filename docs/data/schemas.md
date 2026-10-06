# Schemas

Carmonai keeps one PostgreSQL 17 database and gives each service that owns state its own schema inside it. A
service reaches its schema and no other, and the migrations that create the tables travel with the service
that owns them. This page is the map of those schemas, the migration convention, and the two tables whose
shape carries a decision rather than a column list.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dsch-title" aria-describedby="dsch-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dsch-title">A value crosses a schema boundary; a foreign key does not</title>
  <desc id="dsch-desc">Two schemas are drawn as walls, usage on the left and organizations on the right. A
  solid path carries an organization_id from usage_event across both boundaries to organization, and it
  arrives. A second, dotted path starts at the same place and stops short of the second wall, because no
  foreign key exists between the two schemas. Four further schemas are named below.</desc>

  <defs>
    <marker id="dsch-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1 the id crossing, 2 the constraint that is not there. -->
  <g id="dsch-hops">
    <path id="dsch-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M234 100 H526" marker-end="url(#dsch-arrow)"/>
    <path id="dsch-hop2" class="cmn-link cmn-link--quiet" d="M234 164 H470"/>
  </g>

  <g class="cmn-node cmn-node--soft" id="dsch-usage-schema" aria-labelledby="dsch-usage-schema-label">
    <rect x="30" y="40" width="230" height="150" rx="10"/>
    <text id="dsch-usage-schema-label" x="145" y="60">usage</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dsch-org-schema" aria-labelledby="dsch-org-schema-label">
    <rect x="500" y="40" width="230" height="150" rx="10"/>
    <text id="dsch-org-schema-label" x="615" y="60">organizations</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dsch-usage-event" aria-labelledby="dsch-usage-event-label">
    <rect x="56" y="84" width="178" height="64" rx="10"/>
    <text id="dsch-usage-event-label" x="145" y="104">usage_event</text>
    <text class="cmn-sub" x="145" y="122">one row per request</text>
    <text class="cmn-sub" x="145" y="140">PK (event_id, started_at)</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dsch-organization" aria-labelledby="dsch-organization-label">
    <rect x="526" y="84" width="178" height="64" rx="10"/>
    <text id="dsch-organization-label" x="615" y="104">organization</text>
    <text class="cmn-sub" x="615" y="122">status, tier</text>
    <text class="cmn-sub" x="615" y="140">membership beside it</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dsch-rest" aria-labelledby="dsch-rest-label">
    <rect x="200" y="214" width="360" height="48" rx="10"/>
    <text id="dsch-rest-label" x="380" y="232">the other four schemas</text>
    <text class="cmn-sub" x="380" y="250">accounts · auth · billing · batch</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M234 100 H526'); --cmn-travel: 1.6s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M234 164 H470'); --cmn-travel: 1.4s; --cmn-delay: 0.9s;"></circle>

  <rect class="cmn-label-plate" x="334" y="78" width="92" height="16" rx="4"/>
  <text class="cmn-label" x="380" y="90">organization_id</text>
  <rect class="cmn-label-plate" x="330" y="174" width="100" height="16" rx="4"/>
  <text class="cmn-label" x="380" y="186">no foreign key</text>
</svg>
</div>
<figcaption>The solid path is how a reference actually works here: `usage_event.organization_id` is a plain
`VARCHAR(36)` that crosses both schema boundaries and lands on `organizations.organization`, with nothing in
the database checking that the row on the right exists. The dotted path underneath is the constraint that
would have done that checking — it stops well short of the second wall.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a value travelling (solid)</span>
  <span><i class="is-async"></i> the constraint that is not there (dotted)</span>
</div>

1. **A finished request produces one row in `usage.usage_event`** carrying the organization it belonged to.
2. **That organization is an id, not a reference**: the column is `VARCHAR(36)` and the migration declares no
   foreign key to `organizations.organization`.
3. **The id crosses the boundary between the `usage` schema and the `organizations` schema** — a boundary that
   exists in PostgreSQL as a namespace, and in the code as a rule nothing enforces mechanically.
4. **It arrives** and resolves to a real organization, because the application wrote a real id.
5. **The dotted path is the foreign key that would have made step 4 the database's problem** — it stops at the
   boundary, because a constraint across schemas would couple two services' migration histories.
6. **The other four schemas** (`accounts`, `auth`, `billing`, `batch`) have the same shape: their own tables,
   their own migrations, and ids from elsewhere that nothing constrains.

## What it is

Six schemas in one database, each created and migrated by the service that owns it. The schema name is the
service's aggregate, plural. Two services have no schema at all — `inference-service` and `gateway-service` —
because neither owns a durable fact: inference holds counters in memory and usage in a stream, and the gateway
holds configuration and the access log.

## One schema per service

| Schema | Owning service | The tables that matter |
|---|---|---|
| `accounts` | account-service | `account`, `account_token` |
| `auth` | auth-service | `api_key`, `session` |
| `organizations` | organization-service | `organization`, `membership` |
| `usage` | usage-service | `usage_event`, `usage_window`, `usage_seal` |
| `billing` | billing-service | `price`, `ledger_entry`, `balance`, `billing_cursor` |
| `batch` | batch-service | `file`, `batch`, `batch_line` |

`spring.flyway.schemas` and `hibernate.default_schema` in each service's `application.yaml` point at its own
schema, and `spring.jpa.hibernate.ddl-auto` is `validate` everywhere: Hibernate checks its mapping against the
migrated tables and never writes DDL, so a mismatch fails the service at startup rather than at the first
request. The three services with plain JDBC work — usage, billing and batch — set `currentSchema` in the JDBC
URL instead, so unqualified table names work, and cap every statement at 5 s with
`options=-c statement_timeout=5000`.

## Migrations are date-versioned

Files live in `src/main/resources/db/migration/` of the owning service and are named
`V<year>.<month>.<day>.<n>__<description>.sql` — `V2026.10.02.001__create_table.sql` in account-service,
`V2026.10.05.001__api_key_expiry.sql` in auth-service, `V2026.10.03.002__batch_prices.sql` in billing-service.
Twelve files across the six services today. The date prefix orders migrations by the day they were written,
which survives two branches merging in either order; Flyway's own counter would not. Each service keeps its own
`flyway_schema_history` inside its own schema, so one service's migrations never see another's.

A migration is also where a one-off has to be honest about itself. `V2026.10.03.002__batch_prices.sql` inserts
batch prices starting in the past, which the future-only price trigger refuses, so it disables the trigger,
inserts and re-enables it — inside the single transaction Flyway runs the file in, so nothing else sees it off.

## usage_event is partitioned by day, and keyed for idempotence

```sql
PRIMARY KEY (event_id, started_at)
) PARTITION BY RANGE (started_at);
```

The primary key includes the partition key, and the partition key is `started_at` — fixed when the event is
created, not when it arrives. That pairing is the whole mechanism: an event resent after a retry lands in the
same daily partition and hits the same primary key, so `INSERT … ON CONFLICT DO NOTHING` makes it a no-op.
Partitioning by `received_at` would have put a resend in a different partition on a different day, where the
unique index cannot see the first copy, and the same request would be billed twice.

`PartitionJob` creates the daily partitions — yesterday to a week ahead — at startup and daily under a
PostgreSQL advisory lock, and drops anything older than **90 days**. `usage_event_default` is a `DEFAULT`
partition so an event outside every daily partition lands somewhere instead of failing the whole batch; the
job's own comment names the ceiling, which is that a badly wrong clock filling that partition makes the next
`CREATE TABLE … PARTITION OF` for that day fail. The totals the money is built from do not depend on those
partitions surviving: `usage_window` keeps the sealed 5-minute sums, so dropping a day's raw events after 90
days loses the ability to re-derive a window, not the window.

## batch_line uses the row lock itself as the lease

```sql
WHERE l.status = 'pending' AND b.status = 'in_progress' AND b.expires_at > now()
ORDER BY b.created_at, l.batch_id, l.line
LIMIT 1 FOR UPDATE OF l SKIP LOCKED
```

`BatchWorker` runs that claim inside a transaction that **stays open for the whole call to the model**. The
row lock is the lease. There is no `claimed_at`, no `worker_id`, no heartbeat and no reaper, because none of
them are needed: a `SIGKILL` mid-call closes the connection, PostgreSQL rolls the transaction back, the row is
`pending` again, and the next `SKIP LOCKED` pass finds it. A lock cannot go stale, and a lease with a timeout
can.

Two consequences are visible elsewhere. The partial index `batch_line_pending ON batch_line (batch_id, line)
WHERE status = 'pending'` keeps the claim cheap as a batch drains, and batch-service sets
`hikari.maximum-pool-size: 10` with the comment *"each worker holds one for its whole call: keep above workers
+ 4"* — the pool size is derived from the fact that a worker is holding a connection, not from a throughput
estimate.

## What the missing foreign keys cost

Inside one schema the constraints are real: `account_token.account_id` cascades from `account`,
`membership.organization_id` references `organization`, and `batch_line.batch_id` references `batch`. Across
schemas there is nothing — and in `auth` not even inside it: `api_key.organization_id` and
`session.account_id` are plain strings, because both would point into another service's schema.

What that buys is that a service's migrations are its own, and that services can be split into separate
databases later by changing a URL. What it costs is that the database will happily store an id that refers to
nothing, and no error is raised at write time. The countermeasure is in the reading code:
`BillingRepository.ledgerBalances()` is a `FULL OUTER JOIN` between `balance` and the sum of `ledger_entry`,
so an organization with ledger entries and no balance row appears as a disagreement instead of disappearing
from the check. A `LEFT JOIN` would have silently reported nothing for exactly the case worth finding.

## Why it is like this

**A schema per service, not a table prefix.** A prefix would have meant one schema and one migration history
for ten services: a migration touching a table another team owns, and a `mvn verify` that fails for a reason
unrelated to the change. The schema boundary is cheap to create and impossible to cross by accident.

**No cross-schema foreign keys.** A foreign key across schemas means the target service cannot rename or move
its table without the source service's migration, and it means a write in one service takes a lock on a row in
another. Both were rejected; the cost — an unchecked id — is mitigated where it matters rather than pretended
away.

**`started_at` as the partition key.** It was chosen for deduplication, not for query patterns, and the two are
in tension: the seal job reads by `received_at` and needs the separate `usage_event_received` index to do it.

## What would change it

- **Hosting.** Six schemas in one local database become six databases, or one with six roles, when the platform
  leaves the laptop. The schema split is what makes that a connection string rather than a rewrite.
- **Raw events worth keeping past 90 days.** The retention is `RETENTION_DAYS = 90` in `PartitionJob`; a longer
  window needs storage, not a bigger number.
- **A second batch worker instance.** The claim query is already correct across instances, but each one opens
  connections for the lines it holds, and the pool sizing would have to be revisited.
- **A migration that cannot be done online.** Migrations run inside their service's own startup, so a long
  `ALTER TABLE` is a long startup. Nothing here is large enough yet for that to bite.

## Where to look

- [usage-service V2026.10.03.001](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql)
  — the partitioned table, the default partition and the seal cursor's first value.
- [batch-service V2026.10.03.001](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql)
  — `batch_line`, its partial index, and the `ponytail:` comment on storing content in Postgres.
- [BatchRepository.java](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchRepository.java)
  — the claim query, and the `FOR UPDATE SKIP LOCKED` used to delete and expire pending lines safely.
- [PartitionJob.java](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/java/ai/carmonai/usage/PartitionJob.java)
  — the 7-days-ahead window, the advisory lock and the 90-day drop.
