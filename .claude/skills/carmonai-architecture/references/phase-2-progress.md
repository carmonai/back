# Phase 2 progress (inference skeleton on CPU)

Working log for the overnight run started 2026-10-03; an hourly check-in resumes from the first unchecked item. Plan: [inference-plan.md](inference-plan.md) §2, §3, §11 row 2.

Rules for the run: work on the `phase-2` branches only (all ten repos have one); commit and push them when green locally; open PRs at the end; **never merge and never push to `main`**; don't start phase 3. The user updates `CARMONAI_TOKEN` in the morning (it must also cover `usage`, `usage-service`, `inference-service`), then says when to merge.

## Checklist

- [x] Repos `usage`, `usage-service`, `inference-service` created, initial commit on `main`, added as submodules; every repo on `phase-2`
- [x] llama.cpp image pinned: `ghcr.io/ggml-org/llama.cpp:server@sha256:970168341efef973da5666ea5c362fa428ee66ba0dfa621b0f69bf3feb3320f7`; model `Qwen/Qwen3-0.6B-GGUF:Q8_0` cached in docker volume `carmonai_models`; flags: `-hf Qwen/Qwen3-0.6B-GGUF:Q8_0 --jinja --chat-template-kwargs '{"enable_thinking":false}' -c 4096 -np 2 --metrics --no-slots --no-webui --alias carmonai/qwen3-0.6b --api-key …`
- [x] Probe llama.cpp behaviour (stream format, usage in stream, cancel, metrics names, error shape) and note it below
- [x] `usage` library: `UsageController` (`POST /usage/events`), `UsageEventIn`
- [x] `usage-service` + `UsageServiceIT`
- [x] `inference-service` + `InferenceServiceIT` (stub engine + stub usage via JDK HttpServer)
- [x] gateway: `/v1` route to inference-service, stub `/v1/models` removed, `/v1` hardening filter
- [x] compose (`llama`, `usage`, `inference`), `ENGINE_API_KEY` in `.env`, `.env.example`, CI
- [x] `smoke.sh`: chat non-stream + stream, validation errors, usage rows, cancel, canary check
- [x] `mvn clean verify` + compose + smoke all green; logs clean
- [x] Docs: plan progress/deviations, skills (`carmonai`, templates)
- [x] Commit + push all `phase-2` branches, open PRs with merge order (libraries → services → back)

## Design decisions (keep consistent when resuming)

- **No traces in phase 2** (no backend to see them); moves to phase 4 with dashboards. Deviation to record in the plan.
- **inference-service** (WebFlux, package `ai.carmonai.inference`, no DB, no library):
  - Models from config (`carmonai.inference.models[]`: id, url, api-key, context-window, max-output); `GET /v1/models` from config.
  - `POST /v1/chat/completions`: identity headers `id-organization`, `id-api-key`, `tier` required (401 otherwise). Body parsed as JSON tree; unknown model → 404; `n` > 1 → 400; non-text content → 400; body > context × 16 bytes → 413; max tokens = `max_completion_tokens` else `max_tokens`, absent → model max, above → 400.
  - Field allowlist: messages, stream, temperature, top_p, stop, presence_penalty, frequency_penalty, seed, tools, tool_choice, parallel_tool_calls, stream_options (read for `include_usage`). We set model, n=1, max_tokens, `stream_options {include_usage, continuous_usage_stats}`. `priority`/`cache_salt` only with vLLM (phase 3).
  - Upstream headers built from scratch (Content-Type, Authorization engine key, X-Request-Id).
  - Streaming: SSE relay chunk by chunk; TTFT timeout then idle timeout; one retry on connect error/5xx before the first byte; mid-stream error → `data: {"error":…}` + `data: [DONE]`. Errors before the first byte → OpenAI-shaped JSON with status (engine down/timeout 503, engine 5xx 502, engine 4xx passed through).
  - Usage: last usage seen; if none (llama.cpp cancel) estimate input = body bytes ÷ 4 and output = content chunks (ponytail). If the client didn't ask `include_usage`, strip usage from chunks and drop usage-only chunks.
  - UsageEvent → bounded in-memory queue → batches (100 or 1 s) → `POST http://usage:8080/usage/events`, retry with backoff ~10 min; overflow/4xx/shutdown leftovers → one ERROR log line with ids and counts only. event_id: UUID (v4 is enough; uniqueness only).
- **usage-service** (MVC, JDBC not JPA, schema `usage`):
  - `usage_event` partitioned by `started_at` (day), PK `(event_id, started_at)`, `received_at` default now(), DEFAULT partition as a safety net.
  - Batch insert `ON CONFLICT DO NOTHING` (≤ 1000 per batch) → 202.
  - Partition job at startup + daily under `pg_try_advisory_lock`: today−1 … today+7, drop > 90 days.
  - Seal job every minute under advisory lock: 5-min windows by `received_at`, 60 s grace, cursor row `usage_seal`; `usage_window` sums exclude `status='error'` tokens (not billed) and count errors.
  - Window length, grace and interval are configurable; the IT drives `seal(now)` directly.
- **gateway**: route `/v1/chat/completions` (POST) and `/v1/models` (GET) → `http://inference:8080`, metadata `response-timeout: 660000`, `RemoveRequestHeader=Authorization`. WebFilter before security on `/v1/**`: reject `Transfer-Encoding`, key-like query strings (`cmn_`, `key`, `token`) → 400; POST needs `Content-Length` (411) ≤ 4 MB (413). OpenAI-shaped errors.
- **compose**: `llama` service (internal only, healthcheck `/health`, long start period for the first download), `usage`, `inference`; `ENGINE_API_KEY` generated like the other secrets.

## llama.cpp findings

- Stream: OpenAI chunks `data: {...}`; first chunk has `delta.role` and `content: null`; usage arrives **only in a final chunk** with `choices: []` when `stream_options.include_usage` is true, then `data: [DONE]`. `continuous_usage_stats` is ignored (no running usage), so a cancelled stream has no usage: estimate (see decisions).
- Non-stream: `usage {prompt_tokens, completion_tokens, total_tokens, prompt_tokens_details.cached_tokens}` plus a llama-only `timings` object (strip nothing; harmless).
- Errors: `{"error":{"message","type","code":<int>}}` with the HTTP status (401 bad key, 400 bad request).
- Client disconnect cancels the generation ("stop: cancel task"); `llamacpp:requests_processing` returns to 0.
- Metrics (with `--metrics`, need the API key): `llamacpp:requests_processing`, `llamacpp:requests_deferred`, `llamacpp:prompt_tokens_total`, `llamacpp:tokens_predicted_total`, …
- `--reasoning-budget 0` does NOT stop Qwen3 thinking in this build; `--chat-template-kwargs '{"enable_thinking":false}'` does. Client `chat_template_kwargs` stays off the allowlist.
- `/health` is public (200 when loaded); the image has curl for the compose healthcheck.
- **The API key env var is `LLAMA_API_KEY`**, not `LLAMA_ARG_API_KEY`: with the wrong name the engine served requests without any key. The smoke-time check (no key → 401, key → 200, `/metrics` without key → 401) caught it.
- The server log prints slot/task ids and token counts, not prompt text (confirm with the canary check).
