# Metering what runs

Carmonai runs Prometheus and Grafana inside the compose network, provisioned entirely from files in `docker/`,
and inference-service publishes its own service-level indicators on the management port. This page is what is
measured, what the numbers mean, and — with the same weight — what is not measured yet.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dobs-title" aria-describedby="dobs-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dobs-title">A metric's path from the service to an alert nobody is sent</title>
  <desc id="dobs-desc">inference-service publishes its indicators on the management port; the engine exposes
  its own counters. Prometheus scrapes both every fifteen seconds and evaluates its rule file every sixty
  seconds, producing recording rules and seven alerts. Grafana draws provisioned dashboards and lists those
  alert rules and their firing state. There is no Alertmanager, so a firing rule reaches no destination.</desc>

  <defs>
    <marker id="dobs-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1-3 the metric, 4 the engine's own exposition, 5 the alert with no destination. -->
  <g id="dobs-hops">
    <path id="dobs-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M150 109 H180" marker-end="url(#dobs-arrow)"/>
    <path id="dobs-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M320 109 H350" marker-end="url(#dobs-arrow)"/>
    <path id="dobs-hop3" class="cmn-link cmn-link--flow cmn-dash"
          d="M470 109 H500" marker-end="url(#dobs-arrow)"/>
    <path id="dobs-hop4" class="cmn-link cmn-link--quiet"
          d="M95 190 V150 H200 V138" marker-end="url(#dobs-arrow)"/>
    <path id="dobs-hop5" class="cmn-link cmn-link--quiet"
          d="M410 138 V219 H500" marker-end="url(#dobs-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="dobs-metrics"
     aria-labelledby="dobs-metrics-label">
    <rect x="20" y="80" width="130" height="58" rx="10"/>
    <text id="dobs-metrics-label" x="85" y="100">Metrics</text>
    <text class="cmn-sub" x="85" y="118">inference-service</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dobs-prometheus" aria-labelledby="dobs-prometheus-label">
    <rect x="180" y="80" width="140" height="58" rx="10"/>
    <text id="dobs-prometheus-label" x="250" y="100">Prometheus</text>
    <text class="cmn-sub" x="250" y="118">15 s scrape</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dobs-rules" aria-labelledby="dobs-rules-label">
    <rect x="350" y="80" width="120" height="58" rx="10"/>
    <text id="dobs-rules-label" x="410" y="100">rules.yml</text>
    <text class="cmn-sub" x="410" y="118">7 alerts</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dobs-grafana" aria-labelledby="dobs-grafana-label">
    <rect x="500" y="80" width="120" height="58" rx="10"/>
    <text id="dobs-grafana-label" x="560" y="100">Grafana</text>
    <text class="cmn-sub" x="560" y="118">dashboards</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dobs-engine" aria-labelledby="dobs-engine-label">
    <rect x="20" y="190" width="150" height="58" rx="10"/>
    <text id="dobs-engine-label" x="95" y="210">Engine</text>
    <text class="cmn-sub" x="95" y="228">/metrics, its own</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dobs-nowhere" aria-labelledby="dobs-nowhere-label">
    <rect x="500" y="190" width="180" height="58" rx="10"/>
    <text id="dobs-nowhere-label" x="590" y="210">No destination</text>
    <text class="cmn-sub" x="590" y="228">nobody is paged yet</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M150 109 H180'); --cmn-travel: 0.6s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M320 109 H350'); --cmn-travel: 0.6s; --cmn-delay: 0.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M470 109 H500'); --cmn-travel: 0.6s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M95 190 V150 H200 V138'); --cmn-travel: 1.4s; --cmn-delay: 0.55s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M410 138 V219 H500'); --cmn-travel: 1.5s; --cmn-delay: 0.95s;"></circle>

  <rect class="cmn-label-plate" x="112" y="60" width="76" height="16" rx="4"/>
  <text class="cmn-label" x="150" y="72">every 15 s</text>
  <rect class="cmn-label-plate" x="306" y="60" width="104" height="16" rx="4"/>
  <text class="cmn-label" x="358" y="72">rules every 60 s</text>
  <rect class="cmn-label-plate" x="462" y="60" width="62" height="16" rx="4"/>
  <text class="cmn-label" x="493" y="72">lists them</text>
  <rect class="cmn-label-plate" x="120" y="142" width="110" height="16" rx="4"/>
  <text class="cmn-label" x="175" y="154">engine counters</text>
  <rect class="cmn-label-plate" x="430" y="150" width="140" height="16" rx="4"/>
  <text class="cmn-label" x="500" y="162">no destination</text>
