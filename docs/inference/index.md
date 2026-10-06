# Inference

How a token gets made here: two engines behind one service, with no batcher, nothing of ours holding a
request in front of the model, and no database anywhere on the path.

## What it is

inference-service is the only client of the model engines. It checks the request, admits it, relays the
engine's stream, and meters what came out — but it never runs a model, never decides how many requests the
GPU works on at once, and never assembles a batch. That decision belongs to the engine, and it is remade at
every token.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="inf-title" aria-describedby="inf-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="inf-title">Where batching happens: in the engine, not in Java</title>
  <desc id="inf-desc">A client's request reaches inference-service, which admits it and forwards it to the
  engine. The engine rebuilds its batch at every step, roughly every 22 to 24 milliseconds here, and streams
  the tokens back through inference-service to the client that asked. inference-service holds no batch and no
  queue of its own: the running set of requests lives in the engine.</desc>

  <defs>
    <marker id="inf-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the request in, the step loop, then the stream home. -->
  <g id="inf-hops">
    <path id="inf-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M136 140 H180"
          marker-end="url(#inf-arrow)"/>
    <path id="inf-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M330 140 H380"
          marker-end="url(#inf-arrow)"/>
    <path id="inf-stream" class="cmn-link cmn-link--accent cmn-dash" d="M455 110 V80 H76 V110"
          marker-end="url(#inf-arrow)"/>
    <path id="inf-step-down" class="cmn-link cmn-link--flow cmn-dash" d="M420 170 V200"
          marker-end="url(#inf-arrow)"/>
    <path id="inf-step-up" class="cmn-link cmn-link--flow cmn-dash" d="M490 200 V170"
          marker-end="url(#inf-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="inf-client" aria-labelledby="inf-client-label">
    <rect x="16" y="110" width="120" height="60" rx="10"/>
    <text id="inf-client-label" x="76" y="130">Client</text>
    <text class="cmn-sub" x="76" y="148">one open stream</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="inf-inference" aria-labelledby="inf-inference-label">
    <rect x="180" y="110" width="150" height="60" rx="10"/>
    <text id="inf-inference-label" x="255" y="130">Inference</text>
    <text class="cmn-sub" x="255" y="148">admit, relay, meter</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="inf-engine" aria-labelledby="inf-engine-label">
    <rect x="380" y="110" width="150" height="60" rx="10"/>
    <text id="inf-engine-label" x="455" y="130">Engine</text>
    <text class="cmn-sub" x="455" y="148">owns the batch</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="inf-stepbox" aria-labelledby="inf-stepbox-label">
    <rect x="380" y="200" width="150" height="48" rx="10"/>
    <text id="inf-stepbox-label" x="455" y="220">One step</text>
    <text class="cmn-sub" x="455" y="238">≈ 24 ms, rebuilt</text>
  </g>

  <!-- Packets: the request in, then the tokens home, then the step loop. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M136 140 H180'); --cmn-travel: 0.5s; --cmn-delay: 0.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M330 140 H380'); --cmn-travel: 0.5s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M455 110 V80 H76 V110'); --cmn-travel: 1.2s; --cmn-delay: 1.2s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M455 110 V80 H76 V110'); --cmn-travel: 1.2s; --cmn-delay: 1.45s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M455 110 V80 H76 V110'); --cmn-travel: 1.2s; --cmn-delay: 1.7s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M420 170 V200'); --cmn-travel: 0.4s; --cmn-delay: 1.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M490 200 V170'); --cmn-travel: 0.4s; --cmn-delay: 1.9s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="200" y="62" width="200" height="16" rx="4"/>
  <text class="cmn-label" x="300" y="74">tokens, as they are generated</text>
  <rect class="cmn-label-plate" x="138" y="98" width="40" height="16" rx="4"/>
  <text class="cmn-label" x="158" y="110">prompt</text>
  <rect class="cmn-label-plate" x="385" y="252" width="140" height="16" rx="4"/>
  <text class="cmn-label" x="455" y="264">the batch changes</text>
</svg>
</div>
<figcaption>The request goes in as one HTTP stream and comes back as tokens on the same connection. The loop
under the engine is the whole point of this section: the engine processes a step, emits one token per request
it is running, and rebuilds the batch for the next step. inference-service is a relay in that picture, not a
queue.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> a response coming back (dashed)</span>
</div>

1. **A request arrives as an open stream.** It is not a job handed to a worker; it stays an HTTP response that
   is written to for as long as the answer takes.
2. **inference-service admits it** against the rate buckets and the in-flight caps, and forwards the body it
   built to the engine. It holds no batch of its own.
3. **The engine owns the running set.** vLLM starts with `--max-num-seqs 4` and `--max-num-queued-reqs 8`, so
   at most four requests are generating at once and anything past that waits inside the engine, not with us.
4. **Every step, the engine rebuilds its batch.** It finishes the requests that are done, admits whichever
   queued requests fit in the KV cache, runs one forward pass, and emits one token per running request.
5. **A step takes about as long as a token.** TPOT p95 measured 24 ms on the RTX 3050, so a stream producing
   tokens at 46 tok/s at one request is doing one step every ~22 ms.
