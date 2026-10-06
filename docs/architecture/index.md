# Architecture

## What it is

Carmonai is eight Spring Boot services behind a single gateway, one Postgres holding one schema per
service, one Valkey holding the three checks that must not touch a database, and two model engines. Five of
the services publish a contract library — a Feign interface and its `In`/`Out` records — that other services
call. Nothing else is shared: no shared tables, no shared cache keys owned by two services, no Java model
crossing a service boundary.

The gateway is the only thing reachable from outside. It is also the only thing that decides who is calling:
it strips every inbound identity header and sets its own, so a service can trust `id-organization` without
ever verifying a token. That single rule is what makes the rest of the system simple, and it is the first
thing the [security page](security.md) has to defend.

Everything a request does falls into one of two lanes, and the lane decides the credential, the limits and
the failure mode. Console traffic carries a JWT and reaches auth, account, organization, usage and billing.
The `/v1` API carries an API key and reaches inference-service, which admits the request against a rate
budget and a share of the engine's slots before it may touch a GPU. The two lanes meet only in one place:
the money. A finished request becomes usage, usage becomes a priced window, and a used-up balance turns the
next `/v1` call into a 402 — see [billing](../services/billing.md) and [money](../data/money.md).

## The fork at the gateway

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="arch-index-title" aria-describedby="arch-index-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="arch-index-title">One gateway, two lanes</title>
  <desc id="arch-index-desc">A client reaches the gateway with either a console JWT or an API key. The JWT
  lane goes up to the five console services; the API-key lane goes down to inference, which calls a model
  engine and streams the answer back along the same path to the client.</desc>

  <defs>
    <marker id="arch-index-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="arch-index-arrow-accent" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Hops in reading order: 1 arrive, 2 console lane, 3 /v1 lane, 4 ask the engine, 5 answer back. -->
  <g id="arch-index-hops">
    <path id="arch-index-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M116 140 H152" marker-end="url(#arch-index-arrow-flow)"/>
    <path id="arch-index-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M214 116 V60 H330" marker-end="url(#arch-index-arrow-flow)"/>
    <path id="arch-index-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M214 164 V192 H330" marker-end="url(#arch-index-arrow-flow)"/>
    <path id="arch-index-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M480 192 H560" marker-end="url(#arch-index-arrow-flow)"/>
    <path id="arch-index-hop5" class="cmn-link cmn-link--accent cmn-dash" d="M620 216 V252 H68 V164" marker-end="url(#arch-index-arrow-accent)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="arch-index-client" aria-labelledby="arch-index-client-label">
    <rect x="20" y="116" width="96" height="48" rx="10"/><text id="arch-index-client-label" x="68" y="135">Client</text>
    <text class="cmn-sub" x="68" y="150">SDK or app</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="arch-index-gateway" aria-labelledby="arch-index-gateway-label">
    <rect x="152" y="116" width="124" height="48" rx="10"/><text id="arch-index-gateway-label" x="214" y="135">Gateway</text>
    <text class="cmn-sub" x="214" y="150">the only public port</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="arch-index-console" aria-labelledby="arch-index-console-label">
    <rect x="330" y="36" width="180" height="48" rx="10"/><text id="arch-index-console-label" x="420" y="55">Console services</text>
    <text class="cmn-sub" x="420" y="70">JWT, one schema each</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="arch-index-inference" aria-labelledby="arch-index-inference-label">
    <rect x="330" y="168" width="150" height="48" rx="10"/><text id="arch-index-inference-label" x="405" y="187">Inference</text>
    <text class="cmn-sub" x="405" y="202">admit, relay, meter</text>
  </g>
  <g class="cmn-node cmn-node--accent" id="arch-index-engine" aria-labelledby="arch-index-engine-label">
    <rect x="560" y="168" width="120" height="48" rx="10"/><text id="arch-index-engine-label" x="620" y="187">Engine</text>
    <text class="cmn-sub" x="620" y="202">vLLM or llama.cpp</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M116 140 H152'); --cmn-travel: 0.6s; --cmn-delay: 0s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M214 116 V60 H330'); --cmn-travel: 0.8s; --cmn-delay: 0.2s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M214 164 V192 H330'); --cmn-travel: 0.8s; --cmn-delay: 0.4s;"/>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M480 192 H560'); --cmn-travel: 0.6s; --cmn-delay: 0.6s;"/>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5" style="offset-path: path('M620 216 V252 H68 V164'); --cmn-travel: 1.4s; --cmn-delay: 0.9s;"/>

  <rect class="cmn-label-plate" x="98" y="100" width="72" height="16" rx="4"/><text class="cmn-label" x="134" y="112">key or JWT</text>
  <rect class="cmn-label-plate" x="224" y="78" width="100" height="16" rx="4"/><text class="cmn-label" x="274" y="90">console routes</text>
  <rect class="cmn-label-plate" x="224" y="214" width="100" height="16" rx="4"/><text class="cmn-label" x="274" y="226">the /v1 API</text>
  <rect class="cmn-label-plate" x="484" y="172" width="72" height="16" rx="4"/><text class="cmn-label" x="520" y="184">prompt</text>
  <rect class="cmn-label-plate" x="300" y="244" width="164" height="16" rx="4"/><text class="cmn-label" x="382" y="256">tokens, streamed back</text>
