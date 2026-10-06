# Known gaps

**What is missing, ranked by what blocks a paying customer rather than by how long the fix would take, and
labelled for what it is: a defect, a deliberate deferral, or unbuilt scope.**

## What it is

Every honest gap in the platform, in one place, each with the concrete fix and a label that says which kind
of gap it is. The ranking is by customer impact: something that stops money changing hands, or stops a
customer being served at all, ranks above something that makes an engineer's afternoon worse. Effort is not
part of the ranking — a one-line fix that blocks launch outranks a week of work nobody notices.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="gap-title" aria-describedby="gap-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="gap-title">A gap map: what runs, what waits, and what is not there</title>
  <desc id="gap-desc">Three lanes. The top lane is built and a packet runs along its rail: the gateway,
  admission, the relay to the engine, and the path from usage to ledger. The middle lane is deferred with a
  named trigger — object storage, Kafka, a second replica, console invitations. The bottom lane is unbuilt:
  the payment rail, the customer console, embeddings and an alerting destination. Neither lower lane has a
  rail or a packet, because nothing runs there.</desc>

  <defs>
    <marker id="gap-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- The rail under the built lane: structure, and the path the packet travels. -->
  <g id="gap-rail" aria-hidden="true">
    <path class="cmn-link" d="M136 94 H732" marker-end="url(#gap-arrow-flow)"/>
    <path class="cmn-link" d="M206 78 V94"/>
    <path class="cmn-link" d="M358 78 V94"/>
    <path class="cmn-link" d="M510 78 V94"/>
    <path class="cmn-link" d="M662 78 V94"/>
  </g>

  <!-- The packet: one journey along the built lane, and no journey anywhere else. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M136 94 H732'); --cmn-travel: 2.2s; --cmn-delay: 0s;"></circle>

  <!-- Lane labels -->
  <g class="cmn-node" id="gap-lane-built" aria-labelledby="gap-lane-built-label">
    <text id="gap-lane-built-label" x="64" y="54">Built</text>
  </g>
  <g class="cmn-node" id="gap-lane-deferred" aria-labelledby="gap-lane-deferred-label">
    <text id="gap-lane-deferred-label" x="64" y="128">Deferred</text>
  </g>
  <g class="cmn-node" id="gap-lane-unbuilt" aria-labelledby="gap-lane-unbuilt-label">
    <text id="gap-lane-unbuilt-label" x="64" y="202">Unbuilt</text>
  </g>

  <!-- Lane 1: built -->
  <g class="cmn-node cmn-node--flow" id="gap-gateway" aria-labelledby="gap-gateway-label">
    <rect x="136" y="30" width="140" height="48" rx="10"/>
    <text id="gap-gateway-label" x="206" y="48">Gateway</text>
    <text class="cmn-sub" x="206" y="64">the only public port</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="gap-admission" aria-labelledby="gap-admission-label">
    <rect x="288" y="30" width="140" height="48" rx="10"/>
    <text id="gap-admission-label" x="358" y="48">Admission</text>
    <text class="cmn-sub" x="358" y="64">buckets, tier caps</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="gap-relay" aria-labelledby="gap-relay-label">
    <rect x="440" y="30" width="140" height="48" rx="10"/>
    <text id="gap-relay-label" x="510" y="48">Relay to engine</text>
    <text class="cmn-sub" x="510" y="64">tokens stream back</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="gap-ledger" aria-labelledby="gap-ledger-label">
    <rect x="592" y="30" width="140" height="48" rx="10"/>
    <text id="gap-ledger-label" x="662" y="48">Usage to ledger</text>
    <text class="cmn-sub" x="662" y="64">billed once</text>
  </g>

  <!-- Lane 2: deferred, with a named trigger -->
  <g class="cmn-node cmn-node--soft" id="gap-objectstore" aria-labelledby="gap-objectstore-label">
    <rect x="136" y="104" width="140" height="48" rx="10"/>
    <text id="gap-objectstore-label" x="206" y="122">Object storage</text>
    <text class="cmn-sub" x="206" y="138">files above 4 MB</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="gap-kafka" aria-labelledby="gap-kafka-label">
    <rect x="288" y="104" width="140" height="48" rx="10"/>
    <text id="gap-kafka-label" x="358" y="122">Kafka</text>
    <text class="cmn-sub" x="358" y="138">a second consumer</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="gap-replica" aria-labelledby="gap-replica-label">
    <rect x="440" y="104" width="140" height="48" rx="10"/>
    <text id="gap-replica-label" x="510" y="122">Second replica</text>
    <text class="cmn-sub" x="510" y="138">shared counters first</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="gap-invites" aria-labelledby="gap-invites-label">
    <rect x="592" y="104" width="140" height="48" rx="10"/>
    <text id="gap-invites-label" x="662" y="122">Console invites</text>
    <text class="cmn-sub" x="662" y="138">waits for hosting</text>
  </g>

  <!-- Lane 3: unbuilt -->
  <g class="cmn-node cmn-node--danger" id="gap-payments" aria-labelledby="gap-payments-label">
    <rect x="136" y="178" width="140" height="48" rx="10"/>
    <text id="gap-payments-label" x="206" y="196">Payment rail</text>
    <text class="cmn-sub" x="206" y="212">credit is a grant</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="gap-console" aria-labelledby="gap-console-label">
    <rect x="288" y="178" width="140" height="48" rx="10"/>
    <text id="gap-console-label" x="358" y="196">Customer console</text>
    <text class="cmn-sub" x="358" y="212">there is no UI</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="gap-embeddings" aria-labelledby="gap-embeddings-label">
    <rect x="440" y="178" width="140" height="48" rx="10"/>
    <text id="gap-embeddings-label" x="510" y="196">/v1/embeddings</text>
    <text class="cmn-sub" x="510" y="212">chat and models only</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="gap-alerting" aria-labelledby="gap-alerting-label">
    <rect x="592" y="178" width="140" height="48" rx="10"/>
    <text id="gap-alerting-label" x="662" y="196">Alerting</text>
    <text class="cmn-sub" x="662" y="212">no destination chosen</text>
  </g>
