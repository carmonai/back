# 5 · The end, however it ends

Step 5 of [the path of a request](index.md). [The relay](relay.md) has written the last frame. What happens
next is decided by *how* the request ended — and that is what it costs.

## What it is

Every request that reached the engine ends in exactly one of three ways — `ok`, `error`, `cancelled` — and
each has its own bill. Whatever the outcome, the permit is released, the rate buckets are corrected with the
real token counts, and one usage event is written to a durable stream for usage-service to collect.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="end-title" aria-describedby="end-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="end-title">The three ways a request ends and the order of settlement</title>
  <desc id="end-desc">One request ends as ok, as an error of ours, or cancelled by the client. All three
  lead to the same two steps in a fixed order: the rate buckets are settled with the real token counts
  first, then one usage event is built and written to the Valkey stream usage:events. A relay reads that
  stream once a second and delivers batches to usage-service, deleting each entry once it is stored.</desc>

  <defs>
    <marker id="end-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the three endings, then settlement, then the event and its delivery. -->
  <g id="end-hops">
    <path id="end-fork1" class="cmn-link cmn-link--flow cmn-dash" d="M160 116 H176 V54 H220" marker-end="url(#end-arrow)"/>
    <path id="end-fork2" class="cmn-link cmn-link--flow cmn-dash" d="M160 130 H220" marker-end="url(#end-arrow)"/>
    <path id="end-fork3" class="cmn-link cmn-link--flow cmn-dash" d="M160 144 H190 V206 H220" marker-end="url(#end-arrow)"/>
    <path id="end-join1" class="cmn-link cmn-link--flow cmn-dash" d="M360 54 H380 V110 H400" marker-end="url(#end-arrow)"/>
    <path id="end-join2" class="cmn-link cmn-link--flow cmn-dash" d="M360 130 H400" marker-end="url(#end-arrow)"/>
    <path id="end-join3" class="cmn-link cmn-link--flow cmn-dash" d="M360 206 H380 V150 H400" marker-end="url(#end-arrow)"/>
    <path id="end-hop4" class="cmn-link cmn-link--accent cmn-dash" d="M550 130 H590" marker-end="url(#end-arrow)"/>
    <path id="end-hop5" class="cmn-link cmn-link--quiet" d="M620 160 V180 H475 V206" marker-end="url(#end-arrow)"/>
    <path id="end-hop6" class="cmn-link cmn-link--quiet" d="M550 233 H590" marker-end="url(#end-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="end-request" aria-labelledby="end-request-label">
    <rect x="16" y="100" width="144" height="60" rx="10"/>
    <text id="end-request-label" x="88" y="120">One request</text>
    <text class="cmn-sub" x="88" y="138">ends one of three ways</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="end-ok" aria-labelledby="end-ok-label">
    <rect x="220" y="30" width="140" height="48" rx="10"/>
    <text id="end-ok-label" x="290" y="50">ok</text>
    <text class="cmn-sub" x="290" y="68">input + output</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="end-error" aria-labelledby="end-error-label">
    <rect x="220" y="106" width="140" height="48" rx="10"/>
    <text id="end-error-label" x="290" y="126">error</text>
    <text class="cmn-sub" x="290" y="144">ours: not billed</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="end-cancelled" aria-labelledby="end-cancelled-label">
    <rect x="220" y="182" width="140" height="48" rx="10"/>
    <text id="end-cancelled-label" x="290" y="202">cancelled</text>
    <text class="cmn-sub" x="290" y="220">billed what it saw</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="end-settle" aria-labelledby="end-settle-label">
    <rect x="400" y="100" width="150" height="60" rx="10"/>
    <text id="end-settle-label" x="475" y="120">Settle buckets</text>
    <text class="cmn-sub" x="475" y="138">real counts, once</text>
  </g>

  <g class="cmn-node cmn-node--money" id="end-event" aria-labelledby="end-event-label">
    <rect x="590" y="100" width="154" height="60" rx="10"/>
    <text id="end-event-label" x="667" y="120">Usage event</text>
    <text class="cmn-sub" x="667" y="138">ids and counts only</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="end-stream" aria-labelledby="end-stream-label">
    <rect x="400" y="206" width="150" height="54" rx="10"/>
    <text id="end-stream-label" x="475" y="226">usage:events</text>
    <text class="cmn-sub" x="475" y="244">Valkey stream</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="end-usage" aria-labelledby="end-usage-label">
    <rect x="590" y="206" width="154" height="54" rx="10"/>
    <text id="end-usage-label" x="667" y="226">usage-service</text>
    <text class="cmn-sub" x="667" y="244">batching, each second</text>
  </g>

  <!-- Packets, staggered so the fork and the settlement order are both visible. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M160 116 H176 V54 H220'); --cmn-travel: 0.8s; --cmn-delay: 0.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M160 130 H220'); --cmn-travel: 0.5s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M160 144 H190 V206 H220'); --cmn-travel: 0.8s; --cmn-delay: 0.45s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M360 54 H380 V110 H400'); --cmn-travel: 0.7s; --cmn-delay: 1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M360 130 H400'); --cmn-travel: 0.5s; --cmn-delay: 1.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M360 206 H380 V150 H400'); --cmn-travel: 0.7s; --cmn-delay: 1.3s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M550 130 H590'); --cmn-travel: 0.5s; --cmn-delay: 1.8s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M620 160 V180 H475 V206'); --cmn-travel: 0.8s; --cmn-delay: 2.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M550 233 H590'); --cmn-travel: 0.5s; --cmn-delay: 3.1s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="430" y="76" width="160" height="16" rx="4"/>
  <text class="cmn-label" x="510" y="88">settlement goes first</text>
  <rect class="cmn-label-plate" x="560" y="184" width="170" height="16" rx="4"/>
  <text class="cmn-label" x="645" y="196">batched, then deleted</text>
