# Abandoned ideas

**What was considered and deliberately not built, what it would have bought, what it would have cost, and the
trigger that would bring it back.**

## What it is

This page is the other half of the [decision record](decisions.md): the options that were weighed and turned
down rather than chosen. Each entry names three things — what the mechanism would have bought, what it would
have cost to run, and the observable event that would make it the right answer again. A rejection without a
trigger is just a "later", and a "later" with no trigger is a "never".

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="ab-title" aria-describedby="ab-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="ab-title">One idea, weighed, and the road not taken</title>
  <desc id="ab-desc">An idea is weighed against what it buys and what it costs, then forks: the road that was
  taken leads to what was built and to the ceiling recorded beside it, while the road not taken ends at the
  reason it was parked and the trigger that would bring it back. Packets travel only the road that was
  taken.</desc>

  <defs>
    <marker id="ab-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
    <marker id="ab-arrow-quiet" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: the idea, the fork, and only the second hop of each road. -->
  <g id="ab-hops">
    <path id="ab-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M156 140 H186"
          marker-end="url(#ab-arrow-flow)"/>
    <path id="ab-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M336 140 C368 140, 368 80, 400 80"
          marker-end="url(#ab-arrow-flow)"/>
    <path id="ab-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M550 80 H590"
          marker-end="url(#ab-arrow-flow)"/>
    <path id="ab-hop4" class="cmn-link cmn-link--quiet" d="M336 140 C368 140, 368 200, 400 200"
          marker-end="url(#ab-arrow-quiet)"/>
    <path id="ab-hop5" class="cmn-link cmn-link--quiet" d="M550 200 H590"
          marker-end="url(#ab-arrow-quiet)"/>
  </g>

  <!-- The idea, and the weighing both roads come out of -->
  <g class="cmn-node cmn-node--entry cmn-node--soft" id="ab-idea" aria-labelledby="ab-idea-label">
    <rect x="20" y="112" width="136" height="56" rx="10"/>
    <text id="ab-idea-label" x="88" y="132">An idea</text>
    <text class="cmn-sub" x="88" y="150">cheaper or simpler</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="ab-weighed" aria-labelledby="ab-weighed-label">
    <rect x="186" y="112" width="150" height="56" rx="10"/>
    <text id="ab-weighed-label" x="261" y="132">Weighed</text>
    <text class="cmn-sub" x="261" y="150">what it buys and costs</text>
  </g>

  <!-- The road taken -->
  <g class="cmn-node cmn-node--flow" id="ab-built" aria-labelledby="ab-built-label">
    <rect x="400" y="52" width="150" height="56" rx="10"/>
    <text id="ab-built-label" x="475" y="72">Kept and built</text>
    <text class="cmn-sub" x="475" y="90">with its ceiling named</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="ab-ceiling" aria-labelledby="ab-ceiling-label">
    <rect x="590" y="52" width="150" height="56" rx="10"/>
    <text id="ab-ceiling-label" x="665" y="72">Ceiling recorded</text>
    <text class="cmn-sub" x="665" y="90">in a ponytail comment</text>
  </g>

  <!-- The road not taken -->
  <g class="cmn-node cmn-node--soft" id="ab-notbuilt" aria-labelledby="ab-notbuilt-label">
    <rect x="400" y="172" width="150" height="56" rx="10"/>
    <text id="ab-notbuilt-label" x="475" y="192">Not built</text>
    <text class="cmn-sub" x="475" y="210">a reason and a trigger</text>
  </g>
  <g class="cmn-node cmn-node--soft" id="ab-trigger" aria-labelledby="ab-trigger-label">
    <rect x="590" y="172" width="150" height="56" rx="10"/>
    <text id="ab-trigger-label" x="665" y="192">Its trigger fires</text>
    <text class="cmn-sub" x="665" y="210">then reconsidered</text>
  </g>

  <!-- Three packets: the idea, the fork, and the ceiling. The lower road carries none. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M156 140 H186'); --cmn-travel: 0.8s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M336 140 C368 140, 368 80, 400 80'); --cmn-travel: 1s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M550 80 H590'); --cmn-travel: 0.8s; --cmn-delay: 0.9s;"></circle>

  <!-- Labels last, each on its own plate -->
  <rect class="cmn-label-plate" x="140" y="66" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="200" y="78">the road we took</text>
  <rect class="cmn-label-plate" x="130" y="186" width="140" height="16" rx="4"/>
  <text class="cmn-label" x="200" y="198">the road not taken</text>
