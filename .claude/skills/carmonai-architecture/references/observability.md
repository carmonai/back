# Observability: metrics, dashboards, alerts

Built 2026-10-05 (task B). Prometheus scrapes every service's management port and the engine's own
`/metrics`; Grafana provisions its datasource, three dashboards and its list of alert rules from files in
`docker/`. Nothing is clicked into a container, and nothing that matters is published: metrics stay on the
internal compose network, like the management port they come from (override 6).

The gaps are in §Gaps, named rather than papered over. An empty panel on a dashboard that says so is a
finding; a substitute metric that animates is a lie.

## What runs

| Container | Image | Job | Limits |
|---|---|---|---|
| `prometheus` | `prom/prometheus:v3.15.0` (digest-pinned) | scrape every 15 s, evaluate rules every 60 s, 15 days of local TSDB | 512m / 0.5 cpu |
| `grafana` | `grafana/grafana:13.2.3` (digest-pinned) | provisioned datasource, three dashboards, the Prometheus alert list | 384m / 0.5 cpu |

- Scrape interval **15 s**. The plan's 1 s pipeline belongs to multi-replica autoscaling (§7) and is not
  built; 15 s is the resolution at which an incident is still visible and the VM stays cheap.
- Files: `docker/prometheus/{prometheus.yml,rules.yml}` (mounted read-only), `docker/grafana/provisioning/`
  and `docker/grafana/dashboards/` (read-only, `allowUiUpdates: false` — a change made in the browser would
  not survive the next container restart, so it is not allowed to look like it did).
- Grafana's admin password comes from `GRAFANA_ADMIN_PASSWORD` in `.env`, with no default: compose refuses
  to start without it. Grafana runs as its image's own non-root user (472).
- The engine's `/metrics` takes the engine key on llama.cpp. Prometheus expands no environment variable in a
  scrape config, so the container entrypoint writes the key from the environment to `/tmp/engine-key`
  (`bearer_token_file`) and then execs prometheus. The key is never in a repo file.

## SLIs, SLOs, and where every number comes from

| SLI | SLO | Source of the number |
|---|---|---|
| TTFT p95, streamed | ≤ 2 s | Phase-3 bench goodput definition (TTFT ≤ 2 s and TPOT ≤ 100 ms); plan §8 |
| TTFT goodput (share within 2 s) | ≥ 95% | Phase-4/5 exit check ("enterprise goodput ≥ 95%") |
| Inter-token latency (TPOT) p95 | ≤ 100 ms | Phase-3 bench (measured 24 ms at C = 4) |
| Engine queue depth | ≤ configured: llama.cpp 2, vLLM 8 | `application.yaml` `queue: 2`; `compose.gpu.yaml` `--max-num-queued-reqs 8` |
| Error share (inference) | ≤ 5% over 5 m | Same 5% as the goodput target above |
| Refusals on paying tiers (429) | ≤ 5% over 5 m | Phase-4/5 exit check, enterprise goodput ≥ 95% |
| Service reachability | every target UP; `up == 0` for 2 m alerts | This stack. No numeric availability SLO exists yet (plan §8 leaves it per model class) |
| Reconciliation (engine counters vs stored usage) | any disagreement | `Reconciler`: more than max(0.5%, (slots + queue) × context) |
| Usage ingestion | ≥ 1 stored event per served `/v1` request | Every answered request is billable |
| Per-service RED latency | no SLO | Plan §8 sets SLOs per model class on the inference path, not per internal service |

No number above was invented for this stack: each is the one the code, the compose file or a recorded bench
already uses. If a target looks wrong, it is wrong in the same place it was before — say so there.

## The metric contract (task A publishes it; this stack consumes it)

Status on 2026-10-05, measured against the running CPU stack: **every `carmonai_*` metric was absent**, so
the SLO panels are empty. That is task A's side, not a dashboard defect.

| Metric | Tags | Published 2026-10-05 |
|---|---|---|
| `carmonai_inference_ttft_seconds` (0.05…30 s, q 0.5/0.95/0.99) | `model`, `tier` | no |
| `carmonai_inference_itl_seconds` (0.005…5 s) | `model`, `tier` | no |
| `carmonai_inference_queue_wait_seconds` (0.005…10 s) | `model`, `tier` | no |
| `carmonai_inference_request_seconds` (0.05…600 s) | `model`, `tier` | no |
| `carmonai_inference_requests_total` | `model`, `tier`, `outcome`, `code` | no |
| `carmonai_inference_tokens_total` | `model`, `mode`, `kind` | no |
| `carmonai_inference_inflight` | `model` | no |
| `carmonai_inference_capacity` | `model`, `tier` | no |
| `carmonai_engine_requests_running` / `_waiting` / `_cache_usage` | `model` | no |
| `carmonai_inference_reconcile_mismatch` | `model` | **not in any contract** — see §Gaps |

