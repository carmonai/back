# Resilience

## What it is

Every dependency in this system is allowed to fail, and each one fails in a way that was chosen rather than
discovered: a timeout on every outbound call, a circuit breaker and a bulkhead around the two routes that can
absorb a flood, a single retry that is only legal before the first byte, and a rule about which failures close
the door (a key lookup, a credit check) and which one deliberately leaves it open (the flood brake).

## A dependency failing at three different points

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="resil-title" aria-describedby="resil-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="resil-title">The engine failing before the first byte, while silent, and mid-stream</title>
  <desc id="resil-desc">Three rows, one per failure: an engine that cannot be reached after one retry, an engine that goes silent for thirty seconds, and an engine that closes the stream after the first byte. Each row ends with what the client sees.</desc>

  <defs>
    <marker id="resil-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Row 1: unreachable. Row 2: silent. Row 3: closed after the first byte. -->
  <g id="resil-hops">
    <path id="resil-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M104 58 H160" marker-end="url(#resil-arrow-flow)"/>
    <path id="resil-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M270 58 H330" marker-end="url(#resil-arrow-flow)"/>
    <path id="resil-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M104 138 H160" marker-end="url(#resil-arrow-flow)"/>
    <path id="resil-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M270 138 H330" marker-end="url(#resil-arrow-flow)"/>
    <path id="resil-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M104 218 H160" marker-end="url(#resil-arrow-flow)"/>
    <path id="resil-hop6" class="cmn-link cmn-link--flow cmn-dash" d="M270 218 H330" marker-end="url(#resil-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="resil-client1" aria-labelledby="resil-client1-label">
    <rect x="20" y="36" width="84" height="44" rx="10"/><text id="resil-client1-label" x="62" y="54">Client</text>
    <text class="cmn-sub" x="62" y="69">the caller</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="resil-inference1" aria-labelledby="resil-inference1-label">
    <rect x="160" y="36" width="110" height="44" rx="10"/><text id="resil-inference1-label" x="215" y="54">Inference</text>
    <text class="cmn-sub" x="215" y="69">relays the stream</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="resil-engine1" aria-labelledby="resil-engine1-label">
    <rect x="330" y="36" width="116" height="44" rx="10"/><text id="resil-engine1-label" x="388" y="54">Engine</text>
    <text class="cmn-sub" x="388" y="69">unreachable</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="resil-out1" aria-labelledby="resil-out1-label">
    <rect x="500" y="36" width="244" height="44" rx="10"/><text id="resil-out1-label" x="622" y="54">503 engine_unavailable</text>
    <text class="cmn-sub" x="622" y="69">after one retry, at connect</text>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="resil-client2" aria-labelledby="resil-client2-label">
    <rect x="20" y="116" width="84" height="44" rx="10"/><text id="resil-client2-label" x="62" y="134">Client</text>
    <text class="cmn-sub" x="62" y="149">still waiting</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="resil-inference2" aria-labelledby="resil-inference2-label">
    <rect x="160" y="116" width="110" height="44" rx="10"/><text id="resil-inference2-label" x="215" y="134">Inference</text>
    <text class="cmn-sub" x="215" y="149">relays the stream</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="resil-engine2" aria-labelledby="resil-engine2-label">
    <rect x="330" y="116" width="116" height="44" rx="10"/><text id="resil-engine2-label" x="388" y="134">Engine</text>
    <text class="cmn-sub" x="388" y="149">silent 30 s</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="resil-out2" aria-labelledby="resil-out2-label">
    <rect x="500" y="116" width="244" height="44" rx="10"/><text id="resil-out2-label" x="622" y="134">503 engine_timeout</text>
    <text class="cmn-sub" x="622" y="149">no retry: silence is overload</text>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="resil-client3" aria-labelledby="resil-client3-label">
    <rect x="20" y="196" width="84" height="44" rx="10"/><text id="resil-client3-label" x="62" y="214">Client</text>
    <text class="cmn-sub" x="62" y="229">has tokens</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="resil-inference3" aria-labelledby="resil-inference3-label">
    <rect x="160" y="196" width="110" height="44" rx="10"/><text id="resil-inference3-label" x="215" y="214">Inference</text>
    <text class="cmn-sub" x="215" y="229">relays the stream</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="resil-engine3" aria-labelledby="resil-engine3-label">
    <rect x="330" y="196" width="116" height="44" rx="10"/><text id="resil-engine3-label" x="388" y="214">Engine</text>
    <text class="cmn-sub" x="388" y="229">closed mid-stream</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="resil-out3" aria-labelledby="resil-out3-label">
    <rect x="500" y="196" width="244" height="44" rx="10"/><text id="resil-out3-label" x="622" y="214">error event, then [DONE]</text>
    <text class="cmn-sub" x="622" y="229">usage: cancelled, not retried</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M104 58 H160'); --cmn-travel: 0.5s; --cmn-delay: 0s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M104 138 H160'); --cmn-travel: 0.5s; --cmn-delay: 0.4s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M104 218 H160'); --cmn-travel: 0.5s; --cmn-delay: 0.8s;"/>

  <rect class="cmn-label-plate" x="210" y="92" width="180" height="16" rx="4"/><text class="cmn-label" x="300" y="104">connect fails: one retry only</text>
  <rect class="cmn-label-plate" x="208" y="172" width="184" height="16" rx="4"/><text class="cmn-label" x="300" y="184">silence is never retried</text>
  <rect class="cmn-label-plate" x="200" y="252" width="200" height="16" rx="4"/><text class="cmn-label" x="300" y="264">the error travels inside the stream</text>
