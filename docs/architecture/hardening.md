# Hardening overrides

## What it is

The project's architecture follows a course reference, with six rules that **win wherever they conflict with
it**: Argon2id instead of a bare hash, RS256 with a locally verified JWKS instead of a symmetric token
checked on every request, a timeout plus a breaker plus a bulkhead on every outbound call, paged
collections with a maximum, pinned and non-root containers, and a management port that is never published
and never routed. This page is the concrete evidence for each one, in the order a request meets them.

## One request, six overrides

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="hard-title" aria-describedby="hard-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="hard-title">The six hardening overrides in the order a request meets them</title>
  <desc id="hard-desc">A request meets the container it runs in, the Argon2id password check at login, the RS256 token verified from a cached JWKS, the timeout, breaker and bulkhead on every outbound call, the paged read with a maximum size, and a management port it never reaches.</desc>

  <defs>
    <marker id="hard-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Stations in reading order: 1 container, 2 password, 3 token, 4 outbound call, 5 read, 6 management. -->
  <g id="hard-hops">
    <path id="hard-hop1" class="cmn-link cmn-link--flow" d="M114 132 H144" marker-end="url(#hard-arrow-flow)"/>
    <path id="hard-hop2" class="cmn-link cmn-link--flow" d="M240 132 H270" marker-end="url(#hard-arrow-flow)"/>
    <path id="hard-hop3" class="cmn-link cmn-link--flow" d="M366 132 H396" marker-end="url(#hard-arrow-flow)"/>
    <path id="hard-hop4" class="cmn-link cmn-link--flow" d="M492 132 H522" marker-end="url(#hard-arrow-flow)"/>
    <path id="hard-hop5" class="cmn-link cmn-link--flow" d="M618 132 H648" marker-end="url(#hard-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow cmn-step" id="hard-container" style="--i: 0;" aria-labelledby="hard-container-label">
    <rect x="18" y="100" width="96" height="64" rx="10"/><text id="hard-container-label" x="66" y="124">Container</text>
    <text class="cmn-sub" x="66" y="144">non-root, pinned</text></g>
  <g class="cmn-node cmn-node--flow cmn-step" id="hard-password" style="--i: 1;" aria-labelledby="hard-password-label">
    <rect x="144" y="100" width="96" height="64" rx="10"/><text id="hard-password-label" x="192" y="124">Passwords</text>
    <text class="cmn-sub" x="192" y="144">Argon2id</text></g>
  <g class="cmn-node cmn-node--flow cmn-step" id="hard-token" style="--i: 2;" aria-labelledby="hard-token-label">
    <rect x="270" y="100" width="96" height="64" rx="10"/><text id="hard-token-label" x="318" y="124">Tokens</text>
    <text class="cmn-sub" x="318" y="144">RS256 + JWKS</text></g>
  <g class="cmn-node cmn-node--flow cmn-step" id="hard-call" style="--i: 3;" aria-labelledby="hard-call-label">
    <rect x="396" y="100" width="96" height="64" rx="10"/><text id="hard-call-label" x="444" y="124">Outbound call</text>
    <text class="cmn-sub" x="444" y="144">timeout, breaker</text></g>
  <g class="cmn-node cmn-node--flow cmn-step" id="hard-read" style="--i: 4;" aria-labelledby="hard-read-label">
    <rect x="522" y="100" width="96" height="64" rx="10"/><text id="hard-read-label" x="570" y="124">Collections</text>
    <text class="cmn-sub" x="570" y="144">paged, max 100</text></g>
  <g class="cmn-node cmn-node--soft cmn-step" id="hard-management" style="--i: 5;" aria-labelledby="hard-management-label">
    <rect x="648" y="100" width="96" height="64" rx="10"/><text id="hard-management-label" x="696" y="124">Management</text>
    <text class="cmn-sub" x="696" y="144">never published</text></g>

  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M114 132 H144'); --cmn-travel: 0.4s; --cmn-delay: 0s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M240 132 H270'); --cmn-travel: 0.4s; --cmn-delay: 0.25s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M366 132 H396'); --cmn-travel: 0.4s; --cmn-delay: 0.5s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M492 132 H522'); --cmn-travel: 0.4s; --cmn-delay: 0.75s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M618 132 H648'); --cmn-travel: 0.4s; --cmn-delay: 1s;"/>

  <rect class="cmn-label-plate" x="300" y="52" width="240" height="16" rx="4"/><text class="cmn-label" x="420" y="64">one request, in the order it meets them</text>
  <rect class="cmn-label-plate" x="240" y="188" width="200" height="16" rx="4"/><text class="cmn-label" x="340" y="200">station 2 happens once, at login</text>
  <rect class="cmn-label-plate" x="552" y="188" width="196" height="16" rx="4"/><text class="cmn-label" x="650" y="200">station 6 is off the request path</text>
