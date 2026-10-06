# Inference

## What it is

`inference-service` is the OpenAI-compatible surface and the only service that talks to a model. It owns no
database: it receives a request the gateway has already authenticated, reduces it to a shape the engine can be
trusted with, relays the answer, and reports what was consumed.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="inf-title" aria-describedby="inf-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="inf-title">A chat request narrowed to an allowlist, sent to the engine, and metered</title>
  <desc id="inf-desc">A client posts an OpenAI-shaped body; only ten fields survive the allowlist, and the
  service sets the fields that decide cost and engine behaviour itself. The engine returns tokens as they
  are generated, and when the request ends a usage event carrying counts but no text is written.</desc>
  <defs>
    <marker id="inf-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="inf-arrow-accent" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="inf-arrow-quiet" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: the body in, the allowlist, the call, the tokens back, then the event. -->
  <g id="inf-hops">
    <path id="inf-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M130 130 H180" marker-end="url(#inf-arrow-flow)"/>
    <path id="inf-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M320 130 H370" marker-end="url(#inf-arrow-flow)"/>
    <path id="inf-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M520 130 H570" marker-end="url(#inf-arrow-flow)"/>
    <path id="inf-hop4" class="cmn-link cmn-link--accent cmn-dash" d="M640 102 V74 H75 V102" marker-end="url(#inf-arrow-accent)"/>
    <path id="inf-hop5" class="cmn-link cmn-link--quiet" d="M445 158 V200" marker-end="url(#inf-arrow-quiet)"/>
  </g>
  <g class="cmn-node cmn-node--entry cmn-node--soft" id="inf-client" aria-labelledby="inf-client-label"><rect x="20" y="102" width="110" height="56" rx="10"/><text id="inf-client-label" x="75" y="122">Client</text><text class="cmn-sub" x="75" y="140">OpenAI SDK</text></g>
  <g class="cmn-node cmn-node--flow" id="inf-allowlist" aria-labelledby="inf-allowlist-label"><rect x="180" y="102" width="140" height="56" rx="10"/><text id="inf-allowlist-label" x="250" y="122">Allowlist</text><text class="cmn-sub" x="250" y="140">ten fields survive</text></g>
  <g class="cmn-node cmn-node--flow" id="inf-service" aria-labelledby="inf-service-label"><rect x="370" y="102" width="150" height="56" rx="10"/><text id="inf-service-label" x="445" y="122">Inference</text><text class="cmn-sub" x="445" y="140">sets cost and priority</text></g>
  <g class="cmn-node cmn-node--accent" id="inf-engine" aria-labelledby="inf-engine-label"><rect x="570" y="102" width="140" height="56" rx="10"/><text id="inf-engine-label" x="640" y="122">Engine</text><text class="cmn-sub" x="640" y="140">one URL per model</text></g>
  <g class="cmn-node cmn-node--soft" id="inf-usage" aria-labelledby="inf-usage-label"><rect x="370" y="200" width="150" height="52" rx="10"/><text id="inf-usage-label" x="445" y="219">Usage event</text><text class="cmn-sub" x="445" y="237">counts, never text</text></g>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M130 130 H180'); --cmn-travel: 0.9s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M320 130 H370'); --cmn-travel: 0.9s; --cmn-delay: 0.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M520 130 H570'); --cmn-travel: 0.9s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5" style="offset-path: path('M640 102 V74 H75 V102'); --cmn-travel: 1.4s; --cmn-delay: 0.7s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M445 158 V200'); --cmn-travel: 0.9s; --cmn-delay: 1.6s;"></circle>
  <rect class="cmn-label-plate" x="133" y="110" width="44" height="16" rx="4"/><text class="cmn-label" x="155" y="122">body</text>
  <rect class="cmn-label-plate" x="324" y="110" width="42" height="16" rx="4"/><text class="cmn-label" x="345" y="122">only</text>
  <rect class="cmn-label-plate" x="524" y="110" width="42" height="16" rx="4"/><text class="cmn-label" x="545" y="122">call</text>
  <rect class="cmn-label-plate" x="280" y="52" width="140" height="16" rx="4"/><text class="cmn-label" x="350" y="64">tokens, as generated</text>
  <rect class="cmn-label-plate" x="451" y="172" width="82" height="16" rx="4"/><text class="cmn-label" x="492" y="184">when it ends</text>
