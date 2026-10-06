# 3 · Admission

Step 3 of [the path of a request](index.md). [Who is calling](identity.md) left the request authenticated,
with `id-organization`, `id-api-key` and `tier` on its headers. Here it has to earn a share of the engine
before it is allowed near it.

## What it is

Admission is two gates in a fixed order: three per-minute buckets in Valkey, then two in-flight caps held in
memory. Failing the buckets is an immediate 429; failing a cap is a 429 too, unless the tier pays — those may
wait 1.5 seconds for a slot first.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="adm-title" aria-describedby="adm-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="adm-title">The admission decision, from the rate buckets to a permit or a 429</title>
  <desc id="adm-desc">An admitted request is first charged against three per-minute buckets in one Lua
  script; an empty bucket refuses it at once with a 429. Requests that pass are then checked against the
  tier's share of the model's slots and the organization's own in-flight cap. A paying tier that meets a cap
  waits up to 1.5 seconds, polling, while a lower virtual token counter goes first; trial, flex and batch
  lines are refused immediately. Passing both gates yields a permit that is held until the request ends.</desc>

  <defs>
    <marker id="adm-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: down the decision, then the two refusals, then the wait loop. -->
  <g id="adm-hops">
    <path id="adm-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M142 92 H178" marker-end="url(#adm-arrow)"/>
    <path id="adm-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M304 92 H340" marker-end="url(#adm-arrow)"/>
    <path id="adm-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M466 92 H502" marker-end="url(#adm-arrow)"/>
    <path id="adm-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M628 92 H664" marker-end="url(#adm-arrow)"/>
    <path id="adm-bucket" class="cmn-link" d="M79 120 V186" marker-end="url(#adm-arrow)"/>
    <path id="adm-cap" class="cmn-link" d="M403 120 V186" marker-end="url(#adm-arrow)"/>
    <path id="adm-wait" class="cmn-link cmn-link--flow cmn-dash" d="M596 120 V186" marker-end="url(#adm-arrow)"/>
    <path id="adm-poll" class="cmn-link cmn-link--quiet" d="M622 186 V120" marker-end="url(#adm-arrow)"/>
    <path id="adm-timeout" class="cmn-link" d="M565 120 V158 H440 V186" marker-end="url(#adm-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="adm-buckets" aria-labelledby="adm-buckets-label">
    <rect x="16" y="64" width="126" height="56" rx="10"/>
    <text id="adm-buckets-label" x="79" y="84">Lua buckets</text>
    <text class="cmn-sub" x="79" y="102">three, one script</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="adm-share" aria-labelledby="adm-share-label">
    <rect x="178" y="64" width="126" height="56" rx="10"/>
    <text id="adm-share-label" x="241" y="84">Tier share</text>
    <text class="cmn-sub" x="241" y="102">of the model's slots</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="adm-org" aria-labelledby="adm-org-label">
    <rect x="340" y="64" width="126" height="56" rx="10"/>
    <text id="adm-org-label" x="403" y="84">Organization cap</text>
    <text class="cmn-sub" x="403" y="102">maxInFlight</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="adm-waitnode" aria-labelledby="adm-waitnode-label">
    <rect x="502" y="64" width="126" height="56" rx="10"/>
    <text id="adm-waitnode-label" x="565" y="84">Bounded wait</text>
    <text class="cmn-sub" x="565" y="102">1.5 s, paying tiers</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="adm-permit" aria-labelledby="adm-permit-label">
    <rect x="664" y="64" width="80" height="56" rx="10"/>
    <text id="adm-permit-label" x="704" y="84">Permit</text>
    <text class="cmn-sub" x="704" y="102">held to the end</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="adm-429buckets" aria-labelledby="adm-429buckets-label">
    <rect x="24" y="186" width="160" height="56" rx="10"/>
    <text id="adm-429buckets-label" x="104" y="206">429 buckets</text>
    <text class="cmn-sub" x="104" y="224">rate_limit_exceeded</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="adm-429caps" aria-labelledby="adm-429caps-label">
    <rect x="300" y="186" width="180" height="56" rx="10"/>
    <text id="adm-429caps-label" x="390" y="206">429 caps</text>
    <text class="cmn-sub" x="390" y="224">model_busy · too many in flight</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="adm-vtc" aria-labelledby="adm-vtc-label">
    <rect x="520" y="186" width="180" height="56" rx="10"/>
    <text id="adm-vtc-label" x="610" y="206">Lowest counter first</text>
    <text class="cmn-sub" x="610" y="224">waiters give way</text>
  </g>

  <!-- Packets, staggered so the decision reads in order. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M142 92 H178'); --cmn-travel: 0.5s; --cmn-delay: 0.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M304 92 H340'); --cmn-travel: 0.5s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M466 92 H502'); --cmn-travel: 0.5s; --cmn-delay: 1.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M628 92 H664'); --cmn-travel: 0.5s; --cmn-delay: 1.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M79 120 V186'); --cmn-travel: 0.6s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M403 120 V186'); --cmn-travel: 0.6s; --cmn-delay: 1.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M596 120 V186'); --cmn-travel: 0.6s; --cmn-delay: 1.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M622 186 V120'); --cmn-travel: 0.6s; --cmn-delay: 2.5s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M565 120 V158 H440 V186'); --cmn-travel: 0.7s; --cmn-delay: 2.1s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="122" y="44" width="76" height="16" rx="4"/>
  <text class="cmn-label" x="160" y="56">x-ratelimit-*</text>
  <rect class="cmn-label-plate" x="90" y="146" width="110" height="16" rx="4"/>
  <text class="cmn-label" x="145" y="158">bucket empty</text>
  <rect class="cmn-label-plate" x="272" y="146" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="332" y="158">waited, no slot</text>
