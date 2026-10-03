# Plan review findings (2026-10-02, in progress)

Second planning pass on [inference-plan.md](inference-plan.md), one subagent per topic. Not yet merged into the plan. User agreed to all plan §11 recommendations; hosting deferred (prototype on free GPU, synthetic data only). Assumed agreed (confirm): prepaid Pix, refresh token in a cookie, explicit org creation, membership checks via organization-service.

All seven reviews done and merged into plan revision 2: tenancy/credentials, metering/billing, admission/limits, platform, free GPU + model, request path, security/LGPD.

## Security, LGPD, abuse
- **Missing legal duties:**
  - Marco Civil art. 15: access log kept 6 months.
  - Lei 15.211/2025 (ECA Digital) art. 27: remove and report CSAM.
  - Incident deadlines differ by role: 3 business days as controller (Res. 15/2024), 24 h to the customer as operator.
- **Live CVEs:** vLLM ≥ 0.26.0 (CVE-2026-73555, internal paths leak in error messages; DoS fixes in 0.24.0); Netty ≥ 4.2.13.Final (CVE-2026-42581/42585, request smuggling). Not independently verified; check the advisories when pinning.
- **Modal:** `web_server` binds 0.0.0.0 and the proxy forwards every path. Proxy auth is the only guard for `/pause` and `/update_weights`: OK for synthetic data only.
- **Headers:**
  - Strip Cookie, Forwarded, X-Forwarded-*, traceparent, tracestate and baggage at the gateway.
  - Reject Transfer-Encoding, HTTP/1.0 and key-like query strings on `/v1`.
  - Build upstream headers from scratch.
- **Allowlist additions:** no `structured_outputs`/`guided_*` (a regex DoS history), `chat_template*`, `prompt_embeds`, `echo`. Text-only content (no SSRF). Body ≤ context × 16 bytes.
- **Leak points:** wiretap, Netty access log, DEBUG codecs, `e.getMessage()`, OTel body capture, metric tags, heap dumps, vLLM request logging, llama.cpp `/slots` (use `--no-slots`).
- **Canary check:** a `CANARY-<uuid>` sent through every request type must not appear in logs or the DB.
- **`cmn_test_` keys** outside production; production rejects them. Production refuses unapproved upstream hosts.
- **Liability:** the STF ruling keeps art. 19 for providers that don't interfere in content; a B2B API likely qualifies. Confirm with counsel.
- **PL 2338:** vote after the Oct 2026 elections. Carmonai would be a distributor; generative-AI duties fall on the model developer unless we fine-tune or brand a model.
- **Model license:** Qwen Apache-2.0 has no NOTICE file; serving over an API isn't redistribution.
- **Open questions:** legal entity yet? Outside companies on the prototype? `cmn_test_` prefix OK?

## Request path and streaming
- **Keep inference-service:** gateway filters can't read SSE without buffering; batch-service needs the same relay.
- **Gateway 5.0.3** flushes per chunk for `text/event-stream` and cancels upstream on client disconnect (checked in source).
- **Errors:** OpenAI error shape on `/v1`, ProblemDetail elsewhere.
- **Timeout:** `response-timeout` only times the wait for response headers, so `/v1` gets 660000 ms (not -1). TTFT 30 s, idle 30 s, connect 1 s, all under nginx 60 s / Cloudflare 125 s.
- **Retry:** only on connect error or 5xx before the first byte. A TTFT timeout means overload → 503 with `Retry-After`. Mid-stream errors: `data: {"error":…}` then `[DONE]`.
- **Field allowlist:** we set `model`, `priority`, `cache_salt`, `n=1` and max tokens (`max_completion_tokens` else `max_tokens`). Dropped client fields: `priority`, `request_id`, `kv_transfer_params`, `vllm_xargs`.
- **Usage:** force `continuous_usage_stats`. Cached tokens only appear in the final chunk, so cancelled input is billed at full price. Cancelled non-stream requests → estimated input only.
- **Gateway `/v1` route:** exact paths, `RemoveRequestHeader=Authorization`, `Content-Length` required and ≤ 4 MB (411/413; `RequestSize` misses chunked bodies). `/v1/models` is served from config.
- **Connection pool:** the Reactor default pool would queue streams for 45 s. Give inference-service its own `ConnectionProvider`: maxConnections = pool cap, `pendingAcquireTimeout` 1 s, `maxIdleTime` 4 s (vLLM keep-alive is 5 s).
- **Relay implementation:** `bodyToFlux(ServerSentEvent<String>)`, `timeout(Mono.delay(ttft), e -> Mono.delay(idle))`, `switchOnFirst` for the retry, `spring.codec.max-in-memory-size: 4MB`.
- **API-key chain:** `AuthenticationWebFilter` + converter + `ReactiveAuthenticationManager`. Replace the failure handler (the default sends a Basic challenge).
- **Status codes:** 402 for no credit, not 429 (the OpenAI SDK retries 429s). Engine 5xx and the engine's own 401 → 502.
- **vLLM:** `--enable-request-id-headers` not needed (vLLM already uses the incoming `X-Request-Id`). Without `--scheduling-policy priority`, a non-zero priority returns 400.
- **Property prefix** is `spring.cloud.gateway.server.webflux.*`.
- **llama.cpp differences:** no continuous usage, ignores `priority`/`cache_salt`, no `[DONE]` after errors, `:` pings, `llamacpp:*` metrics.