</svg>
</div>
<figcaption>The client's body is not trusted: step 1 carries it to the allowlist, and step 2 forwards only the
ten fields that survived, with the service's own values for everything that decides cost or engine behaviour.
Step 3 asks the engine, step 4 streams the tokens back along a path of their own, and step 5 reports counts
once the request has ended.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> tokens coming back (dashed)</span>
  <span><i class="is-async"></i> the usage event, after the answer (dotted)</span>
</div>

1. **The client posts an OpenAI-shaped body** to `POST /v1/chat/completions`, with the API key the gateway has
   already resolved.
2. **`ChatRequest.parse` narrows it to an allowlist** and rejects anything else, so ten client fields reach the
   engine and no more.
3. **The service fills in what it decides**: the model, `n = 1`, `max_tokens`, the stream options, and — for a
   vLLM engine — the scheduling `priority` and the cache salt.
4. **The engine's tokens travel back as they are generated**, on a path of their own, because a streaming
   answer is not a reply that arrives at the end.
5. **When the request ends, an event reports what it cost**, carrying ids and counts and never the prompt or
   the answer.

## The two endpoints

`InferenceApplication` declares two routes and nothing else:

```java
RouterFunctions.route()
    .GET("/v1/models", chat::models)
    .POST("/v1/chat/completions", chat::chat)
```

`GET /v1/models` is built from `carmonai.inference.models` in configuration — the model list is configuration,
not code, so adding a model is adding a YAML entry with its engine URL, context window, output cap, slots and
queue. `POST /v1/chat/completions` is the one that matters. There is no `GET /v1/embeddings`: it is not hidden
or unimplemented behind a flag, it does not exist, and an OpenAI SDK that calls it gets a 404.

## The allowlist

Exactly these fields are copied through: `messages`, `temperature`, `top_p`, `stop`, `presence_penalty`,
`frequency_penalty`, `seed`, `tools`, `tool_choice`, `parallel_tool_calls`.

Everything else is either refused or replaced. The service sets `model`, `n = 1`, `max_tokens`, `stream`,
`stream_options` when streaming, and for a vLLM engine `priority` and `cache_salt`. That list is the point: a
client cannot choose its own scheduling priority, cannot ask for multiple completions, cannot claim a larger
output budget than the model allows, and cannot pass a vLLM extension, a `chat_template_kwargs` or a user id
through to the engine.

| Condition | Status | `code` |
|---|---|---|
| the body is not a JSON object | 400 | `invalid_json` |
| `messages` missing, not an array, or empty | 400 | `invalid_messages` |
| a content part that is not text | 400 | `unsupported_content` |
| `n` present and not 1 | 400 | `unsupported_n` |
| `service_tier` not `auto`, `default` or `flex` | 400 | `unsupported_service_tier` |
| `max_tokens` outside 1…`max-output` | 400 | `invalid_max_tokens` |
| the body is larger than `context-window × 16` bytes | 413 | `context_length_exceeded` |
| `model` is not in configuration | 404 | `model_not_found` |

Content is text only — no `image_url`, no audio, no file parts — so the engine never fetches anything on a
request's behalf. `max_completion_tokens` wins over the older `max_tokens`, and neither present means the
model's own output cap.

Two settings are always the platform's, whatever the client asked:

- **Usage is always requested from the engine.** `stream_options` is set to
  `{"include_usage": true, "continuous_usage_stats": true}` on every streaming request. The client's own
  `include_usage` flag decides only whether *the client* sees the usage block; billing's copy is not optional.
- **`cache_salt` is the organization id.** Each tenant gets its own prefix cache, so one organization cannot
  time another's cached prompts — and since the field is not in the allowlist, a client cannot set it either.

`priority` follows the tier: `enterprise` 0, `standard` 10, `trial` 20, and 30 for a batch line or a flex
request. vLLM runs lower values first and preempts them last, so this is the whole of the tier's scheduling
effect — the rest of it is [admission](../requests/admission.md).

## `flex`

`service_tier: "flex"` is OpenAI's spare-capacity lane, and it is honest about what it buys: batch prices at
batch priority, on the model's spare capacity only. A flex request keeps its organization's rate buckets and
its in-flight cap, but takes the share of the model's slots that batch traffic takes — which means it is
admitted only when there is room, and refused at once rather than waiting, with a 429 saying there is no spare
capacity right now. Nothing is billed for a refused request.

