# Carmonai inference plan

Revision 2, 2026-10-02. Revision 1 was reviewed by one subagent per topic; their raw findings are in [plan-review-2026-10-02.md](plan-review-2026-10-02.md). Nothing here is built. ❓ marks a decision still open; the recommendation comes first.

**Progress:** phase 0 merged 2026-10-03 (CI green). Phase 1 built 2026-10-03 (organization + organization-service, API keys in auth-service, Valkey, gateway `/v1` key chain, erasure via organization-service); deviations from the §11 row, on purpose:
- `ApiKey.created_by` dropped: nothing reads it until audit (phase 7), and keeping it would make erasure call auth-service too.
- Gateway flood brake stays the in-memory per-replica limiter (now keyed by any principal, fixing the API-key bug); Valkey-backed limiting comes with a second gateway replica or with the phase-5 token buckets.
- Closing or suspending an organization reaches its keys within the gateway's 60 s cache TTL (revocation itself is immediate).
- `DELETE /organizations/{id}` (owner: status `closed`) added, because erasure needs a way out for a sole owner.
- `/v1` hardening of §3 step 4 (Transfer-Encoding, key-like query strings) moves to phase 2, with the inference route.
- Console sessions, invitations, email verification and roles beyond owner stay deferred (tenancy review: slices S, T, P).

**Phase 2 built 2026-10-03** (overnight; working log in [phase-2-progress.md](phase-2-progress.md)): inference-service relays `/v1/chat/completions` and `/v1/models` to llama.cpp + Qwen3-0.6B on CPU, usage + usage-service meter it, the gateway routes `/v1` with the hardening filter. Deviations, on purpose:
- No traces yet: nothing to view them with; they move to phase 4 with the dashboards.
- `event_id` is a random UUID (v4): uniqueness is all the dedupe needs.
- usage-service uses plain JDBC, not Spring Data JPA: idempotent batch inserts (`ON CONFLICT`) and partition DDL are SQL work.
- inference-service generates `X-Request-Id` itself and returns it (the gateway sets none yet); clients' ids are ignored.
- llama.cpp reports usage only at the end of a stream, so a cancelled stream on the CPU engine is estimated (input = body bytes ÷ 4, output = content chunks); vLLM (phase 3) reports running usage.
- Qwen3 thinking is turned off at the engine (`--chat-template-kwargs '{"enable_thinking":false}'`); `--reasoning-budget 0` doesn't do it in this llama.cpp build.
- No customer-facing usage endpoint yet: the smoke test reads `usage.usage_event` directly. Billing (phase 4) reads the sealed windows.

**Phase 3 built 2026-10-03** (log: [phase-3-progress.md](phase-3-progress.md)): vLLM v0.30.0 serves Qwen3-4B-Instruct-2507 (AWQ 4-bit) on the laptop RTX 3050 6 GB through `docker/compose.gpu.yaml`; inference-service sends vLLM the tier priority (trial 20, standard 10, enterprise 0) and `cache_salt` = organization id; the smoke test passes on both engines. Measured: **C = 4** concurrent requests at ~157 output tok/s, TTFT p95 0.8 s, TPOT p95 24 ms (goodput 100%); at 8 the extra requests only queue (TTFT 4 s, goodput 10%). Deviations, on purpose:
- `--gpu-memory-utilization 0.78` (not 0.90): Windows keeps ~1 GB of VRAM for the desktop and CUDA under WSL2 ~0.9 GiB more.
- `--kv-cache-dtype fp8`: with bf16 the KV cache (0.44 GiB) couldn't hold one 4096-token request; FP8 holds 5,888 tokens. Quality impact to check in the optimization backlog (§13).
- The engine port of vLLM stays internal like llama.cpp; the admission caps from these numbers are phase 5 work.

