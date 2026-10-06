# Carmonai — verified fact sheet

Everything here was read from the code or measured. **Write from this file, not from guesswork.** If a page
needs a fact that is not here, open the file and read it — do not invent a number, a name or a behaviour.
Where a figure is a prototype value rather than a commercial one, say so.

Paths are relative to the repository root (`carmonai/back`).

---

## What the product is

OpenAI-compatible LLM inference, sold as a service in Brazil: prepaid credit in BRL, LGPD by design, tiers
rather than a free plan. Today it is a local prototype on one laptop: two engines, one of them a consumer
GPU.

## Repository shape

One Git repository per module — the user's decision — so `back` holds 13 git submodules under `api/`:

| Submodule | Kind | Owns |
|---|---|---|
| `api/gateway-service` | service | the only public port |
| `api/auth` + `api/auth-service` | library + service | login, JWTs, API keys, console sessions |
| `api/account` + `api/account-service` | library + service | the person: password, email, export, erasure |
| `api/organization` + `api/organization-service` | library + service | the tenant: status, tier, memberships |
| `api/usage` + `api/usage-service` | library + service | what was consumed |
| `api/billing` + `api/billing-service` | library + service | what it costs, and the ledger |
| `api/inference-service` | service | the OpenAI-compatible surface and the engines |
| `api/batch-service` | service | Files and Batch API |

A **library** holds a module's `XController` Feign interface and its `In`/`Out` records — the contract that
the service implements and other services call. A **service** is a Spring Boot application with its own
Postgres schema. `inference-service` and `batch-service` have no library: no Java caller needs them.

Also in `back`: `docker/` (compose, `smoke.sh`, `bench.sh`, `batch-bench.sh`, `revenue-check.sh`),
`.github/workflows/ci.yaml`, the aggregator `pom.xml`, `demo/` (a one-page console used to record the
walkthrough videos), and `.claude/skills/` (the working notes of the project: the inference plan, phase logs,
and the pitfalls list).

---

## Services, file by file

### gateway-service — the only public port
`api/gateway-service/src/main/java/ai/carmonai/gateway/`

| Class | What it does |
|---|---|
| `V1RequestFilter` | `/v1` checks that run *before* authentication: refuses `Transfer-Encoding` and HTTP/1.0 (a body must not be readable two ways), refuses credentials in the query string, requires `Content-Length`, caps the body at **4 MB**. |
| `ApiKeyAuthenticationManager` | Bearer `cmn_…` → format + CRC check (no I/O) → SHA-256 → Valkey `apikey:{hash}` (60 s TTL) → on a miss, auth-service. Caches misses too, so garbage keys cannot hammer auth-service. Refuses an expired key from the cache. Then the `no_credit:{org}` flag → 402. |
| `ApiKeyFormat` | The key's shape and its checksum, so an obviously malformed key never costs a round trip. |
| `IdentityHeadersFilter` | Strips every inbound identity header, then sets `id-account` (from the JWT) or `id-organization` + `id-api-key` + `tier` (from the API key). Also strips `Cookie` except on the two session endpoints. Services trust these headers and nothing else. |
| `RateLimitFilter` | Per-caller token bucket: 10 req/s burst 20 for an authenticated caller, 1 req/s burst 20 for anonymous (login/register). Bucket lives in Valkey, so replicas share it; fails **open** if Valkey is down, because nothing here is the last line of defence. |
| `AccessLogFilter` | One JSON line per request — refusals included — to its own file: request id, method, path without query, status, duration, client IP, ids. Daily files kept **184 days** (Marco Civil art. 15). Nothing goes to stdout. |
| `OriginFilter` | Refuses a POST to login/register/refresh/logout from a foreign `Origin` (CSRF defence for the cookie endpoints). |
| `OpenAiErrors` | The single error writer: `{"error":{"message","type","code"}}`. Messages are fixed strings; nothing from the request is echoed. |
| `ResilienceConfiguration`, `RouteBulkheadFilter`, `FallbackController`, `UpstreamFailureHandler` | Per-route circuit breaker, bulkhead and timeouts; the OpenAI-shaped 503 when an upstream is open, shed, or hanging. |