</svg>
</div>
<figcaption>The top lane is the only one with a rail, because it is the only one a request can travel
today: gateway, admission, relay, and the path from usage into the ledger. The middle lane holds shortcuts
that were deferred on purpose, each with a trigger written down. The bottom lane holds capabilities that do
not exist at all. A red outline marks a box in the bottom lane; the label inside it says what is missing.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> built, and a packet travels it (solid)</span>
  <span><i class="is-async"></i> nothing there; no rail and no packet</span>
  <span>red outline: unbuilt, and the label inside says what is missing</span>
</div>

1. The top lane is what is built, and the only lane with a rail: gateway, admission, the relay to the engine, and the path from usage into the ledger — in the order a request meets them.
2. The middle lane is deliberately deferred: each box names what it waits for, so nothing there is waiting on somebody's memory.
3. The bottom lane is unbuilt: no rail and no packet, because the capability does not exist yet.
4. A box moves up a lane when its work lands. The lane a box sits in is the honest answer to "does this exist today?", and it is the first thing a reader should check before assuming a capability is present.

## The ranking, and what the ranking is not

Three tiers, in the order below: **what blocks taking money from anyone**, **what blocks the second
customer or the second engineer**, and **recorded ceilings that block nothing today**. Nothing here is
estimated in weeks, because an estimate is a different kind of number and this page is about impact.

One caveat about the sources. The handoff's own ranked list is a snapshot from 2026-10-04, and the code has moved since: the flood brake now answers an OpenAI-shaped 429 from a shared Valkey bucket, the `api-keys/{id}/rotate` route and the customer balance and usage routes exist at the gateway, an expired key is refused from the cache, waiting requests are ordered by the virtual token counter, and a paying tier waits for a slot instead of taking an instant 429. Those are not listed below as open, and [which notes to trust](status.md) records where each source lags. Where a gap turned out to be already closed, the entry says so rather than keeping a stale row alive.