Because `engine:requests_waiting` and the engine panels come from the engine's exposition directly, the
engine half of the stack works today: `llamacpp:requests_processing`, `llamacpp:requests_deferred` and
`vllm:num_requests_waiting` are real, live series.

## Dashboards

| Dashboard | Panels |
|---|---|
| **Carmonai — SLO & golden signals** (`carmonai-slo`) | availability, request rate, error share; TTFT p50/p95/p99 against the 2 s line, TTFT goodput, ITL p95 against 100 ms, queue wait, whole-request p95/p99; in-flight vs capacity, engine running/waiting, engine KV cache, tokens/s by mode and kind |
| **Carmonai — service RED (per service)** (`carmonai-red`) | one repeated row per service: rate by route, error share against the 5% line, duration (max and mean); plus a gateway row by `routeId` for the reason in §Gaps |
| **Carmonai — revenue integrity** (`carmonai-revenue`) | 402s served, usage events received vs `/v1` requests served against "at least one event per request", events rejected in the last hour; collapsed row for the four signals no service publishes yet |

Every panel carries its threshold on the panel and its reasoning in its description, so red/green is
readable without a key.

## Alerts and what an operator does

Prometheus owns the rules (`docker/prometheus/rules.yml`); Grafana lists them and their firing state beside
its own alerting (`manageAlerts: true`) and never copies them. **There is no Alertmanager**: no destination
has been chosen, so firing state in Grafana and Prometheus is the deliverable, and a notification channel is
a decision for the user, not a default we pick for them.

| Alert | Fires when | What the operator does |
|---|---|---|
| `ServiceDown` | a service's scrape fails for 2 m | Container down, restarting, or its management port not listening. Check the container's health and logs. Metrics gone means every other SLI for that service is gone too |
| `EngineUnreachable` | no engine target is up for 1 m | Inference answers 503 after one retry. Check the engine container (first start downloads the model: slow is not broken) and that `.env`'s key is the one the engine started with |
| `EngineQueueSustained` | waiting above the configured depth (2 llama, 8 vLLM) for 2 m | Admission is letting more through than the engine can start; TTFT is paying for it. Check TTFT p95 and refusals; if the engine is healthy, revisit C (slots) |
| `ReconciliationMismatch` | the hourly reconcile disagrees (any occurrence) | Tokens the engine processed are not in usage-service: revenue that will never be billed. `GET /actuator/reconcile` on inference-service (management port, internal) gives the delta; check usage-service ingestion and the `usage:events` stream in Valkey |
| `UsageIngestionStalled` | `/v1` requests are being served and usage-service has received nothing for 5 m | Every one of those requests is unbilled right now. Events wait in the Valkey stream, so nothing is lost yet: look for a dead relay or a full stream, and at the usage container |
| `ErrorShareHigh` | more than 5% of inference requests fail for 5 m | Read the `code` tag: 502/503 are the engine or the connection pool; 500 is a defect in inference-service |
| `PayingTierRefusals` | more than 5% of standard/enterprise requests are refused (429) for 5 m | Capacity (C), a tier's share, or one organization holding the slots (gap 4, VTC). Trial being refused is by design and is not this alert |

## Gaps

Named, with the owner. None of these is worked around in a dashboard.

1. **Task A's `carmonai_inference_*` metrics do not exist yet** (measured 2026-10-05: not one series).
   Every SLO panel and five alerts are wired to the contract and waiting. Nothing to do here.
2. **No reconciliation metric exists in any task's contract.** The existing WARN in `Reconciler` is a log
   line and nothing else, so `ReconciliationMismatch` and its panel wait on
   `carmonai_inference_reconcile_mismatch{model}` (1 = the existing check disagrees, 0 = it agrees — the
   tolerance stays in Java, not duplicated in PromQL). Task A owns the instrumenting side; the on-demand
   `GET /actuator/reconcile` (A5) carries the token delta.