Routes live in `src/main/resources/application.yaml`. Management port **8081**, never published and never
routed.

### auth-service — authentication and API keys
`api/auth-service/src/main/java/ai/carmonai/auth/` (schema `auth`, 3 migrations)

- `AuthResource` implements `api/auth/.../AuthController`: `/auth/register`, `/auth/login`, `/auth/refresh`,
  `/auth/logout`, `/auth/whoami`, `/auth/jwks`, the API-key endpoints, and the internal `GET /api-keys/{hash}`.
- `JwtService`: **RS256**, access token **15 minutes**, JWKS published. The gateway verifies locally from the
  cached JWKS, so no request-path call to auth-service.
- `SessionService` + `SessionModel`: the console session behind the `__Host-carmonai-rt` refresh cookie
  (HttpOnly, Secure, SameSite=Strict). Only the secret's SHA-256 is stored. Every refresh rotates it; a
  reused cookie means it was copied, and **every** copy is ended. Idle limit **7 days**, absolute **30 days**.
- `ApiKeyService`: `cmn_test_…` outside production; SHA-256 at rest; at most **50** live keys per organization;
  an optional `expires_at` (null = never); `create` / `revoke` / `rotate`, where rotate issues the new key and
  revokes the old one **in one transaction** so a customer never has zero live keys.
- `IdempotentRetryer`: the retry policy for calls that may be repeated.

### account-service — the person
`api/account-service/src/main/java/ai/carmonai/account/` (schema `accounts`, 2 migrations)

- `AccountResource`: register (**always 202**, so nobody can probe who has an account), verify-email,
  password-reset request and confirm, `GET /accounts/{id}/export`, `DELETE /accounts/{id}`.
- Passwords: **Argon2id**. The hash never leaves this service and no `Out` record carries it.
- Verification and reset links: 24 h and 1 h, single use, only the SHA-256 of the token stored.
- Erasure removes memberships, then sessions, then the account, and answers **409** while the account is the
  sole owner of an active organization.
- Email goes out through SMTP (Mailpit locally).

### organization-service — the tenant
`api/organization-service/src/main/java/ai/carmonai/organization/` (schema `organizations`, 1 migration)

- `OrganizationResource`: create, list mine, find by id (members only), close (`DELETE` → status `closed`),
  the internal `member(id, idAccount)` and `tenant(id)` lookups, and the erasure sweep endpoint.
- Membership roles: `owner`, `admin`, `member`.
- `tenant(id)` answers status and tier for API-key authentication — ids only, no name.

### inference-service — the OpenAI surface and the engines
`api/inference-service/src/main/java/ai/carmonai/inference/` (no database of its own)

