# Gateway

## What it is

`gateway-service` is the only service with a published port. It authenticates every caller, decides whether
the organization may spend money at all, and forwards the request to whichever service owns the path — and
nothing else is reachable from outside the network.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="gw-title" aria-describedby="gw-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="gw-title">The gateway filter chain, and the two ways a request leaves it</title>
  <desc id="gw-desc">A request enters at the access log filter and passes down through the /v1 framing
  checks, authentication, the rate limit and the identity headers, in that order. It either leaves refused —
  a response written by the gateway itself — or continues into a routed upstream service.</desc>
  <defs>
    <marker id="gw-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="gw-arrow-accent" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: the request travels down the chain, then leaves one way or the other. -->
  <g id="gw-hops">
    <path id="gw-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M354 45 V240"/>
    <path id="gw-hop2" class="cmn-link cmn-link--accent cmn-dash" d="M354 87 H420" marker-end="url(#gw-arrow-accent)"/>
    <path id="gw-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M354 240 H420" marker-end="url(#gw-arrow-flow)"/>
  </g>
  <!-- The chain, top to bottom. The first filter is where a reader starts. -->
  <g class="cmn-node cmn-node--entry cmn-node--flow" id="gw-accesslog" aria-labelledby="gw-accesslog-label"><rect x="24" y="26" width="300" height="38" rx="10"/><text id="gw-accesslog-label" x="174" y="38">AccessLogFilter</text><text class="cmn-sub" x="174" y="54">request id, wraps everything</text></g>
  <g class="cmn-node cmn-node--flow" id="gw-v1" aria-labelledby="gw-v1-label"><rect x="24" y="68" width="300" height="38" rx="10"/><text id="gw-v1-label" x="174" y="80">V1RequestFilter</text><text class="cmn-sub" x="174" y="96">framing, size, credentials in URL</text></g>
  <g class="cmn-node cmn-node--flow" id="gw-auth" aria-labelledby="gw-auth-label"><rect x="24" y="110" width="300" height="38" rx="10"/><text id="gw-auth-label" x="174" y="122">Authentication</text><text class="cmn-sub" x="174" y="138">API key, then the credit flag</text></g>
  <g class="cmn-node cmn-node--flow" id="gw-ratelimit" aria-labelledby="gw-ratelimit-label"><rect x="24" y="152" width="300" height="38" rx="10"/><text id="gw-ratelimit-label" x="174" y="164">RateLimitFilter</text><text class="cmn-sub" x="174" y="180">10 req/s, fails open</text></g>
  <g class="cmn-node cmn-node--flow" id="gw-identity" aria-labelledby="gw-identity-label"><rect x="24" y="194" width="300" height="38" rx="10"/><text id="gw-identity-label" x="174" y="206">IdentityHeadersFilter</text><text class="cmn-sub" x="174" y="222">strip every inbound copy, then set</text></g>
  <g class="cmn-node cmn-node--flow" id="gw-route" aria-labelledby="gw-route-label"><rect x="24" y="236" width="300" height="38" rx="10"/><text id="gw-route-label" x="174" y="248">Route</text><text class="cmn-sub" x="174" y="264">bulkhead, breaker, deadline</text></g>
  <g class="cmn-node cmn-node--danger" id="gw-refused" aria-labelledby="gw-refused-label"><rect x="420" y="59" width="316" height="56" rx="10"/><text id="gw-refused-label" x="578" y="79">Refused here</text><text class="cmn-sub" x="578" y="97">400 · 401 · 402 · 413 · 429 · 503</text></g>
  <g class="cmn-node cmn-node--flow" id="gw-upstream" aria-labelledby="gw-upstream-label"><rect x="420" y="212" width="316" height="56" rx="10"/><text id="gw-upstream-label" x="578" y="232">Routed upstream</text><text class="cmn-sub" x="578" y="250">inference, auth, account, billing…</text></g>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M354 45 V240'); --cmn-travel: 1.8s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5" style="offset-path: path('M354 87 H420'); --cmn-travel: 1s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M354 240 H420'); --cmn-travel: 1s; --cmn-delay: 1.2s;"></circle>
  <rect class="cmn-label-plate" x="104" y="4" width="140" height="16" rx="4"/><text class="cmn-label" x="174" y="16">the request enters here</text>