3. **Task D's brief contains no metric contract at all**, so three revenue panels have no source:
   `carmonai_usage_seal_lag_seconds`, `carmonai_billing_debit_lag_seconds`,
   `carmonai_billing_no_credit_organizations`. The panels exist, are empty, and say so. 402s and the
   ingest-vs-served comparison work today because both are ordinary HTTP metrics.
4. **No percentiles for the built-in HTTP metrics.** Micrometer publishes `http_server_requests_seconds`
   with `_count`, `_sum` and `_max` but no `_bucket` — so per-service p95/p99 is not computable until each
   service sets `management.metrics.distribution.percentiles-histogram.http.server.requests: true`. That is
   an `api/*/application.yaml` change, outside task B; the RED dashboard shows max and mean meanwhile. The
   inference SLOs are unaffected: the contract's timers publish explicit buckets.
5. **The gateway's `uri` tag is `UNKNOWN` for every public request** (measured: 3 of 3). Spring Cloud
   Gateway sets no path pattern on the exchange, so `http_server_requests_seconds` cannot break public
   traffic down by route. Route-level RED for the gateway uses its own
   `spring_cloud_gateway_requests_seconds_count{routeId, routeUri, status, outcome}` instead, which exists
   and carries no personal data. Fixing the `uri` tag would mean a filter in `api/gateway-service` (task C).
6. **llama.cpp in this image exposes no KV-cache usage ratio**, so `engine:cache_usage` is empty on the CPU
   stack and fills from vLLM on the GPU stack. A gauge the engine does not expose stays absent, never 0.
7. **The task A brief names the wrong vLLM metric.** It asks for `vllm:gpu_cache_usage_perc`; vLLM v0.30.0
   (the pinned image) exposes `vllm:kv_cache_usage_perc`, whose help text is "KV-cache usage. 1 means 100
   percent usage" — a 0-1 ratio, not a percentage, so it must not be divided by 100. Checked directly
   against the running GPU container on 2026-10-05. `vllm:num_requests_running` and
   `vllm:num_requests_waiting` are correct as written in the brief.

## Deliberately not built

- **Tracing / OpenTelemetry.** A real gap, but a separate decision with a real cost (agent, collector,
  backend, sampling policy) and this pass is one task wide. `trace_id`/`span_id` in the JSON logs (platform.md)
  remain the only correlation.
- **Alertmanager, email, Slack, PagerDuty.** No destination has been chosen. Rules and firing state only.
- **Long-term metric storage** (Thanos, S3, remote write). 15 days of local TSDB is enough to investigate an
  incident on one VM; anything more is infrastructure nobody asked for yet.
- **A 1 s scrape pipeline** (see §What runs).
- **Postgres and Valkey exporters.** The two things they would show that matter — balance vs ledger and the
  `no_credit` flags — are better asserted by the services that own them (D4), and two more containers on a
  7.6 GB VM is a real cost for a startup.

## Verification, 2026-10-05, CPU stack

`docker compose up -d --build --wait` (14 containers, all healthy), then `docker compose down`:

- 10 of 10 Prometheus targets UP: the eight services on `:8081/actuator/prometheus`, `llama:8080/metrics`
  (with the key written at container start, so the authenticated engine scrape works) and Prometheus itself.
- 13 rules loaded in 5 groups, every one `health=ok`; `engine:requests_running` and
  `engine:requests_waiting` produce real samples, `engine:cache_usage` correctly produces none (gap 6).
- 33 dashboard panel expressions executed against Prometheus: 0 errors, the rest empty only where §Gaps
  1–3 say so (or where no traffic has reached the route yet).
- Grafana: datasource provisioned and read-only (`manageAlerts: true`), three dashboards in folder
  *Carmonai*, login required (an unauthenticated request gets 401), and the seven alerting rules listed
  through the same API its Alerting UI uses.
- No label carries personal data: `uri` values are mapped patterns (`/v1/models`, `/usage/events`,
  `/organizations/{id}/tenant`) or `UNKNOWN` on the gateway, the only `id` label is the JVM's memory pools,
  and the gateway's route tags are route names and upstream URLs.
- The engine names were checked against the running containers, which is how gap 7 was found: vLLM v0.30.0
  exposes `kv_cache_usage_perc` (0-1), not the `gpu_cache_usage_perc` the task A brief names.

A temporary published port (9090, 3000) was used only for the acceptance curls above; it is reverted, and
`docker compose config` shows the gateway's 8080 as the only host binding in the whole file.