</svg>
</div>
<figcaption>Step 1 is inference-service's own indicators on `:8081/actuator/prometheus`; step 2 is Prometheus
scraping them every 15 s; step 3 is the rule file, evaluated every 60 s; step 4 is Grafana drawing the
provisioned dashboards and listing the Prometheus alert rules. The second input is the engine's own `/metrics`,
scraped directly — the only place queue depth and KV-cache use are visible faster than the hourly reconcile.
Step 5 is where it stops: a firing rule reaches no destination, because none has been chosen.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a metric travelling (solid)</span>
  <span><i class="is-async"></i> a scrape or a scheduled evaluation (dotted)</span>
  <span><i class="is-accent"></i> the observability stack (teal outline)</span>
</div>

1. **inference-service publishes its indicators on the management port**, `:8081/actuator/prometheus` — the
   same port that was never published and never routed before metrics existed.
2. **Prometheus scrapes every service every 15 s**, one job per service so the `job` label carries the service
   name, plus the engine's own `/metrics` with a bearer token read from a file written at container start.
3. **`rules.yml` is evaluated every 60 s**: six recording rules (three latency, three engine) and seven alerts.
4. **Grafana draws three provisioned dashboards** and lists the alert rules and their state, with
   `allowUiUpdates: false`, so a change made in the browser does not survive the next restart.
5. **Nothing leaves the machine.** There is no Alertmanager and no destination, so a firing rule is a colour on
   a dashboard and an entry in a list, and the operator has to be looking.

## What it is

Two halves that fail independently. The **service** half is Micrometer in inference-service, publishing timers
with explicit histogram buckets and counters tagged `model` and `tier`. The **stack** half is Prometheus,
Grafana and a rules file, all provisioned from `docker/`. The second half works even when the first publishes
nothing: the engine's own counters are real series today.

## The indicators inference-service publishes

| Metric | Type | Tags | Buckets (seconds) |
|---|---|---|---|
| `carmonai_inference_ttft_seconds` | timer | `model`, `tier` | 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 20, 30 |
| `carmonai_inference_itl_seconds` | timer | `model`, `tier` | 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 5 |
| `carmonai_inference_queue_wait_seconds` | timer | `model`, `tier` | 0.005, 0.01, 0.02, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10 |
| `carmonai_inference_request_seconds` | timer | `model`, `tier` | 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 30, 60, 120, 300, 600 |
| `carmonai_inference_requests_total` | counter | `model`, `tier`, `outcome`, `code` | — |
| `carmonai_inference_tokens_total` | counter | `model`, `mode`, `kind` | — |
| `carmonai_inference_inflight` | gauge | `model` | — |
| `carmonai_inference_capacity` | gauge | `model`, `tier` | — |
| `carmonai_engine_requests_running`, `…_waiting`, `…_cache_usage` | gauge | `model` | — |
| `carmonai_inference_reconcile_mismatch` | gauge | `model` | — |

The buckets are not Micrometer's defaults: a default timer stops at 30 seconds, and a TTFT past the last bucket
is a p99 that reads as the bucket edge — the one number an operator most needs during an incident. `2` is
present explicitly because the SLO is "TTFT ≤ 2 s". The timers publish buckets rather than client-side
quantiles because Micrometer's Prometheus registry stops publishing `publishPercentiles` as soon as a timer
carries histogram boundaries, and client-side quantiles do not aggregate across replicas anyway;
`histogram_quantile()` over the buckets is what the dashboards and rules compute.

`code` carries the refusal or failure reason — `model_busy`, `rate_limit_exceeded`, `resource_unavailable`,
`context_length_exceeded` — and `none` for a request that ran and ended. `outcome` is `ok`, `error` or
`cancelled`. A request that fails to parse, or names a model that does not exist, has no `model` tag to be
counted under and is not in these numbers at all; the ordinary HTTP metrics still see it.

## No metric carries an organization

This is a rule, not a convention, and `Metrics` states it in its own class comment: *ids and counts only: an
organization, account, API key, request id or prompt never becomes a tag.* Per-organization numbers live in
usage data, where they already exist, are already scoped by a membership check, and are already billed from.

