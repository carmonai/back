# 4 · The relay

Step 4 of [the path of a request](index.md). [Admission](admission.md) left the request holding a permit for
a share of the engine, with its buckets charged and its slot reserved. Now it is a call to the engine, and
then a stream of server-sent events on its way back to a client that is still waiting.

## What it is

inference-service builds a fresh request from scratch, posts it to the model's engine, and forwards the
engine's server-sent events to the client one at a time, with a deadline on the first one and on the silence
between them. It retries once, and only while the client has not yet seen a byte.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="rly-title" aria-describedby="rly-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="rly-title">Relaying one engine stream to one client</title>
  <desc id="rly-desc">inference-service sends the rebuilt request through its own connection pool to the
  engine. A connect error or an engine 5xx before the first byte is retried once; a full pool is a 503 at
  once. The engine's server-sent events come back one at a time to the client, with thirty seconds allowed
  for the first token, thirty between tokens, and six hundred for a whole non-streamed answer.</desc>

  <defs>
    <marker id="rly-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the call out, the retry, the stream back, then the pool's refusal. -->
  <g id="rly-hops">
    <path id="rly-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M140 72 H180"
          marker-end="url(#rly-arrow)"/>
    <path id="rly-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M304 72 H344"
          marker-end="url(#rly-arrow)"/>
    <path id="rly-retry" class="cmn-link cmn-link--quiet" d="M242 44 V34 H406 V44"
          marker-end="url(#rly-arrow)"/>
    <path id="rly-stream" class="cmn-link cmn-link--accent cmn-dash" d="M440 100 V170 H140"
          marker-end="url(#rly-arrow)"/>
    <path id="rly-busy" class="cmn-link" d="M242 100 V112" marker-end="url(#rly-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="rly-inference" aria-labelledby="rly-inference-label">
    <rect x="16" y="44" width="124" height="56" rx="10"/>
    <text id="rly-inference-label" x="78" y="64">Inference</text>
    <text class="cmn-sub" x="78" y="82">ChatHandler</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="rly-pool" aria-labelledby="rly-pool-label">
    <rect x="180" y="44" width="124" height="56" rx="10"/>
    <text id="rly-pool-label" x="242" y="64">Connection pool</text>
    <text class="cmn-sub" x="242" y="82">64, idle 4 s</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="rly-engine" aria-labelledby="rly-engine-label">
    <rect x="344" y="44" width="124" height="56" rx="10"/>
    <text id="rly-engine-label" x="406" y="64">Engine</text>
    <text class="cmn-sub" x="406" y="82">one SSE stream</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="rly-full" aria-labelledby="rly-full-label">
    <rect x="160" y="112" width="152" height="44" rx="10"/>
    <text id="rly-full-label" x="236" y="130">503 pool full</text>
    <text class="cmn-sub" x="236" y="146">no queueing</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="rly-client" aria-labelledby="rly-client-label">
    <rect x="16" y="142" width="124" height="56" rx="10"/>
    <text id="rly-client-label" x="78" y="162">Client</text>
    <text class="cmn-sub" x="78" y="180">one frame at a time</text>
  </g>

  <!-- The three deadlines, as a time axis rather than a distance. -->
  <path id="rly-axis" class="cmn-link" d="M40 232 H744" marker-end="url(#rly-arrow)"/>
  <path class="cmn-link" d="M180 224 V240"/>
  <path class="cmn-link" d="M420 224 V240"/>
  <path class="cmn-link" d="M680 224 V240"/>

  <!-- Packets: the call out, the retry behind it, then the tokens home. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M140 72 H180'); --cmn-travel: 0.5s; --cmn-delay: 0.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M304 72 H344'); --cmn-travel: 0.5s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M242 44 V34 H406 V44'); --cmn-travel: 1s; --cmn-delay: 1.4s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M440 100 V170 H140'); --cmn-travel: 1.1s; --cmn-delay: 1s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M440 100 V170 H140'); --cmn-travel: 1.1s; --cmn-delay: 1.25s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M440 100 V170 H140'); --cmn-travel: 1.1s; --cmn-delay: 1.5s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M440 100 V170 H140'); --cmn-travel: 1.1s; --cmn-delay: 1.75s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M242 100 V112'); --cmn-travel: 0.4s; --cmn-delay: 2.4s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="238" y="6" width="176" height="16" rx="4"/>
  <text class="cmn-label" x="326" y="18">one retry, before byte 1</text>
  <rect class="cmn-label-plate" x="180" y="176" width="170" height="16" rx="4"/>
  <text class="cmn-label" x="265" y="188">tokens, as generated</text>
  <rect class="cmn-label-plate" x="44" y="212" width="44" height="16" rx="4"/>
  <text class="cmn-label" x="66" y="224">time</text>
</svg>
</div>
<figcaption>The call leaves inference-service through its own pool and reaches the engine as one stream. The
quiet arc above it is the single retry, allowed only before the first byte reaches the client. The dashed
path below carries the tokens home, four of them drawn out to show that each is relayed separately. The axis
at the bottom is time, not distance: 30 s for the first token, 30 s of silence between tokens, 600 s for a
whole non-streamed answer.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> a response coming back (dashed)</span>
  <span><i class="is-async"></i> the one allowed retry (dotted)</span>
  <span><i></i> a refusal (neutral line, outlined node)</span>
