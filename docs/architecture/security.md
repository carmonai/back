# Security and privacy

## What it is

One rule carries the whole trust model: **the gateway is the only component that decides who is calling**.
It strips every inbound identity header and sets its own, so downstream services read `id-organization` and
never parse a token. Everything else on this page follows from that — the checks that run before any I/O,
the three gates a `/v1` request passes, and the rules that keep prompts out of every store that is not the
engine's own memory.

## A request refused at three gates

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="sec-title" aria-describedby="sec-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="sec-title">A /v1 request passing three gates, and what each one refuses</title>
  <desc id="sec-desc">A client sends a request to the gateway. Before authentication, the framing, URL and
  size checks can refuse it with a 400, 411 or 413. Then the API key is checked by format, hash and cached
  lookup, which answers 401. Then the organization's credit flag answers 402. A request that passes all
  three reaches inference.</desc>

  <defs>
    <marker id="sec-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Hop order: arrive, then one hop per gate, then the forward to inference. -->
  <g id="sec-hops">
    <path id="sec-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M104 140 H132" marker-end="url(#sec-arrow-flow)"/>
    <path id="sec-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M248 140 H272" marker-end="url(#sec-arrow-flow)"/>
    <path id="sec-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M396 140 H420" marker-end="url(#sec-arrow-flow)"/>
    <path id="sec-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M544 140 H568" marker-end="url(#sec-arrow-flow)"/>
    <path id="sec-refusal1" class="cmn-link" d="M190 116 V84" marker-end="url(#sec-arrow-flow)"/>
    <path id="sec-refusal2" class="cmn-link" d="M334 116 V84" marker-end="url(#sec-arrow-flow)"/>
    <path id="sec-refusal3" class="cmn-link" d="M482 116 V84" marker-end="url(#sec-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="sec-client" aria-labelledby="sec-client-label">
    <rect x="16" y="116" width="88" height="48" rx="10"/><text id="sec-client-label" x="60" y="135">Client</text>
    <text class="cmn-sub" x="60" y="150">SDK or app</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="sec-gate1" aria-labelledby="sec-gate1-label">
    <rect x="132" y="116" width="116" height="48" rx="10"/><text id="sec-gate1-label" x="190" y="135">Edge checks</text>
    <text class="cmn-sub" x="190" y="150">no I/O yet</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="sec-gate2" aria-labelledby="sec-gate2-label">
    <rect x="272" y="116" width="124" height="48" rx="10"/><text id="sec-gate2-label" x="334" y="135">API key</text>
    <text class="cmn-sub" x="334" y="150">format, hash, cache</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="sec-gate3" aria-labelledby="sec-gate3-label">
    <rect x="420" y="116" width="124" height="48" rx="10"/><text id="sec-gate3-label" x="482" y="135">Credit flag</text>
    <text class="cmn-sub" x="482" y="150">no_credit:{org}</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="sec-inference" aria-labelledby="sec-inference-label">
    <rect x="568" y="116" width="140" height="48" rx="10"/><text id="sec-inference-label" x="638" y="135">Inference</text>
    <text class="cmn-sub" x="638" y="150">calls the engine</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="sec-refused1" aria-labelledby="sec-refused1-label">
    <rect x="110" y="40" width="160" height="44" rx="10"/><text id="sec-refused1-label" x="190" y="58">400 bad framing</text>
    <text class="cmn-sub" x="190" y="73">or 411 / 413</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="sec-refused2" aria-labelledby="sec-refused2-label">
    <rect x="254" y="40" width="160" height="44" rx="10"/><text id="sec-refused2-label" x="334" y="58">401 bad key</text>
    <text class="cmn-sub" x="334" y="73">invalid_api_key</text>
  </g>
  <g class="cmn-node cmn-node--danger" id="sec-refused3" aria-labelledby="sec-refused3-label">
    <rect x="402" y="40" width="160" height="44" rx="10"/><text id="sec-refused3-label" x="482" y="58">402 no credit</text>
    <text class="cmn-sub" x="482" y="73">insufficient_balance</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M104 140 H132'); --cmn-travel: 0.4s; --cmn-delay: 0s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M248 140 H272'); --cmn-travel: 0.4s; --cmn-delay: 0.3s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M396 140 H420'); --cmn-travel: 0.4s; --cmn-delay: 0.6s;"/>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5" style="offset-path: path('M544 140 H568'); --cmn-travel: 0.4s; --cmn-delay: 0.9s;"/>

  <rect class="cmn-label-plate" x="92" y="100" width="80" height="16" rx="4"/><text class="cmn-label" x="132" y="112">Bearer cmn_…</text>
  <rect class="cmn-label-plate" x="600" y="176" width="140" height="16" rx="4"/><text class="cmn-label" x="670" y="188">identity headers only</text>