| Class | What it does |
|---|---|
| `InferenceApplication` | The two routes: `POST /v1/chat/completions`, `GET /v1/models`. |
| `ChatRequest` | The untrusted body is reduced to an **allowlist**: `messages`, `temperature`, `top_p`, `stop`, `presence_penalty`, `frequency_penalty`, `seed`, `tools`, `tool_choice`, `parallel_tool_calls`. `model`, `n=1`, `max_tokens` and `stream_options` are set by the service. `service_tier: "flex"` selects the half-price spare-capacity lane. |
| `Admission` | Rate buckets in Valkey (one Lua script, `buckets.lua`, keys `rl:{orgId:modelId}:requests|input|output`), then in-flight caps in memory. **The tier figure is a shed threshold, not a reservation:** `acquire()` compares `tierCap(model, tier)` against the *model's total* in-flight count, so `trial = C/2` means "a trial request is admitted only while the whole model is below C/2". The per-organization `maxInFlight` (2/4/16) is checked *after* that and, on both models today, is always ≥ its tier's ceiling — so it never binds. A paying tier waits up to `admission-wait` (1.5 s) for a slot; trial, flex and batch lines are refused at once. Waiting requests are ordered by their organization's virtual token counter. |
| `Engine` | The engine client: its own connection pool (**64**), priority per tier, `cache_salt` = organization id, and the time limits — first token 30 s, silence between tokens 30 s, whole non-streamed answer 600 s. One retry, and only before the first byte. A connection failure becomes 503 `engine_unavailable` with `Retry-After: 5`; there is no health poller in this service, so nothing is pre-emptively marked down. |
| `ChatHandler` | Relays the stream, and *how the request ends* (ok / error / cancelled) decides the usage event; the permit is held with `usingWhen` so it is released however the request ends. Settlement of the buckets happens **before** the usage event, deliberately. |
| `Tracker` | Follows one request without keeping its text: first token, inter-token gaps, usage reported by the engine, and the outcome. Its `event_id` is a random **UUID v4, minted when the request ends** (not at admission); only a batch line's id is fixed in advance, which is what makes a re-run bill once. |
| `UsageReporter` | Writes usage events to the Valkey stream `usage:events`; a relay delivers batches to usage-service each second and deletes them once stored. A killed instance loses nothing (append-only file; unconfirmed entries are claimed again after 60 s). |
| `Reconciler` | Every `reconcile-every` (1 h) compares each engine's own token counters with the usage stored meanwhile, and warns past max(0.5%, the tokens that can be in flight). Same check on demand at `/actuator/reconcile`. |
| `Metrics` | The SLIs: TTFT, inter-token latency, queue wait, whole request, request/token counters, in-flight and capacity gauges, engine saturation gauges, `reconcile_mismatch`. Tagged `model` and `tier` only — never an organization. |
| `Caller` | Reads the identity headers the gateway set (or the `batch-line` marker batch-service sends). |

**`Retry-After` is not one number.** A 503 raised *inside* inference-service carries `Retry-After: 5`; a 503 raised by the *gateway* for an open breaker, a shed bulkhead or an unreachable upstream carries `Retry-After: 30`. Both are `api_error`. An SDK sees the same status and a different wait, so a page that quotes one value for "the 503" is wrong.

**Two engine queue numbers disagree.** `docker/compose.gpu.yaml` starts vLLM with `--max-num-seqs 4 --max-num-queued-reqs 8` (an engine backstop of 12), while `application-gpu.yaml` declares `slots: 4, queue: 2` (C+q = 6). Nothing breaks — the service refuses before the engine sees a request — but the engine's stop is looser than the service's and the plan's "C+q as the engine-side backstop" does not hold as written. Recorded as an open item, not silently reconciled.

Configuration (`application.yaml`): models come from configuration, one engine URL each.

### usage-service — what was consumed
`api/usage-service/src/main/java/ai/carmonai/usage/` (schema `usage`, 2 migrations)

- `UsageResource`: internal `POST /usage/events` (idempotent on `(event_id, started_at)`), the internal
  `GET /usage/windows/next` and `GET /usage/totals`, and the customer-facing
  `GET /usage/organizations/{id}/summary`.
- `SealJob` seals 5-minute windows by arrival, after a 60 s grace period (compose: 10 s windows, 2 s grace, so
  billing shows within seconds).
- `PartitionJob` keeps daily partitions for **90 days**.
- Events carry ids and counts: organization, API key, model, mode (`sync`/`batch`), tier, input, cached input,
  output, status, start time, TTFT, duration. **Never a prompt or an answer.**

### billing-service — what it costs
`api/billing-service/src/main/java/ai/carmonai/billing/` (schema `billing`, 2 migrations)

- `BillingService` pulls the next sealed window (cursor), prices it **at the window's start**, and in one
  transaction writes one ledger entry per (organization, model, mode) and updates the balance in the same
  transaction. A missing price stops billing **before** anything is written: it never bills at zero.
- The ledger and the price table are **append-only**, enforced by database triggers that refuse UPDATE, DELETE
  and TRUNCATE.
- `CreditFlags` sets `no_credit:{org}` in Valkey when `balance + credit_limit ≤ 0`; the gateway turns that
  into **402**.