</svg>
</div>
<figcaption>An idea is weighed once, and the two roads start from the same place: the road that was taken
ends at what was built, with the ceiling written down beside it, and the road not taken ends at the reason it
was parked. Only the upper road carries packets — nothing ever travelled the lower one, which is why it is
dotted.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a mechanism that was built (solid)</span>
  <span><i class="is-async"></i> considered, never built (dotted)</span>
</div>

1. An idea arrives: a cheaper way to serve, or a simpler way to run something.
2. It is weighed against exactly two things — what it buys, and what it costs to operate.
3. The road that was taken ends at what was built, and beside it the ceiling that was accepted: the shortcut is named in a `ponytail:` comment in the code, with the upgrade path next to it.
4. The road not taken ends at a reason and a trigger. Nothing travels it, because nothing was built there.
5. When a trigger fires, the idea is reconsidered from the same fork — with the reason the last decision was made still on the table.

## The Java batcher

The design this project started from — a video walkthrough of a batch inference service — put a batcher in
front of the model: collect requests into a snapshot list, flush at 100 items or 40 ms, zip the results back
to their callers by index, and keep three Redis queues so the tiers get served in order.

The batcher was not built, and neither were its three queues. What it would have bought is request-level
control over batching: one place that decides when a batch is full, which is exactly what a model server that
does **not** batch needs. What it would have cost is the 40 ms window itself. LLM answers vary from a few
tokens to thousands, so a static, request-level batch keeps every caller waiting for the longest answer in
it, while the slots of the requests that finished sit idle. vLLM already re-forms its batch at every
generated token — [continuous batching](../inference/batching.md), also called iteration-level scheduling —
so a request leaves the moment it is done and a new one joins at the next step, about 24 ms here, with its
prefill chunked into the same steps. A Java window on top of that would add its own latency and buy nothing.

Two of the video's ideas survive in a different shape, which is the useful part of the story:

- **Priority.** vLLM's `--scheduling-policy priority` orders its own waiting queue, driven by the tier
  priority inference-service sends (enterprise 0, standard 10, trial 20, batch 30). A client-sent priority is
  overwritten.
- **Reserved capacity.** Priority alone does not protect enterprise, because a waiting request cannot evict a
  running one. The tiers are protected at admission instead: per-tier in-flight caps, trial `C/2`, standard
  `0.85·C`, enterprise `C+q`, and the engine's own `--max-num-queued-reqs` as a backstop.

The other ideas from the video were kept as they were: shed the lowest tier first with a 429 at the edge, one
retry and then a clean 503, no database on the hot path, and an asynchronous batch product at a discount.

**Trigger.** An engine that does not batch by itself — a bare embedding model, whose server returns one
result per call with no scheduling at all. That is the case the video's batcher was designed for, and it is
why this is a postponed design rather than a mistake.

## The rest of the list