</svg>
</div>
<figcaption>Every `/v1` request passes the same three gates in the same order, and each gate has exactly one
way out: the framing checks (step 1) refuse a body whose length can be read two ways, authentication (step 2)
refuses a key without ever touching the database for a malformed one, and the credit flag (step 3) refuses an
organization whose prepaid balance is spent. What reaches inference (step 4) carries identity headers and no
`Authorization` header at all.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the request, and the hop that reaches inference (solid)</span>
  <span><i></i> a gate's refusal, going up to the status it answers (grey)</span>
  <span>each refusal box names its status and its error code in words, never in colour alone</span>
</div>

1. **The client sends `Bearer cmn_…`.** Before any authentication runs, `V1RequestFilter` refuses a
   `Transfer-Encoding` header or HTTP/1.0 (`400 unsupported_framing`), a query string containing `cmn_`,
   `key` or `token` (`400 credentials_in_url`), a POST with no `Content-Length` (`411 length_required`) and
   a body over 4 MB (`413 request_too_large`).
2. **The key is checked in three steps, cheapest first.** `ApiKeyFormat` matches
   `cmn_(test_)?[0-9A-Za-z]{43}[0-9A-Za-z]{6}` and verifies a CRC32 of the body — no I/O. A malformed key
   is a `401 invalid_api_key` that costs nothing but a regex.
3. **A well-formed key is hashed and looked up.** SHA-256 → Valkey `apikey:{hash}`, 60 s TTL; a miss calls
   `GET /api-keys/{hash}` on auth-service and caches the answer, misses included, so garbage cannot hammer
   it. Revoking a key deletes the entry, so revocation is immediate; expired and revoked are the same 401.
4. **Credit is the last gate.** billing-service sets `no_credit:{org}` when `balance + credit_limit ≤ 0`, and
   the gateway turns the flag into `402 insufficient_balance` before the request is forwarded.
5. **What is forwarded carries identity, not credentials.** `IdentityHeadersFilter` strips the client's
   copy of `id-account`, `id-organization`, `id-api-key`, `tier`, `batch-line`, `Cookie` and every
   `Forwarded`/`X-Forwarded-*`/`traceparent` header, then sets the identity headers from the principal, and
   the route's `RemoveRequestHeader=Authorization` filter drops the key itself.

## Sessions, cookies and CSRF

The console session is a rotating refresh cookie: `__Host-carmonai-rt`, `HttpOnly`, `Secure`,
`SameSite=Strict`, `Path=/`, holding `{id}.{secret}` where only the secret's SHA-256 is stored. Every
refresh rotates it, and a cookie presented twice ends **every** copy of that session — that is the reuse
detection, and the reason a stolen cookie has a short life. Idle limit 7 days, absolute 30 days, and logout
expires the cookie.

Because the cookie exists, the four POST endpoints that touch it are guarded twice: `SameSite=Strict` keeps
it off cross-site requests, and `OriginFilter` refuses a POST to `/auth/login`, `/auth/register`,
`/auth/refresh` or `/auth/logout` whose `Origin` is not in `carmonai.console.origins`
(`CONSOLE_ORIGINS`, `http://localhost:3000` in compose). No `Origin` at all means not a browser — which is
why curl and SDKs still work. There is no CSRF token because there is no form; the two locks above are the
whole defence, and `/v1` has no CORS configuration at all.

## Privacy by design: no content anywhere

The rule is that logs, metrics, events, error bodies and caches carry **ids and counts only**. Concretely:

- `AccessLogFilter` writes one JSON line per request — `request_id`, `method`, `path` (never the query
  string), `status`, `duration_ms`, `client_ip`, `client_closed`, and the ids the gateway resolved. No
  headers, no bodies.
- `Metrics` tags every meter with `model` and `tier` (plus `outcome` and `code`); "an organization, account,
  API key, request id or prompt never becomes a tag — per-organization numbers live in usage data, where
  they belong".
- `UsageEvent` carries organization, API key, model, mode, tier, token counts, status, timestamps and
  latencies. Never a prompt, an answer or an IP.
