# Decisions

**What was decided, why, and what was rejected instead — with the questions that are still open marked as
open.**

## What it is

This is the decision record: the choices that bind the platform, grouped by area, each with the reason it was
made and the alternative that was turned down. A decision written down without its reason is useless to the
next engineer, so every row here carries one. The last section lists what is *not* decided, and says so
plainly rather than leaving a silent default in the code.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dec-title" aria-describedby="dec-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dec-title">The decision record, and what is still open</title>
  <desc id="dec-desc">Five areas — product, billing rules, identity, engineering and the prototype — each
  send a decided question down into one record that keeps the decision, the reason and the rejected
  alternative. Three questions sit below the record still open: the payment provider, the retention periods,
  and the legal entity with its LGPD questions. Nothing has travelled along those three dotted lines.</desc>

  <defs>
    <marker id="dec-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="dec-arrow-quiet" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Hops in reading order: the five decided areas, then the three open questions. -->
  <g id="dec-hops">
    <path id="dec-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M88 86 V112" marker-end="url(#dec-arrow-flow)"/>
    <path id="dec-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M238 86 V112" marker-end="url(#dec-arrow-flow)"/>
    <path id="dec-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M388 86 V112" marker-end="url(#dec-arrow-flow)"/>
    <path id="dec-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M538 86 V112" marker-end="url(#dec-arrow-flow)"/>
    <path id="dec-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M688 86 V112" marker-end="url(#dec-arrow-flow)"/>
    <path id="dec-hop6" class="cmn-link cmn-link--quiet" d="M160 164 V196" marker-end="url(#dec-arrow-quiet)"/>
    <path id="dec-hop7" class="cmn-link cmn-link--quiet" d="M380 164 V196" marker-end="url(#dec-arrow-quiet)"/>
    <path id="dec-hop8" class="cmn-link cmn-link--quiet" d="M600 164 V196" marker-end="url(#dec-arrow-quiet)"/>
  </g>

  <!-- Decoration: the halo that breathes behind an open question, never on its text. -->
  <g class="cmn-node cmn-node--soft cmn-pulse" aria-hidden="true" style="--cmn-delay: 0s;">
    <rect x="52" y="188" width="216" height="72" rx="14"/></g>
  <g class="cmn-node cmn-node--soft cmn-pulse" aria-hidden="true" style="--cmn-delay: 0.4s;">
    <rect x="272" y="188" width="216" height="72" rx="14"/></g>
  <g class="cmn-node cmn-node--soft cmn-pulse" aria-hidden="true" style="--cmn-delay: 0.8s;">
    <rect x="492" y="188" width="216" height="72" rx="14"/></g>

  <g class="cmn-node cmn-node--flow" id="dec-product" aria-labelledby="dec-product-label">
    <rect x="22" y="30" width="132" height="56" rx="10"/>
    <text id="dec-product-label" x="88" y="50">Product</text><text class="cmn-sub" x="88" y="68">no free tier</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="dec-billing" aria-labelledby="dec-billing-label">
    <rect x="172" y="30" width="132" height="56" rx="10"/>
    <text id="dec-billing-label" x="238" y="50">Billing rules</text><text class="cmn-sub" x="238" y="68">errors aren't billed</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="dec-identity" aria-labelledby="dec-identity-label">
    <rect x="322" y="30" width="132" height="56" rx="10"/>
    <text id="dec-identity-label" x="388" y="50">Identity</text><text class="cmn-sub" x="388" y="68">cookie, not header</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="dec-engineering" aria-labelledby="dec-engineering-label">
    <rect x="472" y="30" width="132" height="56" rx="10"/>
    <text id="dec-engineering-label" x="538" y="50">Engineering</text><text class="cmn-sub" x="538" y="68">Kafka only later</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="dec-prototype" aria-labelledby="dec-prototype-label">
    <rect x="622" y="30" width="132" height="56" rx="10"/>
    <text id="dec-prototype-label" x="688" y="50">Prototype</text><text class="cmn-sub" x="688" y="68">local, synthetic</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dec-record" aria-labelledby="dec-record-label">
    <rect x="60" y="112" width="640" height="52" rx="10"/>
    <text id="dec-record-label" x="380" y="132">The decision record</text>
    <text class="cmn-sub" x="380" y="150">decision · reason · alternative</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dec-payment" aria-labelledby="dec-payment-label">
    <rect x="60" y="196" width="200" height="56" rx="10"/>
    <text id="dec-payment-label" x="160" y="216">Payment provider</text>
    <text class="cmn-sub" x="160" y="234">open · not chosen</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="dec-retention" aria-labelledby="dec-retention-label">
    <rect x="280" y="196" width="200" height="56" rx="10"/>
    <text id="dec-retention-label" x="380" y="216">Retention periods</text>
    <text class="cmn-sub" x="380" y="234">open · with counsel</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="dec-legal" aria-labelledby="dec-legal-label">
    <rect x="500" y="196" width="200" height="56" rx="10"/>
    <text id="dec-legal-label" x="600" y="216">Legal entity and LGPD</text>
    <text class="cmn-sub" x="600" y="234">open · blocks real data</text>
  </g>

  <!-- One packet per decided area, in reading order. The open questions get none. -->
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M88 86 V112'); --cmn-travel: 0.6s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M238 86 V112'); --cmn-travel: 0.6s; --cmn-delay: 0.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M388 86 V112'); --cmn-travel: 0.6s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M538 86 V112'); --cmn-travel: 0.6s; --cmn-delay: 0.45s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M688 86 V112'); --cmn-travel: 0.6s; --cmn-delay: 0.6s;"></circle>
</svg>
</div>
<figcaption>Five areas of the record send a decided question down into the record, which keeps three things:
the decision, the reason, and the alternative that was rejected. The three questions below are still open, so
no packet travels their dotted lines — the page marks them as undecided instead of choosing for them.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a decision entering the record (solid)</span>
  <span><i class="is-async"></i> still open: nothing has moved along it (dotted)</span>
