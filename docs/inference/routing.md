# Routing responses

## What it is

This page answers one question that the batching page leaves open: once the engine is producing tokens for
several requests at once, **how does each token find its way back to the one client that asked for it?** The
short answer is that nothing is matched, nothing is looked up, and nothing is shared: by the time a token
reaches our code it is already inside one request's own stream.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="route-title" aria-describedby="route-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="route-title">One engine batch feeding three separate response streams</title>
  <desc id="route-desc">The engine runs one batch containing three requests. Each request's new tokens are
  placed in that request's own queue, which its own task reads; each task writes to its own HTTP response, so
  a token can only reach the client that opened that stream.</desc>

  <defs>
    <marker id="route-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <g id="route-hops">
    <path id="route-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M236 140 V44 H316" marker-end="url(#route-arrow-flow)"/>
    <path id="route-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M236 140 H316" marker-end="url(#route-arrow-flow)"/>
    <path id="route-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M236 140 V236 H316" marker-end="url(#route-arrow-flow)"/>
    <path id="route-hop4" class="cmn-link cmn-link--accent cmn-dash" d="M462 44 H544 V92" marker-end="url(#route-arrow-flow)"/>
    <path id="route-hop5" class="cmn-link cmn-link--accent cmn-dash" d="M462 140 H544 V140" marker-end="url(#route-arrow-flow)"/>
    <path id="route-hop6" class="cmn-link cmn-link--accent cmn-dash" d="M462 236 H544 V188" marker-end="url(#route-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--accent" id="route-engine" aria-labelledby="route-engine-l">
    <rect x="96" y="112" width="140" height="56" rx="10"/>
    <text id="route-engine-l" x="166" y="132">Engine</text>
    <text class="cmn-sub" x="166" y="150">one batch, three rows</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="route-q1" aria-labelledby="route-q1-l">
    <rect x="316" y="20" width="146" height="48" rx="10"/>
    <text id="route-q1-l" x="389" y="40">Queue A</text>
    <text class="cmn-sub" x="389" y="56">request 1's tokens</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="route-q2" aria-labelledby="route-q2-l">
    <rect x="316" y="116" width="146" height="48" rx="10"/>
    <text id="route-q2-l" x="389" y="136">Queue B</text>
    <text class="cmn-sub" x="389" y="152">request 2's tokens</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="route-q3" aria-labelledby="route-q3-l">
    <rect x="316" y="212" width="146" height="48" rx="10"/>
    <text id="route-q3-l" x="389" y="232">Queue C</text>
    <text class="cmn-sub" x="389" y="248">request 3's tokens</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="route-client1" aria-labelledby="route-client1-l">
    <rect x="544" y="92" width="150" height="48" rx="10"/>
    <text id="route-client1-l" x="619" y="112">Client 1</text>
    <text class="cmn-sub" x="619" y="128">its own HTTP stream</text>
  </g>
  <g class="cmn-node cmn-node--accent" id="route-client2" aria-labelledby="route-client2-l">
    <rect x="544" y="116" width="150" height="48" rx="10"/>
    <text id="route-client2-l" x="619" y="136">Client 2</text>
    <text class="cmn-sub" x="619" y="152">its own HTTP stream</text>
  </g>
  <g class="cmn-node cmn-node--accent" id="route-client3" aria-labelledby="route-client3-l">
    <rect x="544" y="164" width="150" height="48" rx="10"/>
    <text id="route-client3-l" x="619" y="184">Client 3</text>
    <text class="cmn-sub" x="619" y="200">its own HTTP stream</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M236 140 V44 H316'); --cmn-travel: 1.4s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M236 140 H316'); --cmn-travel: 1.4s; --cmn-delay: 0.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M236 140 V236 H316'); --cmn-travel: 1.4s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M462 140 H544 V140'); --cmn-travel: 1.2s; --cmn-delay: 0.7s;"></circle>

  <rect class="cmn-label-plate" x="238" y="96" width="132" height="16" rx="4"/>
  <text class="cmn-label" x="304" y="108">by position, per step</text>
  <rect class="cmn-label-plate" x="470" y="66" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="530" y="78">one task each</text>
</svg>
</div>
<figcaption>Step 1 is the engine's own batch: three requests, one ordered list of rows. Step 2 places each
request's new tokens in that request's own queue. Step 3 has one task per queue read it and write to the
response that opened it, so three clients on three connections each receive only their own tokens.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> tokens leaving the batch (solid)</span>
  <span><i class="is-accent"></i> a client's own stream (dashed)</span>
</div>

1. **The engine forms one batch** containing several requests, and keeps an ordered list of which row belongs
   to which request for that step.
2. **Each request's new tokens go into its own queue**, inside the engine process.
3. **One task per request reads its queue** and writes into that request's own response — the socket the
   client opened.
4. **Three clients on three connections each see only their own tokens**, because there is no step in which
   their output shares a container.

## Why it is like this

There are three places a response could be misrouted, and each is answered by a different design decision.

**Inside the GPU.** The engine returns sampled tokens for the whole batch in one tensor. Row *i* belongs to
the *i*-th entry of the ordered `req_ids` list the scheduler built for that step. This is a positional
correspondence, and it is the reason a batch can be re-formed at all: the batch changes every step, so there
is no stable batch identity to key on — only a position within one step.

**Between the engine and our process.** A batch changes every step and crosses a process boundary, so the
tokens are sorted into per-request queues the moment they are produced. A queue lookup costs microseconds
against a step that takes about 24 ms here.

**Inside our services: nothing to match.** This is the part that surprises people. `inference-service` gives
each request its own HTTP call to the engine, its own reactive stream in, and its own response out. The
gateway does the same. On Netty and Reactor a waiting request is just a socket, so there is no shared list, no
lookup table, and no correlation id to get wrong — a token physically travels along the connection that
belongs to one client.

That is why this platform has **no batcher in Java** and no 40 ms fill window. The batching that matters
happens inside the engine at every token; a second batcher in front of it would add latency and could not
improve throughput. [Batching](batching.md) argues that case in full, including the one situation where a
Java batcher would be needed.

**What a disconnect does.** When a client hangs up, the response stream is cancelled, which cancels the
upstream request, which tells the engine to abort that sequence. The other rows in the same batch are
untouched — they are separate queues and separate tasks — and the aborted request still produces a usage event
with status `cancelled`, billed for what it generated.

## What would change it

| Ceiling | Would change if |
|---|---|
| One engine endpoint per model; routing between replicas is configuration | a second replica exists — then something has to choose one, and that choice needs the queue depth of each |
| No prefix-aware routing | several replicas and a prefix cache worth steering traffic towards, which is a Kubernetes-layer concern rather than Java |
| No correlation id in the payload | a proxy or a queue were introduced between the client and the response, which would break the "one connection, one answer" property that makes this simple |
| The engine's own batch is not observable from outside | the engine exposes a per-request identity in its metrics; today `num_requests_running` is the signal |

## Where to look

- [`Engine.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Engine.java) — the per-request engine call, the pool, and the retry that is allowed only before the first byte.
- [`ChatHandler.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatHandler.java) — the reactive stream in and out, and what happens when it ends.
- [The relay](../requests/relay.md) — the same flow from the request's point of view, with its time limits.
- [Batching](batching.md) — why the batch is re-formed every step, and why there is no Java batcher.