| Not built | What it would have bought | What it would have cost | What brings it back |
|---|---|---|---|
| Kafka, an outbox and Spring Modulith, before a second consumer | Replay, several independent consumers, ordering guarantees, and one broker instead of a stream plus a relay | A broker to run and pin, Modulith in every service with a database, and a system to operate for a single consumer that the [Valkey stream and its relay](../services/metering.md) already serve. The review priced the later move at one to two days | An event gets a second consumer |
| An erasure saga driven by events, instead of a pull sweep | At-least-once delivery of "this organization closed" to every service that holds its data, with no polling | A broker, an outbox table, a saga to debug, and a new library repository. The sweep that was built instead asks organization-service for each organization's status every minute (5 s in compose), erases only an explicit `closed`, and heals itself after any failure — see [Tenancy](../data/tenancy.md) | A second consumer of "organization closed", or a second step in the saga |
| Separate database roles, instead of triggers on the ledger | Real privilege separation: an application role with INSERT and SELECT only, so a bug cannot rewrite history | Two roles to create and keep in sync in every environment that has a single database user today. The trigger refuses UPDATE, DELETE and TRUNCATE with no grant management at all | A shared database, or a production environment with duties actually split |
| Object storage for batch files, instead of Postgres `bytea` | OpenAI's 200 MB upload limit, and blobs out of the database | A second store with its own credentials, lifecycle rules and backup story — all of which wait on the hosting decision. The uploaded file is capped by the gateway's 4 MB `/v1` body limit; [Schemas](../data/schemas.md) has where it lives now | A customer file above 4 MB, or hosting being decided |
| The video's three Redis tier queues | A queue we control, with the tiers' progress visible from the edge | A second scheduler whose opinion can disagree with the engine's. vLLM prioritises its own waiting queue, and a waiting request cannot preempt a running one anyway | An engine that cannot prioritise, or several replicas that need one shared queue |
| Gatling or k6 as the load tool | A familiar harness with scenarios, thresholds and reports | Neither can see time to first token: Gatling's SSE timer stops at HTTP 200 and k6 needs an extension — and TTFT is the number the whole SLO rests on. The bench uses curl workers instead, and `vllm bench serve` for the engine alone. [Observability](../operations/observability.md) explains why TTFT is the number that matters | A load tool whose server-sent-event timing is trustworthy |
| `vllm bench serve` against the running compose stack | The engine's own tool, with goodput measurement built in, driven through the gateway | A second Python and torch process on the same VM: two of them ran the 7.6 GB Docker VM out of memory, hung WSL and got vLLM OOM-killed. It is used against the engine before the stack starts, and never beside it | A machine with memory to spare |
| Publishing the shared libraries to GitHub Packages | Versioned artifacts, instead of `mvn install` from the aggregator | Cross-repository reads need a classic token, and a published `1.0.0` cannot be republished, so every mistake becomes a version bump | An outside consumer of one of the libraries |
| A pepper on the API-key hash, and bcrypt on the key itself | Defence against an attacker who already reads the database, and slowness against guessing | A pepper cannot be rotated without reissuing every key the customer holds, and a 256-bit random secret cannot be guessed at any speed | A stored-secret compromise that a plain SHA-256 would not have survived |
| A token-family table for refresh-token reuse | Family-level revocation, and a record of how far a stolen cookie reached | Another table and another state machine for a signal that one row per login already gives: a known session id with the wrong hash ends every copy of it | Several devices per session, or per-device revocation |
| A `flex` mode of its own in the usage schema | A flex price and a flex report, separate from the Batch API | New CHECK constraints, new price rows and a migration for a lane that is priced exactly like batch | Flex needs a price or a report apart from batch |
| Per-window pricing in the customer usage summary | Exact agreement, window by window, between the summary a customer reads and the charge in the ledger | Thousands of priced rows per model per month. The ceiling of the per-day version: a price that changes inside a day misprices that day's earlier tokens, by under 1 micro-BRL per window, while the ledger charge itself stays exact | A price history that needs bounding, or a customer who notices |
| `last_used_at` written on the request path | A customer knowing which key is safe to delete | A database write on every request, on the one path where no database is allowed at all | A throttled writer fed by usage events, which needs no new data: `UsageEvent` already carries `api_key_id` |
| A Redis key holding each model's capacity zone | One shared view of how full a model is, readable from outside the JVM | A cache write per request for a number that is only logged; the zone is derived in memory from the in-flight count instead, and never stored | Several replicas that need to agree on a zone |
| `--reasoning-budget 0` to silence Qwen3's thinking | Answers with no reasoning tokens in them, from a flag | Nothing — it simply does not work in this llama.cpp build. Thinking is turned off with `--chat-template-kwargs '{"enable_thinking":false}'` instead | An engine build where the flag does what it says |

## The free GPU, option by option