- `reconcile()` re-syncs every flag and checks every balance against the sum of its ledger — a `FULL OUTER
  JOIN`, so an organization with ledger entries but no balance row is **loud instead of invisible**. Every
  10 minutes, and on demand at `GET /actuator/reconcile`. `docker/revenue-check.sh` exits non-zero when the
  books disagree.
- Customer-facing `GET /billing/organizations/{id}/balance`; internal `POST /billing/grants` (idempotent by
  `idempotencyKey`) and `GET /billing/prices`.
- `Price` (record + `cost`) lives in the **library**, so both services use one arithmetic.

### batch-service — Files and Batch API
`api/batch-service/src/main/java/ai/carmonai/batch/` (schema `batch`, 2 migrations)

- `BatchResource`: `/v1/files`, `/v1/files/{id}/content`, `/v1/batches`, `/v1/batches/{id}`,
  `/v1/batches/{id}/cancel`.
- Upload stores the content in Postgres `bytea`, expires after 30 days, is never logged, and is capped by the
  gateway's **4 MB** `/v1` body limit (OpenAI allows 200 MB — a known gap).
- `BatchService` validates the whole file at creation: unique `custom_id`s, POST to `/v1/chat/completions`, one
  model, at most 50,000 lines, a 24 h window.
- `BatchWorker`: two workers claim a line with `FOR UPDATE SKIP LOCKED` and **hold the row lock for the whole
  call** — the lock is the lease, so a crash just makes the line claimable again.
- A line's usage event id is a name-based UUID of (batch, line) and its `started_at` is the batch's creation
  time, so it is **billed once** however often it runs.
- `BatchFinisher` completes, cancels or expires batches and writes the output and error files.
- Closing an organization erases its batch data within a minute (a sweep asks organization-service for status).

---

## The numbers

**Tiers** (per organization and model). The last column is the **model's total in-flight ceiling for that
tier** — a shed threshold, not a reserved allocation: the check is `modelTotalInFlight >= ceiling`, so
`trial = C/2` reads "trial is admitted only while the whole model is below C/2".

| Tier | Requests/min | Input tok/min | Output tok/min | Per-org in flight | Model in-flight ceiling |
|---|---|---|---|---|---|
| trial | 20 | 20,000 | 10,000 | 2 | C/2 |
| standard | 300 | 200,000 | 50,000 | 4 | 0.85·C |
| enterprise | 3,000 | 2,000,000 | 500,000 | 16 | C+q |

The per-organization column never binds on either model today, because every value is ≥ its tier's ceiling
and the ceiling is tested first. It is a limit waiting for a bigger engine.

**Prices** (placeholder prototype values, BRL per million tokens): qwen3-0.6b sync 0.10 in / 0.05 cached /
0.40 out; qwen3-4b sync 0.50 / 0.25 / 2.00; batch and flex are half the sync price.

**Engine capacity measured on the laptop's RTX 3050 (6 GB)**, so **C = 4** slots and **q = 2** queue:

| Concurrency | Output tok/s | TTFT p95 | Goodput |
|---|---|---|---|
| 1 | 46 | 254 ms | 100% |
| 2 | 88 | 314 ms | 100% |
| 4 | 157 | 801 ms | 100% |
| 8 | 159 | 4,033 ms | 10% |

Exit checks: three tiers at once → enterprise goodput 98%, TTFT p95 253–351 ms, TPOT p95 22 ms, trial refused
in 9–16 ms at p95. Batch: 10,000 lines in 999 s (10 lines/s) beside enterprise traffic at 100% goodput, and
SIGKILLing batch-service mid-call still billed exactly once.

**Money unit**: `bigint` micro-BRL (1 BRL = 1,000,000). Cost per window is rounded half up, once.

---

## Decisions worth quoting (from the user, they bind the whole project)

- Secrets come from env or a secret manager — never the repo, never a default.
- **No personal data in logs, usage or the ledger**: ids and counts only. A smoke test greps every log, the
  access log and a database dump for a canary string.
