# Batching and response routing

There is no batcher in this codebase, and its absence is a decision rather than a gap. This page is about why,
and about the one condition that would bring one back.

## What it is

Batching is the act of running several requests through the model in one forward pass. In this platform that
happens entirely inside the engine. inference-service sends one HTTP request per API call, forwards one
server-sent-event stream back per call, and never groups two callers' work together.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="bat-title" aria-describedby="bat-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="bat-title">Static batching against continuous batching, on the same clock</title>
  <desc id="bat-desc">Two engines receive the same four requests, A to D, with the same durations. In the
  static panel the four run as one batch that ends only when its longest member ends, so three slots sit idle
  from the moment their request finished until the batch is over and the next two requests start. In the
  continuous panel a request joins the batch in the step after a slot frees, so E starts when A ends, F when
  D ends and G when B ends, and no slot is ever idle.</desc>

  <defs>
    <marker id="bat-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the static panel, then the continuous one. Both share one clock. -->
  <g id="bat-static">
    <g class="cmn-node" id="bat-static-title" aria-labelledby="bat-static-title-label">
      <text id="bat-static-title-label" x="195" y="34">Static batching</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-s-a" aria-labelledby="bat-s-a-label">
      <rect x="40" y="48" width="70" height="24" rx="10"/>
      <text id="bat-s-a-label" x="75" y="60">A</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-s-b" aria-labelledby="bat-s-b-label">
      <rect x="40" y="78" width="110" height="24" rx="10"/>
      <text id="bat-s-b-label" x="95" y="90">B</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-s-c" aria-labelledby="bat-s-c-label">
      <rect x="40" y="108" width="180" height="24" rx="10"/>
      <text id="bat-s-c-label" x="130" y="120">C</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-s-d" aria-labelledby="bat-s-d-label">
      <rect x="40" y="138" width="90" height="24" rx="10"/>
      <text id="bat-s-d-label" x="85" y="150">D</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-s-e" aria-labelledby="bat-s-e-label">
      <rect x="220" y="48" width="90" height="24" rx="10"/>
      <text id="bat-s-e-label" x="265" y="60">E</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-s-f" aria-labelledby="bat-s-f-label">
      <rect x="220" y="78" width="130" height="24" rx="10"/>
      <text id="bat-s-f-label" x="285" y="90">F</text>
    </g>
    <path id="bat-s-idle1" class="cmn-link cmn-dash" d="M112 60 H218"/>
    <path id="bat-s-idle2" class="cmn-link cmn-dash" d="M152 90 H218"/>
    <path id="bat-s-idle3" class="cmn-link cmn-dash" d="M132 150 H218"/>
    <path id="bat-s-marker" class="cmn-link cmn-link--quiet" d="M220 40 V196"/>
    <path id="bat-s-axis" class="cmn-link" d="M40 204 H350" marker-end="url(#bat-arrow)"/>
  </g>

  <g id="bat-cont">
    <g class="cmn-node" id="bat-cont-title" aria-labelledby="bat-cont-title-label">
      <text id="bat-cont-title-label" x="565" y="34">Continuous batching</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-a" aria-labelledby="bat-c-a-label">
      <rect x="410" y="48" width="70" height="24" rx="10"/>
      <text id="bat-c-a-label" x="445" y="60">A</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-b" aria-labelledby="bat-c-b-label">
      <rect x="410" y="78" width="110" height="24" rx="10"/>
      <text id="bat-c-b-label" x="465" y="90">B</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-c" aria-labelledby="bat-c-c-label">
      <rect x="410" y="108" width="180" height="24" rx="10"/>
      <text id="bat-c-c-label" x="500" y="120">C</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-d" aria-labelledby="bat-c-d-label">
      <rect x="410" y="138" width="90" height="24" rx="10"/>
      <text id="bat-c-d-label" x="455" y="150">D</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-e" aria-labelledby="bat-c-e-label">
      <rect x="480" y="48" width="90" height="24" rx="10"/>
      <text id="bat-c-e-label" x="525" y="60">E</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-f" aria-labelledby="bat-c-f-label">
      <rect x="500" y="138" width="130" height="24" rx="10"/>
      <text id="bat-c-f-label" x="565" y="150">F</text>
    </g>
    <g class="cmn-node cmn-node--flow" id="bat-c-g" aria-labelledby="bat-c-g-label">
      <rect x="520" y="78" width="80" height="24" rx="10"/>
      <text id="bat-c-g-label" x="560" y="90">G</text>
    </g>
    <path id="bat-c-marker" class="cmn-link cmn-link--quiet" d="M590 40 V196"/>
    <path id="bat-c-axis" class="cmn-link" d="M410 204 H720" marker-end="url(#bat-arrow)"/>
  </g>

  <!-- One clock per panel, running together; then what happens in the freed slot. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M40 204 H350'); --cmn-travel: 2.4s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M410 204 H720'); --cmn-travel: 2.4s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M112 60 H218'); --cmn-travel: 0.9s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M152 90 H218'); --cmn-travel: 0.7s; --cmn-delay: 1.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M132 150 H218'); --cmn-travel: 0.8s; --cmn-delay: 1s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5"
          style="offset-path: path('M480 60 H570'); --cmn-travel: 0.7s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5"
          style="offset-path: path('M500 150 H630'); --cmn-travel: 1s; --cmn-delay: 1s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5"
          style="offset-path: path('M520 90 H600'); --cmn-travel: 0.6s; --cmn-delay: 1.2s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="112" y="44" width="70" height="16" rx="4"/>
  <text class="cmn-label" x="147" y="56">slot idle</text>
  <rect class="cmn-label-plate" x="120" y="214" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="195" y="226">waits for the longest</text>
  <rect class="cmn-label-plate" x="490" y="214" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="565" y="226">refilled every step</text>