</div>

1. The record is grouped into five areas, and each area can be read on its own.
2. Every decided question travels into one record that keeps the decision, the reason, and the rejected alternative together.
3. Three questions never arrive — they are still open, and the page labels them as open rather than letting a default stand in for a decision.
4. The payment provider waits for the first customer who pays; the retention periods wait for counsel; the legal entity and its LGPD questions wait for any outside user at all.
5. A decision that is later reversed is edited in place, not deleted: the ceiling it hit is the part the next engineer needs most.

## Product

| Decision | Why | Rejected alternative |
|---|---|---|
| OpenAI-compatible `/v1`, served by vLLM | Any OpenAI SDK works after a base-URL change, and vLLM supplies continuous batching, tier priority, `cache_salt` and running token counts that a hand-written server would have to build | A bespoke request schema, which makes every customer write a client; llama.cpp as the production engine, which ignores `priority` and `cache_salt` and reports usage only at the end of a stream |
| Tiers: `trial`, `standard`, `enterprise`; no free plan | The tier is what the rate buckets, the in-flight caps and the engine priority are keyed on, and a prepaid product needs an enforceable unit — the mechanism is on [Admission](../requests/admission.md) | A free plan with public signup — capacity given away with no way to shed it |
| Prepaid credit in BRL; Pix when the first customer pays | Prepaid means no dunning and no credit risk before there is a legal entity to invoice from; Pix is the rail Brazilian customers already use | Cards and subscriptions (Stripe's Pix is invite-only); postpaid invoicing |
| Batch API at half the sync price, and `service_tier: "flex"` in the same lane | It is the OpenAI convention (50%, a 24 h window) and it fills capacity that would otherwise idle: priority 30, and only while the model is at most half busy. Flex gives retry-tolerant live traffic the same cheap lane without a second billing path, and a flex request is served as flex or refused, never moved | A separate batch cluster; per-line dynamic pricing; queueing flex requests instead of shedding them; a separate `flex` mode in the schema |
| `cmn_test_` key prefix outside production | Production rejects the prefix before any lookup, so a test key cannot become a production key by accident | One key format everywhere with an environment check in the database |

## Billing rules

| Decision | Why | Rejected alternative |
|---|---|---|
| A cancelled stream is billed its input plus the output generated so far | Those tokens were generated and the GPU time was spent; vLLM reports running usage in every chunk, so the last chunk before the cancel is the truth — see [Metering](../services/metering.md) | Billing nothing — the pre-2026-10-04 behaviour, when the only usage chunk arrived at the end and a cancelled stream billed zero |
| Our own failures are not billed (`status=error`) | The customer paid for an answer and did not get one; the fault is ours | Billing every attempt |
| The balance floor is 0, and the floor never refuses a debit — it only sets the flag | Usage already incurred has to be recorded, or the balance stops agreeing with the ledger, which is what the reconciliation exists to catch | Refusing a debit below the floor; a negative-balance buffer as a hard stop |
| A batch line is billed once, for the run that answered | A crash releases the line and it runs again; the event id is a name-based UUID of (batch, line) and `started_at` is the batch's creation time, so the partitioned key `(event_id, started_at)` catches the re-run | Billing the first attempt — found by killing batch-service mid-call, which billed the partial run while the answer went free |
| Out of credit answers 402, not OpenAI's 429 `insufficient_quota` | SDKs retry 429s automatically, and retrying cannot add credit | 429, for shape-consistency with OpenAI |
| Money is `bigint` micro-BRL, rounded half up once per window | Integers cannot drift, and a single rounding point keeps the ledger and the sum of the ledger equal to the last unit — the unit itself is explained on [Money](../data/money.md) | Decimal BRL or floating point in the ledger |
| Credit arrives through an internal, idempotent grant; prices are placeholders | With no payment provider, a staff grant is the only source of credit, and idempotency makes a retry safe. Laptop numbers prove the pipeline and size the prototype's caps — a price comes from a bench on the production GPU | Editing a balance by hand; a top-up endpoint without an idempotency key; quoting a commercial price before that bench exists |
| Usage and money are readable by any member of one organization, one organization per request | A missing `id-account` header is refused, so a mistake fails closed, and an endpoint never confirms that another organization exists or shows its numbers | "My balance" by ambient identity; listing the caller's organizations; letting a customer endpoint move money |

## Identity

| Decision | Why | Rejected alternative |
|---|---|---|
| The refresh token lives in an HttpOnly `__Host-carmonai-rt` cookie, not a response body | An XSS can read `localStorage`; it cannot read an HttpOnly cookie. `SameSite=Strict` plus an `Origin` check on the cookie endpoints is the CSRF defence — walked through on [Who is calling](../requests/identity.md) | A refresh token in the JSON body, stored by the console SPA; a cookie without the `__Host-` prefix |
| Sessions end after 7 days idle or 30 days absolute, every refresh rotates the secret, and a reused cookie ends every copy | A stolen cookie is caught by its second use — the one signal a stateless JWT cannot give | Long-lived refresh tokens; a token-family table, when one row per login already answers the question |
| Organizations are created explicitly; a person is not implicitly an organization | The organization is the billing unit, the rate-limit unit and the tenant, and membership has to be an explicit grant with a role | An implicit personal organization created at registration |
| Membership is checked through organization-service on every console request, with no cache | A cached membership is a revoked membership that still works; `/v1` never checks membership at all, because the API key's organization is the identity there | Caching memberships in the gateway; re-checking membership on the inference path |
| The sole owner of an active organization cannot erase their account: 409 | Erasure would leave an organization with nobody able to own it, and its data with no responsible party | Auto-closing the organization as part of erasure |
| Registration always answers 202, and login answers 403 until the email is verified | A 409 "email already registered" lets anyone probe who has an account; a known address gets an email instead of a second account | 409 on a known email — the pre-phase-7 behaviour |
| API keys are `cmn_` + 43 base62 characters + a CRC32, SHA-256 at rest with no pepper, at most 50 live keys, an optional expiry where null means never, and rotation as one transaction | The format check costs no I/O, so a malformed key never reaches auth-service; a 256-bit random secret cannot be brute-forced, and a pepper cannot be rotated without reissuing every key | bcrypt on a random secret (slow for no gain); counting expired keys against the 50-key cap, which would let a customer's own expiries lock them out; a hidden maximum lifetime, when a policy belongs in the console |
| An expired key and a revoked key give the same answer: 401 `invalid_api_key` | Nothing on the wire says which of the two it was | A `key_expired` code, which leaks that the key existed |

## Engineering

| Decision | Why | Rejected alternative |
|---|---|---|
| The gateway is the only public port, and services trust the identity headers it sets and nothing else | One place authenticates, and one place strips the headers a client tried to forge — see [The shape of the system](../architecture/topology.md) | Every service verifying JWTs itself |
| No database on the chat path: admission reads Valkey and in-process counters | A token must not wait behind a Postgres write | Admission counters or usage events in Postgres |
| Kafka only when an event gets a second consumer; until then usage goes to a Valkey stream with a consumer group and an append-only file | A broker for one consumer is a system to operate for no benefit, and a killed inference-service loses nothing: the relay is a plain HTTP consumer that already existed. Kafka later is a one-to-two-day move | An in-memory buffer sent over HTTP, which lost events on a crash; Kafka, an outbox and Spring Modulith now — see [Abandoned ideas](abandoned.md) |
| One Git repository per module: 13 submodules under `api/` | A library and its service version independently, and CI can point at their merge commits in order | A monorepo; publishing the libraries to GitHub Packages |
| Java 25 LTS, Spring Boot 4.1, Spring Cloud 2025.1, Jackson 3, Testcontainers 2 | 25 is LTS and inside the range Boot 4.1 documents (17–26) | Java 27, which is outside that range and not LTS |
| Append-only ledger and price table, enforced by database triggers | A trigger refuses UPDATE, DELETE and TRUNCATE with no role or grant management to keep in sync | Separate database roles — deferred, with a named ceiling |
| The gateway's flood brake is one Lua script in Valkey, and it fails **open** on a Valkey failure | Replicas share one rate instead of multiplying it, and `retry-after` is the real refill time; flood protection is not the last line of defence, so a Valkey blip must not become an outage | Per-replica memory, which is still the fallback when Valkey is down; failing closed on flood protection |
| Waiting requests are ordered by their organization's virtual token counter, and a paying tier waits up to `admission-wait` (1.5 s) for a slot | One organization cannot hold every slot of its tier while another waits, and the instant 429 punished a paying tier for a race at start-up; trial, flex and batch lines are still refused at once because they are the traffic to shed | A second cap; DRR across replicas, which needs Kubernetes; an instant 429 for everyone |
| Flex usage is recorded as mode `batch` | The half-price lane is already priced and already reported, so no usage or billing migration was needed | A `flex` mode of its own |
| A request's bucket settlement is written before its usage event and its metrics | The settlement is the correction the next request from that organization sees; with the event first, a second request could arrive before the refund | Emitting the event first |
| No personal data in logs, in usage or in the ledger: ids and counts only, checked by a canary in the smoke test | LGPD by design is cheaper than retrofitting it, and a prompt in a log is a prompt in a backup | Scrubbing later |
| Ponytail mode: the least code that works, a `ponytail:` comment naming the ceiling, one runnable check behind non-trivial logic | The ceiling is the part a later engineer needs, and a comment is where they will read it | Writing the general version first |

## Prototype

| Decision | Why | Rejected alternative |
|---|---|---|
| Local only: one developer laptop, synthetic data, no outside users, no legal entity; hosting deferred | Nothing real is at stake while the shape is still moving, and hosting is a decision with legal consequences — [Running it locally](../operations/running.md) says what the stack actually is | Renting a cloud GPU and a hosted environment first — see [Abandoned ideas](abandoned.md) |
| The engine is the laptop's own RTX 3050 6 GB | It costs nothing and it is already there; the numbers it produces size the prototype's caps | A free cloud GPU, every option of which was rejected for a stated reason |
| vLLM runs with `--gpu-memory-utilization 0.78` and `--kv-cache-dtype fp8` | Windows keeps about 1 GB of VRAM for the desktop and CUDA under WSL2 costs about 0.9 GiB more; with bf16 the KV cache could not hold one 4096-token request. Ceiling: the effect of an FP8 KV cache on Portuguese quality is unmeasured | 0.90 utilisation, which refuses to start; bf16 KV, which cannot serve a full-length request |

## Still open

Nothing below has been chosen, and each blocks a named thing. Two further decisions are deferred rather than open, because the work that needs them does not exist yet: **hosting and GPU** (AWS `sa-east-1` is the only in-country hyperscaler with H100s and it is expensive; Magalu Cloud needs a quote; abroad needs ANPD standard contractual clauses) and **the platform** (Kubernetes with KEDA, nginx at the edge).

| Open question | What it blocks | Where the options stand |
|---|---|---|
| Payment provider, and an NFS-e invoicing provider | Taking money from anyone: credit today comes from a staff grant | Efí (Pix-native, webhooks over mTLS), Mercado Pago (HMAC-signed webhooks) and Stripe (Pix, invite-only) all sign their webhooks; Asaas sends only a token. Whichever is chosen, the webhook is a hint and the charge is re-fetched before credit is given |
| Retention periods for accounts, usage, batches and the access log | Any promise made in a customer contract | To confirm with counsel. The access log is already kept 184 days for Marco Civil art. 15, usage partitions 90 days, batch files 30 days |
| Legal entity, and the LGPD questions around it | Any outside user at all | Whether Carmonai counts as a small agent (which doubles an incident deadline unless the processing is high-risk), whether inference is high-risk processing, and the Marco Civil access-log duty: all three are counsel questions, not engineering ones |

## Why it is like this

The expensive part of a project is not the code — it is knowing why the code is shaped that way six months
later. Three habits follow from that:

- **The rejected alternative is part of the decision.** "Batch files live in Postgres" is a fact; "batch files
  live in Postgres because object storage needs hosting first, and the ceiling is a 4 MB upload" is a decision,
  and only the second one says when to revisit it.
- **Open is written as open.** The payment provider, the retention periods and the legal questions are marked
  undecided rather than quietly resolved by whichever default was convenient. A default nobody chose is the
  most expensive kind of decision, because nobody knows to revisit it.
- **The record is maintained.** Two decisions changed after review and both are still visible: the output
  bucket now sets `max_tokens` aside at admission, and usage events now go through a durable Valkey stream.

## What would change it

Most rows carry a ceiling in their *why* column, and each ceiling names its own trigger. The shortcuts with a
real trigger are collected on [Known gaps](gaps.md) and [Abandoned ideas](abandoned.md): separate database
roles when the database is shared, object storage when hosting is decided, Kafka when an event gets a second
consumer, shared counters before a second replica, a `flex` mode of its own when flex needs its own price or
report, and a maximum API key lifetime if a customer asks for a policy.

## Where to look

- [inference-plan.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/inference-plan.md) — §12 is this page's spine, and the blocks at the top list every deviation, phase by phase.
- [plan-review-2026-10-02.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/plan-review-2026-10-02.md) — the review that changed several of these decisions, with its sources.
- [Price.java](https://github.com/carmonai/back/blob/main/api/billing/src/main/java/ai/carmonai/billing/Price.java) — the one implementation of the money arithmetic, shared by the debit job and the customer summary.
- [Admission.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java) — where the tier share, the organization cap and the virtual token counter actually meet.