</svg>
</div>
<figcaption>The gateway is the fork: the same client reaches the console services with a JWT and the
inference API with an API key. Step 5 is the answer coming back along the same path, one chunk at a time,
while the client is still waiting.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> a response (dashed)</span>
</div>

1. **The client reaches the gateway** — the only container with a published port (`8080:8080` in
   `docker/compose.yaml`). Everything else is on the internal network.
2. **Console traffic goes up the JWT lane.** The gateway validates the token locally against auth-service's
   cached JWKS and sets `id-account`; account, auth, organization, usage and billing each answer from their
   own schema.
3. **API traffic goes down the API-key lane.** `POST /v1/chat/completions` is authenticated against a cached
   key lookup, the organization's credit flag is checked, and the request is forwarded with
   `id-organization`, `id-api-key` and `tier`.
4. **Inference asks the engine.** It admits the request against the organization's rate buckets in Valkey
   and a tier share of the engine's slots, then relays one HTTP stream from vLLM or llama.cpp.
5. **The answer streams back** down the same path, and the request's usage is written to a Valkey stream at
   the end. Nothing on this path reads a database.

## The five pages in this section

<div class="grid cards" markdown>

-   **The shape of the system**

    ---

    [Topology](topology.md) — the services as a graph, the public boundary, the data stores and the
    container set, with the direction every dependency points.

-   **Why the lines are where they are**

    ---

    [Service boundaries](boundaries.md) — one schema per service, one repository per module, what counts as
    an aggregate here, and where the split was deliberately not made.

-   **What was hardened first**

    ---

    [Hardening overrides](hardening.md) — the six rules that override the reference architecture, each with
    the code that satisfies it.

-   **What happens when something breaks**

    ---

    [Resilience](resilience.md) — timeouts, breakers and bulkheads per route, the engine's retry rule, and
    which failures fail closed.

-   **Who is trusted, and with what**

    ---

    [Security and privacy](security.md) — the identity headers, the key path, the 402 gate, and the rules
    that keep prompts out of logs, metrics and caches.

</div>

## Why it is like this

- **One public port, one place that authenticates.** Every other decision follows from it: services can
  read identity from a header, which means no service needs to parse a JWT, and no service needs a signing
  key. The cost is that the gateway is a single point of failure and a single place to get wrong — which is
  why its filters are the most heavily tested code in the repository.
- **One database, one schema per service.** A single Postgres instance is what a laptop can run; separate
  schemas keep the boundary honest without paying for separate servers. The rejected alternative was a
  shared schema with joins across modules: fast to write, impossible to split later.
- **Valkey on the request path, never Postgres.** A key lookup, a rate bucket and a credit flag are the only
  things a request must read, and all three are in memory. The engine answers in 253 ms at p95; a database
  round trip on every token would be visible.
- **Two lanes instead of one credential.** An API key cannot log into the console and a JWT cannot call
  `/v1`; they are two Spring Security chains in [GatewayApplication.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/GatewayApplication.java),
  with the API-key chain first. The alternative — one credential type for both — was rejected because the
  key must be cheap to verify thousands of times per minute and revocable per key, while a console session
  must be short-lived and cookie-backed.

## What would change it

The prototype runs on one laptop with one replica per service and no Kubernetes. Second replicas break two
things that are in one JVM's memory today: inference-service's in-flight caps and virtual token counters,
and the gateway's per-replica flood brake. Nginx in front of gateway replicas, Kafka once an event has a
second consumer, and object storage for batch files are all written down with their ceilings in
[known gaps](../reference/gaps.md) and in the phase notes under `.claude/skills/carmonai-architecture/`.

## Where to look

- [docker/compose.yaml](https://github.com/carmonai/back/blob/main/docker/compose.yaml) — every container,
  port, volume and dependency edge, with the reason in a comment above it.
- [GatewayApplication.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/GatewayApplication.java)
  — the two security chains and the JWKS-backed decoder.
- [application.yaml](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/resources/application.yaml)
  — the route table, with a comment per route naming its timeout and its bulkhead.
- [.claude/skills/carmonai-architecture/SKILL.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/SKILL.md)
  — the rules this section explains, in their original form.
