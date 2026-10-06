# Data

Carmonai keeps every durable fact in one PostgreSQL 17 database, split into six schemas — one per service
that owns state — plus Valkey for what must be answered on the request path, plus whatever the model engine
is holding in its own memory right now. This section is where that state lives, how the money in it is kept
exact, and how one tenant is kept out of another's rows.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dindex-title" aria-describedby="dindex-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dindex-title">Where a request touches state, and where it does not</title>
  <desc id="dindex-desc">A client sends a request to the gateway, which reads Valkey for the API key, the
  credit flag and its own rate bucket, then forwards it to the inference service. Inference reads its own
  rate buckets in Valkey, admits the request against in-memory counters, and calls the engine, which holds
  the KV cache in its own memory. No PostgreSQL is read or written anywhere on that path. Once the request
  has ended, a usage event is written to a Valkey stream and relayed to the usage service; billing later
  pulls the sealed window it makes and writes a ledger entry and a balance into PostgreSQL.</desc>

  <defs>
    <marker id="dindex-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
    <marker id="dindex-arrow-money" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1-3 the request, 4-5 the Valkey reads,
       6 the usage event, 7 billing's pull, 8 the ledger write. -->
  <g id="dindex-hops">
    <path id="dindex-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M130 88 H180" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M310 88 H360" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop3" class="cmn-link cmn-link--flow cmn-dash"
          d="M500 88 H560" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop4" class="cmn-link cmn-link--flow"
          d="M245 116 V140" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop5" class="cmn-link cmn-link--flow"
          d="M380 116 V164 H320" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop6" class="cmn-link cmn-link--quiet"
          d="M430 116 V200" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop7" class="cmn-link cmn-link--quiet"
          d="M500 228 H440" marker-end="url(#dindex-arrow-flow)"/>
    <path id="dindex-hop8" class="cmn-link cmn-link--money"
          d="M620 228 H650" marker-end="url(#dindex-arrow-money)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="dindex-client"
     aria-labelledby="dindex-client-label">
    <rect x="20" y="60" width="110" height="56" rx="10"/>
    <text id="dindex-client-label" x="75" y="80">Client</text>
    <text class="cmn-sub" x="75" y="98">SDK or app</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dindex-gateway" aria-labelledby="dindex-gateway-label">
    <rect x="180" y="60" width="130" height="56" rx="10"/>
    <text id="dindex-gateway-label" x="245" y="80">Gateway</text>
    <text class="cmn-sub" x="245" y="98">the only port</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dindex-inference" aria-labelledby="dindex-inference-label">
    <rect x="360" y="60" width="140" height="56" rx="10"/>
    <text id="dindex-inference-label" x="430" y="80">Inference</text>
    <text class="cmn-sub" x="430" y="98">no schema of its own</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dindex-engine" aria-labelledby="dindex-engine-label">
    <rect x="560" y="60" width="120" height="56" rx="10"/>
    <text id="dindex-engine-label" x="620" y="80">Engine</text>
    <text class="cmn-sub" x="620" y="98">its own memory</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dindex-valkey" aria-labelledby="dindex-valkey-label">
    <rect x="170" y="140" width="150" height="48" rx="10"/>
    <text id="dindex-valkey-label" x="245" y="158">Valkey</text>
    <text class="cmn-sub" x="245" y="176">keys and buckets</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dindex-usage" aria-labelledby="dindex-usage-label">
    <rect x="300" y="200" width="140" height="56" rx="10"/>
    <text id="dindex-usage-label" x="370" y="220">Usage</text>
    <text class="cmn-sub" x="370" y="238">sealed windows</text>
  </g>

  <g class="cmn-node cmn-node--money" id="dindex-billing" aria-labelledby="dindex-billing-label">
    <rect x="500" y="200" width="120" height="56" rx="10"/>
    <text id="dindex-billing-label" x="560" y="220">Billing</text>
    <text class="cmn-sub" x="560" y="238">the ledger</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dindex-db" aria-labelledby="dindex-db-label">
    <rect x="650" y="200" width="100" height="56" rx="10"/>
    <text id="dindex-db-label" x="700" y="220">Postgres</text>
    <text class="cmn-sub" x="700" y="238">six schemas</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M130 88 H180'); --cmn-travel: 1s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M310 88 H360'); --cmn-travel: 1s; --cmn-delay: 0.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M500 88 H560'); --cmn-travel: 1s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M245 116 V140'); --cmn-travel: 0.8s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M380 116 V164 H320'); --cmn-travel: 1.2s; --cmn-delay: 0.75s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M430 116 V200'); --cmn-travel: 1.3s; --cmn-delay: 1.05s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M500 228 H440'); --cmn-travel: 0.9s; --cmn-delay: 1.5s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="4.5"
          style="offset-path: path('M620 228 H650'); --cmn-travel: 0.9s; --cmn-delay: 1.7s;"></circle>

  <rect class="cmn-label-plate" x="131" y="44" width="48" height="16" rx="4"/>
  <text class="cmn-label" x="155" y="56">key</text>
  <rect class="cmn-label-plate" x="300" y="44" width="60" height="16" rx="4"/>
  <text class="cmn-label" x="330" y="56">forward</text>
  <rect class="cmn-label-plate" x="505" y="44" width="50" height="16" rx="4"/>
  <text class="cmn-label" x="530" y="56">prompt</text>
  <rect class="cmn-label-plate" x="180" y="192" width="112" height="16" rx="4"/>
  <text class="cmn-label" x="236" y="204">keys and buckets</text>
  <rect class="cmn-label-plate" x="440" y="150" width="110" height="16" rx="4"/>
  <text class="cmn-label" x="495" y="162">usage event, later</text>
  <rect class="cmn-label-plate" x="444" y="206" width="40" height="16" rx="4"/>
  <text class="cmn-label" x="464" y="218">pull</text>
  <rect class="cmn-label-plate" x="622" y="180" width="58" height="16" rx="4"/>
  <text class="cmn-label" x="651" y="192">ledger</text>