</svg>
</div>
<figcaption>A request walks the decision left to right and top to bottom: buckets first, then the two caps,
then either a permit or a wait. The refusal at the buckets is immediate; the refusal at the caps is either
immediate (trial, flex, batch) or arrives after the 1.5-second wait (standard, enterprise).</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-async"></i> the wait's next look (dotted)</span>
  <span><i></i> a refusal (neutral line, outlined node)</span>
</div>

1. **One Lua script charges three buckets** for the pair (organization, model): requests per minute, input
   tokens per minute, and output tokens per minute. One script, one round trip, one hash slot — so the three
   cannot disagree about the same arrival.
2. **Input is charged on an estimate**: the request body's UTF-8 length ÷ 4. Counting real tokens would mean
   a GPU round trip to `/tokenize`, and that endpoint is not covered by the engine's API key.
3. **Output is charged at the full `max_tokens`** the request is allowed to generate, and the unused part is
   given back when the request ends. OpenAI counts `max_tokens` toward its limits for the same reason: the
   budget has to be reserved before it is spent.
4. **A bucket below 1 refuses the request at once** with 429 `rate_limit_exceeded` and the exact wait for the
   bucket that ran dry, in `retry-after-ms`.
5. **The model's share for this tier is checked next**, in memory, not in Valkey: trial and the batch lines
   get `C/2`, standard `0.85·C`, enterprise `C+q`. On `carmonai/qwen3-4b` (C = 4, q = 2) that is 2, 3 and 6 —
   and then the organization's own `max-in-flight` (2, 4 and 16) caps what one customer can take of it.
6. **A paying tier that meets a cap waits**, polling every 100 ms for up to `admission-wait`, 1500 ms by
   default. Trial, flex and batch lines are refused at once: they are the traffic meant to be shed first.
7. **While several organizations wait for one model, the lowest counter goes first.** Each organization has a
   virtual token counter — tokens served plus tokens reserved by its requests in flight — and a waiter whose
   counter is higher gives way for a poll.
8. **Passing both gates returns a permit** that carries the reservation, held until the request ends and
   released there, however it ends.

## Why it is like this

