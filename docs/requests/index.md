# The path of a request

One request, five steps, from the socket to the last token. This section follows a single
`POST /v1/chat/completions` with `stream: true` all the way through, and each page is one step of it.

The example request, used on every page of this section:

```json
POST /v1/chat/completions
Authorization: Bearer cmn_test_<43 base62><6 CRC>
Content-Type: application/json

{"model": "carmonai/qwen3-4b", "messages": [{"role": "user", "content": "Explique o Pix."}],
 "stream": true, "max_tokens": 256}
```

Model `carmonai/qwen3-4b` is the GPU engine in the `gpu` compose profile; `carmonai/qwen3-0.6b` is the
CPU one. Nothing on the path below depends on which of the two answers.

## What it is

Five steps, run by two services, in a fixed order: the gateway checks the socket and resolves the caller,
then inference-service admits the request, relays the engine's answer, and settles what it cost. No step can
be skipped and none of them writes to a database.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="rq-idx-title" aria-describedby="rq-idx-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="rq-idx-title">One streaming request through five steps</title>
  <desc id="rq-idx-desc">A client posts a chat completion to the gateway, which assigns a request id and
  runs the socket checks; the gateway resolves the API key against Valkey and the organization's credit
  flag; inference-service admits the request against rate buckets and in-flight caps; it calls the engine
  and relays the tokens back to the client one frame at a time; when the request ends, however it ends, the
  buckets are settled and a usage event is written to a Valkey stream.</desc>

  <defs>
    <!-- One arrowhead for every line: context-stroke makes it take the line's colour. -->
    <marker id="rq-idx-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the clock, then the five hops inward, then the return, then usage. -->
  <path id="rq-idx-time" class="cmn-link" d="M24 76 H736" marker-end="url(#rq-idx-arrow)"/>
  <g id="rq-idx-hops">
    <path id="rq-idx-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M100 138 H132"
          marker-end="url(#rq-idx-arrow)"/>
    <path id="rq-idx-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M224 138 H256"
          marker-end="url(#rq-idx-arrow)"/>
    <path id="rq-idx-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M348 138 H380"
          marker-end="url(#rq-idx-arrow)"/>
    <path id="rq-idx-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M472 138 H504"
          marker-end="url(#rq-idx-arrow)"/>
    <path id="rq-idx-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M596 138 H628"
          marker-end="url(#rq-idx-arrow)"/>
    <path id="rq-idx-hop6" class="cmn-link cmn-link--accent cmn-dash" d="M550 166 V194 H54 V166"
          marker-end="url(#rq-idx-arrow)"/>
    <path id="rq-idx-hop7" class="cmn-link cmn-link--quiet" d="M674 166 V196"
          marker-end="url(#rq-idx-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="rq-idx-client"
     aria-labelledby="rq-idx-client-label">
    <rect x="8" y="110" width="92" height="56" rx="10"/>
    <text id="rq-idx-client-label" x="54" y="130">Client</text>
    <text class="cmn-sub" x="54" y="148">SDK or app</text>
  </g>

  <g class="cmn-node cmn-node--flow cmn-step" id="rq-idx-edge" style="--i: 0;"
     aria-labelledby="rq-idx-edge-label">
    <rect x="132" y="110" width="92" height="56" rx="10"/>
    <text id="rq-idx-edge-label" x="178" y="130">Edge</text>
    <text class="cmn-sub" x="178" y="148">framing, key</text>
  </g>
  <circle class="cmn-step-num" cx="148" cy="96" r="10" aria-hidden="true"/>
  <text class="cmn-step-num-text" x="148" y="96" aria-hidden="true">1</text>

  <g class="cmn-node cmn-node--flow cmn-step" id="rq-idx-identity" style="--i: 1;"
     aria-labelledby="rq-idx-identity-label">
    <rect x="256" y="110" width="92" height="56" rx="10"/>
    <text id="rq-idx-identity-label" x="302" y="130">Identity</text>
    <text class="cmn-sub" x="302" y="148">cache, credit</text>
  </g>
  <circle class="cmn-step-num" cx="272" cy="96" r="10" aria-hidden="true"/>
  <text class="cmn-step-num-text" x="272" y="96" aria-hidden="true">2</text>

  <g class="cmn-node cmn-node--flow cmn-step" id="rq-idx-admission" style="--i: 2;"
     aria-labelledby="rq-idx-admission-label">
    <rect x="380" y="110" width="92" height="56" rx="10"/>
    <text id="rq-idx-admission-label" x="426" y="130">Admission</text>
    <text class="cmn-sub" x="426" y="148">buckets, caps</text>
  </g>
  <circle class="cmn-step-num" cx="396" cy="96" r="10" aria-hidden="true"/>
  <text class="cmn-step-num-text" x="396" y="96" aria-hidden="true">3</text>

  <g class="cmn-node cmn-node--flow cmn-step" id="rq-idx-relay" style="--i: 3;"
     aria-labelledby="rq-idx-relay-label">
    <rect x="504" y="110" width="92" height="56" rx="10"/>
    <text id="rq-idx-relay-label" x="550" y="130">Relay</text>
    <text class="cmn-sub" x="550" y="148">engine, tokens</text>
  </g>
  <circle class="cmn-step-num" cx="520" cy="96" r="10" aria-hidden="true"/>
  <text class="cmn-step-num-text" x="520" y="96" aria-hidden="true">4</text>

  <g class="cmn-node cmn-node--flow cmn-step" id="rq-idx-ending" style="--i: 4;"
     aria-labelledby="rq-idx-ending-label">
    <rect x="628" y="110" width="92" height="56" rx="10"/>
    <text id="rq-idx-ending-label" x="674" y="130">Ending</text>
    <text class="cmn-sub" x="674" y="148">settle, bill</text>
  </g>
  <circle class="cmn-step-num" cx="644" cy="96" r="10" aria-hidden="true"/>
  <text class="cmn-step-num-text" x="644" y="96" aria-hidden="true">5</text>

  <g class="cmn-node cmn-node--soft" id="rq-idx-usage" aria-labelledby="rq-idx-usage-label">
    <rect x="628" y="196" width="92" height="52" rx="10"/>
    <text id="rq-idx-usage-label" x="674" y="216">Usage</text>
    <text class="cmn-sub" x="674" y="234">Valkey stream</text>
  </g>

  <!-- Packets: one per hop, each on its own edge, staggered so the order is visible. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M100 138 H132'); --cmn-travel: 0.7s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M224 138 H256'); --cmn-travel: 0.7s; --cmn-delay: 0.8s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M348 138 H380'); --cmn-travel: 0.7s; --cmn-delay: 1.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M472 138 H504'); --cmn-travel: 0.7s; --cmn-delay: 1.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M596 138 H628'); --cmn-travel: 0.7s; --cmn-delay: 2.0s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M550 166 V194 H54 V166'); --cmn-travel: 1.3s; --cmn-delay: 2.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M674 166 V196'); --cmn-travel: 0.5s; --cmn-delay: 2.6s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="352" y="68" width="56" height="16" rx="4"/>
  <text class="cmn-label" x="380" y="80">time</text>
  <rect class="cmn-label-plate" x="200" y="172" width="140" height="16" rx="4"/>
  <text class="cmn-label" x="270" y="184">tokens, streamed back</text>