## Platform foundations
- **Java version:** Boot 4.1.1 documents support for Java 17–26; 27 is outside that range and not LTS. Recommend Java 25 LTS (also removes the Lombok override).
- **Phase 0 = tests + CI only:**
  - Unit tests on logic with branches.
  - One Testcontainers integration test per database service.
  - A Feign contract test: the service calls itself through `FeignClientBuilder(...).url(localhost)`.
  - One GitHub Actions workflow in `back`:
    - `checkout@v7` with submodules, using a GitHub App token (`GITHUB_TOKEN` can't read sibling repos);
    - `setup-java@v6` with sapmachine;
    - `mvn -B verify`, then compose up and `smoke.sh`.
  - JSON logs via `logging.structured.format.console: ecs`.
- **Move or drop:**
  - Redis moves to phase 1.
  - Kafka, outbox and Modulith dropped until a second consumer exists (then Modulith 2.1.1, only in services that own a DB).
  - No GitHub Packages: cross-repo reads need a classic token, and version `1.0.0` can't be republished.
  - Tracing in phase 2 (`spring-boot-starter-opentelemetry`), dashboards in phase 4, springdoc on the management port later.
- **Versions:**
  - Testcontainers 2.0.5 (renamed artifacts, no JUnit 4).
  - springdoc 3.1.1, OTel agent 2.31.1.
  - Kafka image `apache/kafka:4.3.1` (KRaft).
  - **Valkey 9.0.6 instead of Redis** (Redis 8 is AGPL/RSAL; Valkey is BSD). In tests use `@ServiceConnection(name="redis")`.
- **Rate limiting:** `RedisRateLimiter` lets everything through when Redis errors, so keep the in-memory login limit as a backstop.
- **Open questions:** Java 27 required? Kafka required by the Insper course by some date? Keep one repo per module, or a single repo?

## Free GPU + model
- **Ranking:**
  1. Modal (US$30/month credit, T4/L4, vLLM serving documented, fixed HTTPS URL, proxy auth).
  2. Lightning AI (~80 interruptible GPU-h/month, publishes a port).
  3. Kaggle 2×T4 (rules ban "server farming": grey area, short private sessions only).
  4. **Colab: no** (FAQ bans web services/proxies).
  - Not usable: P100 (vLLM needs compute capability ≥ 7.5), HF ZeroGPU, Studio Lab, GCP trial.
- **Model:**
  - `Qwen/Qwen3-4B-Instruct-2507`: fp16, Apache-2.0, no thinking mode, hermes tool parser. Beats Gaia/Tucano2 on Portuguese instruction-following.
  - On a T4: ~4.8 GiB left for KV cache ≈ 35k tokens (16 requests × 2k). Roughly 25–30 tok/s per stream; measure it.
  - Gemma 4 crashes on Turing. Qwen3.5 is fragile on a T4; use it on L4 or newer.
- **Launch:** `vllm serve Qwen/Qwen3-4B-Instruct-2507 --served-model-name carmonai/qwen3-4b --dtype float16 --max-model-len 8192 --max-num-seqs 16 --gpu-memory-utilization 0.90 --scheduling-policy priority --enable-auto-tool-choice --tool-call-parser hermes --host 127.0.0.1`
- **CPU engine:** llama.cpp with `Qwen/Qwen3-0.6B-GGUF:Q8_0`, `--jinja --reasoning-budget 0`.
- **Security:**
  - vLLM `--api-key` covers only `/v1`; `/invocations`, `/pause`, `/abort_requests` and `/update_weights` stay open. The edge must allow only `/v1/*`, `/health` and `/metrics`.
  - Cloudflare quick tunnels don't support SSE: use ngrok with a static domain and traffic policy, or Modal proxy auth.
  - Upstream URL and key come from env; new key every session.
- **Phases:** new phase 3b = vLLM on the free GPU, before phase 4 (llama.cpp has no `priority` or vLLM metrics). T4 numbers are never used for prices; production GPU staging moves to phase 7.
- **Open questions:** OK to put a card with a spend limit on Modal/Lightning? Is Kaggle's grey area acceptable?

## Tenancy and credentials
- **Bug today:** `RateLimitFilter` only recognizes `JwtAuthenticationToken`, so every `/v1` API-key caller would land in the anonymous 1 req/s per-IP bucket.
- **API key:**
  - Plain SHA-256 (no pepper: it can't be rotated, and a pepper only stops an attacker who can already write to the DB).
  - Format `cmn_` + 43 base62 chars (256 bits) + 6-char CRC32 checksum, checked before any I/O. Fix the format now; changing it later means reissuing every key.
  - Store a `hint` = last 4 chars. Max 50 active keys per org; only owner or admin can create them.
- **Gateway lookup:**
  - Redis `apikey:{sha256}` → {keyId, orgId, orgStatus, tier}, 60 s TTL; delete the entry after the revoke commits; no pub/sub.
  - Redis down → `/v1` answers 503 + Retry-After, not 401.
  - Separate `SecurityWebFilterChain` for `/v1/**`, ordered first, accepting keys only; a JWT on `/v1` → 401, a key on console routes → 401.
  - Strip and set `id-organization`, `id-api-key`, `tier`; the rate limit keys `/v1` traffic by org.
- **`tier` lives on Organization** (default trial).
- **Session:**
  - One row per login: {id, account_id, token_hash, created, last_used, expires}; cookie value `{id}.{secret}`.
  - Refresh is a conditional UPDATE; id matches but hash doesn't → reuse → delete the row. No family table.
  - Cookie `__Host-carmonai-rt; Secure; HttpOnly; SameSite=Strict; Path=/`, set by auth-service. The gateway strips `Cookie` on non-auth routes.
  - Gateway checks `Origin` on POST `/auth/login|refresh|logout` (CSRF, including login CSRF). The "csrf disabled, no cookies" comment becomes false.
- **Erasure (phase 1, synchronous and idempotent):**
  - organization-service `DELETE /internal/members/{accountId}` → 409 if the account is the sole owner of an active org.
  - auth-service deletes the sessions and nulls `created_by` on keys.
  - Then the account row is deleted. The event saga waits for phase 7.
- **Note:** register returning 409 "email already registered" lets anyone check if an email has an account; fix it together with email verification.
- **Phase-1 slice:**
  1. auth-service gets Postgres.
  2. organization-service: org {id, name, status, tier} + owner membership; `POST /organizations` creates both in one transaction.
  3. API keys at `/organizations/{orgId}/api-keys`.
  4. Gateway: Redis, the `/v1` chain, a stub `/v1/models`.
  5. Erasure update.
- **Later:** sessions and cookie with the console SPA; invitations, roles and email verification when a second user needs access; reset, login delay, DPA gate and secret scanning before public signup.
- **Open questions:** SPA on the same origin as the console API (rec, no CORS) or subdomains? Session idle 7 d / absolute 30 d? Sole-owner erasure → 409 (rec) or auto-close the org?

## Metering and billing
- **Bugs:**
  - Cancelled streams would bill 0: the usage chunk only arrives at the end. Use `stream_options {include_usage, continuous_usage_stats}` (vLLM) and bill the last usage seen.
  - Day partitions keyed by arrival break dedupe: the unique key must include the partition key. Partition by `started_at` (fixed per event); PK `(event_id, started_at)`.
  - Batch retries bill twice unless `event_id = UUIDv5(job, line)`.
- **Prototype transport: no Kafka/outbox/Modulith.**
  - inference-service sends usage in batches over HTTP to usage-service (internal, not routed). usage-service acks 2xx after the DB commit.
  - Emit in `doFinally`; bounded queue, retry ~10 min; leftovers go to an ERROR log line with ids and counts only.
  - Moving to Kafka later is ~1–2 days. When it comes: Modulith 2.1.x for Boot 4.1; keep `KafkaTemplate.send` off the Netty loop (Reactor Kafka is discontinued).
- **UsageEvent v1:** event_id (UUIDv7, minted at admission), request_id, org_id, api_key_id, model, mode, tier, input_tokens (incl. cached), cached_input_tokens, output_tokens, status, started_at, ttft_ms, duration_ms.
- **usage-service:**
  - One multi-row `INSERT … ON CONFLICT DO NOTHING` per batch.
  - Partition job under an advisory lock (+7 days ahead, drop > 90 d); no pg_partman.
  - Seal job every minute writes 5-min `usage_window` rows (60 s grace). Drop UsageHourly.
- **billing:**
  - Pulls sealed windows by cursor.
  - Cost = round half-up once per window with `multiplyExact`. A missing price stops the cursor and alerts; never bill at 0.
  - Ledger key `usage:{org}:{model}:{mode}:{window_start}`.
  - `INSERT ledger ON CONFLICT DO NOTHING RETURNING` then `UPDATE balance SET amount = amount + ?` (the row lock serializes writers; drop `version`).
  - The floor only sets the 402 flag; it never rejects a debit.
  - Two DB roles (app role: INSERT/SELECT on the ledger).
  - Daily reconciliation that only alerts: balance = sum of ledger; every sealed window has an entry; tokens match vLLM's counters within 0.5%.
- **Price:** `effective_from > now()`; batch prices are their own rows.
- **Pix:**
  - Deferred to the first paying customer.
  - PSPs with sandboxes: Efí (Pix-native, webhooks over mTLS), Mercado Pago (HMAC-signed webhooks), Asaas (only a token header), Stripe (Pix invite-only).
  - Whichever is chosen: treat the webhook as a hint and re-fetch the charge before crediting.
- **Open questions:** bill `status=error`? (rec: no). Floor 0 vs a buffer?

## Admission, limits, fairness
- **Wrong layer:** token limits and shedding need the model, the body and the final usage, so they move to inference-service. The gateway keeps auth, tenant flags and a flat per-key/IP flood brake (built-in `RedisRateLimiter`).
- **Priority alone doesn't protect enterprise:** vLLM preempts only running requests that lack KV blocks, so a waiting enterprise request never evicts trial streams that fill every slot. Reserve capacity at admission.
  - In-memory in-flight count per pool: tier caps trial 0.5·C, standard 0.85·C, enterprise C+q; plus a per-org cap.
  - C = the highest concurrency that keeps goodput ≥ 95%, measured with `vllm bench serve`.
  - Zones are derived from this, for logs only; no Redis zone key.
- **Lua token buckets** `rl:{org:class}:rpm|itpm|otpm`:
  - Input estimate = body bytes / 4, corrected from usage. Not vLLM `/tokenize`: an extra GPU round trip, and vLLM's `--api-key` doesn't protect that route.
  - OTPM settled at the end; balances may go negative.
  - Headers: OpenAI-style `x-ratelimit-*` + `retry-after` + `retry-after-ms`.
  - Redis down → fail open; the in-memory caps still protect the GPU.
- **Add:**
  - Overwrite any client-sent `priority` (trial 20 / standard 10 / enterprise 0 / batch 30).
  - `cache_salt = org id` (no cross-tenant prefix-cache timing leak).
  - Reject `n > 1`.
  - vLLM `--max-num-seqs C --max-num-queued-reqs C+q` as the queue backstop.
  - Pool down → fast 503.
- **Defer:** VTC/DRR fairness (later via GIE/llm-d flow control), metric scraping (needed once there are >1 replicas), autoscaling, Gatling/k6 (can't see time to first token) → use `vllm bench serve` / GuideLLM.
- **Phase-4 exit:** three bench runs, one key per tier. Trial at 3×C gets 429 in < 100 ms, enterprise goodput ≥ 95%.
- **Open question:** Colab's FAQ bans web services on all runtimes, so serving through a tunnel puts the account at risk. Accept that, or budget for an hourly T4/L4? Kaggle's terms were not checked (the free-GPU review covers it).