**Phase 5 built 2026-10-03** (log: [phase-5-progress.md](phase-5-progress.md)): inference-service admits each chat request before the engine: rate buckets per organization and model in Valkey (requests, input tokens, output tokens per minute; one Lua script; settled with real counts at the end), then in-flight caps in memory (trial half of C, standard 85%, enterprise C + q; plus a cap per organization), held until the response ends. Refusals are immediate 429s with `retry-after`/`retry-after-ms` (codes `rate_limit_exceeded`, `model_busy`); answers carry `x-ratelimit-*` headers. Bench through the gateway on the RTX 3050 (`docker/bench.sh`, three tiers at once): enterprise goodput 98% at C = 4 (TTFT p95 ≤ 351 ms), trial 429 p95 ≤ 16 ms (max 91 ms), no TTFT timeouts. Deviations, on purpose:
- Limits are per tier, applied per organization and model; no "model class" axis while there are two models.
- Buckets are checked before the caps, so a request refused by a cap still counts against the buckets (OpenAI counts unsuccessful requests too) and the cap is taken with no async gap before the engine call.
- q = 2 on vLLM (phase 3: a longer queue pushes TTFT p95 past 2 s); `--max-num-queued-reqs 8` stays as the engine-side backstop.
- No engine health-check loop: a dead engine already answers 503 within ~2 s (1 s connect timeout, one retry).
- No dashboards or admission metrics yet; they come with the observability stack (platform.md). The bench prints the numbers.
- Rate-limit headers cover requests and input tokens (OpenAI's names); no `x-ratelimit-reset-*`.
- The bench uses curl workers, not `vllm bench serve`: a second torch process beside vLLM, llama.cpp and nine JVMs ran the 7.6 GB Docker VM out of memory.
- The gateway's flood brake still answers 429 with an empty body on `/v1` (not OpenAI-shaped).

**Phase 4 built 2026-10-03** (log: [phase-4-progress.md](phase-4-progress.md)): billing-service (schema `billing`) bills sealed usage windows into an append-only ledger in micro-BRL, keeps a per-organization balance in the same transaction, and flags `no_credit:{org}` in Valkey when `balance + credit_limit ≤ 0`; the gateway answers `/v1` with 402 `insufficient_balance` while the flag is set. Credit comes from an internal grant (`POST /billing/grants`, idempotent). usage-service gained `GET /usage/windows/next?after=` for the debit job. Deviations, on purpose:
- Append-only is enforced by triggers (UPDATE/DELETE/TRUNCATE refused on `ledger_entry` and `price`; new prices must start in the future), not by a second DB role: one DB user in the prototype. Roles when a shared DB exists.
- No customer-facing balance endpoint (no console yet); the smoke test reads balances with psql.
- Compose runs 10 s usage windows (2 s grace, debit every 2 s) so billing shows within seconds; service defaults stay 5 min / 60 s.
- A new organization can call `/v1` until its first debit (no balance row, no flag); the overshoot is at most one window of usage. Trial credit on org creation is a later decision.
- Flags are synced after every debit and grant, plus a reconciliation every 10 min that re-syncs all flags and logs (ids only) any balance that differs from the sum of its ledger; it never fixes anything itself.
- Seeded prices are placeholders, not commercial prices.

**Update 2026-10-03:** user accepted the §12 recommendations; the prototype runs locally on the laptop's RTX 3050 6 GB (no free cloud GPU needed); one repo per module stays.

**What changed from revision 1:** prototype on a local GPU with `Qwen3-4B-Instruct-2507` (4-bit); Kafka, outbox and Pix deferred (usage goes over HTTP, credits granted manually); token limits and shedding moved from the gateway to inference-service; tier priority alone was found not to protect enterprise, so capacity is reserved per tier; three billing bugs fixed (cancelled streams, partition dedupe, batch retries); phase 0 cut to tests + CI; Valkey instead of Redis; a real-engine phase added before admission work; engine endpoints outside `/v1` found unauthenticated; §9 rewritten with enforceable no-content-in-logs guards and a canary check, the Marco Civil access log, CSAM reporting, controller vs operator incident deadlines, and a checklist for before real customer data.

## 1. What carries over from the video, and what doesn't

The video (skill `batch-inference-design`) designs for a toy GPU: one batch at a time, fixed 100 ms, one answer per request. Real engines (vLLM, SGLang, TensorRT-LLM) batch continuously at every token, the KV cache in GPU memory limits concurrency, and answers stream.

| Video idea | Real LLM serving | Carmonai |
|---|---|---|
| Hand-written batcher, 100 items or 40 ms | Engine batches every step, 2–4×+ throughput over static batching | **No batcher in Java** |
| Index demux, futures | One HTTP/SSE stream per request | WebFlux relays each stream |
| Three Redis tier queues | vLLM `--scheduling-policy priority` orders the waiting queue, but a waiting request never evicts running ones; it only preempts running requests short of KV blocks | **Priority + per-tier in-flight caps** at admission; no Redis queue on the interactive path |
| Capacity in requests/s | Capacity in tokens/s; prompt length dominates | Limits and prices in tokens, measured |
| One latency number | TTFT, ITL, end-to-end; goodput | SLOs on TTFT and ITL, goodput as the test pass mark |
| Scale on GPU utilization | Utilization reads busy when healthy | Waiting requests and KV-cache usage (later, >1 replica) |
| Edge 429, shed lower tiers first | Same | **Keep**, in inference-service |
| One retry, then a clean 503 | Safe only before the first token reaches the client | **Retry once on connect error/5xx before the first byte** |
| No DB on the hot path | Same | **Keep**: Valkey lookups and in-memory counters only |
| Batch inference product | Async batch at a discount (OpenAI: 50%, 24 h) | Batch API, phase 6, fills idle capacity at the lowest priority |

## 2. Target architecture

```
client ─HTTPS─> nginx ─> gateway-service (WebFlux)
                           ├─ console routes, JWT ──> account / auth / organization / billing / usage
                           └─ /v1/chat/completions, /v1/models, API key ──> inference-service (WebFlux)
                                                         ├─ admission (Valkey buckets, in-memory caps)
                                                         ├─ field allowlist, relay SSE, retry before 1st byte
                                                         ├─> engine: llama.cpp (CPU, compose) | vLLM (free GPU, behind an edge allowlist)
                                                         └─ UsageEvent ─HTTP batch─> usage-service <─pull sealed windows── billing
Valkey: api-key cache · org flags (suspended / no credit) · rate buckets
Kafka: later, when an event gets a second consumer
```

- **gateway-service** is the edge: credentials, tenant flags, a flat flood brake, routing. It knows nothing about models.
- **inference-service** (new, WebFlux) is the only caller of engines; batch-service will use it too. Gateway filters can't read an SSE body without buffering it, and long streams stay out of the login path, so it is worth the extra hop. It allowlists OpenAI request fields and sets `model`, `priority`, `cache_salt`, `n`, max tokens and `stream_options` itself; admits; relays with a flush per chunk; times TTFT and idle gaps; retries once before the first byte; publishes `UsageEvent`. It treats the body as JSON with a few parsed fields, not Java records for the whole OpenAI schema, and ships no Feign library until a Java caller exists.
- **Engines** run as containers or notebooks (Python/CUDA). Java never runs a model. Phase 2: one engine URL per model. Replica picking (fewest waiting) only when there is more than one replica; the llm-d router / Gateway API Inference Extension replaces it on Kubernetes.

## 3. One streaming request, step by step

1. **Gateway, credentials**: `Authorization: Bearer cmn_…` → checksum check (no I/O for garbage) → SHA-256 → Valkey `apikey:{hash}` → {key, org, org status, tier}; miss → auth-service → cache 60 s. Unknown/revoked → 401. Valkey down → 503 with `Retry-After` (fail closed, so clients don't think the key died).
2. **Gateway, tenant flags**: org suspended → 403; `no_credit` flag → 402 (not OpenAI's 429 `insufficient_quota`: the OpenAI SDK retries 429s).
3. **Gateway, flood brake**: flat requests/s per API key with the built-in `RedisRateLimiter` (it fails open; inference-service caps still protect the GPU). Console and login keep the in-memory per-IP limiter.
4. **Gateway → inference-service**: only `/v1/chat/completions` and `/v1/models`. Before auth, `/v1` rejects with 400 any `Transfer-Encoding`, HTTP/1.0, or a query string carrying `cmn_`/`key`/`token`; no CORS on `/v1`. Strips `id-account`, `id-organization`, `id-api-key`, `tier`, `Cookie`, `Forwarded`, `X-Forwarded-*`, `traceparent`, `tracestate`, `baggage` on every route and sets the identity ones from the principal; sets `X-Request-Id`; removes `Authorization`; requires `Content-Length` ≤ 4 MB (411/413; the built-in `RequestSize` filter misses chunked bodies). Route metadata `response-timeout: 660000` (the gateway only times the wait for headers, which inference-service sends with the first token).
5. **inference-service, request**: unknown `model` → 404; `n` > 1 → 400; body > context × 16 bytes (128 KB at 8k) → 413; max tokens = `max_completion_tokens` else `max_tokens`, absent → model max, above it → 400. Field allowlist: drops client `priority`, `request_id`, `kv_transfer_params`, `vllm_xargs`, `structured_outputs`/`guided_*`, `chat_template*`, `prompt_embeds`, `echo`, large `top_logprobs`; message content is text only (no `image_url`, audio or file, so the engine never fetches a URL). Sets `priority` from tier, `cache_salt` = per-org secret (no cross-tenant prefix-cache timing), `stream_options {include_usage, continuous_usage_stats}`. Upstream headers are built from scratch, never copied. Tool calls are returned to the client, never executed.
6. **inference-service, admission** (§7): engine down → 503 `Retry-After: 30`. One Lua script on Valkey debits rpm, input tokens (estimate = body bytes ÷ 4) and checks output budget; then tier in-flight cap and org in-flight cap (in memory). Any failure → immediate 429 with `retry-after`, `retry-after-ms`, `x-ratelimit-*`. Valkey down → skip buckets, caps still apply.
7. **Relay**: own `ConnectionProvider` (maxConnections = pool cap, `pendingAcquireTimeout` 1 s → 503, `maxIdleTime` 4 s under vLLM's 5 s keep-alive). Timeouts: connect 1 s, TTFT 30 s, idle between chunks 30 s, all under nginx's 60 s read timeout. Connect error or 5xx before the first byte → one retry; TTFT timeout → 503 (overload, don't retry); after the first byte → `data: {"error":{…}}` then `data: [DONE]`. Engine 4xx passed through in OpenAI shape; 5xx and engine 401 → 502.
8. **End, error or disconnect** (`doFinally`): cancel upstream (frees the GPU slot), release caps, settle token buckets with real counts, publish `UsageEvent` from the last usage seen. Cancelled stream = input + generated output; cancelled non-stream = estimated input only.

Nothing on this path writes to a database.

## 4. Object models

**Tenancy and credentials** (phase 1)
```
Organization  id · name · status(active|suspended|closed) · tier(trial|standard|enterprise, default trial)
Membership    org_id + account_id · role(owner|admin|member); creating an org makes the creator owner
ApiKey        id · org_id · name · hint(last 4) · secret_hash(SHA-256) · created_by(null after erasure) · created_at · revoked_at
              format cmn_ (production) or cmn_test_ (any other environment; production rejects it before lookup)
              + 43 base62 (256 bits) + 6-char CRC32; shown once; ≤ 50 active per org; owner/admin create
Session       id · account_id · token_hash · created_at · last_used_at · expires_at      ← with the console SPA
```
- SHA-256 without pepper: a 256-bit random secret can't be brute-forced, and a pepper can't be rotated without reissuing keys.
- `last_used_at` comes from UsageEvent, never written by the gateway.
- Refresh cookie `__Host-carmonai-rt` (HttpOnly, Secure, SameSite=Strict, Path=/) set by auth-service, value `{id}.{secret}`; refresh = conditional UPDATE, hash mismatch on a known id = reuse → delete the row. Gateway checks `Origin` on POST `/auth/login|refresh|logout`.
- Services check membership by calling organization-service per console request, no cache; `/v1` never does.
- Later: invitations, email verification, roles with the owner lock (`SELECT … FOR UPDATE` on the org), password reset, login delay, DPA gate.

**Metering and money** (phases 2 and 4)
```
UsageEvent   v=1, JSON, additive changes stay v1
             event_id(UUIDv7 minted at admission; batch: UUIDv5(job, line)) · request_id · org_id · api_key_id
             · model · mode(sync|batch) · tier · input_tokens(incl. cached) · cached_input_tokens · output_tokens
             · status(ok|error|cancelled) · started_at · ttft_ms · duration_ms        ← no prompt, output or IP
UsageRaw     partitioned by started_at (day); PK (event_id, started_at); index received_at; 90-day retention
UsageWindow  org · api_key · model · mode · window_start(5 min) · sums                ← sealed by a job
Price        model · kind(input|cached_input|output) · mode(sync|batch) · micro_brl_per_million · effective_from(> now)
LedgerEntry  org · amount(bigint micro-BRL) · type(grant|usage|refund|adjustment|top_up) · reference · idempotency_key UNIQUE
Balance      org · amount · credit_limit
```
**Inference**
```
Model        id("carmonai/qwen3-4b") · context_window · max_output · status · license   ← config in inference-service
Deployment   model · engine · url · api-key(env) · slots C · queue q                     ← config in inference-service
Tier         trial | standard | enterprise → vLLM priority 20 | 10 | 0; batch 30; client value overwritten
RateLimit    tier × model class → rpm · input_tpm · output_tpm · max_in_flight_per_org    ← config
Zone         in-flight ÷ C → green/yellow/red, derived in memory for logs/dashboards; never stored
File, BatchJob  (phase 6) as in revision 1; event_id = UUIDv5(job, line) so a re-dispatched line bills once
```

## 5. Changes to what is built today

1. **`RateLimitFilter` bug**: it only recognises `JwtAuthenticationToken`, so every API-key caller would share the anonymous 1 req/s per-IP bucket. Key on the principal's name.
2. **Gateway timeout**: the global 15 s stays for console routes; `/v1` sets 660000 ms in route metadata. Property prefix is `spring.cloud.gateway.server.webflux.*` (the timeouts docs page still shows the old one).
3. **Two security chains**: API-key chain first (`@Order(HIGHEST_PRECEDENCE)`, `securityMatcher("/v1/**")`, `AuthenticationWebFilter` + converter for `Bearer cmn_…` + `ReactiveAuthenticationManager`, failure handler replaced: the default sends a Basic challenge); JWT chain as fallback. JWT on `/v1` → 401; key on console → 401.
4. **`IdAccountFilter` → `IdentityHeadersFilter`**: strips all four identity headers on every route, sets them by principal type.
5. **CSRF**: the "csrf disabled, no cookies" comment stops being true when the refresh cookie arrives; add the `Origin` check then.
6. **Streaming**: Gateway 5.0.3 flushes per chunk for `text/event-stream` and cancels upstream on client disconnect (checked in source); the phase-2 smoke proves it. nginx on `/v1`: `proxy_buffering off`, read timeout above TTFT.
7. **Registration enumeration**: `POST /auth/register` answers 409 "email already registered"; fix together with email verification.
8. **Erasure**: deleting an account must remove memberships (409 if sole owner of an active org), delete sessions and null `created_by` on keys — synchronous, idempotent calls in phase 1; the event saga in phase 7.
9. **auth-service gets Postgres** (keys, later sessions).
10. **Java version** ❓: Boot 4.1.1 documents Java 17–26 (checked); 27 is outside and non-LTS. Recommend 25 LTS (also drops the Lombok override).
11. **Edge**: the gateway port stops being published once nginx exists, and the gateway trusts forwarded headers from nginx only. nginx on `/v1`: `client_max_body_size 4m`, `proxy_request_buffering on` (clean Content-Length upstream), `proxy_buffering off`, `proxy_http_version 1.1`, `X-Forwarded-For $remote_addr` (overwrite), log `$uri` not `$request` (no query strings in logs).
12. **Pinned versions with security fixes**: vLLM ≥ 0.26.0 (error-message path leak; earlier DoS fixes), Netty ≥ 4.2.13.Final (request-smuggling fixes). Advisory ids in the review file.

## 6. Prototype environment

- **Production hosting is deferred.** When it comes back: AWS sa-east-1 is the only in-country hyperscaler H100 (pricey); abroad needs ANPD SCCs (Res. CD/ANPD 19/2024); Magalu Cloud to be quoted.
- **Local dev (CPU)**: llama.cpp `server` in compose with `Qwen/Qwen3-0.6B-GGUF` Q8_0 (639 MB, Apache-2.0), `--jinja --reasoning-budget 0`. Same tokenizer and tool-call format as the GPU model. Limits: no continuous usage (cancel billing untestable on CPU), ignores `priority` and `cache_salt`, no `[DONE]` after errors, `:` pings, `llamacpp:*` metrics.
- **The prototype is local only** (decided): one developer laptop, no outside users, no legal entity yet. Free, no card, nothing leaves the machine.
- **GPU: the laptop's own NVIDIA RTX 3050 6 GB** (Ampere, compute 8.6: bf16 and FlashAttention work; ~5.5 GB free with the desktop running). Docker Desktop on WSL2 already exposes the `nvidia` runtime, so vLLM runs as a compose service (`gpus: all`, `ipc: host`) under a compose profile `gpu`; the Hugging Face cache is a named volume so weights download once.
- **Model on the GPU**: `cyankiwi/Qwen3-4B-Instruct-2507-AWQ-4bit` — the planned Qwen3-4B-Instruct-2507 (Apache-2.0, no thinking mode, hermes tool calls, best small model on Portuguese instruction following) in 4-bit AWQ (W4A16, compressed-tensors), a community quant: safetensors only, no `trust_remote_code`, pin the revision. Sizing on 6 GB: 0.85 × 6 GB ≈ 5.1 GB − ~3.0 GB weights − ~0.8 GB activations/CUDA ≈ 1.3 GB KV ÷ 144 KiB/token ≈ 9k tokens → `--max-model-len 4096 --max-num-seqs 4` to start; measure. Fallback if it doesn't fit or misbehaves: official `Qwen/Qwen3-1.7B` in bf16 with thinking disabled by inference-service (`chat_template_kwargs.enable_thinking=false`).
  ```bash
  vllm serve cyankiwi/Qwen3-4B-Instruct-2507-AWQ-4bit --revision <pinned-sha> --served-model-name carmonai/qwen3-4b \
    --max-model-len 4096 --max-num-seqs 4 --max-num-queued-reqs 8 --gpu-memory-utilization 0.85 \
    --scheduling-policy priority --enable-prompt-tokens-details \
    --enable-auto-tool-choice --tool-call-parser hermes --api-key ${VLLM_API_KEY}
  ```
- **CPU engine stays** for CI and machines without a GPU: llama.cpp with `Qwen/Qwen3-0.6B-GGUF` (default compose profile). The Java code is the same; phase-3 checks that need vLLM (priority, continuous usage, metrics) run only under the `gpu` profile.
- **Connection**: both engines are compose services on the internal network, never published; inference-service reads the engine URL and key from env. vLLM's `--api-key` covers only `/v1`, `/v2`, `/inference`, `/cohere` (`/invocations`, `/pause`, `/abort_requests`, `/update_weights` stay open), so nothing but inference-service may reach the engine — true on the internal network, and a path allowlist becomes mandatory on any remote host.
- **Data rule**: synthetic data only; nothing in the prototype holds real personal data.
- **Rejected free options**: Colab (FAQ bans web services), Kaggle (bans "server farming"), Modal/Lightning (need a card for useful credits), HF ZeroGPU / Studio Lab / GCP trial (can't run our own server). Kept here in case the laptop GPU stops being enough.
- **Laptop numbers are not prices.** They prove the pipeline and size the prototype's caps. Prices come from `vllm bench serve` on the production GPU.

## 7. Admission, fairness, capacity

**Now (one replica):**
- C = highest `--max-concurrency` in `vllm bench serve` that keeps goodput ≥ 95% against the SLOs; q = queue backstop.
- Tier caps on the pool's in-flight count: trial 0.5·C, standard 0.85·C, enterprise C+q; plus a per-org cap so one customer can't fill a tier. This, not engine priority, is what keeps trial from starving enterprise.
- Token buckets `rl:{org:class}:rpm|itpm|otpm` in one Lua script (Valkey `TIME`, one hash slot). Input charged on the bytes ÷ 4 estimate, corrected from usage (vLLM `/tokenize` would be a GPU round trip and isn't covered by `--api-key`). Output settled at the end; buckets and balances may go negative. ponytail: overshoot ≤ org in-flight × max tokens; settle mid-stream if it ever matters.
- vLLM `--max-num-seqs C --max-num-queued-reqs C+q` as the engine-side backstop (it ignores tiers).
- Health check every 5 s; engine down → fast 503 (the laptop GPU sleeps and restarts; that is normal).
- Batch: priority 30, smallest cap, backs off on 429.

**Later (>1 replica or instance):** scrape `vllm:num_requests_waiting`, `vllm:num_requests_running`, `vllm:kv_cache_usage_perc` every 1 s into memory; a replica stale > 3 s counts as full. Then asymmetric autoscaling (KEDA on waiting / KV / TTFT p95; up fast, down slow, one at a time), node autoscaling, baked weights, min replicas ≥ 1, reserved capacity. Fairness within a tier (VTC/DRR) and prefix-aware routing via GIE/llm-d flow control on Kubernetes, not Java code.

## 8. SLOs and measurement

- SLOs per model class on TTFT p95, ITL p95, end-to-end p95 (non-stream), availability; goodput = share of requests meeting all of them. Set from phase-3 measurements, revisited on the production GPU.
- Tools: `vllm bench serve` (`--base-url`, `--header`, `--goodput`, `--max-concurrency`) or GuideLLM, run through the gateway with one key per tier. Not Gatling/k6: Gatling's SSE timer stops at HTTP 200 and k6 needs an extension, so neither sees TTFT.
- inference-service records queue wait, TTFT, tokens/s and outcome per org × model (ids only). Reconciliation compares hourly usage with vLLM's token counters (alert on > 0.5% gap).

## 9. LGPD, security and abuse

**Roles.** The customer is controller of prompts and outputs; Carmonai is operator. The DPA says: process on instructions only, no training, zero retention for synchronous requests, batch files ≤ 30 days, a sub-operator list with 30-day notice of changes, deletion on termination, incident notice to the customer within 24 h. Carmonai is controller of accounts, billing, access logs and abuse reports. One ROPA table (LGPD art. 37) covers both roles.

**Incidents.** As controller: notify the ANPD and affected people within 3 business days of learning personal data was affected, when the risk is relevant (Res. CD/ANPD 15/2024; small agents get double time unless the processing is high-risk); keep an incident record for 5 years. As operator: tell the customer within 24 h so they can meet their own deadline.

**Content stays in the request** — never in logs, traces, metrics, events, error bodies, caches or dumps:
- Off outside local debug: gateway wiretap, Reactor Netty access log, DEBUG on `reactor.netty`, `org.springframework.web`, `org.springframework.http.codec`.
- Error bodies are fixed OpenAI-style messages plus the request id; never `e.getMessage()` (decoder messages quote the body; don't copy account-service's `IllegalArgumentException` handler into inference code). Engine error bodies are never logged; engine 5xx → generic error.
- OpenTelemetry: no body/header capture; GenAI content capture off.
- Metric tags: `model` only after allowlist resolution; no key or org tags (per-org numbers live in usage data).
- No `HeapDumpOnOutOfMemoryError`; actuator stays health + prometheus.
- vLLM: request/output logging stays off (`--enable-log-requests`, `--enable-log-outputs` not set), no DEBUG logging. llama.cpp: `--no-slots` (its `/slots` endpoint has exposed prompts), no `--log-verbose`. On Modal/Lightning the engine's stdout is the platform's log.
- **Check (smoke.sh):** send `CANARY-<uuid>` in a streamed chat, a plain chat, malformed JSON, an over-context prompt, an aborted stream, and as `?api_key=cmn_test_…CANARY`; then `docker compose logs`, `pg_dumpall` (and `modal app logs` on Modal) must contain no `CANARY`, no test-key secret and no `Bearer `.

**Access log** (Marco Civil da Internet art. 15): timestamp, IP, org, key, request id, status; 6-month retention; restricted access; separate from usage events, which stay IP-free.

**Abuse.** No public signup: staff activate orgs; trial capacity is one global cap. Signals without content: per org/key requests, tokens, 4xx/429/5xx, distinct IPs per key. Suspension: org → `suspended`, auth-service deletes its `apikey:*` entries, 403 within the cache TTL; running streams finish. The AUP bans illegal use, CSAM, sexualized minors, non-consensual intimate content, malware and — during the prototype — any personal data; abuse@ is published. Credible CSAM report: suspend, preserve ids/timestamps/IPs, report to the authorities (Polícia Federal / SaferNet) as Lei 15.211/2025 art. 27 requires.

**Liability.** The STF's 2025–2026 Marco Civil ruling keeps the court-order regime of art. 19 for providers that don't interfere in the flow of content; a B2B API that publishes nothing likely qualifies. Keep the notice channel and published rules anyway; confirm with counsel.

**International transfer.** None while data is synthetic. Real data abroad → ANPD standard contractual clauses (Res. CD/ANPD 19/2024, verbatim) plus the provider's DPA as sub-operator — or GPUs in Brazil. Pinning a Modal region is not enough: logs, images and volumes stay in the US (fine only because our logs carry no content).

**Prototype = local and synthetic only.** It runs on the developer laptop with `cmn_test_` keys; nothing is exposed beyond `localhost`. When a shared or production environment exists: separate database and Valkey, production rejects `cmn_test_` keys and refuses to start if an upstream host isn't on its approved list, non-production `/v1` responses carry `X-Carmonai-Environment`, console banner.

**Model license.** Qwen3-4B-Instruct-2507 is Apache-2.0 without a NOTICE file; serving it over an API isn't redistribution. Record license and origin on `Model`; use "Qwen" only to describe origin.

**Regulation to watch.** PL 2338/2023 is in the Chamber's special committee, vote expected after the October 2026 elections; under the Senate text Carmonai would be a distributor, with generative-AI duties on the model developer unless we fine-tune or brand a model. ANPD generative-AI work (Radar Tecnológico 2024, Nota Técnica 1/2026).

**Before real customer data reaches any GPU:**
- [ ] Paid plan with the provider (free tiers: Modal "as-is", Lightning needs written consent for commercial use, Kaggle never).
- [ ] Provider DPA as sub-operator, named in our DPA.
- [ ] Abroad: ANPD SCCs and disclosure; otherwise a GPU in Brazil.
- [ ] Canary check passes on that provider, including its log store.
- [ ] Customer DPA and AUP signed; ROPA done; encarregado named (or a contact channel if a small agent); incident runbook written.
- [ ] Access log running with 6-month retention; suspension proven to reach the gateway within the cache TTL.

## 10. Platform

- **CI**: one GitHub Actions workflow in `back` on `ubuntu-latest`: `actions/checkout@v7` with `submodules: recursive` and a read-only GitHub App token (`GITHUB_TOKEN` can't read sibling private repos); `actions/setup-java@v6` with `sapmachine` and Maven cache; `mvn -B verify` from the aggregator (no install, no package registry); `docker compose up --wait` with freshly generated `.env`; `smoke.sh`.
- **Tests**: plain JUnit on logic with branches (`RateLimitFilter.tryAcquire`, `IdempotentRetryer`, `JwtService`, Lua bucket math, pricing). One Testcontainers `*IT` per database service (Flyway + `validate` + constraints; `@ServiceConnection`; Postgres pinned to the compose digest). Feign contract: the service calls itself through `FeignClientBuilder(...).url("http://localhost:"+port)` (the annotation's `url` beats properties). Money paths: duplicate `event_id` → one debit; price in effect at the window start; empty balance → 402; rerunning the debit job changes nothing.
- **Versions**: Testcontainers 2.0.5 (renamed artifacts, no JUnit 4); Valkey `9.0.6` (BSD; Redis 8 is AGPL/RSAL) with `@ServiceConnection(name="redis")`; Kafka `apache/kafka:4.3.1` (KRaft) when it arrives, with Spring Modulith 2.1.x only in services that own a DB; springdoc 3.1.x on the management port when needed; images pinned `tag@sha256`.
- **Observability**: JSON logs now (`logging.structured.format.console: ecs`); traces in phase 2 (`spring-boot-starter-opentelemetry`); Prometheus/Grafana dashboards in phase 4.
- **Not now**: GitHub Packages (cross-repo reads need a classic token; `1.0.0` can't be republished), GHCR pushes until something deploys, Kafka until a second consumer.

## 11. Phases

Each phase ends with a runnable check; nothing starts before the previous exit holds.

| Phase | Builds | Exit check |
|---|---|---|
| 0 Tests + CI | unit tests on branchy logic; one Testcontainers IT per DB service; Feign self-contract; CI workflow in `back`; JSON logs; Java version settled | CI green; a broken migration, a Resource/Feign mismatch or a smoke security regression fails it |
| 1 Tenancy + keys | Valkey; auth-service on Postgres; organization-service (org with status + tier, owner membership); org-owned API keys; gateway API-key chain, identity headers, flood brake; `RateLimitFilter` fix; erasure removes memberships/sessions | smoke: register → org → key → stub `/v1/models` 200; revoked key → 401 within seconds; JWT on `/v1` → 401; Valkey stopped → 503; sole-owner erasure → 409 |
| 2 Walking skeleton (CPU) | inference-service: allowlist, relay, timeouts, retry before first byte, `/v1/models` from config; llama.cpp + Qwen3-0.6B in compose; UsageEvent → HTTP batch → usage-service (raw rows, partition job, 5-min windows); traces | smoke: tokens stream event by event through the gateway; a window appears; replayed event counted once; client disconnect stops generation upstream; canary check (§9) finds nothing |
| 3 Real engine (laptop GPU) | vLLM + Qwen3-4B-Instruct-2507 AWQ as a compose service under profile `gpu` (RTX 3050 6 GB), revision pinned, key from env; `vllm bench serve` → C, q and SLOs | smoke passes against vLLM incl. tool call, priority and cancelled-stream usage; engine port unreachable from the host; bench numbers recorded (not prices) |
| 4 Money | billing: seeded prices, ledger, balance, pull-and-debit of sealed windows, internal credit grant, `no_credit` flag → 402, daily reconciliation, two DB roles | grant → usage drains → 402 → grant → 200; rerunning the debit job changes nothing; balance = sum of ledger |
| 5 Admission + fairness | Lua buckets + settle; tier and org caps; priority overwrite; `cache_salt`; queue backstop; rate-limit headers; dashboards | three bench runs through the gateway, one key per tier: trial at 3×C gets 429 in < 100 ms, enterprise goodput ≥ 95%, nothing hits the TTFT timeout |
| 6 Batch API | files in object storage, jobs, worker at priority 30, batch prices, `event_id = UUIDv5(job, line)` | 10k-line JSONL completes while interactive SLOs hold; a re-dispatched line bills once |
| 7 Production | hosting decision and GPU staging (prices from bench on the real GPU), Kubernetes, KEDA, Kafka when a second consumer exists, audit, LGPD erasure saga and export, console sessions/invitations/email flows, Pix (when the first customer pays), NFS-e | §9 "before real customer data" checklist complete; SLOs met on the production GPU; access log running |

Out of scope until there is a reason: disaggregated prefill/decode, speculative decoding, LoRA/fine-tuning, embeddings, `/v1/completions`, `/v1/responses`, multi-region.

## 12. Decisions

**Made**:
- Product: OpenAI-compatible `/v1`; vLLM; tiers trial/standard/enterprise, no free tier; Batch API in phase 6; prepaid credits (Pix when the first customer pays).
- Billing rules: cancelled streams billed input + generated output; cancelled non-stream requests billed estimated input only; `status=error` (our failure) not billed; balance floor 0.
- Identity: refresh token in an HttpOnly cookie; sessions idle 7 days, absolute 30 days; console SPA on the same origin as the console API; explicit org creation; membership checks via organization-service; erasing the sole owner of an active org → 409 until the org is closed; `cmn_test_` prefix outside production.
- Engineering: Java 25 LTS; one repo per module (CI needs a read token for the sibling repos); Kafka only when an event gets a second consumer.
- Prototype: local only on the developer laptop (RTX 3050 6 GB + CPU fallback), synthetic data, no outside users, no legal entity yet; hosting deferred.

**Open** (not blocking any phase before 7):
1. PSP (Efí, Mercado Pago and Stripe sign webhooks; Asaas only sends a token) and NFS-e provider.
2. Retention periods, to confirm with legal.
3. Before any outside user: legal entity, Marco Civil access-log duty, LGPD "small agent" status, whether inference is high-risk processing (counsel).

## 13. Backlog

- [ ] **Research and plan vLLM / inference optimizations** (asked 2026-10-03). Start from phase-3 bench numbers and measure every change with `vllm bench serve` against the goodput SLOs, never by intuition. Candidates:
  - **Engine flags:** `--max-num-batched-tokens`, chunked prefill, prefix caching hit rate, CUDA graphs vs `--enforce-eager`, `--gpu-memory-utilization`.
  - **Quantization:** weights (AWQ / GPTQ / FP8 where the GPU supports it) and KV cache (FP8 KV) against Portuguese quality.
  - **Speculative decoding** (draft model or n-gram) and its effect on ITL.
  - **Engine choice per workload** (vLLM vs SGLang).
  - **Later, with more GPUs:** tensor parallelism, prefix-aware routing (llm-d), disaggregated prefill/decode.
  - Output: a short plan with expected gain, cost and risk per item, and which ones change prices.

## Sources

Full source lists per topic are in [plan-review-2026-10-02.md](plan-review-2026-10-02.md) and the subagent reports. Key ones:
- Video: https://www.youtube.com/watch?v=CYFs6mR--KE (skill `batch-inference-design`)
- Continuous batching: https://www.anyscale.com/blog/continuous-batching-llm-inference
- vLLM source v0.30.0 (scheduler, protocol, auth middleware): https://github.com/vllm-project/vllm/tree/v0.30.0/vllm · security: https://docs.vllm.ai/en/latest/usage/security/ · metrics: https://docs.vllm.ai/en/latest/design/metrics.html · bench: https://docs.vllm.ai/en/latest/cli/bench/serve.html
- Spring Cloud Gateway 5.0.3 source: https://github.com/spring-cloud/spring-cloud-gateway/tree/v5.0.3/spring-cloud-gateway-server-webflux
- Spring Boot system requirements: https://docs.spring.io/spring-boot/system-requirements.html
- Rate limits: https://platform.claude.com/docs/en/api/rate-limits · https://developers.openai.com/api/docs/guides/rate-limits
- Free GPUs: https://modal.com/pricing · https://modal.com/docs/examples/vllm_inference · https://lightning.ai/pricing · https://www.kaggle.com/docs/notebooks · https://research.google.com/colaboratory/faq.html
- Model: https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507 · https://huggingface.co/Qwen/Qwen3-0.6B-GGUF
- Postgres partitioning: https://www.postgresql.org/docs/17/ddl-partitioning.html
- OAuth security BCP: https://www.rfc-editor.org/rfc/rfc9700.html · OWASP CSRF: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
- Fairness: https://www.usenix.org/conference/osdi24/presentation/sheng · https://cohere.com/blog/serving-fairness
- ANPD international transfer: https://www.gov.br/anpd/pt-br/assuntos/assuntos-internacionais/transferencia-internacional-de-dados
