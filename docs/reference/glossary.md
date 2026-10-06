# Glossary

**The vocabulary, in the sense this project uses it — including the words that mean something narrower here
than they do outside.**

## What it is

Every term a reader will meet on these pages that is either project-specific or used in a narrower sense than
elsewhere. Each entry says what it means *here* in one or two sentences and names the page that uses it. The
words are alphabetical, because a glossary is looked up rather than read.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="gl-title" aria-describedby="gl-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="gl-title">Where the words live on one request's path</title>
  <desc id="gl-desc">Four stages of one request, left to right: admission, the relay, the ending and the
  money. Each stage carries the terms used at that point — C and q, tier share and the virtual token counter
  at admission; TTFT, TPOT, continuous batching and cache salt during the relay; the usage event, settlement
  and goodput at the ending; the sealed window, micro-BRL, the ledger and the no-credit flag in the money
  stage.</desc>

  <defs>
    <marker id="gl-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: admission, relay, ending, money. -->
  <g id="gl-hops">
    <path id="gl-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M180 140 H212"
          marker-end="url(#gl-arrow-flow)"/>
    <path id="gl-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M364 140 H396"
          marker-end="url(#gl-arrow-flow)"/>
    <path id="gl-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M548 140 H580"
          marker-end="url(#gl-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="gl-admission" aria-labelledby="gl-admission-label">
    <rect x="28" y="104" width="152" height="72" rx="10"/>
    <text id="gl-admission-label" x="104" y="126">Admission</text>
    <text class="cmn-sub" x="104" y="144">C and q · tier share</text>
    <text class="cmn-sub" x="104" y="160">VTC · admission-wait</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="gl-relay" aria-labelledby="gl-relay-label">
    <rect x="212" y="104" width="152" height="72" rx="10"/>
    <text id="gl-relay-label" x="288" y="126">The relay</text>
    <text class="cmn-sub" x="288" y="144">TTFT · TPOT</text>
    <text class="cmn-sub" x="288" y="160">batching · cache_salt</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="gl-ending" aria-labelledby="gl-ending-label">
    <rect x="396" y="104" width="152" height="72" rx="10"/>
    <text id="gl-ending-label" x="472" y="126">The ending</text>
    <text class="cmn-sub" x="472" y="144">usage event · settled</text>
    <text class="cmn-sub" x="472" y="160">goodput · status</text>
  </g>
  <g class="cmn-node cmn-node--money" id="gl-money" aria-labelledby="gl-money-label">
    <rect x="580" y="104" width="152" height="72" rx="10"/>
    <text id="gl-money-label" x="656" y="126">The money</text>
    <text class="cmn-sub" x="656" y="144">window · micro-BRL</text>
    <text class="cmn-sub" x="656" y="160">ledger · no_credit</text>
  </g>

  <!-- One packet per hop, in the order the request meets them. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M180 140 H212'); --cmn-travel: 0.8s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M364 140 H396'); --cmn-travel: 0.8s; --cmn-delay: 0.35s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="5"
          style="offset-path: path('M548 140 H580'); --cmn-travel: 0.8s; --cmn-delay: 0.7s;"></circle>
</svg>
</div>
<figcaption>One request, one stage at a time, with the project's own words placed where they are used.
The first node is where a request is admitted, the last is where it becomes money — and the money hop is a
different colour because it happens later, from a sealed window, not from the request itself.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the request moving through a stage (solid)</span>
  <span><i class="is-money"></i> the request becoming money, later (dashed, gold)</span>
</div>

1. At **admission**, a request meets `C` and `q`, its tier's share of the model's slots, and the virtual token
   counter that orders waiters.
2. During **the relay**, TTFT and TPOT are what the customer feels, and continuous batching plus `cache_salt`
   are what the engine does about it.
3. At **the ending**, the request's buckets are settled with the real token counts and a usage event goes out
   carrying ids and counts, never the prompt or the answer.
4. In **the money** stage, a sealed window is priced in micro-BRL into the ledger, and a balance that reaches
   zero sets the `no_credit` flag.

Terms that describe a practice rather than a stage — *ponytail*, *ceiling*, *trigger*, *defect*, *deliberate
deferral*, *unbuilt scope* — are defined below and used on [Decisions](decisions.md),
[Abandoned ideas](abandoned.md) and [Known gaps](gaps.md).

## The vocabulary

