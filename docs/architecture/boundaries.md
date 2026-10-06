# Service boundaries

## What it is

Carmonai is one Git repository per module: thirteen Maven modules under `api/`, five of them **libraries**
that hold a contract and no behaviour, and eight of them **services** that hold a Spring Boot application
and one Postgres schema. A service may call another service's library and may never read another service's
tables. Where two services genuinely need each other's data, they call each other — and the page below is
mostly about what that costs.

## The module rule

A **library** is a Feign interface plus its `In`/`Out` records. It has no service, no controller and no
repository; it is the shape of a call, published so that the caller and the callee compile against one
definition.

```java
@FeignClient(
    name="organization",
    url="${carmonai.organization.url:http://organization:8080}"
)
public interface OrganizationController {
```

The `url` is a placeholder with a compose default, which is what lets an integration test point the client
at a stub instead of a container.

| Module | Kind | Artifact | Depends on these libraries |
|---|---|---|---|
| `api/account` | library | `account` | — |
| `api/auth` | library | `auth` | `account` (because `AuthController.whoami` answers an `AccountOut`) |
| `api/organization` | library | `organization` | — |
| `api/usage` | library | `usage` | — |
| `api/billing` | library | `billing` | — |
| `api/account-service` | service | `account-service` | `account`, `organization`, `auth` |
| `api/auth-service` | service | `auth-service` | `auth`, `organization` |
| `api/organization-service` | service | `organization-service` | `organization` |
| `api/usage-service` | service | `usage-service` | `usage`, `organization`, `billing` |
| `api/billing-service` | service | `billing-service` | `billing`, `usage`, `organization` |
| `api/batch-service` | service | `batch-service` | `organization` |
| `api/inference-service` | service | `inference-service` | none |
| `api/gateway-service` | service | `gateway-service` | none |

Apart from that one library-to-library edge, every library's dependency list is the same two entries:
`spring-cloud-starter-openfeign` and `lombok`.
A library that needed a database driver would be a sign that behaviour had leaked into it.

## What an aggregate is here

The schema **is** the aggregate boundary, and it is named after the aggregate in the plural:
`accounts`, `auth`, `organizations`, `usage`, `billing`, `batch`. Inside a service:

- the **domain class** (`Account`) has no persistence annotations;
- the **JPA model** (`AccountModel`) is built from it (`new AccountModel(domain, hash)`) and converts back
  (`model.to()`);
- the **resource** parses at the HTTP edge (`AccountIn` → `Account`, `Account` → `AccountOut`), so
  `AccountService` never sees a DTO or an HTTP type;
- ids are `String` UUIDs, and Hibernate only validates the schema — Flyway owns every `CREATE TABLE`.

The result is a module whose public surface is one interface and a handful of records, and whose internals
can be replaced without any other module noticing. The alternative — JPA entities shared through a library
— was rejected because it would put one service's column names into another service's compile path.

## The rule: no shared tables

No service reads a table that another service's Flyway migrations create. `usage-service` sets
`currentSchema=usage` in its JDBC URL and `billing-service` sets `currentSchema=billing`; a query that
reached across would have to spell the other schema out, which is what makes the violation visible in
review.

What the rule costs is a call, and the honest example is metering and money. `billing-service` pulls sealed
usage windows with `GET /usage/windows/next` and prices them; `usage-service` answers the customer's summary
by reading the price history with `GET /billing/prices`. Neither can join, because the ledger and the price
table are billing's and the events are usage's.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="bound-title" aria-describedby="bound-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="bound-title">Two services that call each other instead of joining</title>
  <desc id="bound-desc">Billing pulls the next sealed usage window from usage over HTTP; usage reads the
  price history from billing over HTTP. Each service writes only its own schema, and no query joins the two
  schemas.</desc>

  <defs>
    <marker id="bound-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Hop 1 goes right to left: billing pulls from usage. Hop 2 is the price read. -->
  <g id="bound-hops">
    <path id="bound-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M460 58 H300" marker-end="url(#bound-arrow-flow)"/>
    <path id="bound-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M300 86 H460" marker-end="url(#bound-arrow-flow)"/>
    <path id="bound-hop3" class="cmn-link cmn-link--flow" d="M205 100 V170" marker-end="url(#bound-arrow-flow)"/>
    <path id="bound-hop4" class="cmn-link cmn-link--flow" d="M555 100 V170" marker-end="url(#bound-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="bound-usage" aria-labelledby="bound-usage-label">
    <rect x="110" y="44" width="190" height="56" rx="10"/><text id="bound-usage-label" x="205" y="64">Usage</text>
    <text class="cmn-sub" x="205" y="82">what was consumed</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="bound-billing" aria-labelledby="bound-billing-label">
    <rect x="460" y="44" width="190" height="56" rx="10"/><text id="bound-billing-label" x="555" y="64">Billing</text>
    <text class="cmn-sub" x="555" y="82">what it costs</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="bound-usage-schema" aria-labelledby="bound-usage-schema-label">
    <rect x="110" y="170" width="190" height="56" rx="10"/><text id="bound-usage-schema-label" x="205" y="190">schema usage</text>
    <text class="cmn-sub" x="205" y="208">events, sealed windows</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="bound-billing-schema" aria-labelledby="bound-billing-schema-label">
    <rect x="460" y="170" width="190" height="56" rx="10"/><text id="bound-billing-schema-label" x="555" y="190">schema billing</text>
    <text class="cmn-sub" x="555" y="208">ledger, prices, balance</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="bound-no-join" aria-labelledby="bound-no-join-label">
    <rect x="330" y="180" width="100" height="36" rx="10"/><text id="bound-no-join-label" x="380" y="198">no join</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M460 58 H300'); --cmn-travel: 0.8s; --cmn-delay: 0s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M300 86 H460'); --cmn-travel: 0.8s; --cmn-delay: 0.4s;"/>

  <rect class="cmn-label-plate" x="300" y="44" width="160" height="16" rx="4"/><text class="cmn-label" x="380" y="56">pulls sealed windows</text>
  <rect class="cmn-label-plate" x="296" y="90" width="168" height="16" rx="4"/><text class="cmn-label" x="380" y="102">reads the price history</text>
  <rect class="cmn-label-plate" x="118" y="124" width="170" height="16" rx="4"/><text class="cmn-label" x="203" y="136">writes only its own tables</text>
  <rect class="cmn-label-plate" x="470" y="124" width="170" height="16" rx="4"/><text class="cmn-label" x="555" y="136">reads only its own tables</text>