`auto` and `default` mean the standard lane, and any other value is a 400. A batch line is already running in
the half-price lane, so `flex` is ignored for it rather than applied twice.

## The identity it reads

`Caller.from(headers)` reads three headers and nothing else: `id-organization`, `id-api-key` and `tier`. The
gateway sets them and strips any inbound copy, so a request that arrives without them did not come through the
gateway and is answered 401 `invalid_api_key`. A `tier` outside `trial`, `standard`, `enterprise` fails the
same way.

The fourth is `batch-line`, of the form `{batchId} {line} {batchCreatedAt}`, which marks a request
batch-service is running for a batch. The gateway strips that header too, or a client could buy answers at
batch prices.

## The usage event it produces

`UsageEvent` is usage-service's `UsageEventIn` shape: `eventId`, `requestId`, `organizationId`, `apiKeyId`,
`model`, `mode`, `tier`, `inputTokens`, `cachedInputTokens`, `outputTokens`, `status`, `startedAt`, `ttftMs`,
`durationMs`. Ids and counts — never the prompt, the answer, or the caller's address.

Three details are decisions rather than plumbing:

- **The outcome is the event's status.** How a request ends — ok, an error of ours, or cancelled by a client
  that hung up — sets `status`, and `Tracker` follows the request without keeping its text to be able to say
  which happened.
- **`mode` is `sync` unless the request came from batch-service, or asked for `flex`.** Both of those run in
  the half-price lane, so both are recorded as `batch`.
- **A batch line's event id is a name-based UUID of `(batch, line)`, and its `startedAt` is the batch's
  creation time.** So however many times a line is retried or a worker is killed, the event's identity is the
  same and it is stored, and billed, once.

The event goes to the Valkey stream `usage:events`; a relay delivers batches to usage-service every second and
deletes them once they are stored. A killed instance loses nothing: the stream is append-only on disk, and an
entry that was never confirmed is claimed again after `carmonai.inference.usage-claim-after` (60 s).
[Metering](metering.md) takes it from there.

## Why it is like this

**An allowlist, not a denylist.** A denylist has to enumerate everything a future engine version might accept,
and it is wrong the moment the engine adds a field. Ten names that are known to be safe stay correct.

**Nothing that decides cost comes from the client.** `model`, `max_tokens` and `n` are the three fields that
determine what a request costs, and all three are set here. A client that could set `n` could multiply its own
bill, and a client that could set `priority` would be scheduling itself ahead of other tenants.

**The tokens come back on their own hop.** A streaming answer is not a reply that exists at the end, so the
diagram separates it: the client may be reading the first token while the last one has not been decided. That
is also why the timeouts are what they are — a first token within 30 s, silence between tokens never longer
than 30 s, and a whole non-streamed answer within 600 s.

**The usage event is written after the request ends, deliberately.** Settlement of the rate buckets happens
before it, so a client cannot be billed twice by a retry of the accounting, and the event describes a request
that is over rather than one in flight.

## What would change it

- **Flex usage is recorded in mode `batch`.** That is what the half-price lane prices, so it is correct today
  and wrong the moment flex needs a price or a report of its own — a `flex` mode, with the migrations that go
  with it.
- **One engine endpoint per model.** `carmonai.inference.models` maps a model id to a single URL. Routing
  across replicas needs more GPUs and a different model of capacity.
- **In-flight caps live in one JVM's memory.** Admission's per-tier and per-organization caps are a single
  replica's view, so a second replica would double them.
- **There is no `GET /v1/embeddings`**, and the model list is configuration rather than a catalogue.
- **Tracing is not wired**, so a request id is the only thing joining these logs to the gateway's.

## Where to look

- [InferenceApplication.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/InferenceApplication.java) — the two routes, in full.
- [ChatRequest.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatRequest.java) — the allowlist, the refusals and the flex lane.
- [Caller.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Caller.java) — the identity headers and the batch line.
- [UsageEvent.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/UsageEvent.java) — what a finished request reports.
- [application.yaml](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/resources/application.yaml) — the tiers, the timeouts and the model list.
