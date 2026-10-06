# The shape of the system

## What it is

Eight Spring Boot services, one Postgres, one Valkey and two model engines, all on a single Docker network.
Exactly one container publishes a port: the gateway. Everything else — including every management port — is
reachable only from inside, so the topology of this system is mostly the story of what the gateway forwards
and what it refuses to.

## The whole system on one page

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="topo-title" aria-describedby="topo-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="topo-title">The service graph and the public boundary</title>
  <desc id="topo-desc">A client outside the network reaches the gateway, the only container with a published
  port. Inside the boundary the gateway fans out to five console services and to inference and batch, and
  inference calls one of two engines. Every edge in the picture points away from the gateway.</desc>

  <defs>
    <marker id="topo-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- The network boundary: decoration, so it is hidden from assistive technology. -->
  <rect class="cmn-link cmn-link--quiet" x="128" y="10" width="620" height="262" rx="12" aria-hidden="true"/>
  <text class="cmn-label" x="330" y="30">internal network — no published port</text>
  <text class="cmn-label" x="64" y="30">outside</text>

  <!-- Hops in reading order: arrive, console fan, /v1 fan, engine calls. -->
  <g id="topo-hops">
    <path id="topo-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M112 110 H144" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 V58 H308" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 V58 H416" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 V58 H532" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 H308" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop6" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 H440" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop7" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 V182 H308" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop8" class="cmn-link cmn-link--flow cmn-dash" d="M260 110 V182 H460" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop9" class="cmn-link cmn-link--flow cmn-dash" d="M378 204 V224" marker-end="url(#topo-arrow-flow)"/>
    <path id="topo-hop10" class="cmn-link cmn-link--flow cmn-dash" d="M448 182 H545 V224" marker-end="url(#topo-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="topo-client" aria-labelledby="topo-client-label">
    <rect x="16" y="86" width="96" height="48" rx="10"/><text id="topo-client-label" x="64" y="105">Client</text>
    <text class="cmn-sub" x="64" y="120">SDK or app</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-gateway" aria-labelledby="topo-gateway-label">
    <rect x="144" y="86" width="116" height="48" rx="10"/><text id="topo-gateway-label" x="202" y="105">Gateway</text>
    <text class="cmn-sub" x="202" y="120">publishes 8080</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-auth" aria-labelledby="topo-auth-label">
    <rect x="308" y="36" width="96" height="44" rx="10"/><text id="topo-auth-label" x="356" y="53">Auth</text>
    <text class="cmn-sub" x="356" y="68">schema auth</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-account" aria-labelledby="topo-account-label">
    <rect x="416" y="36" width="104" height="44" rx="10"/><text id="topo-account-label" x="468" y="53">Account</text>
    <text class="cmn-sub" x="468" y="68">accounts</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-organization" aria-labelledby="topo-organization-label">
    <rect x="532" y="36" width="152" height="44" rx="10"/><text id="topo-organization-label" x="608" y="53">Organization</text>
    <text class="cmn-sub" x="608" y="68">organizations</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-usage" aria-labelledby="topo-usage-label">
    <rect x="308" y="88" width="120" height="44" rx="10"/><text id="topo-usage-label" x="368" y="105">Usage</text>
    <text class="cmn-sub" x="368" y="120">schema usage</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-billing" aria-labelledby="topo-billing-label">
    <rect x="440" y="88" width="120" height="44" rx="10"/><text id="topo-billing-label" x="500" y="105">Billing</text>
    <text class="cmn-sub" x="500" y="120">schema billing</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-inference" aria-labelledby="topo-inference-label">
    <rect x="308" y="160" width="140" height="44" rx="10"/><text id="topo-inference-label" x="378" y="177">Inference</text>
    <text class="cmn-sub" x="378" y="192">no database</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="topo-batch" aria-labelledby="topo-batch-label">
    <rect x="460" y="160" width="104" height="44" rx="10"/><text id="topo-batch-label" x="512" y="177">Batch</text>
    <text class="cmn-sub" x="512" y="192">schema batch</text>
  </g>
  <g class="cmn-node cmn-node--accent" id="topo-vllm" aria-labelledby="topo-vllm-label">
    <rect x="308" y="224" width="150" height="40" rx="10"/><text id="topo-vllm-label" x="383" y="239">vLLM</text>
    <text class="cmn-sub" x="383" y="253">Qwen3-4B, GPU</text>
  </g>
  <g class="cmn-node cmn-node--accent" id="topo-llama" aria-labelledby="topo-llama-label">
    <rect x="470" y="224" width="150" height="40" rx="10"/><text id="topo-llama-label" x="545" y="239">llama.cpp</text>
    <text class="cmn-sub" x="545" y="253">Qwen3-0.6B, CPU</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M112 110 H144'); --cmn-travel: 0.5s; --cmn-delay: 0s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M260 110 V58 H308'); --cmn-travel: 0.9s; --cmn-delay: 0.2s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M260 110 H308'); --cmn-travel: 0.5s; --cmn-delay: 0.4s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M260 110 V182 H308'); --cmn-travel: 0.9s; --cmn-delay: 0.6s;"/>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5" style="offset-path: path('M378 204 V224'); --cmn-travel: 0.4s; --cmn-delay: 1.0s;"/>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5" style="offset-path: path('M448 182 H545 V224'); --cmn-travel: 0.9s; --cmn-delay: 1.2s;"/>

  <rect class="cmn-label-plate" x="92" y="66" width="84" height="16" rx="4"/><text class="cmn-label" x="134" y="78">key or JWT</text>
  <rect class="cmn-label-plate" x="266" y="92" width="36" height="16" rx="4"/><text class="cmn-label" x="284" y="104">JWT</text>
  <rect class="cmn-label-plate" x="264" y="120" width="42" height="16" rx="4"/><text class="cmn-label" x="285" y="132">/v1</text>
  <rect class="cmn-label-plate" x="390" y="204" width="84" height="16" rx="4"/><text class="cmn-label" x="432" y="216">engine call</text>