Two reasons. Cardinality: an organization id on a latency timer multiplies every series by the customer count,
which is how a 512 MB Prometheus falls over. And privacy: a metric label is the hardest thing in a system to
delete, and a per-organization time series is a record of when a customer was busy. The gateway follows the
same rule — `carmonai.gateway.rate_limit.refused{route}` — and the verification pass behind this stack checked
it directly: `uri` labels are mapped patterns (`/v1/models`, `/usage/events`,
`/organizations/{id}/tenant`) or `UNKNOWN` on the gateway, and the only `id` label in the whole exposition is
the JVM's own memory pools.

## The reconciliation against the engines' own counters

`Reconciler` is the only thing that can notice usage going missing, and it is why the revenue-integrity
dashboard exists. Every `carmonai.inference.reconcile-every` — 1 hour, and the file says why it is not a
second — it reads each engine's token counters and compares their increase with the tokens usage-service
stored in the same interval. Two tolerances, and both are needed:

```java
return Math.abs(usage - engine) <= Math.max(engine / 200, slack);
```

`engine / 200` is 0.5 %, the plan's figure. `slack` is `(slots + queue) × contextWindow` — the tokens that can
legitimately be in flight across the window's edges, counted by the engine and not yet by usage. Without the
second term the check would warn on every window boundary, and an alert that always fires is an alert nobody
reads. The engines' counters are not the same counter on both engines: vLLM's `vllm:prompt_tokens_total`
includes cache hits and adds a prompt once; llama.cpp counts prompt tokens it computed separately from those it
reused, so its input is `llamacpp:prompt_tokens_total` plus `llamacpp:prompt_tokens_cached_total`.

The verdict is published as a gauge, not only logged: `carmonai_inference_reconcile_mismatch{model}` is `1`
when the two disagree and `0` when they agree — and it is **absent** until a model has two readings to compare,
because a false `0` would claim a check that never ran had passed. `GET /actuator/reconcile` runs the same
check on demand.

## The Prometheus and Grafana stack

Both are in `docker/compose.yaml`, pinned by digest, on the internal network, with no published port.
`prometheus` (`prom/prometheus:v3.15.0`) scrapes every 15 s, evaluates rules every 60 s and keeps 15 days of
local TSDB, capped at 512m/0.5 cpu. `grafana` (`grafana/grafana:13.2.3`) provisions its datasource, three
dashboards and the Prometheus alert list from files, capped at 384m/0.5 cpu.

**Carmonai — SLO & golden signals** has availability, request rate and error share; TTFT p50/p95/p99 against
the 2 s line and TTFT goodput; ITL p95 against 100 ms; queue wait; whole-request p95/p99; in-flight against
capacity; engine running/waiting and KV cache; and tokens per second by mode and kind. **Carmonai — service
RED** has one repeated row per service — rate by route, error share against the 5 % line, duration max and
mean — plus a gateway row by `routeId`. **Carmonai — revenue integrity** has 402s served, usage events received
against `/v1` requests served, events rejected in the last hour, and a collapsed row for the four signals no
service publishes yet.

Seven alert rules, each with what an operator should do about it: `ServiceDown` (2 m), `EngineUnreachable`
(1 m), `EngineQueueSustained` (2 m above the configured depth), `ReconciliationMismatch` (any occurrence),
`UsageIngestionStalled` (5 m), `ErrorShareHigh` (5 % over 5 m) and `PayingTierRefusals` (5 % over 5 m on
standard and enterprise — trial being refused is by design and is not this alert).

The engine's `/metrics` takes the engine key on llama.cpp, and Prometheus expands no environment variable in a
scrape config. The container's entrypoint therefore writes the key from the environment to `/tmp/engine-key`
and then `exec`s Prometheus, which reads it through `bearer_token_file`. The key is never in a repo file.

## The access log is a separate concern