</div>

1. **inference-service rebuilds the request.** Nothing the client sent is forwarded: `model`, `n = 1`,
   `max_tokens` and `stream_options` are set here, `priority` comes from the tier and `cache_salt` from the
   organization, and only ten allowlisted fields survive from the client's body.
2. **It goes out through a pool of 64 connections.** The pool is inference-service's own, not the default
   one: a request that cannot get a connection within one second is a 503 rather than a 45-second queue.
3. **The first byte is the deadline that matters.** Thirty seconds are allowed for the first event from the
   engine.
4. **A connect error or an engine 5xx before that first byte is retried once.** The retry is behind a
   `started` flag: once a token has reached the client, there is no second attempt, because it would replay
   tokens the client already has.
5. **A first-token timeout is not retried.** It becomes a 503: a timeout means the engine is overloaded, and
   one more request is the last thing it needs.
6. **Each server-sent event is relayed as it arrives**, one at a time and in order, through `concatMap`, as
   an SSE frame with the same `data:` payload. Keep-alive comments are dropped. The tracker reads each
   chunk for timing and usage and does not keep its text.
7. **Between tokens there is a second thirty-second deadline.** A stream that has gone silent is treated as
   a failed one, so a hung engine ends the request instead of holding the connection open.
8. **After the first byte, an error ends the stream instead of changing the status**: an OpenAI-shaped error
   event, then `[DONE]`.
9. **A non-streamed answer gets one whole-answer deadline of 600 s**, because it has no intermediate events
   to prove the engine is still working.

## Why it is like this

**The upstream request is built from scratch, headers and body alike.** A field the client sends is a client
decision: `priority` would let a caller buy a place in the engine's queue, `cache_salt` would let one tenant
read the timing of another tenant's prefix cache, and `chat_template_kwargs` or a vLLM extension would reach a
component the client is not supposed to configure. What does survive — `temperature`, `stop`, `seed`, `tools`
— is an allowlist, so a field added to the OpenAI schema tomorrow is dropped until someone adds it on purpose.

**The pool is a decision about failure, not about performance.** Reactor Netty's default provider queues a
request for a connection for 45 seconds; on a saturated engine that turns a slow answer into a stalled
gateway. A pool of 64 with a one-second acquire timeout converts the same condition into a 503 the caller can
act on. 64 is the number the gateway's route admits concurrently, so the queue is never built in front of a
gate and then built again behind it.

**Idle connections expire at 4 s, under the engines' 5 s keep-alive.** Reusing a socket the peer has just
closed produces a connect error on a request that had already been sent, which is a retry for no reason.

**Thirty seconds for the first token is generous on purpose.** On this hardware TTFT p95 was 253–351 ms with
three tiers running at once, so 30 s is not a latency target — it is the ceiling that catches a sleeping GPU
or a model that has to be loaded, and it sits under nginx's 60 s read timeout so the failure surfaces here
with an OpenAI-shaped error rather than as a proxy timeout.

**The retry is limited to before the first byte because there is no other safe point.** A retried stream
after the first token cannot be reconciled with what the client already rendered; the only honest options are
an error event or a silent gap, and an error event is the one the SDK can see. For the same reason a 4xx is
never retried: it is an answer, not a failure.

**`onRetryExhaustedThrow` rethrows the engine's own error.** Without it Reactor reports "retries exhausted",
which maps to a generic 500; with it, an engine that answered 500 twice maps to 502 `engine_error` and a
connect failure maps to 503, so the caller learns which of the two happened.

**The whole answer is capped at 600 s because it has no heartbeat.** A streamed answer proves it is alive by
sending events; a buffered one sends nothing until it is done, so the only available guard is a total
deadline — and 600 s sits under the gateway's 660 s so the error comes from the service that knows why.

## What would change it

- **A second engine replica** needs a way to choose one; today a model has exactly one URL in configuration.
  The upgrade is replica routing — fewest-waiting, or the Gateway API Inference Extension on Kubernetes.
- **A model that legitimately pauses for longer than 30 s between tokens** would trip the idle deadline. The
  fix is a per-model limit, not a larger global one.
- **Tracing is not wired**, so a request's path across the engine call is not visible outside the metrics.
- **Reading every frame costs one JSON parse per chunk.** The tracker parses each event to read its timing and
  usage, which is the price of per-request TTFT and ITL without keeping the text. It is the first thing to
  revisit if the relay ever shows up in a profile.

## Where to look

- [`Engine.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Engine.java)
  — the pool, the retry rule and the two streaming timeouts.
- [`ChatHandler.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatHandler.java)
  — the SSE response and what happens to an error before and after the first byte.
- [`Tracker.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Tracker.java)
  — one chunk at a time: first token, gaps, usage, and no text kept.
- [`ChatRequest.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatRequest.java)
  — the allowlist, `priority` and `cache_salt`.
- [`ApiError.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ApiError.java)
  — how an engine failure becomes a status and a code.

**Next:** [5 · The end, however it ends](ending.md) — the last frame has been written, and now the platform
has to decide what the request cost.