</svg>
</div>
<figcaption>The gateway is inside the boundary and is the only way in: it fans out to the five console
services (steps 2–4), to the metering and money pair (steps 5–6) and to the `/v1` lane (steps 7–8); steps 9
and 10 are the engine calls. Where two edges share a segment they are drawn on top of each other, so a line
appears to pass behind a service rather than through it.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid), and an engine call (solid, accent)</span>
</div>

1. **The client reaches the gateway** — the only container with a published port (`ports: ["8080:8080"]`).
2. **The gateway forwards a console request** to auth-service after verifying the JWT locally against its
   cached JWKS, with `id-account` set and inbound identity headers stripped.
3. **Account and organization** answer from their own schemas; when account-service needs memberships it
   calls organization-service rather than reading its tables.
4. **Organization is the tenant**: status, tier, memberships, and the internal `tenant(id)` lookup.
5. **Usage** stores what was consumed: `POST /usage/events` from inference-service, plus sealed windows.
6. **Billing** prices a sealed window and writes a ledger entry; its `no_credit:{org}` flag in Valkey turns
   the next `/v1` call into a 402.
7. **Inference** is the only caller of the engines and the only writer of usage events. It has no database.
8. **Batch** runs Files and Batch API lines *through* inference-service over HTTP with a `batch-line` header.
9. **One engine endpoint per model**: `ENGINE_URL` for llama.cpp on the CPU, `VLLM_URL` for vLLM on the GPU.

## What each service owns

| Service | Schema | Holds | Reached by the gateway at |
|---|---|---|---|
| `gateway-service` | — | no data; it is the edge | — |
| `auth-service` | `auth` | `api_key`, `session` | `/auth/*`, `/organizations/{id}/api-keys**` |
| `account-service` | `accounts` | `account`, `account_token` | `/accounts/{id}`, `/accounts/{id}/export`, the public email endpoints |
| `organization-service` | `organizations` | `organization`, `membership` | `/organizations`, `/organizations/{id}` |
| `usage-service` | `usage` | `usage_event` (daily partitions, 90 days), `usage_window`, `usage_seal` | `/usage/organizations/{id}/summary` |
| `billing-service` | `billing` | `price`, `ledger_entry`, `balance`, `billing_cursor` | `/billing/organizations/{id}/balance` |
| `batch-service` | `batch` | `file`, `batch`, `batch_line` | `/v1/files**`, `/v1/batches**` |
| `inference-service` | — | nothing durable; usage goes to a Valkey stream | `/v1/chat/completions`, `/v1/models` |

Six services hold a schema in one Postgres, created by Flyway and versioned by date; Hibernate only validates.
Two hold none — the point of `/v1` is that nothing on the token path reads a database
([schemas](../data/schemas.md), [tenancy](../data/tenancy.md)).

## Where the state that is not a table lives

Valkey is a store of things that expire or are rebuilt, on purpose:

| Key | Written by | TTL |
|---|---|---|
| `apikey:{sha256}` | gateway (from auth-service's lookup) | 60 s, misses cached too |
| `no_credit:{org}` | billing-service (`CreditFlags`) | none — state, re-synced every 10 min |
| `rl:gw:{…}` and `rl:{org}:{model}:{…}` | gateway's and inference's token buckets | 120 s, refilled per minute |
| `usage:events` | inference-service (`UsageReporter`) | no TTL — an append-only stream until usage-service stores it |

## The container set

`docker/compose.yaml` runs fourteen containers; `docker/compose.gpu.yaml` adds a fifteenth.

| Container | Image or build | Notes |
|---|---|---|
| `db` | `postgres:17.11-bookworm` (digest-pinned) | one database, six schemas |
| `valkey` | `valkey/valkey:9.0.6` (digest-pinned) | `--appendonly yes --appendfsync everysec` |
| `mailpit` | `axllent/mailpit:v1.31.4` | verification and reset mail, locally |
| `account`, `organization`, `auth`, `usage`, `billing`, `inference`, `batch`, `gateway` | `build: ../api/<name>/Dockerfile` | one jar per service, non-root, port 8080, management 8081 |
| `llama`, `vllm` | `ghcr.io/ggml-org/llama.cpp:server`, `vllm/vllm-openai:v0.30.0` | CPU and GPU engines, one model each |
| `prometheus` | `prom/prometheus:v3.15.0` | scrapes every `:8081/actuator/prometheus`, 15-day retention |
| `grafana` | `grafana/grafana:13.2.3` | dashboards provisioned from `docker/grafana` — both unpublished |

Compose wires readiness, not just startup: every healthcheck opens a socket to its own management port and
greps `/actuator/health/readiness` for `UP`, so `service_healthy` means "answering".

## The direction every dependency points

| Caller | Callee | How | Why |
|---|---|---|---|
| `gateway-service` | `auth-service` | WebClient | `GET /api-keys/{hash}` on a cache miss, and `GET /auth/jwks` |
| `account-service` | `organization-service` | Feign `OrganizationController` | memberships for export and erasure |
| `account-service`, `auth-service` | each other | Feign `AuthController` / `AccountController` | `closeSessions` on erasure, credential check and `whoami` |
| `auth-service` | `organization-service` | Feign `OrganizationController` | `tenant(id)` for key authentication, `member(id, idAccount)` |
| `usage-service` | `organization-service` | Feign | membership check behind the customer summary |
| `usage-service`, `billing-service` | each other | Feign | sealed windows one way, the price history the other |
| `billing-service`, `batch-service` | `organization-service` | Feign | the balance endpoint's membership check, and the erasure sweep |
| `batch-service` | `inference-service` | HTTP | runs each batch line through `/v1/chat/completions` |
| `inference-service` | engine | WebClient | the only caller of an engine anywhere |

Two pairs are mutual: account ↔ auth, and usage ↔ billing. Each cycle is deliberate and has its reason
written down — `depends_on` cannot express a cycle, so usage's dependency on billing is deliberately absent
from compose, and a summary taken while billing is down answers tokens with a `null` cost instead of failing.
[Service boundaries](boundaries.md) explains what the cycle costs.

## Why it is like this

- **One database, many schemas.** A laptop runs one Postgres comfortably; six would be six more containers for
  no isolation the prototype needs. Schemas keep the boundary enforceable (a query naming another schema's
  table is visible in review) without paying for separate instances; [boundaries](boundaries.md) names the
  rejected alternative.
- **Compose DNS instead of service discovery.** `http://auth:8080` resolves because they are containers on the
  same network. There is no registry, no sidecar and no mesh, which is why every client URL is a configurable
  property with a compose default — that is also what lets an integration test point a client at a stub.
- **Valkey rather than Postgres for the request-path checks.** Key lookup, credit flag and rate buckets are
  reads a request cannot afford to do against a disk, and each one expires or is re-synced on its own.
- **The engines are the only Python.** Java never runs a model, never batches tokens and never touches a KV
  cache; it relays a stream and counts. See [Inference](../services/inference.md).

## What would change it

Nginx in front of gateway replicas, and Kubernetes with a Deployment per service, are written down in
`.claude/skills/carmonai-architecture/references/platform.md` and are not built. A second replica changes the
picture above in two specific places: the gateway's flood brake and inference-service's in-flight caps and
virtual token counters are per-JVM memory, so both need shared counters first. A single engine endpoint per
model is the third ceiling. [Known gaps](../reference/gaps.md) has them.

## Where to look

- [docker/compose.yaml](https://github.com/carmonai/back/blob/main/docker/compose.yaml) — the container set,
  healthchecks, volumes and every dependency edge (the GPU engine lives in `compose.gpu.yaml`).
- [gateway application.yaml](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/resources/application.yaml)
  — the route table: id, uri, path, timeout, bulkhead and fallback code per route.
- [UsageApplication.java](https://github.com/carmonai/back/blob/main/api/usage-service/src/main/java/ai/carmonai/usage/UsageApplication.java)
  and [BillingApplication.java](https://github.com/carmonai/back/blob/main/api/billing-service/src/main/java/ai/carmonai/billing/BillingApplication.java)
  — the two `@EnableFeignClients` lines that close the mutual dependency.