</svg>
</div>
<figcaption>Three ways the same engine can fail, and three different things the client gets. In row 1 the
connection never opens, so one retry is legal and the second failure is a 503. In row 2 nothing arrives for
30 s: a timeout means overload, and retrying would only add load. In row 3 the answer had already started, so
a retry would replay tokens the client has — the stream carries the error and ends.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the request reaching inference (solid); the engine node repeats in every row</span>
</div>

1. **The client sends a request** and inference-service admits it — a rate bucket in Valkey and a share of
   the engine's slots. Everything after this point is the engine's problem, not the caller's.
2. **The engine cannot be reached.** `Engine.stream` retries exactly once, and only while nothing has been
   written back to the client; the predicate is `WebClientRequestException`, which is what a refused
   connection raises. Both attempts spent, `ApiError.from` maps it to `503 engine_unavailable`.
3. **The engine goes silent.** The first event must arrive within `ttft-timeout` (30 s) and each next one
   within `idle-timeout` (30 s). A `TimeoutException` is not retried: an engine that is not answering is busy,
   so it maps to `503 engine_timeout`.
4. **The engine dies after the first token.** The response is committed, so no status code can be rewritten.
   `ChatHandler` ends the stream with an OpenAI-shaped error event followed by `data: [DONE]`, and the usage
   event records the outcome as `cancelled`.
5. **The usage is settled either way**: `Admission.settle` runs before the usage event, and the event reaches
   the Valkey stream whatever happened, so a cancelled stream is billed for what it generated.
6. **Each row ends in a different number**, and the difference is the point: two 503s that name a time to
   come back, and a stream that ends with an error the caller must not retry.

## What each hop is allowed to cost

| Hop | Connect | Read | Set in |
|---|---|---|---|
| gateway → any route | 1000 ms | 15 s default; `/v1` 660 s, files and batches 60 s | `application.yaml`, per-route `metadata` |
| Feign clients (account, billing, usage services) | 1000 ms | 3 s | `spring.cloud.openfeign.client.config.<name>` |
| inference → engine, first token | 1000 ms | 30 s (`ttft-timeout`) | `Engine`, `InferenceProperties` |
| inference → engine, whole non-streamed answer | — | 600 s (`response-timeout`) | same |
| inference → usage-service (usage relay) | 1000 ms | 5 s | `UsageReporter` |
| gateway/inference → Valkey | 1 s | 1 s (500 ms in inference) | `spring.data.redis` |

The engine pool is its own `ConnectionProvider` with `maxConnections: 64`, a 1 s `pendingAcquireTimeout` and
a 4 s `maxIdleTime` — under the engines' 5 s keep-alive, so a closed socket is never reused. A full pool
refuses at once instead of queueing for reactor-netty's 45 s default.

## Circuit breakers and bulkheads, per route

At the gateway, only the two routes that can absorb a flood have them:

| Route | Breaker | Bulkhead (`metadata.max-concurrent`) | Fallback code |
|---|---|---|---|
| `inference` (`/v1/chat/completions`, `/v1/models`) | `inference` | 64 | `inference_unavailable` |
| `batch` (`/v1/files**`, `/v1/batches**`) | `batch` | 16 | `batch_unavailable` |
| console routes | none | none | — |

Both breakers come from one `ResilienceConfiguration`: a sliding window of 20 calls, a minimum of 20 calls,
a 50% failure rate, 30 s open and 5 half-open probes. `RouteBulkheadFilter` holds a `Semaphore` per route id
and answers `503 gateway_busy` over the limit rather than letting the call queue: "a flood on one route must
not eat the gateway's capacity for the others". Console routes get no breaker on purpose — they are
interactive, the flood brake already covers them, and a breaker there turns a slow login into a 503.