</svg>
</div>
<figcaption>The request ends one of three ways and all three arrive at the same two steps, in this order:
settle the buckets, then build the event. The event goes into a Valkey stream — a dotted hop, off the
request's path — and a relay delivers it to usage-service in batches, deleting each entry once it is
stored.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> the request ending (solid)</span>
  <span><i class="is-accent"></i> the number that gets billed (dashed)</span>
  <span><i class="is-async"></i> off the request's path (dotted)</span>
</div>

1. **The permit is released, whichever way it went.** `Flux.usingWhen` holds it for the whole exchange and
   releases it on completion, on error and on cancellation — including the case where the client is gone
   before the response body was ever subscribed.
2. **`doFinally` supplies the outcome.** It sees the `SignalType`: `ON_COMPLETE` is `ok`, `ON_ERROR` is
   `error`, `CANCEL` is `cancelled`.
3. **A failure after the first byte is not a signal.** By then the status is already sent, so the relay
   turns the error into an error event followed by `[DONE]`, the stream completes normally, and the tracker
   sets a `failed` flag instead. Without that flag the ending would look like a success.
4. **The usage event is built from what the tracker saw**: the last usage the engine reported, the time to
   the first token, the gaps between tokens, and the outcome. It keeps no text.
5. **The buckets are settled first**, with the real counts: the input estimate's error, and the output
   actually generated in place of the `max_tokens` that was set aside. A request refused after its wait
   gives back only the output reservation, once — the request and its input still count.
6. **Then the event is written** to the Valkey stream `usage:events`, with up to ten retries behind it. An
   event that cannot be written at all is logged as one ERROR line, to be replayed by hand.
7. **A relay delivers in batches of 100, once a second.** Entries another relay read but never confirmed
   within 60 s are claimed first; new ones follow.
8. **Each entry is deleted, then acknowledged.** The order is deliberate: an acknowledged entry that failed to
   delete would sit in the stream for good, while a deleted entry whose acknowledgement failed is gone.
9. **A batch of 100 that usage-service rejects with 400 is resent one event at a time**, and only the rejected
   one is dropped. Anything else — including a 404 from a wrong URL — leaves every entry pending for 60 s.

## Why it is like this