</svg>
</div>
<figcaption>The container is fixed before anything runs (step 1), the password is checked once at login
(step 2), and every console request after that is authenticated from a locally verified token (step 3);
steps 4 and 5 bound what a service may spend on a peer and on a read, and step 6 is the port the request
never reaches.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the request path, and the checks on it (solid)</span>
  <span>station 6 sits outside the path: metrics are scraped on the internal network</span>
</div>

1. **The container is non-root and pinned by digest** — two build stages, uid 10001, no `latest` tag.
2. **A password is checked by Argon2id, in account-service only**; no `Out` record carries the hash.
3. **A token is an RS256 JWT, verified at the gateway** against a cached JWKS, with no per-request call to
   auth-service and no shared secret that could sign one.
4. **Every outbound call has a timeout, a breaker and a bulkhead**, so a slow peer is refused, not queued.
5. **A collection is paged with a maximum**: `page`/`size`, default 20, ceiling 100 per service.
6. **Actuator and Prometheus answer on port 8081**, unpublished by any container and unrouted by the gateway.

## 1 · The container (override 5)

Every service's Dockerfile is the same 17 lines: a build stage and a runtime stage from the *same*
digest-pinned base, a layered jar extraction, and an unprivileged `USER`.

```dockerfile
FROM eclipse-temurin:25-jre-noble@sha256:398f810215757dc1926390014272579fb0e57c41ef1c8aa4f64ae761613a168b
RUN useradd --system --uid 10001 app
USER app
```

Compose pins every third-party image the same way (`postgres:17.11-bookworm`, `valkey/valkey:9.0.6`,
`vllm/vllm-openai:v0.30.0`, `prom/prometheus:v3.15.0`), and readiness is a real check: bash opens a socket to
`127.0.0.1:8081` and greps `/actuator/health/readiness` for `UP`, because the JRE image has no `curl`.
**The Kubernetes half of this override is not built** — no manifest exists, and `requests`/`limits` are only
`mem_limit` and `cpus` on Prometheus and Grafana in compose.

## 2 · Passwords: Argon2id (override 1)

```java
// OWASP minimum for Argon2id: m=19 MiB, t=2, p=1.
private static final Argon2PasswordEncoder ENCODER = new Argon2PasswordEncoder(16, 32, 1, 19 * 1024, 2);
// Checked when the email is unknown, so a miss costs the same Argon2 run as a hit.
private static final String DUMMY_HASH = ENCODER.encode("carmonai-timing-dummy");
```