| Term | What it means here | Where it is used |
|---|---|---|
| Access log | One JSON line per request in the gateway's own file, refusals included: request id, method, path without the query, status, duration, client IP and ids. Daily files are kept 184 days, for Marco Civil art. 15 | [Gateway](../services/gateway.md) |
| Admission | The step before the engine where a request is charged against the rate buckets and takes a share of the model's slots. It decides 429 or go, and it is the only place fairness is enforced | [Admission](../requests/admission.md) |
| `admission-wait` | The 1.5 s a paying tier may wait for a slot when its tier is full. Trial, flex and batch lines are refused at once instead, because they are the traffic to shed first | [Capacity and fairness](../inference/capacity.md) |
| `batch-line` | The internal header batch-service sends when it runs a batch line through inference-service. It means priority 30, no rate buckets, credit checked per line, and batch prices; the gateway strips it from clients | [Batch API design](../operations/batch-api.md) |
| Bench | `docker/bench.sh` (three tiers at once through the gateway) and `docker/batch-bench.sh` (10,000 lines beside interactive traffic). Goodput is their pass mark, and a number they print is a measurement, not a price | [Observability](../operations/observability.md) |
| C and q | C is the number of concurrent requests the engine serves while still meeting the latency targets — 4 on the RTX 3050. q is how many more may wait in its queue — 2, because a longer queue pushes TTFT p95 past two seconds | [Capacity and fairness](../inference/capacity.md) |
| `cache_salt` | The per-organization salt inference-service puts on vLLM's prefix cache, so one tenant cannot detect another tenant's cached prompts by timing it | [Inference](../services/inference.md) |
| Canary check | A `CANARY-<uuid>` string sent through every kind of request in the smoke test; every log, the access log and a database dump are then grepped for it. It is how "no personal data in logs" is held to | [Security and privacy](../architecture/security.md) |
| Ceiling | The limit a deliberate shortcut accepts, written next to the shortcut in a `ponytail:` comment together with the upgrade path | [Abandoned ideas](abandoned.md) |
| `cmn_test_` | The API-key prefix used outside production. Production rejects it before any lookup, so a test key cannot become a production key by accident | [Auth](../services/auth.md) |
| Continuous batching | The engine re-forms its batch at every generated token, so a request joins and leaves mid-flight. Iteration-level scheduling is the same thing under its paper name | [Batching](../inference/batching.md) |
| `custom_id` | The caller's own identifier for a batch line, unique within the file. The output and error files key on it, which is how a customer matches an answer to a request | [Batch API design](../operations/batch-api.md) |
| Defect | A bug, as distinct from a deliberate deferral or unbuilt scope. Sorting gaps into these three kinds is what stops "future work" from flattening them | [Known gaps](gaps.md) |
| Deliberate deferral | A shortcut taken on purpose, with a trigger that would revisit it. It is a decision, and calling it a bug would hide the honest rows | [Known gaps](gaps.md) |
| DPA | The data-processing agreement that makes the customer the controller of prompts and outputs and Carmonai the operator. Sub-operators are named in it, and changes get 30 days' notice | [Security and privacy](../architecture/security.md) |
| Engine | The process that runs the model: vLLM on the GPU, llama.cpp on the CPU. Only inference-service talks to it, with a key, and its port is never published | [Inference](../inference/index.md) |
| Erasure | Deleting an account or closing an organization, which must also remove memberships, sessions and batch data. The sole owner of an active organization gets 409 instead, until the organization is closed | [Tenancy](../data/tenancy.md) |
| Exit check | The one runnable check that ends a phase — a bench, a smoke script, or SIGKILLing a service mid-call. Nothing starts before the previous phase's exit holds | [CI and shipping](../operations/ci.md) |
| Flex | `service_tier: "flex"`: a live request served in the batch lane, at batch prices, on spare capacity only. With no spare capacity it is refused at once with 429 `resource_unavailable` and is not billed | [Inference](../services/inference.md) |
| `FOR UPDATE SKIP LOCKED` | How a batch worker claims a line and holds it for the whole call. The row lock is the lease, so a crash simply makes the line claimable again | [Batch API design](../operations/batch-api.md) |
| Goodput | The share of requests that met every latency target. It is the pass mark for each bench, and it is why a 98% goodput at 4 concurrent requests counts for more than a fast average | [Capacity and fairness](../inference/capacity.md) |
| Grant | The internal, idempotent credit top-up (`POST /billing/grants`). With no payment provider, it is the only way credit enters a balance | [Billing](../services/billing.md) |
| `IdempotentRetryer` | The retry policy for calls that may safely be repeated. Usage events and grants are idempotent, so a retry cannot double-count | [Libraries](../services/libraries.md) |
| KV cache | The engine's per-request memory. It, not compute, is what limits concurrency here: with bf16 a 4096-token request did not fit on the prototype's card, so the cache is quantised to FP8 | [Capacity and fairness](../inference/capacity.md) |
| Ledger | The append-only table of money movements, one entry per (organization, model, mode) per window, with the balance updated in the same transaction. Database triggers refuse UPDATE, DELETE and TRUNCATE | [Money](../data/money.md) |
| Library versus service | A library holds a module's Feign controller interface and its `In`/`Out` records — the contract other services call. A service is the Spring Boot application that implements it and owns a Postgres schema | [Libraries](../services/libraries.md) |
| micro-BRL | The money unit: 1 BRL = 1,000,000, stored as a `bigint`. A window's cost is rounded half up exactly once, so a balance and the sum of its ledger can be compared to the last unit | [Money](../data/money.md) |
| `no_credit` flag | The Valkey key billing sets when `balance + credit_limit ≤ 0`. While it exists, the gateway answers 402 before the request reaches inference-service | [Billing](../services/billing.md) |
| Operator | Carmonai's LGPD role for the customer's prompts and outputs: process on instruction only, no training, zero retention for synchronous requests | [Security and privacy](../architecture/security.md) |
| Partition job | The job that keeps daily usage partitions for 90 days, created ahead under an advisory lock rather than by an extension | [Schemas](../data/schemas.md) |
| Pix | The Brazilian instant-payment rail the product will take money on, once a payment provider is chosen. Until then, credit is granted by staff | [Decisions](decisions.md) |
| Ponytail | The house coding style: the least code that works, with each deliberate shortcut marked by a `ponytail:` comment naming its ceiling and upgrade path, and one runnable check behind non-trivial logic | [Decisions](decisions.md) |
| Priority | The number inference-service sends the engine per tier: enterprise 0, standard 10, trial 20, batch 30. Any priority a client sends is overwritten, never passed through | [Admission](../requests/admission.md) |
| PSP | Payment service provider — the open decision that stands between the platform and its first paying customer | [Decisions](decisions.md) |
| Rate bucket | A Valkey token bucket per organization and model, covering requests, input tokens and output tokens per minute, refilled and debited atomically by one Lua script. Refusals carry `retry-after` and `retry-after-ms` | [Admission](../requests/admission.md) |
| Reconciliation | Two checks with one purpose. Billing re-syncs every credit flag and compares every balance with the sum of its ledger every 10 minutes; inference-service compares each engine's own token counters with the usage stored, every hour. Both report; neither fixes anything | [Billing](../services/billing.md) |
| Reuse detection | A refresh cookie presented twice means it was copied, and every copy of that session ends. It is the one signal a stateless token cannot give | [Auth](../services/auth.md) |
| Revenue leak | Tokens the engine processed that never became a usage event, and so were never billed. The reconciliation exists to make them visible; `docker/revenue-check.sh` exits non-zero when the books and the ledger disagree | [Metering](../services/metering.md) |
| ROPA | The record of processing activities (LGPD art. 37): one table covering both of Carmonai's roles, the controller side and the operator side | [Security and privacy](../architecture/security.md) |
| Sealed window | A usage window — 5 minutes, or 10 seconds in compose — that no longer accepts events, so billing can debit it exactly once. The seal job closes a window 60 seconds after it ends | [Metering](../services/metering.md) |
| Settlement | Giving back the output tokens a request reserved at admission and did not generate. It is written *before* the usage event and the metrics, because it is the correction the next request from that organization sees | [The end, however it ends](../requests/ending.md) |
| SLO | The latency targets per model class: TTFT and inter-token latency at p95, plus whole-request latency for non-streamed calls. Goodput is the share of requests that met all of them | [Observability](../operations/observability.md) |
| Smoke test | `docker/smoke.sh`: the end-to-end check CI runs, including the canary grep, the revoked-key path and the no-credit path | [CI and shipping](../operations/ci.md) |
| Tenant | The organization. It is the unit of billing, of rate limiting and of identity; `tenant(id)` answers status and tier for API-key authentication, with ids only and no name | [Tenancy](../data/tenancy.md) |
| Tier | `trial`, `standard` or `enterprise`, held by the organization. It sets the rate buckets, the share of slots and the engine priority. There is no free tier | [Capacity and fairness](../inference/capacity.md) |
| Tier share | The largest number of requests in flight on a model at which a tier is still admitted: trial `C/2`, standard `0.85·C`, enterprise `C+q` | [Capacity and fairness](../inference/capacity.md) |
| Trigger | The observable event that would bring a rejected idea back — a second consumer for an event, a file above 4 MB, a second replica. A rejection without one is a "never" | [Abandoned ideas](abandoned.md) |
| TTFT, TPOT | Time to the first token, and time per output token after it. Both are compared at p95, because a good average with a bad tail is a bad product. TPOT is also called inter-token latency | [The relay](../requests/relay.md) |
| Unbuilt scope | A capability that does not exist at all, as opposed to one deferred on purpose. The payment rail and `/v1/embeddings` are this kind of gap | [Known gaps](gaps.md) |
| Usage event | What one request consumed: organization, API key, model, mode, tier, input tokens, cached input tokens, output tokens, status, start time, TTFT and duration. Never a prompt or an answer | [Metering](../services/metering.md) |
| Virtual token counter (VTC) | The per-organization counter that orders *waiting* requests within a model: `estimatedInputTokens + max_tokens` is charged at admission and settled to the real counts, and the lowest counter goes first | [Capacity and fairness](../inference/capacity.md) |
| `x-ratelimit-*` | The headers on an admitted answer, covering requests and input tokens under OpenAI's names. There are no reset headers yet | [Admission](../requests/admission.md) |
| `__Host-carmonai-rt` | The console's refresh cookie: HttpOnly, Secure, SameSite=Strict, Path=/, and deliberately no Domain — which is what the `__Host-` prefix requires | [Who is calling](../requests/identity.md) |
| 402 `insufficient_balance` | The answer when the credit flag is set. It is 402 rather than OpenAI's 429 `insufficient_quota` because SDKs retry 429s, and retrying cannot add credit | [The edge](../requests/edge.md) |