</svg>
</div>
<figcaption>Steps 1 to 3 are the request path: the client reaches the gateway, the gateway forwards to the
inference service, and inference asks the engine for an answer. Steps 4 and 5 are the only state read while
that happens — Valkey, for the API-key cache, the credit flag and the rate buckets. The engine's memory is the
third kind of state and the only one nothing can rebuild. Step 8 is the first PostgreSQL write in the picture.
</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-async"></i> an asynchronous hop (dotted)</span>
  <span><i class="is-money"></i> money moving (dashed, gold)</span>
</div>

1. **The client sends an API key and a body** to the gateway, the only service with a published port.
2. **The gateway forwards it** to the inference service with identity headers it set itself.
3. **Inference calls the engine**, which keeps the conversation's KV cache in its own GPU or CPU memory.
4. **The gateway reads Valkey**: `apikey:{sha256}`, `no_credit:{org}`, and its own `rl:gw:…` flood brake.
5. **Inference reads Valkey too**: `rl:{org:model}:requests|input|output`. Its in-flight counters are in the
   JVM's memory, not in Valkey and not in PostgreSQL.
6. **When the request ends, a usage event is written to the Valkey stream `usage:events`** and a relay
   delivers it to the usage service a second later. A killed instance loses nothing.
7. **Billing pulls the next sealed window** from the usage service, in order, using a cursor row.
8. **Billing writes the ledger entry and updates the balance**, in one transaction, both in PostgreSQL.

## What it is

Three kinds of state. **PostgreSQL** holds everything durable: six schemas, one per service that owns data.
**Valkey** holds what must be answered in under a millisecond on the request path, plus the usage stream that
makes metering survive a crash. The **engine's memory** holds the KV cache, the prefix cache and the queue,
and it is the only one of the three that cannot be rebuilt.