</svg>
</div>
<figcaption>The request enters at the top and travels down the chain in order: the access log assigns the
request id and writes its line when the exchange ends, the `/v1` checks run before Spring Security, then the
key is resolved, the bucket charged, the identity headers replaced, and the route chosen. Only two things
can happen next: the gateway writes a refusal itself, or the request reaches an upstream.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the request travelling (solid)</span>
  <span><i class="is-accent"></i> a response written by the gateway, refusals included (dashed)</span>
</div>

1. **`AccessLogFilter` opens the request.** It assigns a fresh `X-Request-Id` — a client's own value is
   replaced — stamps it on the response at commit time, and registers the line it writes when the exchange
   ends, however it ends.
2. **`V1RequestFilter` runs before Spring Security** on paths under `/v1/`: no `Transfer-Encoding`, no
   HTTP/1.0, no credential-looking query string, a `Content-Length`, and at most 4 MB.
3. **Authentication runs by path.** On `/v1/**` the API key is resolved by `ApiKeyAuthenticationManager` and
   the credit flag checked; everywhere else a JWT is verified locally against the cached JWKS.
4. **`RateLimitFilter` charges a token bucket** keyed by the account or the API key, or by client IP when
   nobody is authenticated yet — one Lua script in Valkey, so replicas share the rate.
5. **`IdentityHeadersFilter` removes every inbound identity header** and sets its own: `id-account`, or
   `id-organization` + `id-api-key` + `tier`.
6. **The route is chosen and the call is placed** inside a per-route bulkhead and circuit breaker: a refusal
   here is the gateway's own response, and anything else goes to the upstream the route names.

## The chain, in the order it runs

| Order | Component | What it decides |
|---|---|---|
| 1 | `AccessLogFilter` | the request id, and the access line written on the way out |
| 2 | `V1RequestFilter` | framing, body size and credentials-in-URL, for `/v1/` only |
| 3 | `OriginFilter` | a browser `POST` to the four cookie endpoints must come from a console origin |
| 4 | Security chains | `apiKeys` on `/v1/**`, the JWT chain everywhere else |
| 5 | `RateLimitFilter` | the flood brake, per caller |
| 6 | `RouteBulkheadFilter` | at most `max-concurrent` calls to this upstream, refused rather than queued |
| 7 | `CircuitBreaker` | the route's breaker, with `forward:/fallback` as the fallback |
| 8 | `IdentityHeadersFilter` | the headers the upstream is allowed to trust |
| 9 | `NettyRoutingFilter` | the call itself, with the route's `response-timeout` |

`AccessLogFilter`, `V1RequestFilter` and `OriginFilter` are `WebFilter`s, outside the gateway's routing
machinery; the rest are `GlobalFilter`s inside it. That is why the `/v1` checks can refuse a request before
Spring Security sees it, and why the identity headers are set as late as possible.

`V1RequestFilter` exists because a body must not be readable two ways along the chain
nginx → gateway → inference-service. It refuses: a `Transfer-Encoding` header or an HTTP/1.0 request
(`unsupported_framing`); a query string matching `(?i)cmn_|key|token` (`credentials_in_url`), because query
strings end up in logs and browser history; a `POST` with no `Content-Length` (`length_required`, 411); and a
body over `MAX_BODY` = 4 MB (`request_too_large`, 413). Nothing is checked before it.

## API keys: the format check, the cache, and the 60-second TTL

`ApiKeyFormat` mirrors auth-service's `ApiKeys`: `cmn_` optionally followed by `test_`, then 43 base62
characters and a 6-character base62 CRC32 of those 43. A typo therefore costs no I/O at all.

Only then does `ApiKeyAuthenticationManager` hash the key with SHA-256 and look up `apikey:{hash}` in Valkey.
A miss falls through to auth-service's `GET /api-keys/{hash}`, and **the answer is cached either way** — the
literal string `none` for an unknown key, so garbage keys cannot hammer auth-service. The cached value is
five space-separated fields: `id organizationId status tier expiresAt`.