The plan assumed a free or near-free GPU until the user decided the laptop's own card was enough. The
comparison is kept here because it is the question that comes back the moment the laptop GPU is not enough,
and because "free" turned out to be a terms-of-service question more often than a price one.

| Option | What it offered | Why it was rejected | What would bring it back |
|---|---|---|---|
| Colab | A free T4 in a notebook, immediately | Colab's FAQ bans web services and proxies on every runtime, so serving through a tunnel puts the account at risk | A provider whose terms allow serving |
| Kaggle | Two T4s for a limited session | Kaggle's rules ban "server farming", which leaves private serving a grey area | Written permission, or a paid tier |
| Modal | US$30 a month of credit, T4 and L4, vLLM serving documented, a fixed HTTPS URL, proxy auth | Useful credits need a card on file; logs, images and volumes stay in the US; proxy auth is the only guard on `/pause` and `/update_weights`, which vLLM's own key does not cover | The laptop GPU stops being enough, and a paid plan with a DPA is in place |
| Lightning AI | About 80 interruptible GPU-hours a month, publishes a port | The free tier needs written consent for commercial use | A paid plan |
| Hugging Face ZeroGPU, Studio Lab, GCP trial | Free or cheap compute with a notebook | None of them can run our own server | An option that can |
| A P100 anywhere | A cheap, widely available card | vLLM needs compute capability 7.5 or above | A newer card |

The laptop won, and it still runs the prototype: an RTX 3050 6 GB with the desktop sharing it, synthetic data
only, `cmn_test_` keys, nothing reachable beyond `localhost` — [Running it locally](../operations/running.md)
is the whole environment. Before real customer data reaches **any** GPU,
the checklist is the same whichever option is chosen: a paid plan with the provider, the provider's DPA as a
sub-operator named in ours, ANPD standard contractual clauses if the GPU is abroad, the canary check passing
on that provider including its log store, and a signed customer DPA and acceptable-use policy.

## Why it is like this

- **The cost of a mechanism is what it takes to operate it, not what it takes to write it.** Kafka, an
  outbox and a saga are each about a day of writing and an ongoing tax of running, and the review's estimate
  for adding Kafka later was one to two days. Deferring is cheap; carrying is not.
- **A "later" without a trigger is a "never".** Every row above ends with something observable, so a future
  engineer can tell whether the world has changed without re-reading the whole plan.
- **Nothing here was rejected for being hard.** The Java batcher was rejected because it would have added
  latency and bought nothing. The free GPUs were rejected over terms and jurisdiction, not money. The
  database roles were rejected because they cost more to keep in sync than the trigger they would replace.
- **Two of these were one decision away from being built.** The batcher was the starting design, and the plan
  assumed a free cloud GPU for weeks. Both are harmless only because the reason and the trigger were written
  down at the moment of the decision.

## What would change it

The triggers, collected: a second consumer for an event (Kafka, and the erasure saga with it); a shared
database (separate roles); a file above 4 MB or a hosting decision (object storage); an engine that does not
batch by itself (the batcher, and with it the index demultiplexing the video designed); an engine that cannot
prioritise, or a second replica (a shared queue and a shared capacity view); several devices per session
(token families); a flex price (a flex mode); a customer who notices a mid-day price change (per-window
pricing); an outside consumer of a library (a package registry).

A rejection is revisited when its trigger fires, not when somebody finds the note again.

## Where to look

- [inference-plan.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/inference-plan.md) — the "Phase N built" blocks at the top of the file are the deviation log this page is built from.
- [plan-review-2026-10-02.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/plan-review-2026-10-02.md) — the free-GPU ranking and the transport decision, with the sources they were read from.
- [templates.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-new-service/references/templates.md) — "Pitfalls already hit": the failures that decided several entries above.
- [V1RequestFilter.java](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/V1RequestFilter.java) — the 4 MB body cap that makes object storage a future need rather than a preference.
- [docker/bench.sh](https://github.com/carmonai/back/blob/main/docker/bench.sh) — the check that replaced the load tools that could not see TTFT.