The rule that shapes this whole section: **nothing on the request path reads or writes PostgreSQL.** Not the
gateway, not the inference service — which has no schema at all — and not the engine.

## The six schemas

`accounts` (account-service), `auth` (auth-service), `organizations` (organization-service), `usage`
(usage-service), `billing` (billing-service) and `batch` (batch-service). One schema per service, no shared
tables, and no foreign key across a schema boundary — the full table, the migration convention and the two
structural decisions inside `usage` and `batch` are in [Schemas](schemas.md).

## What is not in PostgreSQL

Valkey holds four things. `apikey:{sha256}` is the resolved API key, cached 60 s — misses cached too, so
garbage keys cannot hammer auth-service, and revocation deletes the entry so it is immediate rather than
TTL-bound. `no_credit:{org}` is set by billing when `balance + credit_limit ≤ 0` and read by the gateway,
which answers **402** while it exists; no TTL, because it is state, re-synced every 10 minutes. `rl:gw:…` and
`rl:{org:model}:…` are the token buckets the gateway and inference-service take from, so replicas share a rate.
`usage:events` is a stream, written as each request ends and drained by a relay; Valkey runs with
`--appendonly yes --appendfsync everysec` in a volume, so losing Valkey loses about a second.

Two of those reads are on the request path, and both fail deliberately. `ApiKeyAuthenticationManager` checks
the key's format and CRC with **no I/O at all** before asking Valkey, and **Valkey down is a 503** — failing
closed, so a client does not conclude its key was revoked. `RateLimitFilter` **fails open**, because the flood
brake is not the last line of defence; the in-flight caps behind it are.

The engine holds the KV cache, the prefix cache and its waiting queue. Nothing can reconstruct any of it; when
vLLM restarts, every prompt is prefilled again. That is why the engine is the only dependency whose loss is
measured in TTFT rather than in correctness.

## Why it is like this

**One database, six schemas.** A schema per service means a service can be pointed at its own database later
by changing one connection string, and no service can read another's tables by accident. The rejected
alternative — one shared schema with every service's tables — makes every join a coupling nobody can see in a
code review. The cost is paid in the code: an id that crosses a schema is a plain `VARCHAR(36)`.

**Valkey on the path, PostgreSQL off it.** An API-key lookup against PostgreSQL is a network round trip and a
connection from a pool the streaming path would otherwise never touch. Keeping the path free of the database
is also what lets the engines be restarted and a table vacuumed without a customer noticing.

**Usage leaves the path asynchronously.** A synchronous write per request would put the database in the
latency budget. The cost of the asynchronous version is named rather than hidden: a crash between an answer's
last byte and its `XADD`, about a millisecond wide, loses that request's usage event. `Admission`'s in-flight
counters are a `HashMap` in one JVM for the same reason — nothing shared on the path.

## What would change it

- **A second replica of anything.** The in-flight caps and virtual token counters live in one JVM's memory;
  they have to become shared counters before a second inference-service replica is correct.
- **Batch files outgrowing the gateway.** File content is `bytea`, capped by the 4 MB `/v1` body limit. Object
  storage is the upgrade, blocked on the hosting decision.
- **A shared database.** The append-only triggers assume one database role, the application's; separate roles
  are the fix, and they arrive when the database is shared.
- **A second consumer of usage events.** The relay is a Valkey stream with one consumer group; that is the
  point where Kafka stops being speculative.

## Where to look

- [compose.yaml](https://github.com/carmonai/back/blob/main/docker/compose.yaml) — `db` and `valkey`, their
  volumes, and Valkey's append-only settings.
- [ApiKeyAuthenticationManager.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ApiKeyAuthenticationManager.java)
  — the 60 s cache, the credit flag and the fail-closed 503.
- [Admission.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java)
  — the per-organization buckets and the in-memory in-flight caps.
- [UsageReporter.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/UsageReporter.java)
  — the `usage:events` stream and the relay that drains it.
