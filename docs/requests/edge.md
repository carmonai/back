# 1 · The edge

Step 1 of [the path of a request](index.md). The previous page left the request as a `POST
/v1/chat/completions` with `stream: true`; here it is a byte stream arriving on the gateway's socket, before
anything knows who sent it.

## What it is

The gateway is the only service with a published port. Before it authenticates anything, it checks that the
request's own framing can be read one way and no other, refuses credentials in the URL, requires a stated
body size, and gives the request an id. Every one of those decisions is written to a log line that is
emitted when the request is over — however it ends.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="edge-title" aria-describedby="edge-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="edge-title">Checks a request passes at the gateway before authentication</title>
  <desc id="edge-desc">A client's request enters the gateway, which mints a request id and replaces any id
  the client sent. The request then passes three checks in order — framing, credentials in the URL, and a
  stated body size — any of which can refuse it with a 400, 411 or 413 before authentication is attempted.
  If it passes all three it is forwarded to inference-service; when the exchange ends, one line is written
  to the access log, refusals included.</desc>

  <defs>
    <marker id="edge-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the request inward through the three gates, then the two writes. -->
  <g id="edge-hops">
    <path id="edge-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M120 110 H210"
          marker-end="url(#edge-arrow)"/>
    <path id="edge-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M210 110 H330"
          marker-end="url(#edge-arrow)"/>
    <path id="edge-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M330 110 H450"
          marker-end="url(#edge-arrow)"/>
    <path id="edge-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M450 110 H500"
          marker-end="url(#edge-arrow)"/>
    <path id="edge-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M610 110 H650"
          marker-end="url(#edge-arrow)"/>
    <path id="edge-refuse1" class="cmn-link" d="M210 136 V196" marker-end="url(#edge-arrow)"/>
    <path id="edge-refuse2" class="cmn-link" d="M330 136 V196" marker-end="url(#edge-arrow)"/>
    <path id="edge-refuse3" class="cmn-link" d="M450 136 V196" marker-end="url(#edge-arrow)"/>
    <path id="edge-id" class="cmn-link cmn-link--flow cmn-dash" d="M68 136 V196"
          marker-end="url(#edge-arrow)"/>
    <path id="edge-log" class="cmn-link cmn-link--quiet" d="M560 136 V196"
          marker-end="url(#edge-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="edge-client" aria-labelledby="edge-client-label">
    <rect x="16" y="84" width="104" height="52" rx="10"/>
    <text id="edge-client-label" x="68" y="104">Client</text>
    <text class="cmn-sub" x="68" y="122">POST /v1/chat/…</text>
  </g>

  <!-- The three gates: a tick the request crosses, labelled above. -->
  <path class="cmn-link cmn-link--flow" d="M210 84 V136"/>
  <path class="cmn-link cmn-link--flow" d="M330 84 V136"/>
  <path class="cmn-link cmn-link--flow" d="M450 84 V136"/>

  <g class="cmn-node cmn-node--flow" id="edge-gateway" aria-labelledby="edge-gateway-label">
    <rect x="500" y="84" width="110" height="52" rx="10"/>
    <text id="edge-gateway-label" x="555" y="104">Gateway</text>
    <text class="cmn-sub" x="555" y="122">auth, routes</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="edge-inference" aria-labelledby="edge-inference-label">
    <rect x="650" y="84" width="94" height="52" rx="10"/>
    <text id="edge-inference-label" x="697" y="104">Inference</text>
    <text class="cmn-sub" x="697" y="122">/v1 only</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="edge-requestid" aria-labelledby="edge-requestid-label">
    <rect x="16" y="196" width="124" height="52" rx="10"/>
    <text id="edge-requestid-label" x="78" y="216">Request id</text>
    <text class="cmn-sub" x="78" y="234">ours, not theirs</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="edge-refused" aria-labelledby="edge-refused-label">
    <rect x="150" y="196" width="320" height="52" rx="10"/>
    <text id="edge-refused-label" x="310" y="216">400 · 411 · 413</text>
    <text class="cmn-sub" x="310" y="234">refused before authentication</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="edge-logline" aria-labelledby="edge-logline-label">
    <rect x="490" y="196" width="140" height="52" rx="10"/>
    <text id="edge-logline-label" x="560" y="216">access.log</text>
    <text class="cmn-sub" x="560" y="234">one line, 184 days</text>
  </g>

  <!-- Packets, staggered so the gate order is unmistakable. -->
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M68 136 V196'); --cmn-travel: 0.5s; --cmn-delay: 0.05s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M120 110 H210'); --cmn-travel: 0.8s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M210 110 H330'); --cmn-travel: 0.8s; --cmn-delay: 1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M330 110 H450'); --cmn-travel: 0.8s; --cmn-delay: 1.7s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M450 110 H500'); --cmn-travel: 0.4s; --cmn-delay: 2.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M610 110 H650'); --cmn-travel: 0.4s; --cmn-delay: 2.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M560 136 V196'); --cmn-travel: 0.5s; --cmn-delay: 2.9s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="160" y="56" width="100" height="16" rx="4"/>
  <text class="cmn-label" x="210" y="68">no chunked bodies</text>
  <rect class="cmn-label-plate" x="279" y="56" width="102" height="16" rx="4"/>
  <text class="cmn-label" x="330" y="68">no key in the URL</text>
  <rect class="cmn-label-plate" x="387" y="56" width="126" height="16" rx="4"/>
  <text class="cmn-label" x="450" y="68">Content-Length ≤ 4 MB</text>
  <rect class="cmn-label-plate" x="628" y="56" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="688" y="68">660 s to headers</text>
  <rect class="cmn-label-plate" x="575" y="152" width="160" height="16" rx="4"/>
  <text class="cmn-label" x="655" y="164">written when it ends</text>