Three consequences follow from that cache, and they are the interesting part:

- **Revocation is immediate, expiry is not quite.** Revoking a key deletes the cache entry, so it stops
  working at once. An expiry can only be enforced from the cached value, so a key that expires just after a
  lookup stays usable for up to the 60 s TTL. The code marks this as a deliberate shortcut.
- **`status` is checked from the cache too.** A key of an organization that is not `active` is refused with
  `DisabledException`, which becomes 403 `organization_not_active`.
- **Expired and revoked answer the same 401.** Both are `invalid_api_key`, on purpose: the caller learns
  nothing about which.

If Valkey or auth-service is unreachable, authentication fails **closed** with a 503 and `Retry-After: 5`.

## The credit gate, and the brake that does not gate

After the key resolves, the manager checks `no_credit:{organization}`, the flag billing-service writes when
`balance + credit_limit ≤ 0`. Its presence turns the request into **402** with OpenAI's `insufficient_quota`
type and the code `insufficient_balance` — 402 rather than OpenAI's 429 because SDKs retry 429s and retrying
cannot add credit. The check fails closed: a Valkey outage here is a 503, never a free request.
[Billing](billing.md) owns the flag.

`RateLimitFilter` does the opposite and fails **open**: if Valkey is unavailable it logs a warning and admits
the request. It is flood protection, and turning a Valkey blip into a total outage would be a worse bug than
the flood it prevents. Its local token buckets are only the memory of that fail-open path, and they are crude
on purpose — past 100,000 keys it clears every bucket rather than evicting carefully.

## The route table

Routes live in `src/main/resources/application.yaml`; there is no `lb://` anywhere.

| Route id | Predicate | Target | `response-timeout` | `max-concurrent` |
|---|---|---|---|---|
| `auth` | `/auth/login`, `/register`, `/whoami`, `/refresh`, `/logout` | `http://auth:8080` | 15 s | — |
| `account-public` | the three signed-out `POST`s under `/accounts` | `http://account:8080` | 15 s | — |
| `account` | `GET`/`DELETE` `/accounts/{id}` and `/accounts/{id}/export` | `http://account:8080` | 15 s | — |
| `organization` | `/organizations`, `/organizations/{id}` | `http://organization:8080` | 15 s | — |
| `api-keys` | three API-key paths, `{id}` and `{id}/rotate` separately | `http://auth:8080` | 15 s | — |
| `billing-balance` | `GET /billing/organizations/{id}/balance` | `http://billing:8080` | 15 s | — |
| `usage-summary` | `GET /usage/organizations/{id}/summary` | `http://usage:8080` | 15 s | — |
| `inference` | `/v1/chat/completions`, `/v1/models` | `http://inference:8080` | 660 s | 64 |
| `batch` | the Files and Batch paths | `http://batch:8080` | 60 s | 16 |

Every route sets `connect-timeout: 1000`; the global `httpclient.response-timeout` of 15 s is the floor for a
route that forgot to declare one. The two `/v1` routes also carry `RemoveRequestHeader=Authorization` — the
API key never travels further than the gateway, which sends the identity headers instead.

The numbers on `inference` are chosen against the service behind it: 660 s covers inference's own 600 s
non-streamed ceiling plus a margin for the response to start and does not cut a streaming answer off, and
`max-concurrent: 64` matches inference's engine pool, beyond which a queue would only build.
`ResilienceConfiguration` declares one breaker per `/v1` route — `inference` and `batch` — with a sliding
window of 20 calls, a 50% failure threshold, 30 s open and 5 half-open probes: constants in Java rather than
properties, because a configuration prefix nothing validates is a silent misconfiguration waiting to happen.
`disable-time-limiter` is `true`, because the route's `response-timeout` is the deadline and a time limiter
would cut a streaming answer for no gain.

## The error contract

`OpenAiErrors` is the only thing that writes an error body. Every response is
`{"error":{"message","type","code"}}`, and every message is a fixed string — nothing from the request is
echoed, and `e.getMessage()` is never used.