**Two gates, in this order, because they answer different questions.** The buckets answer "is this caller
sending more than its plan allows?" and are shared across replicas in Valkey. The caps answer "is there room
on this GPU right now?" and live in memory because a slot's occupant is a connection this JVM holds; putting
them in Valkey would add a round trip to a decision made in microseconds.

**Priority alone does not protect anyone.** vLLM's `--scheduling-policy priority` orders its waiting queue; it
never evicts a request that is already running. With a full engine, trial traffic enqueued first keeps the GPU
until it drains, whatever the priority of the enterprise request behind it. Reserved shares are what leave room.

**The caps are per tier *and* per organization** because the failure has two directions: the tier share stops
one tier from eating another's capacity, and the organization cap stops one customer from eating its tier's.
Without the second, the first is a promise the loudest tenant can break.

**Paying tiers wait; the cheap ones do not.** A slot frees on the order of one engine step — 24 ms measured on
the RTX 3050 — so 1.5 seconds is roughly sixty chances to get one, and far under the 30 s first-token timeout.
Retrying a 429 costs a round trip and a new admission; waiting 200 ms costs neither. Trial, flex and batch are
refused at once because they exist to use capacity nobody else wants.

**The wait polls instead of waking on release.** A permit-released sink would admit a waiter the instant a slot
frees, and the code says plainly that it is worth writing only if the poll interval ever shows up in the
queue-wait p95. Until then, one 100 ms timer is less machinery than a signalling path.

**The virtual token counter orders waiters, and limits nobody.** A plain in-flight count lets one organization
with several requests hold every slot of its tier while another waits. The counter is what makes a waiter give
way; a new request still passes through the same `acquire()`, so the counter cannot let anyone past their cap.

**The output budget is reserved, not measured, so a request can overshoot.** A request is admitted while each
bucket holds at least 1, so the last request through can push the output bucket to `-max_tokens`. Refusing
anything that would not fit instead makes a customer's *first* request of the minute fail whenever its
`max_tokens` exceeds the whole per-minute budget.

**Valkey down skips the buckets and keeps the caps.** A GPU that stops serving is worse than a rate limit that
is briefly not enforced, and the skipped charge is not lost: settlement writes the real counts either way.

**Batch and flex use spare capacity only.** A batch line skips the buckets and the organization cap and takes
the model at half of `C`; a flex request keeps its own buckets and cap but takes the same half. Both run at
priority 30, behind every interactive tier, and both are priced at half the sync rate.

## What would change it

- **A second replica of inference-service multiplies these caps.** The in-flight counters are one JVM's view
  of the world; two replicas would each admit a full set. Shared counters come before the second replica.
- **The admission wait is a poll every 100 ms.** If that interval shows up in the queue-wait p95, the upgrade
  is a sink that admits a waiter when a permit is released.
- **The virtual counters are swept by a scan** on every admission and settlement, and an organization that
  comes back after ten idle minutes starts from zero. A timer-driven sweep or an LRU is the fix if a model
  ever gathers thousands of organizations.
- **The input estimate, bytes ÷ 4, is wrong in both directions.** JSON punctuation inflates the body; a body
  of one-letter words deflates it. The correction only lands at settlement.
- **`x-ratelimit-*` reports requests and input tokens, and has no output-token header**, even though the
  output bucket is the one most likely to refuse a request that asks for a large `max_tokens`.

## Where to look

- [`Admission.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java)
  — both gates, the wait, the counter and the settlement.
- [`buckets.lua`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/buckets.lua)
  — the three buckets, their linear refill and the exact wait they return.
- [`ChatRequest.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatRequest.java)
  — the input estimate, `max_tokens` and the `flex` flag.
- [`application.yaml`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/application.yaml)
  — `admission-wait`, `max-connections`, the three tiers and each model's `slots` and `queue`.
- [`Metrics.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Metrics.java)
  — the queue-wait timer and the in-flight and capacity gauges.

**Next:** [4 · The relay](relay.md) — the permit is held, the slot is taken, and the request goes to the
engine for an answer.