Inside a service, every Feign call runs through a Resilience4j breaker (20-call window, 10-call minimum, 50%,
30 s open, 3 half-open probes) and a semaphore bulkhead of 25 concurrent calls with no wait at all. A 4xx is
excluded from the count, because a service that answers "no such organization" is working.

## What the client sees, and which of it is worth retrying

| Status | Code | Raised by | The reason for the number |
|---|---|---|---|
| `401` | `invalid_api_key` | gateway | unknown, revoked and expired keys are deliberately indistinguishable |
| `403` | `organization_not_active` | gateway | the key is real; the tenant is not |
| `402` | `insufficient_balance` | gateway (`no_credit:{org}`) or inference (batch and flex credit check) | **not** OpenAI's `429 insufficient_quota`, "because SDKs retry 429s, and retrying can't add credit" |
| `429` | `rate_limit_exceeded`, `model_busy`, `resource_unavailable` | inference admission, gateway flood brake | the caller's own limit: `retry-after` and `retry-after-ms` say when to come back |
| `503` | `engine_unavailable`, `engine_timeout`, `service_unavailable`, `gateway_busy`, `inference_unavailable` | inference, gateway fallback, `UpstreamFailureHandler` | a dependency, not the caller: `Retry-After: 5` or `30` |
| `502` | `engine_error` | inference | the engine answered 5xx without an OpenAI-shaped body, or refused our own key |

Only the 429 and the 503 name a time to come back; the 402 and the 403 do not — which is why the credit gate is a 402.

## Fail closed, and one deliberate fail open

`ApiKeyAuthenticationManager` refuses to guess: if Valkey or auth-service is unavailable, the key lookup
raises `AuthenticationServiceException` and the caller gets `503 service_unavailable` with `Retry-After: 5`.
The credit check fails the same way. `docker/smoke.sh` stops the Valkey container and asserts exactly that —
`expect 503 -H "Authorization: Bearer $key2" "$G/v1/models"` — because a 401 would tell a customer their key
had been revoked.

`RateLimitFilter` is the exception, and the comment says why:

> Fail OPEN on a Valkey failure (WARN, admit the request): this is flood protection. The checks that must
> fail CLOSED are the API-key lookup and the no_credit check in ApiKeyAuthenticationManager, where a Valkey
> blip is a 503; turning that blip into a total outage here would be a worse bug than the flood.

Its in-memory fallback bucket answers while Valkey is gone, capped at 100 000 keys (cleared when exceeded —
a crude ceiling the code marks as such). inference-service makes the same choice for its rate buckets: a
Valkey failure logs `rate buckets unavailable, admitting on in-flight caps only`, and the caps still hold.

## Why it is like this

- **No database on the request path.** inference-service has no datasource at all, and usage is written to a
  Valkey stream and relayed afterwards. `docker/smoke.sh` stops usage-service, runs three chats to a 200,
  SIGKILLs inference-service and restarts it: all three usage events still arrive, once each. Billing before
  answering was rejected — it puts a database write in the latency of every request.
- **Retry only where it is invisible.** One retry before the first byte, for a connection error or an engine
  5xx. After that the tokens are already with the client, so a retry would duplicate them and the error
  travels inside the stream instead.
- **The time limiter is disabled at the gateway**, because the route's own `response-timeout` is the deadline
  and a second one with a different value would race it.
- **`UpstreamFailureHandler` exists because a connect timeout escaped the breaker.** A Netty
  `ConnectTimeoutException` never reaches the CircuitBreaker filter's `onErrorResume`, so it was not counted
  as a failure and the SDK got Spring's own error page — measured at ten calls, ten error pages, breaker
  still closed. The handler runs outside the chain and writes the same 503.

## What would change it

The gateway's bulkhead and the flood brake's fallback bucket are per-JVM memory, so a second gateway replica
doubles both limits, and a second inference replica breaks the in-flight caps and virtual token counters the
same way. The reconciler's mismatch is a metric and a log line, not a page: there is no Alertmanager
destination, and nothing is traced. Latency numbers on this page come from
[docker/bench.sh](https://github.com/carmonai/back/blob/main/docker/bench.sh) and
[docker/smoke.sh](https://github.com/carmonai/back/blob/main/docker/smoke.sh); the full list of ceilings is
in [known gaps](../reference/gaps.md).

## Where to look

- [Engine.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Engine.java)
  — the pool, the timeouts and the one retry, in 84 lines.
- [ApiError.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ApiError.java)
  — every failure mapped to a status and an OpenAI-shaped code.
- [RateLimitFilter.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/RateLimitFilter.java)
  — the Lua token bucket, and the comment that explains failing open.
- [ResilienceConfiguration.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ResilienceConfiguration.java)
  — the breaker numbers and why they are constants.
