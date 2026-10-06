# Capacity and fairness

Where the limits live, what they are made of, and what is honestly not covered by them.

## What it is

Capacity in this platform is one number per model — how many requests the engine runs at once — plus a
ceiling per tier on how full the model may be for that tier's traffic, plus a per-organization cap. The
first is measured from a bench; the other two are configuration. Everything else in this section is a
consequence of those three.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="cap-title" aria-describedby="cap-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="cap-title">Model occupancy over time and the tier that is refused by it</title>
  <desc id="cap-desc">Seven moments in the life of the GPU model, with the number of requests in flight at
  each drawn as a bar. Three dashed lines mark the ceilings: six for enterprise, three for standard and two
  for trial. A trial request is refused whenever two or more requests are in flight, a standard request
  whenever three or more are, and an enterprise request only when the model is completely full; the band
  below the chart marks which tiers are refused at each moment.</desc>

  <defs>
    <marker id="cap-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Lines first: the three ceilings the bars are read against. -->
  <g id="cap-ceilings">
    <path id="cap-cap6" class="cmn-link cmn-dash" d="M160 36 H700"/>
    <path id="cap-cap3" class="cmn-link cmn-dash" d="M160 138 H700"/>
    <path id="cap-cap2" class="cmn-link cmn-dash" d="M160 172 H700"/>
  </g>

  <!-- Then the seven moments, left to right, and the refusals they cause. -->
  <g id="cap-bars">
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 0;" id="cap-c1" aria-labelledby="cap-c1-label">
      <rect x="170" y="172" width="48" height="68" rx="10"/>
      <text id="cap-c1-label" x="194" y="206">2</text>
    </g>
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 1;" id="cap-c2" aria-labelledby="cap-c2-label">
      <rect x="246" y="138" width="48" height="102" rx="10"/>
      <text id="cap-c2-label" x="270" y="189">3</text>
    </g>
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 2;" id="cap-c3" aria-labelledby="cap-c3-label">
      <rect x="322" y="104" width="48" height="136" rx="10"/>
      <text id="cap-c3-label" x="346" y="172">4</text>
    </g>
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 3;" id="cap-c4" aria-labelledby="cap-c4-label">
      <rect x="398" y="36" width="48" height="204" rx="10"/>
      <text id="cap-c4-label" x="422" y="138">6</text>
    </g>
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 4;" id="cap-c5" aria-labelledby="cap-c5-label">
      <rect x="474" y="70" width="48" height="170" rx="10"/>
      <text id="cap-c5-label" x="498" y="155">5</text>
    </g>
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 5;" id="cap-c6" aria-labelledby="cap-c6-label">
      <rect x="550" y="36" width="48" height="204" rx="10"/>
      <text id="cap-c6-label" x="574" y="138">6</text>
    </g>
    <g class="cmn-node cmn-node--flow cmn-step" style="--i: 6;" id="cap-c7" aria-labelledby="cap-c7-label">
      <rect x="626" y="36" width="48" height="204" rx="10"/>
      <text id="cap-c7-label" x="650" y="138">6</text>
    </g>
  </g>

  <path id="cap-axis" class="cmn-link" d="M160 240 H700" marker-end="url(#cap-arrow)"/>

  <g class="cmn-node cmn-node--danger" id="cap-refused" aria-labelledby="cap-refused-label">
    <rect x="160" y="250" width="540" height="22" rx="10"/>
    <text id="cap-refused-label" x="194" y="261">T</text>
    <text x="270" y="261">T S</text>
    <text x="346" y="261">T S</text>
    <text x="422" y="261">T S E</text>
    <text x="498" y="261">T S</text>
    <text x="574" y="261">T S E</text>
    <text x="650" y="261">T S E</text>
  </g>

  <!-- One clock crossing the whole chart: time is the axis, not the distance. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M160 240 H700'); --cmn-travel: 2.6s; --cmn-delay: 0s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <text class="cmn-label" x="80" y="36">cap 6 · enterprise</text>
  <text class="cmn-label" x="80" y="138">cap 3 · standard</text>
  <text class="cmn-label" x="80" y="172">cap 2 · trial</text>
  <rect class="cmn-label-plate" x="88" y="222" width="44" height="16" rx="4"/>
  <text class="cmn-label" x="110" y="234">time</text>
  <rect class="cmn-label-plate" x="20" y="253" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="80" y="265">refused here</text>
</svg>
</div>
<figcaption>Each bar is the number of requests in flight on the GPU model at one moment, and each dashed line
is the ceiling a tier is measured against: a request is admitted only while the model is below its tier's
line. The band under the chart marks the tiers refused at each moment — T for trial, S for standard, E for
enterprise — so trial is refused from the first bar on, standard from the second, and enterprise only while
the model is completely full.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the model's occupancy at one moment (solid outline)</span>
  <span><i></i> a tier's ceiling (neutral, dashed)</span>
  <span><i class="is-async"></i> a refusal (danger band, letters in the caption)</span>
</div>

1. **The first bar is the model running two requests.** That is exactly the trial ceiling, so a trial request
   arriving now is refused with 429 `model_busy`.
2. **At three in flight, standard reaches its own ceiling**, and is refused the same way. Enterprise is still
   below six and gets in.
3. **At four, the engine is at `--max-num-seqs`.** The four are generating; a fifth admitted request waits
   inside the engine rather than in our code.
4. **At six the model is completely full**: `slots + queue`. This is the only level at which enterprise is
   refused.
5. **Trial is refused at every moment on this chart.** That is not an accident of the example: with a ceiling
   of `C/2` = 2, trial is only ever admitted while the model is nearly idle.