It is deliberately not a metric and not an event. `AccessLogFilter` is a `WebFilter` at
`Ordered.HIGHEST_PRECEDENCE`, outside the security chain, so refused requests are recorded too. It writes one
JSON line per request to logger `access`: request id, method, path without the query string, status,
`duration_ms`, client IP, and whichever of `account_id`, `organization_id`, `api_key_id` the request had. It
skips `/actuator/**`, because readiness probes are not access. `logback-spring.xml` sends that logger to its own
rolling file and nowhere else — `additivity=false`, so it never reaches stdout — and keeps **184 days** of
daily files, about six months, which is the retention Marco Civil da Internet art. 15 asks for. It is the only
place in the platform that records a client IP, and usage events stay IP-free precisely because this file
exists.

## What is not measured

Named rather than papered over. An empty panel that says so is a finding; a substitute metric that animates is
a lie.

- **Tracing.** `spring-boot-starter-opentelemetry` is not on any classpath. `trace_id`/`span_id` in the JSON
  logs remain the only correlation between services, and the gateway strips `traceparent`, `tracestate` and
  `baggage` from inbound requests. A real gap with a real cost: an agent, a collector, a backend, a sampling
  policy.
- **No Alertmanager, no email, no Slack, no PagerDuty.** No destination has been chosen, so firing state in
  Prometheus and Grafana is the deliverable.
- **Per-service p95 and p99 are not computable.** Micrometer publishes `http_server_requests_seconds` with
  `_count`, `_sum` and `_max` but no `_bucket`, so the RED dashboard shows max and mean. The fix is
  `management.metrics.distribution.percentiles-histogram.http.server.requests: true` in each service. The
  inference SLOs are unaffected: those timers declare their own buckets.
- **The gateway's `uri` tag is `UNKNOWN` for every public request**, because Spring Cloud Gateway sets no path
  pattern on the exchange. Route-level RED uses its own
  `spring_cloud_gateway_requests_seconds_count{routeId, routeUri, status, outcome}` instead, which exists.
- **Three revenue panels have no source.** `carmonai_usage_seal_lag_seconds`,
  `carmonai_billing_debit_lag_seconds` and `carmonai_billing_no_credit_organizations` are in no service's
  metric contract. The panels exist, are empty, and say why.
- **llama.cpp exposes no KV-cache usage ratio** on the CPU stack, so `engine:cache_usage` produces no samples
  there and fills from vLLM on the GPU stack. A gauge the engine does not expose stays absent, never `0`.
- **No Postgres or Valkey exporter, no 1-second scrape pipeline, no long-term storage.** The two things an
  exporter would show that matter — balance against ledger, and the `no_credit` flags — are asserted by the
  services that own them.

## Why it is like this

**Rules in Prometheus, not in Grafana.** Grafana lists the Prometheus alert rules and never copies them
(`manageAlerts: true`). One definition, one evaluator, one place a firing state can be read.

**Everything provisioned from files.** Datasource, dashboards and the alert list live in `docker/grafana/`;
rules live in `docker/prometheus/rules.yml`. A replaced container loses nothing, and a change is a pull request
rather than a click.

**Buckets, not quantiles.** Explicit `le` boundaries make `histogram_quantile()` possible in PromQL, aggregate
across replicas, and let an alert read a share — `ttft:goodput_5m` is the `le="2"` bucket divided by the count,
which is the goodput definition the benches already use.

## What would change it

- **A destination for alerts.** Choosing one is a decision, not a default; the rules and their firing state are
  already there for it.
- **`percentiles-histogram` in each service.** One property per `application.yaml`, and the RED dashboard's max
  and mean become p95 and p99.
- **Longer metric history, or tracing.** 15 days of local TSDB is enough for one machine; tracing needs a
  sampling policy, a backend, and a decision about the gateway's header stripping.
- **A second replica.** `Reconciler` runs in every replica and reconciles every model; one reconciler per
  model, with a lock, is the upgrade the code names.

## Where to look

- [Metrics.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Metrics.java)
  — every metric name, tag and bucket boundary, in one file, with the tag rule in its comment.
- [Reconciler.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Reconciler.java)
  — the tolerance, the engine counter mappings and the mismatch gauge.
- [rules.yml](https://github.com/carmonai/back/blob/main/docker/prometheus/rules.yml) — the recording rules and
  all seven alerts, each with what an operator should do about it.
- [prometheus.yml](https://github.com/carmonai/back/blob/main/docker/prometheus/prometheus.yml) — the scrape
  jobs, the 15 s interval and the engine's token file.
- [observability.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/observability.md)
  — the SLI/SLO table this page summarises, the verification pass, and the gaps list.