</svg>
</div>
<figcaption>Billing pulls the next sealed window from usage (step 1) and usage reads the price history from
billing (step 2), so a price change and the charge it causes can never disagree. Each service writes and
reads its own schema only (steps 3 and 4); the gap between the two boxes is the rule — no query joins
across it, because there is no transaction that could span it.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a call between two services, and the read of a schema (solid)</span>
  <span>the two schemas are separate stores: no foreign key, no cross-schema query, no join</span>
</div>

1. **Billing pulls the next sealed usage window.** `BillingService` calls
   `UsageController.nextWindow(after)` over Feign with a cursor, so windows are billed in order and exactly
   once.
2. **Usage reads the price history.** For the customer summary it calls `BillingController.prices()` and
   prices the tokens with `Price.cost`, the same record and the same rounding the debit job uses.
3. **Each service writes its own tables.** Usage owns `usage_event`, `usage_window` and `usage_seal`;
   billing owns `ledger_entry`, `price`, `balance` and `billing_cursor`.
4. **Nothing joins the two.** There is no foreign key between them and no cross-schema query, so the
   database will not enforce the relationship — the *call* does, and it can fail.

## Why it is like this

- **A call rather than a join, in both directions.** The alternatives were considered and named when the
  summary was built: serving the summary from billing-service inverts ownership (the summary belongs with
  the usage data), duplicating the price table creates a second source of money arithmetic, and replicating
  prices is a cache whose staleness is a money bug. The mutual call stayed, deliberately, and the two
  `@EnableFeignClients` lines are the whole of it.
- **A library with no caller is a dependency nobody asked for.** `inference-service` and `batch-service`
  have no library. batch-service runs each line through `/v1/chat/completions` over plain HTTP with a
  `batch-line` header, and the gateway routes to inference without a Feign client, so neither has a Java
  caller to publish a contract for. The moment one exists — a console that streams tokens, an eval runner —
  is the moment a library gets written.
- **`Price` in the library, not in the service.** The one piece of real logic that two services share is
  money arithmetic, so the record and its `cost` live in `api/billing` and usage-service depends on that
  library rather than on a copy. It did not remove the call between the two services: the price *table* is
  still billing's schema, and no design that keeps the summary in usage-service can change that.
- **The domain/model split costs a mapper.** `new AccountModel(account)` and `model.to()` are boilerplate,
  and they buy a service whose domain objects cannot be lazily loaded by accident and whose tests need no
  database.

## What would change it

The rule is enforced by review and by the shape of the code, **not by the database**: one Postgres user
owns all six schemas, so nothing physically stops a query from joining across two of them. The append-only
ledger has the same ceiling — it is enforced by triggers, not by a second role. Both are written down as
shortcuts in the fact sheet's shortcut table, with "separate roles when the DB is shared" as the upgrade
path. Two other boundaries are waiting on a decision rather than on code: batch files belong in object
storage once hosting exists, and Kafka arrives when an event gets a second consumer — until then the usage
relay is a Valkey stream with one consumer, and the erasure of a closed organization is a pull sweep rather
than an event saga. [Known gaps](../reference/gaps.md) has the full list.

## Where to look

- [OrganizationController.java](https://github.com/carmonai/back/blob/main/api/organization/src/main/java/ai/carmonai/organization/OrganizationController.java)
  — the library contract, with a comment on every internal-only method.
- [UsageService.java](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/java/ai/carmonai/usage/UsageService.java)
  — the membership check, the summary and the price read.
- [BillingService.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingService.java)
  — the cursor pull, the one-transaction ledger write and the credit flag.
- [BillingRepository.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingRepository.java)
  — plain JDBC against `currentSchema=billing`, including the reconciliation query.