6. **Each token goes back down the same connection**, through the relay, to the client that asked for it —
   four requests being served at once produce four interleaved streams, not one batch result.

## The three pages here

<div class="grid cards" markdown>

-   **Why there is no batcher in Java**

    ---

    [Batching and response routing](batching.md) sets static batching side by side with the iteration-level
    batching the engine actually does, and names the one case where a Java batcher would be needed.

-   **How responses find their way back**

    ---

    [Routing responses](routing.md) follows one engine stream back to the one client waiting for it, and the
    retry that is only allowed before the first byte.

-   **Where the limits live**

    ---

    [Capacity and fairness](capacity.md) explains C and q, the tier shares, the per-organization cap and the
    honest ceiling on all of them.

</div>

## The model of how inference works here

**The engine batches; we admit.** That split is the whole design. Batching is a property of the model server
— it needs the KV cache, the GPU and the scheduler — and an HTTP service in Java has none of those. What a
Java service can do better than an engine is decide *who* gets in, and that is what inference-service does.

**The unit of capacity is the token, not the request.** A request that asks for 20 tokens and one that asks
for 1,024 occupy the same slot in the running set but cost wildly different amounts of GPU time. So the limits
are in tokens per minute, the reservation is in `max_tokens`, and the metrics are TTFT and the gap between
tokens rather than requests per second.

**The engine's queue is short and the refusal is early.** `--max-num-queued-reqs` is 8 while `maxInFlight` for
enterprise alone is 16, so most of the queueing that can happen, happens in our admission, where the client
gets a 429 with a retry delay. What reaches the engine is already bounded, which is why TTFT p95 stayed at
253–351 ms with three tiers running at once.

**The engine is told two things about a request and nothing else.** `priority` from the tier (enterprise 0,
standard 10, trial 20, batch and flex 30 — vLLM runs lower values first) and `cache_salt` set to the
organization id. The second one is not a performance knob: without it, one tenant could measure how warm
another tenant's prefix cache is by watching its own first-token latency.

**Usage comes from the engine, per step.** Every request asks the engine for `stream_options.include_usage`
and `continuous_usage_stats`, so the real prompt and completion token counts arrive on the stream that is
already open — no second call, no tokenizer in Java, and a total that matches what the engine itself counted.

**Nothing on the path touches a database.** Admission reads Valkey and memory; the relay writes to a socket;
usage goes to a Valkey stream and is delivered afterwards. That is what keeps a token's latency a function of
the GPU and not of a connection pool to Postgres.

## Why it is like this

**The rejected alternative is a hand-written batcher, and it was rejected on measurement, not taste.** The
design this project started from assembles a batch of up to 100 requests or waits 40 ms after the first one,
then runs the GPU once. That is correct for a model server that processes one batch at a time. vLLM, SGLang
and TensorRT-LLM do not: they batch at every generated token, which is worth 2–4× the throughput of static
batching, and a Java batcher in front of them would add a 40 ms delay to every request and change nothing
about how the GPU works. See [Batching](batching.md).

**No Redis tier queues on the interactive path.** Three priority queues, one per tier, is the design that goes
with a hand-written batcher. Here the ordering already exists — vLLM's scheduler with the priority we set —
and a queue in front of it would only add a place for a request to wait that we cannot see into.

**Capacity in tokens per second, not requests per second.** A request is not a unit of work: prompt length
dominates the cost of the prefill, and `max_tokens` dominates the reservation. The measurements make the same
point from the other side — at 4 concurrent requests the engine produced 157 output tok/s with TTFT p95 at
801 ms; at 8 it produced 159 tok/s with TTFT p95 at 4,033 ms. The second request does not add throughput, it
adds waiting.

**`C` is where goodput stops being 100%, and it is measured, not chosen.** From the bench on the RTX 3050:
100% goodput at 1, 2 and 4 concurrent requests, 10% at 8. So `slots: 4` in `application-gpu.yaml`, with
`queue: 2` on top to absorb a burst without letting the wait run away.

## What would change it

- **A model server that does not batch** would need a batcher in Java. There is none in the stack today:
  both engines batch.
- **More than one GPU** changes the question from "which batch" to "which replica", and that routing does not
  exist yet: one engine endpoint per model in configuration.
- **A longer context window** would move the limit from `--max-num-seqs` to the KV cache, and `C` would have
  to be re-measured rather than re-derived.
- **The engine numbers here were measured on a laptop's consumer GPU**, so they size the prototype's caps and
  prove the pipeline; they are not prices and not a production SLO.

## Where to look

- [`InferenceApplication.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/InferenceApplication.java)
  — the whole surface: two routes.
- [`ChatHandler.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatHandler.java)
  — where a request becomes a stream and a stream becomes an event.
- [`Engine.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Engine.java)
  — the only caller of an engine, and its pool and timeouts.
- [`application-gpu.yaml`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/application-gpu.yaml)
  — `slots` and `queue` per model, with the measurement they came from.
- [`Metrics.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Metrics.java)
  — TTFT, ITL, queue wait and in-flight, tagged by model and tier and never by organization.