Salt 16 bytes, hash 32 bytes, parallelism 1, 19 MiB of memory, 2 iterations — the OWASP floor, in
[AccountService.java](https://github.com/carmonai/back/blob/main/api/account-service/src/main/java/ai/carmonai/account/AccountService.java).
`spring-security-crypto` and `bcprov-jdk18on` are its dependencies, and the encoded hash lives in
`AccountModel` only: `AccountOut` carries an id, a name and an email, which is what makes
`GET /accounts/{id}/export` safe to return to its owner. The dummy hash is what stops an unknown email
answering measurably faster than a known one.

## 3 · Tokens: RS256, verified locally (override 2)

auth-service signs with a key derived from `carmonai.jwt.private-key` (base64 PKCS#8 DER, from the
environment) and publishes the public half at `GET /auth/jwks`; the token lives 15 minutes, and its claims
are ids only — issuer `ai.carmonai`, subject = the account id.

```java
NimbusReactiveJwtDecoder decoder = NimbusReactiveJwtDecoder.withJwkSetUri(jwksUri)   // http://auth:8080/auth/jwks
    .webClient(auth).build();
decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer("ai.carmonai"));
```

Nimbus caches the JWKS, so the fetch happens on a cold start rather than per request, and the `webClient` it
reuses has a 1 s connect and a 2 s response timeout. This override names its reference: HS256 with an
`/auth/solve` call per request makes auth-service a hard dependency of every request, and a shared secret
makes every service able to mint tokens. The ceiling is one signing key — rotating it means publishing old
and new until the oldest live token expires, at most 15 minutes (`ponytail:` in `JwtService`).

## 4 · Every outbound call is bounded (override 3)

Feign clients carry explicit timeouts, per dependency, in the service that owns the call:

| Service | Client | connect | read |
|---|---|---|---|
| `account-service` | `organization`, `auth` | 1000 ms | 3000 ms |
| `billing-service` | `usage`, `organization` | 1000 ms | 3000 ms |
| `gateway-service` | `auth` (WebClient) | 1000 ms | 2000 ms |
| `inference-service` | engine (WebClient) | 1000 ms | 30 s first token, 30 s idle, 600 s whole |

```yaml
resilience4j:
  circuitbreaker:
    configs:
      default:            # sliding-window-size 20, minimum-number-of-calls 10, failure-rate 50,
        wait-duration-in-open-state: 30s          # 3 half-open probes
        ignore-exceptions: [feign.FeignException$FeignClientException]   # a 4xx is an answer
  bulkhead:
    configs:
      default: { max-concurrent-calls: 25, max-wait-duration: 0 }
```

`spring.cloud.openfeign.circuitbreaker.enabled: true` puts every Feign call through that breaker.
`disable-time-limiter: true` is deliberate: the Feign timeouts above already bound the call, and a second
deadline with a different value races the first. `disable-thread-pool: true` keeps the call on the caller's
thread so a Feign error reaches the code that knows how to read it. Retries exist only where a call is safe
to repeat: [IdempotentRetryer.java](https://github.com/carmonai/back/blob/main/api/auth-service/src/main/java/ai/carmonai/auth/IdempotentRetryer.java)
retries **GETs only**, three attempts in total, backoff with full jitter. The gateway adds a breaker and a
bulkhead per `/v1` route — [resilience](resilience.md) has the numbers and the routes that have neither.

## 5 · Collections are paged, with a maximum (override 4)

The read is `accountRepository.findAll(PageRequest.of(page, Math.min(size, MAX_PAGE_SIZE), Sort.by("id")))`.
`MAX_PAGE_SIZE` is 100 in each of the three services that answers a list. `GET /accounts`,
`GET /organizations` and `GET /organizations/{id}/api-keys` all take `page` (default 0) and `size` (default
20), a negative page or a size below 1 is refused rather than defaulted, and the export pages *through*
organization-service 100 at a time instead of asking for everything.

Two shapes are deliberately not paged, and both say why in the code: `GET /billing/prices` returns the whole
price history — append-only, one row per price change — and `GET /usage/organizations/{id}/summary` caps its
answer with `limit` (1–100 groups, at most 31 days), because a silently truncated summary is worse than a
400.

## 6 · Management on 8081, never published and never routed (override 6)

```yaml
management:
  server: { port: 8081 }            # never published, never routed; the comment is in all eight services
  endpoint: { health: { probes: { enabled: true } } }
  endpoints: { web: { exposure: { include: health,prometheus,reconcile } } }   # reconcile: inference, billing
```

Compose publishes one port — `8080:8080` on the gateway — and the gateway's route predicates contain no
`/actuator` path, so `curl http://gateway:8080/actuator/prometheus` is a 401 with no route behind it.
Prometheus scrapes `:8081/actuator/prometheus` over the internal network, including the engine's own
`/metrics`; `AccessLogFilter` skips `/actuator/` so health probes never fill the access log.

## Why it is like this

- **The overrides exist because the reference is a teaching architecture.** Unsalted SHA-256, HS256 with a
  per-request `/auth/solve` and `/<service>/actuator` routed through the gateway are all fine in a classroom
  and all wrong in front of customers. Naming the replacement keeps a reviewer from "fixing" the code back.
- **Timeouts are per dependency, not global.** Console routes hold 15 s, `/v1` holds 660 s because it waits
  for a stream to *start*, and a Feign call to organization-service holds 3 s.
- **A 4xx is not a failure, and a maximum size is a control.** A 404 from organization-service must not count
  toward opening a breaker, and an unbounded read of `/accounts` is a denial of service with extra steps.

## What would change it

The breaker and bulkhead numbers are Java constants in `ResilienceConfiguration`, not properties, on purpose
— "a prefix nothing validates is a silent misconfiguration waiting to happen" — so changing them is a code
change with a test. The page ceiling is the same 100 written in three services; a shared constant belongs in
a library the day a fourth needs it. The K8s manifest, tracing and an Alertmanager destination are unbuilt:
[known gaps](../reference/gaps.md) tracks them.

## Where to look

- [AccountService.java](https://github.com/carmonai/back/blob/main/api/account-service/src/main/java/ai/carmonai/account/AccountService.java)
  — the Argon2id encoder, the dummy hash and the export/erasure order.
- [JwtService.java](https://github.com/carmonai/back/blob/main/api/auth-service/src/main/java/ai/carmonai/auth/JwtService.java)
  — RS256, the 15-minute TTL and the JWKS it publishes.
- [GatewayApplication.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/GatewayApplication.java)
  — the local JWKS decoder and both security chains.
- [account-service application.yaml](https://github.com/carmonai/back/blob/main/api/account-service/src/main/resources/application.yaml)
  — the resilience4j block, the Feign timeouts and the management port in one file.