| Status | `type` | `code` | When |
|---|---|---|---|
| 400 | `invalid_request_error` | `unsupported_framing`, `credentials_in_url` | bad framing, or a credential in the URL |
| 411 | `invalid_request_error` | `length_required` | a `POST` without `Content-Length` |
| 413 | `invalid_request_error` | `request_too_large` | body over 4 MB |
| 401 | `invalid_request_error` | `invalid_api_key` | missing, malformed, unknown, revoked or expired |
| 402 | `insufficient_quota` | `insufficient_balance` | the organization's prepaid balance is used up |
| 403 | `permission_error` | `organization_not_active` | the key is fine, the organization is not |
| 429 | `rate_limit_exceeded` | `rate_limit_exceeded` | the caller's bucket is empty |
| 503 | `api_error` | `service_unavailable` | the key lookup or the credit check is unavailable |
| 503 | `api_error` | `inference_unavailable`, `batch_unavailable`, `gateway_busy` | breaker, bulkhead, or a shed call |

The 429 carries both `Retry-After` and `Retry-After-Ms`, because inference-service sends the same pair and
SDKs honour the millisecond one; the 503s carry `Retry-After: 30`. `RouteBulkheadFilter` refuses an
over-limit call with `gateway_busy` rather than letting it wait, and copies the route's `fallback-code` into
an exchange attribute — the route and its metadata do not survive the breaker's forward, but attributes do.

`UpstreamFailureHandler` exists because a connect that hangs raises Netty's `ConnectTimeoutException`, which
escapes the whole filter chain and is therefore never counted by the breaker — measured against the running
stack, ten calls to a stopped container produced ten Spring error pages and a still-closed breaker.

## The access log

`AccessLogFilter` writes one JSON line per request — refusals included, because it wraps the security chain —
to its own file and nothing to stdout: logger `access`, `/var/log/carmonai/access.log`, daily, gzipped,
`maxHistory` 184 days. Marco Civil da Internet art. 15 requires six months, and 184 days satisfies it. The
line carries `request_id`, `method`, `path` (no query string), `status`, `duration_ms`, `client_ip`,
`client_closed` when the caller hung up, and whichever ids the request had; `/actuator/**` is skipped.

## Why it is like this

**No auth call on the request path.** The JWT is verified locally against auth-service's JWKS — cached by
Nimbus and fetched through a `WebClient` with a 1 s connect and a 2 s response timeout — and an API key is
resolved from a 60 s Valkey cache.

**Strip, then set.** `IdentityHeadersFilter` removes `id-account`, `id-organization`, `id-api-key`, `tier`,
`batch-line`, `cookie`, every `x-forwarded-*`, `forwarded`, `traceparent`, `tracestate` and `baggage` from the
inbound request before adding its own. Services trust these headers and nothing else, so an inbound copy
would be a complete authentication bypass. `Cookie` is removed too, except on the two paths that need
`__Host-carmonai-rt`, `/auth/refresh` and `/auth/logout`.

## What would change it

- **`ApiKeyFormat` accepts the prototype prefix.** The pattern is `cmn_(?:test_)?…`, so a `cmn_test_` key
  keeps working in production. Production refuses it; the pattern and auth-service's `ApiKeys.PREFIX` change
  together.
- **The cached expiry is up to a minute stale.** A key that expires inside that window keeps working until
  the entry drains. Shortening the TTL is the fix if it ever matters.
- **`RateLimitFilter` has no shared memory of a Valkey outage.** Its fallback buckets are per-replica and
  reset wholesale past 100,000 keys, so they bound one instance's flood, not a fleet's.
- **The `/v1` body cap is 4 MB**, which is also what caps a Batch file upload; OpenAI allows 200 MB.
- **Alerts are visible but nobody is paged.** There is no Alertmanager destination configured.

## Where to look

- [application.yaml](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/resources/application.yaml) — the route table and every timeout.
- [GatewayApplication.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/GatewayApplication.java) — the two security chains and the JWKS decoder.
- [ApiKeyAuthenticationManager.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ApiKeyAuthenticationManager.java) — the key cache, the TTL and the credit gate.
- [IdentityHeadersFilter.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/IdentityHeadersFilter.java) — the strip list and the headers it sets.
- [OpenAiErrors.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/OpenAiErrors.java) — every error body the gateway can write.