- Branch, PR, wait: never push to `main`; merge only when the user says merge.
- "Ponytail mode": the least code that works, with each deliberate shortcut marked by a `ponytail:` comment
  naming its ceiling and upgrade path, and one runnable check behind every non-trivial piece of logic.
- Java 25 LTS, Spring Boot 4.1, Spring Cloud 2025.1, Jackson 3, Testcontainers 2.
- Kafka only when an event gets a **second** consumer; until then idempotent HTTP and pull sweeps.

---

## Deliberate shortcuts, with their ceiling

| Shortcut | Ceiling | Upgrade path |
|---|---|---|
| Append-only ledger enforced by DB triggers | one DB role | separate roles when the DB is shared |
| Batch files in Postgres `bytea` | 4 MB, not 200 MB | object storage when hosting is decided |
| Usage relay is a Valkey stream, not Kafka | one consumer | Kafka when an event gets a second consumer |
| One engine endpoint per model | one GPU, no replica routing | multi-replica routing with more GPUs |
| In-flight caps in one JVM's memory | one replica's view | shared counters before a second replica |
| Per-day pricing in the usage summary | a mid-day price change misprices that day | per-window pricing with a cursor |
| No Alertmanager destination | alerts are visible, nobody is paged | choose a destination |
| No maximum API key lifetime | the caller decides | a policy in the console |
| Flex usage recorded as mode `batch` | no separate flex price or report | a `flex` mode of its own |

## Honest gaps

`GET /v1/embeddings` does not exist. There is no payment rail (credit comes from a staff grant), no customer
console, and no Kubernetes or second replica. Password resets have a per-IP throttle but no per-email one.
**The flood brake is Valkey-backed** (one Lua token bucket, shared by replicas) and answers an OpenAI-shaped
429 with `retry-after` and `retry-after-ms`; only its fail-open path keeps an in-memory bucket, for the case
where Valkey itself is unreachable. **Observability exists**: `docker/prometheus/rules.yml` holds the
recording rules and 7 alerts and `docker/grafana/dashboards/` the three dashboards, all built 2026-10-05;
what is missing is an **Alertmanager destination**, so the rules fire into nothing. Tracing is not wired.
Per-service p95/p99 needs
`management.metrics.distribution.percentiles-histogram.http.server.requests: true` in each service. Full list
in `.claude/skills/carmonai-architecture/references/inference-plan.md` §13.

## Which documents are current, and which lag

This matters because several of the project's own notes are behind the code, and a page that trusts the wrong
one will state something false:

| Document | State |
|---|---|
| `inference-plan.md` | **Current.** Its top block carries one entry per change, newest first, including 2026-10-05/06. |
| `references/observability.md` | **Current.** Written with the Prometheus/Grafana work. |
| `references/phase-*-progress.md`, `revenue-leaks-progress.md` | Current for their phase. |
| `references/plan-review-2026-10-02.md` | A snapshot of the review that produced the ranked gaps. Its findings are inputs, not status. |
| `.claude/skills/carmonai/SKILL.md` | **Stale.** It still calls observability "later" and says there is no refresh flow, which phase 7a part 2 built. |
| The handoff page (`Carmonai Handoff.md`, 2026-10-04) | **Behind by one pass.** Its §13 still lists gaps 4 (fairness) and 6 (instant 429) as open — both were built on 2026-10-05 — and it contradicts itself about whether the demo console PR is merged. |

**The rule the project already states, and which resolves every conflict: when a note and the repository
disagree, the repository wins.**

## Corrections to earlier drafts of this sheet

Two claims in the first version of this file were wrong, and both came from trusting a summary instead of the
code. They are recorded here so that nobody re-derives them:

1. "The gateway's flood brake is per-replica in memory." It is not any more: `RateLimitFilter` keeps the
   bucket in Valkey through one Lua round trip, with in-memory buckets only on the fail-open path. It answers
   an OpenAI-shaped 429 with `retry-after` and `retry-after-ms`.
2. "There is no observability." Prometheus and Grafana were added on 2026-10-05, with 7 alert rules and 3
   provisioned dashboards. What is genuinely missing is the alerting *destination*.