## 1 · What blocks taking money from anyone

| # | The gap | Kind | The concrete fix |
|---|---|---|---|
| 1 | **No payment rail.** Credit enters the system only through `POST /billing/grants`, an internal, idempotent staff call; there is no way for a stranger to pay | unbuilt scope, and an open decision | Choose a PSP and an NFS-e provider, then treat the webhook as a hint and re-fetch the charge before crediting the balance — [Billing](../services/billing.md) has the current grant path |
| 2 | **No customer console.** The only UI in the repository is `demo/`, a one-page console used to record the walkthrough videos; nothing lets a customer mint a key, rotate it, read usage or see a balance | unbuilt scope | Phase 7b's console SPA on the same origin as the console API — the endpoints behind it exist and are already routed, and [Money](../data/money.md) describes what they return |
| 3 | **No legal entity, DPA, acceptable-use policy, ROPA or named data-protection contact, and no decided retention periods** | unbuilt scope, waiting on counsel and on the user | The plan's "before real customer data reaches any GPU" checklist, plus a retention decision per data class |
| 4 | **No Alertmanager, so nothing pages anybody.** Prometheus evaluates the rules and Grafana shows their firing state; no destination has been chosen | deliberate deferral | Pick a destination. The rules, the metrics and the on-demand `GET /actuator/reconcile` already exist — [Observability](../operations/observability.md) lists them |
| 5 | **One GPU, one engine endpoint per model, no replica routing.** Deployment config holds one engine URL per model, so [Inference](../services/inference.md) has nothing to route between | deliberate deferral | Multi-replica routing with more GPUs — fewest-waiting first, or the llm-d router on Kubernetes |
| 6 | **In-flight caps live in one JVM's memory**, so a second replica would double every cap | deliberate deferral | Shared counters in Valkey, or a fixed share per replica, **before** a second inference-service exists |
| 7 | **No Kubernetes and no second replica**, so there is no rolling deploy and no availability target that means anything | unbuilt scope, platform decision deferred | The phase-7 decision: Kubernetes with KEDA autoscaling and nginx at the edge. The observability half is already provisioned from files in `docker/` |
| 8 | **Tracing is not wired.** No `micrometer-tracing`, no OpenTelemetry agent or collector, no backend; `trace_id` and `span_id` in the JSON logs are the only correlation | deliberate deferral that became permanent | The OTel Java agent in each image with `OTEL_EXPORTER_OTLP_ENDPOINT` and a 0.1 sampler, body and header capture off — and a backend to look at |
| 9 | **Batch files are capped at 4 MB and stored in Postgres `bytea`**; OpenAI allows 200 MB, so a real batch upload fails at the gateway | deliberate deferral | Object storage once hosting is decided. The cap itself is one constant, `V1RequestFilter.MAX_BODY`; [Batch API design](../operations/batch-api.md) covers the rest of the surface |
| 10 | **`GET /v1/embeddings` does not exist.** The inference service has exactly two routes: `POST /v1/chat/completions` and `GET /v1/models` — see [Inference](../services/inference.md) | unbuilt scope, out of scope until there is a reason | A decision first, then an engine that serves it. Note that a batch file whose `endpoint` is `/v1/embeddings` is already refused at creation with `invalid_line` |

## 2 · What blocks the second customer, or the second engineer