6. **A refusal is immediate for the tiers that do not pay.** Trial, flex and batch get their 429 in 9–16 ms at
   p95; standard and enterprise may wait 1.5 s for a slot first.

## The numbers, and where they came from

| Concurrency | Output tok/s | TTFT p95 | Goodput |
|---|---|---|---|
| 1 | 46 | 254 ms | 100% |
| 2 | 88 | 314 ms | 100% |
| 4 | 157 | 801 ms | 100% |
| 8 | 159 | 4,033 ms | 10% |

Measured with `vllm bench serve` against the RTX 3050 6 GB, one model, through the gateway. The reading is
blunt: throughput stops improving between four and eight, and everything the eighth request adds is waiting.
So `C = 4` — the highest concurrency that still holds goodput at 100% — and `q = 2`, a queue just deep enough
to absorb the gap between two steps without letting the wait run away. Both are written into
`application-gpu.yaml` as `slots: 4` and `queue: 2`, and the enterprise ceiling is `C + q = 6`.

With three tiers running at once, the exit check came out at enterprise goodput 98%, TTFT p95 253–351 ms,
TPOT p95 22 ms, and trial refused in 9–16 ms at p95.

## Why it is like this

**The tier ceiling is a threshold on the whole model, not a reserved block.** `tierCap(model, tier)` is
compared against the model's total in-flight count, so "trial 0.5·C" means *trial may enter while the model is
below half of C* — not *trial owns half the slots*. The effect is the one that matters: enterprise always has
somewhere to go, because everything below it stops being admitted before enterprise does. The cost is that
trial traffic is served only in the model's quiet moments, which is exactly what a trial tier is for.

**`C` is a measurement, not a decision.** It is the highest concurrency that kept goodput at 100% on this GPU,
and the comment in `application-gpu.yaml` says so. Reading it off a spec sheet — "6 GB, so six requests" —
would have produced a number that makes the eighth request wait four seconds for a token.

**`q` is headroom, not a queue we run.** `queue: 2` is never something the service sends to the engine by
itself: it is added to `C` to make the enterprise ceiling of six, and it is part of the slack the reconciler
allows when it compares token counts. The waiting it permits happens inside the engine, whose own queue
(`--max-num-queued-reqs 8`) is deeper than the service's number. A deeper service ceiling would only move the
wait into a place the client cannot see.

**The enterprise ceiling deliberately exceeds `C`.** Six against `--max-num-seqs 4` means an enterprise
request can be admitted into the engine's own queue, where it waits a step or two rather than getting a 429.
That is the trade enterprise is paid for: a little waiting instead of a refusal.

**The per-organization cap is the second line, and today it never fires.** `max-in-flight` is 2, 4 and 16 for
the three tiers, and the tier ceiling is checked first: for `carmonai/qwen3-4b` the ceilings are 2, 3 and 6.
Since every organization cap is at or above its tier's ceiling, no organization can reach its own cap while
the tier ceiling is doing the work. It is a limit waiting for a bigger engine, and it is worth saying so
rather than implying it is load-bearing.

**Flex is a lane, not a tier.** `service_tier: "flex"` takes the same ceiling as a batch line — half the model
— keeps the organization's own rate buckets, and runs at priority 30 behind every interactive tier. It is
priced at half the sync rate and refused with `resource_unavailable` when there is no spare capacity. The
deal is explicit: cheap, and first to be shed.

**A refusal is cheap and it says when to come back.** All three refusals — buckets, tier ceiling,
organization cap — carry `retry-after` in whole seconds and `retry-after-ms` with the exact figure, so an SDK
that honours the millisecond header does not back off by a second for a wait of 40 ms.

## What would change it

- **The in-flight counters are one JVM's memory.** A second replica of inference-service would double every
  ceiling on this page, because each replica would count only its own requests. Shared counters come before
  a second replica, not with it.
- **The engine's queue is looser than the service's `q`.** `compose.gpu.yaml` starts vLLM with
  `--max-num-queued-reqs 8` while `application-gpu.yaml` declares `queue: 2`. The service's ceiling is the one
  that binds, so nothing is wrong today — but they are two numbers describing one queue and they should
  agree.
- **Every number here comes from a laptop's consumer GPU.** They size the prototype's caps and prove the
  pipeline. A production `C` has to be re-measured on the hardware that will serve customers.
- **The virtual token counter is in-process.** It orders waiters within one replica; across replicas the
  equivalent is DRR or flow control in a router, which does not exist here.
- **`metrics` reports the ceiling per tier** as `carmonai_inference_capacity`, so a dashboard can show how
  close each tier is to its line — but only for the replica that served the request.

## Where to look

- [`Admission.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java)
  — `tierCap`, the two in-flight checks and the order they run in.
- [`application-gpu.yaml`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/application-gpu.yaml)
  — `slots: 4`, `queue: 2`, and the bench they came from.
- [`compose.gpu.yaml`](https://github.com/carmonai/back/blob/main/docker/compose.gpu.yaml)
  — the engine's side of the same limit: `--max-num-seqs`, `--max-num-queued-reqs`, `--kv-cache-dtype fp8`.
- [`application.yaml`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/application.yaml)
  — the three tiers' per-minute budgets and `max-in-flight`, with the prototype note on them.
- [`Metrics.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Metrics.java)
  — the in-flight gauge and the capacity gauge a dashboard reads.

**Back to:** [Batching and response routing](batching.md) for why one model serves four requests at once at
all, and [Routing responses](routing.md) for what happens to a stream while it waits.