</svg>
</div>
<figcaption>Both panels receive the same four requests with the same durations, and both clocks run at the same
rate. On the left the batch ends when C ends, so A, B and D leave their slots idle until then and E and F can
only start at that moment. On the right E joins as A finishes, F as D finishes and G as B finishes: the same
four requests, three more served in the window, no slot empty.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request occupying a slot</span>
  <span><i class="is-accent"></i> a request that took a freed slot (dashed)</span>
  <span><i class="is-async"></i> the instant the first batch ends (dotted)</span>
  <span><i></i> a slot sitting idle (neutral, dashed)</span>
</div>

1. **Four requests arrive at once**: A, B, C and D. They are the same four in both panels.
2. **In the static panel they run as one batch**, and the batch is not finished until its longest member is —
   C. A, B and D hold slots they are no longer using.
3. **The dotted line is the same instant in both panels**: the end of C.
4. **In the static panel, that instant is the only one at which E and F may start.** Everything they could
   have done in the meantime was spent waiting for C.
5. **In the continuous panel the batch is rebuilt at every step.** A finishes and E takes the slot in the next
   step; D finishes and F takes its slot; B finishes and G takes its.
6. **Nothing waits for a peer.** A request's latency depends on its own tokens and on how full the engine is,
   never on another caller's answer being long.
7. **Same four requests, same durations, seven served in the window** on the right against six on the left —
   and the difference is entirely in the idle stretches the left panel draws.

## Why it is like this

**The 40 ms window is a delay we do not have to pay.** The design this project started from — a Java batcher
that waits for 100 requests or 40 ms after the first, then calls the GPU — is what a model server that
processes one batch at a time needs. It buys a bigger batch at the cost of adding that window's worst case to
every request's latency, including the ones that arrive alone at 3 a.m. and wait the full 40 ms for company
that never comes.

**Continuous batching is strictly better, and it is the engine's to do.** A transformer generates one token
per sequence per forward pass, so the natural moment to change the batch is the step boundary. vLLM does
exactly that: finished sequences leave, queued ones join, the KV cache decides who fits. Measured against
static batching, the literature and the bench agree it is worth 2–4× the throughput — for the same GPU, with
no delay added to anyone.

**A Java batcher would have to re-implement the KV cache to be correct.** What fits in a step is not "four
requests", it is "four requests whose KV blocks are resident". A batcher in front of the engine cannot see the
cache, so it would be choosing a batch with the one piece of information that decides the batch missing. The
engine's scheduler has it.

**Two hops would also mean two queues.** A batcher implies a queue in front of the batcher, which implies its
own admission decision, its own timeout and its own way to lose a request. Today the only thing that holds a
request is the engine's own queue, and the only other place one can stop is admission's bounded wait — which
ends in a 429 rather than in a buffer.

**The measurements are the argument.** On the RTX 3050, four concurrent requests produce 157 output tok/s with
TTFT p95 at 801 ms; eight produce 159 tok/s with TTFT p95 at 4,033 ms. The engine is already saturated at
four, so the only thing a bigger batch would add is queueing — and queueing is what a batcher exists to
create.

## The one case where a Java batcher would be needed

A model server that processes **one input per call and cannot batch**: a plain `transformers` loop behind a
Flask route, an embedding server that takes a single string, a model served by a runtime with no scheduler.
Against a server like that, a Java batcher that collects requests into one call is the only way to use the
GPU at all, and the 40 ms window becomes a real trade rather than a pure cost.

There is no such server in this stack. `llama.cpp` serves `-np 2` slots and works across them, and vLLM's
whole reason for being is the scheduler. The CPU engine is the dev-and-CI path — it ignores `priority` and
`cache_salt` and reports usage only at the end of a stream — and the GPU one is where the numbers come from.

## What would change it

- **A non-batching model server** brings the batcher back, and with it the fill window, the demux by position
  and the queue in front of it. The decision above is a decision about *these* engines, and it has to be
  revisited rather than quietly inherited when a new model arrives.
- **A long-context model** would make `--max-num-seqs` the wrong knob entirely: what fits would be decided by
  the KV cache, and a batch of four could become a batch of one.
- **More than one GPU** moves the interesting question from batching to routing, which lives on
  [Routing responses](routing.md).
- **A second consumer of the same GPU** — a batch job beside interactive traffic — is a scheduling problem
  the engine's priority policy only partly solves, and it is why batch lines take the smallest share.

## Where to look

- [`Engine.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Engine.java)
  — one API call, one SSE stream: no grouping anywhere.
- [`ChatRequest.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatRequest.java)
  — `priority` from the tier and `cache_salt` from the organization: the only two hints the engine gets.
- [`application-gpu.yaml`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/application-gpu.yaml)
  — `slots: 4` and `queue: 2`, and the bench comment behind them.
- [`compose.gpu.yaml`](https://github.com/carmonai/back/blob/main/docker/compose.gpu.yaml)
  — the engine's own flags: `--max-num-seqs`, `--max-num-queued-reqs`, `--scheduling-policy priority`,
  `--kv-cache-dtype fp8`.
- [`Admission.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java)
  — the only queue we own, and it refuses rather than buffers.

**Next:** [Routing responses](routing.md) picks up the stream this page left running, and
[Capacity and fairness](capacity.md) explains how many of them can run at once.