**`doFinally` alone is not enough, and neither is `usingWhen` alone.** `doFinally` is the only place that
knows *how* a stream ended, but it runs on the inner publisher — if the client disappears before that
publisher is ever subscribed, it never runs and the permit is held by a request that no longer exists.
`usingWhen` releases the resource on every terminal path, including that one, but knows nothing about
outcomes. The pair gives both: the resource is always released, and the reason is always recorded.

**The ending decides the bill, so it is recorded rather than inferred.** A stream that finished, a stream we
broke, and a stream the client abandoned all stop producing frames. Only the signal distinguishes them:

| Ending | What the engine reported | What is billed |
|---|---|---|
| `ok` | real usage | input (cached included) + output |
| `error` — our failure | real or partial usage | nothing: the event is stored with `status = error` and left out of the window's sums |
| `cancelled` — the client hung up | real usage on vLLM, nothing on llama.cpp | a stream: input + output generated; a non-streamed request: the estimated input only |

**The settlement goes before the event because the settlement is what the next request reads.** A usage
event that cannot be written retries with exponential backoff for tens of seconds; if it went first, the
correction to this organization's buckets would wait behind it, and every request admitted meanwhile would be
charged against an uncorrected bucket. Settle, then report — and the metrics line between them cannot block,
because the report is the only one of the three that talks to Valkey.

**The correction happens once, and only for what was reserved.** The permit remembers whether the buckets were
charged at admission, so a request admitted while Valkey was down is settled with its real counts, and a
request refused after its wait does not give its `max_tokens` back twice.

**An error of ours is not billed, but it is recorded.** The event is written with `status = error`; the window
counts it in `requests` and in `errors`, and excludes its tokens from the sums. The failure is visible in the
customer's numbers without appearing on their invoice.

**A cut-short batch line is not reported at all.** Every run of one line shares a single event id and a single
`started_at`, and usage-service stores the first event it sees for that pair — so a failed run reported first
would freeze that line's numbers for good. Only the run that answered is written, and a line that was
interrupted simply runs again.

**Usage goes to a stream because the request must not wait for it.** The write is fire-and-forget on whatever
thread ended the request. Valkey's append-only file means a killed instance does not take its pending events
with it, and the 60-second claim means an instance that died mid-delivery does not strand them.

**Nothing in the event is content.** Organization, key, model, mode, tier, counts, status, timings. No prompt,
no answer, no IP. That is what makes the whole metering path legal to keep, and the smoke test greps every
log, the access log and a database dump for a canary string to prove it.

## What would change it

- **Kafka replaces this stream when an event gets a second consumer.** Until then a stream with one
  consumer group is the smaller thing that works.
- **A flex request is recorded as mode `batch`.** It is in the half-price lane that billing already prices;
  a `flex` mode of its own is what a separate flex price or report would need.
- **A cancelled stream on the CPU engine is estimated**, because llama.cpp reports usage only at the end of
  a stream: input is the body's bytes ÷ 4 and output is the number of content chunks, roughly one token
  each. vLLM sends continuous usage, so on the GPU the real counts are used.
- **The usage event id is a random UUID minted as the request ends.** The plan describes a UUIDv7 minted at
  admission; nothing in the pipeline depends on which of the two it is, so the difference is a note rather
  than a bug.
- **The relay deletes before it acknowledges.** If a delete succeeds and the acknowledgement fails, the
  entry is gone and the claim will not find it — which is the intended direction of that trade, but it does
  mean the stream is not a replayable log.

## Where to look

- [`ChatHandler.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatHandler.java)
  — `usingWhen`, `doFinally` and the order inside `finish`.
- [`Tracker.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Tracker.java)
  — the outcome, the token counts and the estimate when the engine reported none.
- [`UsageReporter.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/UsageReporter.java)
  — the stream, the relay, the batch and the shutdown grace.
- [`usage-next.lua`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/usage-next.lua)
  — the claim of unconfirmed entries, then the new ones.
- [`Admission.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Admission.java)
  — `settle`, and the `charged` flag on the permit.

**Next:** [Inference](../inference/index.md) takes the engine itself apart — the box that produced those tokens.