| # | The gap | Kind | The concrete fix |
|---|---|---|---|
| 11 | **Password-reset mail has a per-IP throttle and no per-email one**, so the per-IP bucket is the only ceiling on reset mail to one address | deliberate deferral | A per-email counter in Valkey beside the per-IP bucket |
| 12 | **Invitations are not built, and the SMTP credentials for a real provider wait for hosting.** Registration, verification, reset and the "already registered" notice all work, through Mailpit in compose | unbuilt scope | Invitations, and a real SMTP provider — the mail path itself already exists |
| 13 | **No `last_used_at` on API keys**, so a customer cannot tell which key is safe to revoke | deliberate deferral | A throttled writer fed by usage events rather than a write on the request path: `UsageEvent` already carries `api_key_id` |
| 14 | **Per-service p95/p99 is not computable**: Micrometer publishes `http_server_requests_seconds` with `_count`, `_sum` and `_max` and no `_bucket` | deliberate deferral, recorded with the exact property | `management.metrics.distribution.percentiles-histogram.http.server.requests: true` in each `api/*/application.yaml`. The inference SLOs are unaffected; those timers publish their own buckets |
| 15 | **Three revenue panels have no metric behind them**: `carmonai_usage_seal_lag_seconds`, `carmonai_billing_debit_lag_seconds` and `carmonai_billing_no_credit_organizations` are named in a dashboard and published by no service | unbuilt scope | Instrument the seal job, the debit job and `CreditFlags`; the panels light up as soon as the series exist |
| 16 | **The gateway's `uri` tag is `UNKNOWN` for every public request**, so `http_server_requests_seconds` cannot break public traffic down by route | deliberate deferral | Set the route pattern on the exchange in gateway-service; the gateway's own `spring_cloud_gateway_requests_seconds_count{routeId,…}` covers route-level RED meanwhile |
| 17 | **The two pinned-version advisories were never independently verified.** The review names a vLLM error-message path leak and a Netty request-smuggling family, and says itself that it did not verify them | defect in the record, not in the code | Open both advisories against the pinned image and the resolved Netty version, then either bump or record that the pin is already past them |
| 18 | **vLLM's own key protects only `/v1`, `/v2`, `/inference` and `/cohere`**; `/invocations`, `/pause`, `/abort_requests` and `/update_weights` stay open to anything that can reach the port | deliberate deferral, safe only on a private network | A path allowlist (`/v1/*`, `/health`, `/metrics`) at the edge of any host where the engine is not on an internal network |
| 19 | **The bench's workers ignore `retry-after-ms`.** The service side is fixed — a paying tier now waits up to 1.5 s for a slot — but `docker/bench.sh`'s curl workers retry immediately, so a start race can still show a goodput number the service did not cause | deliberate deferral, offered as the next fix | Make the bench workers honour the header, as an SDK does, and re-run the three-tier check |
| 20 | **The engine gauges refresh once an hour**, because they are read by the reconciler's scrape rather than a per-second pipeline | deliberate deferral | The per-second scrape into memory that the plan places with the multi-replica work; until then `EngineQueueSustained` is a slow trend, and a metric the engine does not expose stays absent rather than reading a false 0 |

## 3 · Recorded ceilings that block nothing today

