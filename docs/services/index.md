# Services

## What it is

Carmonai is eight Spring Boot applications and five contract libraries, in thirteen Git repositories under
`api/`. Each service owns one Postgres schema, exposes a small HTTP surface, and talks to the others over
Feign or not at all. This page is the key to the other eight: what a service is here, what a library is, and
which schema belongs to whom.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="svc-index-title" aria-describedby="svc-index-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="svc-index-title">A library, a service, and the schema it owns</title>
  <desc id="svc-index-desc">A caller reaches a service through a library's Feign interface, which the service
  implements; the service owns one Postgres schema that no other service reads. In tests the same interface
  is pointed at a stub through the url placeholder.</desc>

  <defs>
    <marker id="svc-index-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Hops, in reading order: 1 the Feign call, 2 the implementation, 3 the schema it owns,
       4 the same interface pointed at a stub (the bottom-left elbow). -->
  <g id="svc-index-hops">
    <path id="svc-index-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M142 68 H200" marker-end="url(#svc-index-arrow)"/>
    <path id="svc-index-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M350 68 H426" marker-end="url(#svc-index-arrow)"/>
    <path id="svc-index-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M501 96 V150" marker-end="url(#svc-index-arrow)"/>
    <path id="svc-index-hop4" class="cmn-link cmn-link--quiet" d="M142 178 H250 V96" marker-end="url(#svc-index-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="svc-index-caller" aria-labelledby="svc-index-caller-label"><rect x="24" y="40" width="118" height="56" rx="10"/>
    <text id="svc-index-caller-label" x="83" y="60">Caller</text><text class="cmn-sub" x="83" y="78">another service</text></g>
  <g class="cmn-node cmn-node--flow" id="svc-index-library" aria-labelledby="svc-index-library-label"><rect x="200" y="40" width="150" height="56" rx="10"/>
    <text id="svc-index-library-label" x="275" y="60">Library</text><text class="cmn-sub" x="275" y="78">XController + records</text></g>
  <g class="cmn-node cmn-node--flow" id="svc-index-service" aria-labelledby="svc-index-service-label"><rect x="426" y="40" width="150" height="56" rx="10"/>
    <text id="svc-index-service-label" x="501" y="60">Service</text><text class="cmn-sub" x="501" y="78">implements it</text></g>
  <g class="cmn-node cmn-node--flow" id="svc-index-schema" aria-labelledby="svc-index-schema-label"><rect x="426" y="150" width="150" height="56" rx="10"/>
    <text id="svc-index-schema-label" x="501" y="170">Schema</text><text class="cmn-sub" x="501" y="188">its own tables</text></g>
  <g class="cmn-node cmn-node--soft" id="svc-index-stub" aria-labelledby="svc-index-stub-label"><rect x="24" y="150" width="118" height="56" rx="10"/>
    <text id="svc-index-stub-label" x="83" y="170">Test stub</text><text class="cmn-sub" x="83" y="188">the url property</text></g>

  <!-- One packet per hop, matching each path's geometry. -->
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M142 68 H200'); --cmn-travel: 1.1s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M350 68 H426'); --cmn-travel: 1.1s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M501 96 V150'); --cmn-travel: 1.1s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5" style="offset-path: path('M142 178 H250 V96'); --cmn-travel: 1.6s; --cmn-delay: 1s;"></circle>

  <!-- Labels last, each on its own plate so it never sits on a stroke. -->
  <rect class="cmn-label-plate" x="143" y="44" width="56" height="16" rx="4"/><text class="cmn-label" x="171" y="56">Feign call</text>
  <rect class="cmn-label-plate" x="358" y="44" width="60" height="16" rx="4"/><text class="cmn-label" x="388" y="56">implements</text>
  <rect class="cmn-label-plate" x="138" y="154" width="92" height="16" rx="4"/><text class="cmn-label" x="184" y="166">points at a stub</text>
  <rect class="cmn-label-plate" x="509" y="113" width="40" height="16" rx="4"/><text class="cmn-label" x="529" y="125">owns</text>
</svg>
</div>
<figcaption>Step 1 carries an internal call along a library's Feign interface and step 2 is the service
implementing that same interface. Step 3 is the schema the service alone reads and migrates. Step 4 is the
test arrangement: the library's client is pointed at a stub instead of the service, through the same
placeholder the stack resolves.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-async"></i> a test-only hop (dotted)</span>
</div>

1. A caller holds the library's `XController` interface and calls it; the URL comes from configuration, not
   from the caller's code.
2. The service implements that interface. There is one definition of each operation, so a caller and an
   implementation cannot drift apart without failing to compile.
3. The service owns exactly one Postgres schema, and it is the only writer of it. The arrow points down
   because the schema belongs to the service, not the other way round.
4. In an integration test the same interface points at a stub, because `@FeignClient` takes
   `url="${carmonai.<name>.url:http://<name>:8080}"` — the property the test sets, and the default the
   compose network resolves.

## The vocabulary this section uses

A **service** is a Spring Boot application with a port, a `spring.application.name`, its own datasource and
its own Flyway schema history. It is the only thing that reads its tables.

A **library** is a jar with no `@SpringBootApplication` in it: one `XController` Feign interface and the
`In`/`Out` records it exchanges. It carries no behaviour, no entity and no repository. Its whole job is to be
the one place where a contract is written down.

## One schema per service

A service writes its own schema and reads nobody else's. `accounts` belongs to account-service, `auth` to
auth-service, `organizations` to organization-service, `usage` to usage-service, `billing` to
billing-service, `batch` to batch-service. Two services have no schema at all — gateway-service holds no
data, and inference-service deliberately holds none.

That single rule buys three things:

- **The schema is the boundary.** No service can reach into another's tables, so a table can be reshaped
  inside its own service without a coordination meeting. A migration is a private act.
- **Each service starts alone.** `spring.flyway.schemas` names one schema and `hibernate.default_schema`
  names the same one, so a service can be started against a database that contains only its own tables.
- **A cross-service read has to be a call.** If account-service needs to know a role, it asks
  organization-service — which is why the internal lookups on [Organization](organization.md) exist at all.
  The cost is a network hop and a failure mode; the benefit is that there is exactly one answer.

Every service also connects with `logServerErrorDetail=false`, so row values never reach an exception message
or a log, and the JDBC-only services add `currentSchema` and a 5 s `statement_timeout` in the URL itself.

## The eight services

| Service | Schema | Migrations | What it owns | Page |
|---|---|---|---|---|
| `gateway-service` | none | — | the only published port, authentication, rate limiting, the access log | [Gateway](gateway.md) |
| `auth-service` | `auth` | 3 | login, JWTs, sessions, API keys | [Auth](auth.md) |
| `account-service` | `accounts` | 2 | the person: password, email, export, erasure | [Account](account.md) |
| `organization-service` | `organizations` | 1 | the tenant: status, tier, memberships | [Organization](organization.md) |
| `inference-service` | none | — | the OpenAI-compatible surface and the engines | [Inference](inference.md) |
| `usage-service` | `usage` | 2 | what was consumed: events, partitions, sealed windows | [Metering](metering.md) |
| `billing-service` | `billing` | 2 | what it costs: prices, ledger, balance, credit flags | [Billing](billing.md) |
| `batch-service` | `batch` | 2 | Files and the Batch API | Batch (its own page) |

A migration count is a fair proxy for how settled a service is: organization-service has one file because one
table pair has been enough, while auth-service and billing-service each needed a second pass — to add key
expiry, and to add batch prices.

## The five libraries

`api/auth`, `api/account`, `api/organization`, `api/usage` and `api/billing`. Each is named after the service
that implements it, minus the `-service` suffix — so `api/billing` is the contract and `api/billing-service`
is the thing behind it. Reading a library is the fastest way to learn a service's public shape: the interface
lists every operation, and the records list every field that crosses the wire.

## Why it is like this

**One Git repository per module** is the decision that shapes everything else. `back` is an aggregator:
thirteen submodules pinned by commit in `.gitmodules`, and a root `pom.xml` whose only content is the module
list. The upside is that a module's history is its own; the cost is that a contract change is a commit in the
library's repository before any service can build against it, which [Libraries](libraries.md) spells out.

**HTTP with idempotency keys, not a broker.** The rule is that Kafka arrives when an event gets a *second*
consumer. Until then every hand-off is an HTTP call that can safely be repeated: usage events are keyed by
`(event_id, started_at)`, grants by `idempotencyKey`, ledger entries by an idempotency key unique in the
table. Retries are therefore free to be naive, and there is no broker to operate for a platform with one of
everything.

**Prepaid rather than metered-and-invoiced.** Credit is granted first and spent down, which is why a service
can answer 402 without a payment integration existing at all. The rejected alternative — usage accumulates
and a monthly invoice follows — needs a payment rail, dunning and a collections process before it can serve a
first customer.

## What would change it

- **A second replica of anything.** In-flight caps live in one JVM's memory (inference-service), the
  gateway's local rate buckets are per-replica, and the erasure sweep assumes it may run anywhere. Shared
  counters come before a second replica, not after.
- **A second consumer of any event.** The usage relay is a Valkey stream, which carries one consumer
  comfortably. The moment a second service wants the same events, that stream becomes Kafka.
- **Hosting decisions.** Batch files sit in Postgres `bytea` because there is no object storage yet; that
  choice caps uploads at the gateway's 4 MB rather than OpenAI's 200 MB.
- **A shared database role.** The append-only ledger is enforced by database triggers, which hold for one
  role. Separate roles per service come with a shared database.

## Where to look

- [pom.xml](https://github.com/carmonai/back/blob/main/pom.xml) — the thirteen modules in dependency order.
- [.gitmodules](https://github.com/carmonai/back/blob/main/.gitmodules) — each module is its own repository.
- [organization/pom.xml](https://github.com/carmonai/back/blob/main/api/organization/pom.xml) — what a library module actually contains.
- [auth-service application.yaml](https://github.com/carmonai/back/blob/main/api/auth-service/src/main/resources/application.yaml) — one schema, one datasource, one service.
- [organization-service migration](https://github.com/carmonai/back/blob/main/api/organization-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql) — the schema a service calls its own.

<div class="grid cards" markdown>

-   **[Gateway](gateway.md)**

    ---

    The only published port: the filter chain, the API-key cache, the route table and the error contract.

-   **[Auth](auth.md)**

    ---

    Login, RS256 access tokens, the rotating refresh cookie, and API keys that are only ever stored hashed.

-   **[Account](account.md)**

    ---

    The person: Argon2id, single-use email links, export, and erasure that can be refused.

-   **[Organization](organization.md)**

    ---

    The tenant: status, tier, three roles, and the lookups other services are allowed to make.

-   **[Inference](inference.md)**

    ---

    The OpenAI-compatible surface: what the service accepts, what it sets itself, and what it reports.

-   **[Metering](metering.md)**

    ---

    `usage-service`: idempotent events, daily partitions, and five-minute windows sealed by arrival.

-   **[Billing](billing.md)**

    ---

    `billing-service`: prices, an append-only ledger, and the flag that turns the next request into a 402.

-   **[Libraries](libraries.md)**

    ---

    The five shared Feign contracts, the `url` convention, and what changing one costs.

</div>