</svg>
</div>
<figcaption>Hops 1 to 5 carry the request inward, in order, through the gateway and into inference-service.
Hop 6 brings the answer back to the client as it is generated. Hop 7 is the usage event, written once the
request has ended — after the buckets are settled, never before.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> a response (dashed)</span>
  <span><i class="is-async"></i> an asynchronous hop (dotted)</span>
</div>

1. **The client posts the body** to the one published port. The gateway gives the request an id, replacing
   any id the client sent, and checks the request's framing before it looks at the credentials at all.
2. **The gateway resolves the key**: a checksum check with no I/O, SHA-256, one Valkey lookup, and
   auth-service only on a miss. It then refuses an inactive organization and a used-up balance.
3. **Inference-service admits the request**: one Lua script debits the organization's three per-minute
   buckets, then an in-flight cap decides whether the request runs now or waits.
4. **The engine is called** and its server-sent events are relayed to the client one at a time, with a
   deadline on the first token and on the silence between tokens.
5. **The request ends — ok, in error, or cancelled** — and that outcome decides what is billed. The buckets
   are corrected with the real counts before the usage event is written.
6. **The usage event waits in a Valkey stream** until a relay delivers it to usage-service. It carries ids
   and token counts, never the prompt or the answer.

## Why it is like this

The five steps are not five services. Two services do the work, and the steps are the moments where the
request changes hands or changes state — which is also where it can be refused.

- **The socket is checked before the caller is identified.** A malformed body or a key in the query string
  is refused without touching Valkey or auth-service, so the cheapest checks come first and a flood of
  garbage costs nothing downstream. See [The edge](edge.md).
- **Identity is resolved on the way in, not by the service that uses it.** The gateway strips every inbound
  identity header and sets its own; inference-service trusts `id-organization`, `id-api-key` and `tier` and
  nothing else. That removes the alternative — every service calling auth-service to ask who is calling.
  See [Who is calling](identity.md).
- **Admission happens in front of the engine, in our code.** The engine's own queue would accept far more
  than the GPU can serve and answer all of it slowly; a 429 in 9–16 ms at p95 is a better answer than a
  request that sits for four seconds. See [Admission](admission.md).
- **The response is streamed, not buffered.** A relay that waits for the whole answer to forward it turns a
  250 ms first token into several seconds, and the client's own tools — an SDK, a terminal, a chat box —
  expect to render as tokens arrive. See [The relay](relay.md).
- **The ending is a first-class event.** A client that hangs up, an engine that fails mid-answer and a
  request that finishes cleanly are three different bills, so the code tracks which one happened instead
  of treating the end of a stream as an afterthought. See [The end, however it ends](ending.md).

## What would change it

- **A second replica of inference-service** breaks the in-flight caps, because they live in one JVM's
  memory. Sharing them comes before a second replica, not with it.
- **A payment rail** replaces the staff grant that tops up a balance today; the 402 on the way in stays
  where it is.
- **A model server that does not batch** would need a batcher in Java, and there is none — see
  [Batching](../inference/batching.md).
- **The gateway stops being the only public port** the moment nginx or a load balancer sits in front of
  it; the `/v1` checks stay where they are, because they exist to keep one reading of the body's length
  from disagreeing with another.

## Where to look

- [`V1RequestFilter.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/V1RequestFilter.java)
  — the four checks that run before authentication.
- [`ApiKeyAuthenticationManager.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ApiKeyAuthenticationManager.java)
  — key resolution, the 60 s cache and the credit flag.
- [`ChatHandler.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatHandler.java)
  — the two routes, the relay and the ending.
- [`Admission.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java)
  — buckets, in-flight caps and the bounded wait.
- [`Engine.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Engine.java)
  — the engine call, its pool and its time limits.

**Next:** [1 · The edge](edge.md) — the request arrives on a socket, and the first thing that happens to it
is a set of checks that never look at the caller.