</svg>
</div>
<figcaption>The request crosses three gates in a fixed order and only then reaches the routing chain, where
the key is resolved. Each gate has its own refusal — a 400 for bad framing or credentials in the URL, a 411
for a body with no length, a 413 for one over 4 MB — and a refusal is logged like any other request. The id
is minted on the way in, the log line is written on the way out.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-async"></i> a write that happens after the fact (dotted)</span>
  <span><i></i> a refusal (neutral line, outlined node)</span>
</div>

1. **The request arrives.** `AccessLogFilter` gives it a `X-Request-Id` — a fresh UUID — and replaces any id
   the client sent, on the request and again on the response before it is committed.
2. **The body must be readable one way.** A `Transfer-Encoding` header, or an HTTP/1.0 request, is refused
   with 400 `unsupported_framing`: along nginx → gateway → inference-service the length of a body must not
   be readable two different ways.
3. **The URL must not carry a credential.** A query string matching `cmn_`, `key` or `token` (case
   insensitive) is refused with 400 `credentials_in_url`.
4. **A POST must state its size.** No `Content-Length` is 411 `length_required`; more than 4 MB is 413
   `request_too_large`. The same filter that would have streamed a chunked body cannot be trusted to stop
   one, which is why the length is required rather than measured.
5. **It passes, and the key is resolved** by the API-key security chain — [step 2](identity.md) — and the
   gateway forwards the request to inference-service without the `Authorization` header.
6. **When the exchange ends, one line is written** to the access log with the request id, method, path
   without its query string, status, duration, peer address and whatever ids are known — refusals included.

## Why it is like this

**These checks run before authentication, at `Ordered.HIGHEST_PRECEDENCE`.** They read headers and the URL
only, so they cost nothing and can refuse a flood without a Valkey lookup or a call to auth-service. The
alternative — authenticate first, then look at the request — makes a malformed body fund an authentication
round trip.

**Framing is a security check, not a formality.** With nginx in front, a request whose length can be read
two ways is a request-smuggling primitive: one hop counts bytes in a chunked body, the next counts the
`Content-Length` it was given, and the two disagree about where the next request starts. Refusing
`Transfer-Encoding` and HTTP/1.0 outright removes the disagreement instead of trying to normalise it.

**The key goes in a header, never in the URL.** Query strings end up in access logs, proxy logs and browser
history, and the access log's whole design is to keep credentials out of it — it logs `getPath()`, which has
no query string. A URL is also the one part of a request that is almost always logged somewhere we do not
control.

**The size is required rather than measured** because measuring means reading the body, and reading the body
is the thing being defended against. 4 MB is the ceiling: it is below the gateway's own body limit and well
below anything a chat request needs, and `inference-service` sets `spring.codec.max-in-memory-size` to the
same figure so the two agree.

**The route's `response-timeout` is 660 000 ms, and it times the wait for headers only.** A streamed answer
takes as long as it takes; what has to arrive inside a deadline is the response's *start*. inference-service
sends that start with the first token within 30 s, so 660 s is the generous ceiling for a non-streamed
answer (600 s) plus the hops around it. A timeout that covered the whole stream would cut every long answer
at the same arbitrary minute.

**Nothing configures CORS on `/v1`,** so no browser page on another origin can read a response from it. The
API is for servers and SDKs; a console with a browser origin gets its own routes with their own guards.

**The access log is a legal record, not a debugging aid.** Marco Civil da Internet art. 15 requires the
connection records to be kept for six months, so the line goes to its own file (logger `access`) with
`maxHistory` 184 days, never to stdout, and it carries ids, a path, a status, a duration and an address —
never a header, a body or a query string.

## What would change it

- **nginx or a load balancer in front** is already planned. It does not move these checks: nginx overwrites
  `X-Forwarded-For` and logs `$uri` rather than `$request` for exactly the same reasons, and the gateway
  stops publishing its own port.
- **The 4 MB cap is a ceiling that a file upload would hit.** `POST /v1/files` shares it today; OpenAI
  allows 200 MB, so object storage and a larger limit are a prerequisite for a real Files API, not a
  tweak.
- **A second replica of the gateway** multiplies its in-memory flood brake by the number of replicas. The
  `/v1` checks here are stateless and would be unaffected.

## Where to look

- [`V1RequestFilter.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/V1RequestFilter.java)
  — the four checks and their exact refusal strings.
- [`AccessLogFilter.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/AccessLogFilter.java)
  — the request id and the one line written at the end.
- [`logback-spring.xml`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/resources/logback-spring.xml)
  — the access log's own file and its 184-day retention.
- [`OpenAiErrors.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/OpenAiErrors.java)
  — the single error writer, in OpenAI's shape, with fixed messages.
- [`application.yaml`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/resources/application.yaml)
  — the `inference` route: its predicates, `response-timeout` and `max-concurrent`.

**Next:** [2 · Who is calling](identity.md) — the checks passed, and now the gateway has to find out whose
key this is, without asking auth-service on every request.