- `OpenAiErrors` builds every message from fixed strings — "nothing from the request is echoed back, never
  `e.getMessage()`" — and `ApiErrorHandler` logs only the exception *class*, because a message can quote
  input.
- Nothing caches content: the only per-request cache is a keyed hash with a 60 s TTL.

That rule is not left to review. `docker/smoke.sh` sends a random `CANARY-$RANDOM$RANDOM` through a sync
prompt, a streamed prompt, a malformed body, an over-context body and a query string, then greps every
container's logs, a full `pg_dumpall`, the gateway's access log file and Valkey's append-only file for the
canary, `Bearer `, the live API key, `api_key=` and a password-reset token:

```bash
leaks=$( { "${DC[@]}" logs --no-color 2>&1; "${DC[@]}" exec -T db sh -c 'pg_dumpall -U "$POSTGRES_USER"'; access_log; valkey_file; } \
  | grep -acF -e "$canary" -e "Bearer " -e "$key2" -e "api_key=" -e "${keep#*=}" || true)
[[ $leaks == 0 ]] || { echo "FAIL $leaks lines leak ..."; exit 1; }
```

The same run asserts that the request appears in the access log with its `organization_id` and that the
access log did **not** reach stdout.

## The access log, and erasure

Brazil's Marco Civil da Internet (art. 15) requires connection records to be kept for six months, so the
gateway keeps them for 184 days: logback rolls `access.log` daily into `/var/log/carmonai`, gzipped, on its
own appender that never writes to stdout. `AccessLogFilter` wraps the security chain, so refused requests
are recorded too — that is the point of a connection log. `client_ip` is the TCP peer today; behind nginx it
becomes the `X-Forwarded-For` value nginx sets.

Erasure is a chain of idempotent calls, not a cascade: `DELETE /accounts/{id}` calls organization-service to
remove the account's memberships (which answers **409** while the account is the sole owner of an
organization that is not closed), then auth-service to end every session, then deletes the account and its
tokens. `GET /accounts/{id}/export` returns the account and every organization it belongs to, paged through
100 at a time, and returns no password hash. Closing an organization is erasure by status: batch-service's
sweep (every minute, 5 s in compose) deletes its files and ends its running batches, and the gateway stops
its keys within the 60 s cache TTL.

## Why it is like this

- **Identity as a header, set once.** The alternative — every service verifying the JWT itself — needs the
  public key in every service and repeats the check eight times per request fan-out. The cost is that the
  gateway is a single point of trust, which is why it is the most heavily tested module here and why the
  strip list is a constant a reviewer can read.
- **Cheapest check first.** A regex and a CRC32 before a cache read, a cache read before a network call, a
  token count before a database query. Garbage never becomes load.
- **402 rather than OpenAI's 429 `insufficient_quota`**, "because SDKs retry 429s, and retrying can't add
  credit". The status is the only signal some clients look at, so it has to mean what it says.
- **A canary instead of a policy document.** "No personal data in logs" is a claim until something greps
  for a string that was actually sent.

## What would change it

The access log is a file in a volume with no access control of its own; production ships it to a store with
restricted access, and that is unwritten. Password resets have a per-IP throttle but **no per-email one**, so
a distributed attacker can still spam one mailbox. There is no DPA gate, no CSAM reporting flow and no
second factor. TLS in transit is a deployment concern that is not configured anywhere in this repository —
nginx terminates it, and nginx is not built. Every one of those is listed in
[known gaps](../reference/gaps.md); the LGPD working rules themselves are in
`.claude/skills/carmonai-architecture/SKILL.md` and are marked "confirm with legal/DPO".

## Where to look

- [IdentityHeadersFilter.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/IdentityHeadersFilter.java)
  — the strip list, the identity headers and the two endpoints that keep the cookie.
- [ApiKeyAuthenticationManager.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ApiKeyAuthenticationManager.java)
  — the format check, the hash, the 60 s cache and the 402.
- [V1RequestFilter.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/V1RequestFilter.java)
  — the four refusals that run before authentication.
- [AccessLogFilter.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/AccessLogFilter.java)
  and [logback-spring.xml](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/resources/logback-spring.xml)
  — the fields, the file and the 184-day retention.
- [docker/smoke.sh](https://github.com/carmonai/back/blob/main/docker/smoke.sh) — the canary check and the
  fail-closed assertion, at the end of the run.