| # | The gap | Kind | The concrete fix |
|---|---|---|---|
| 21 | **A new organization can call `/v1` until its first debit**, because it has no balance row and therefore no flag. The overshoot is at most one window of usage | deliberate deferral | Trial credit at organization creation — a decision, not a bug |
| 22 | **Flex usage is recorded as mode `batch`**, so a flex request appears in a batch report and is priced like a batch line | deliberate deferral | A `flex` mode of its own: CHECK constraints, price rows and `UsageService.MODES` |
| 23 | **The usage summary prices per day, not per window.** A price that changes inside a day misprices that day's earlier tokens, by under 1 micro-BRL per window; the ledger charge itself stays exact | deliberate deferral | Per-window pricing in the summary, when the price history or the read needs bounding |
| 24 | **No maximum API key lifetime**: the caller decides, and null means never | deliberate deferral | A policy in the console; the server takes what the caller asks for, on purpose |
| 25 | **A crash between an answer's last byte and its `XADD` still loses that event**, about a millisecond of window | accepted risk | None wanted: billing before answering would put a write in front of every request. The reconciliation is what makes it visible |
| 26 | **The reconciliation warns rather than alerts.** Past `max(0.5%, the tokens that can be in flight)` it logs a WARN and sets `carmonai_inference_reconcile_mismatch`; the rule fires and, with no destination, nobody is paged | deliberate deferral | The alerting destination in row 4. The metric and the rule are already there |
| 27 | **The gateway's flood brake falls back to per-replica memory when Valkey is down.** It fails open by design, so an outage multiplies the effective limit by the number of replicas — one today | deliberate deferral | None: the checks that must fail closed are the API-key lookup and the credit flag, and they do |
| 28 | **`client_ip` in the access log is the TCP peer**, so a request that arrived through a proxy would be logged as the proxy | deliberate deferral | nginx with `X-Forwarded-For $remote_addr` (overwritten, never appended) plus the gateway's forwarded-headers strategy, before the log is relied on for a Marco Civil request |
| 29 | **A cancelled stream on the CPU engine is estimated** — input from body bytes, output from content chunks — because llama.cpp reports usage only at the end of a stream | deliberate deferral, CPU only | Nothing while the CPU engine is the CI engine; vLLM reports running usage, so the GPU path is measured, not estimated |
| 30 | **The Batch API's shape differs from OpenAI's in three places**: validation happens at creation with a 400 naming the bad line instead of an asynchronous `validating` → `failed`, there are no list endpoints and no `metadata`, and a file must POST to `/v1/chat/completions` | deliberate deviation | Only if a customer's client depends on the polling state; the deviation is deliberate and cheaper |
| 31 | **`BillingJobs` logs only the exception class**, which hides the cause | defect | Log the root cause's class too. It is one line, and this is the job whose failure means nobody is billed |
| 32 | **Leftover synthetic data in the local database** — bench accounts and organizations, files of experiment organizations | local only, harmless | Nothing; it is the developer's database, and deleting user data is not an agent's decision |

## Why it is like this

- **A gap is labelled by kind, because "future work" flattens three different things.** A **defect** is a bug
  and should be fixed. A **deliberate deferral** is a decision with a trigger, and it should be revisited when
  the trigger fires rather than when somebody notices the note. **Unbuilt scope** is a product that does not
  exist, and the only question worth asking is whether to build it at all.
- **A deferral is not a defect.** Row 9 (batch files in Postgres) and row 6 (in-flight caps in one JVM) are
  shortcuts taken on purpose, with their ceilings written into the code as `ponytail:` comments. Calling them
  bugs would make the honest rows harder to find.
- **Dates are kept because a closed gap is information.** "This was broken and now is not" is worth as much to the next engineer as an open row, so a closed gap stays on the page for a while instead of vanishing.
- **Nothing is worked around in a dashboard.** Where a panel has no metric behind it, the panel is empty and says which metric it is waiting for, rather than animating a substitute.

## What would change it

A gap leaves this page when the code changes, and the rows above name their own triggers: a hosting decision closes rows 9 and 12 together and unblocks rows 5 and 18; a payment provider closes row 1; a console closes row 2 and with it row 13; a second replica must close row 6 first, which is why row 6 is ranked above row 7; an alerting destination closes rows 4 and 26 at once; and the legal checklist closes row 3, the only row here that no amount of engineering can close.

## Where to look

- [inference-plan.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/inference-plan.md) — §13 is the backlog, and the "Phase N built" blocks name each deliberate deviation and its reason.
- [observability.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/observability.md) — the metrics contract, the gaps it names against itself, and the exact wording of each alert rule.
- [plan-review-2026-10-02.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/plan-review-2026-10-02.md) — where the ranked findings came from, including the unverified advisories.
- [docker/prometheus/rules.yml](https://github.com/carmonai/back/blob/main/docker/prometheus/rules.yml) — the alerts that fire into nothing.
- [docker/revenue-check.sh](https://github.com/carmonai/back/blob/main/docker/revenue-check.sh) — the check that exits non-zero when the books and the ledger disagree.
