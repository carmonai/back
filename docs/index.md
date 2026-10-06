# Carmonai

**An OpenAI-compatible inference platform for Brazil: prepaid credit in BRL, LGPD by design, sold in tiers.**

This site explains how the platform is built, for a reader who has the repository open beside them. Every
page names the classes and files that do the work, and every number came from a measurement recorded in the
repository rather than from a wish.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="hero-title" aria-describedby="hero-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="hero-title">A request crossing the platform</title>
  <desc id="hero-desc">A client sends an API key and a request to the gateway, which authenticates it and
  forwards it with identity headers to the inference service; the inference service admits it, calls the
  engine, and streams tokens back the same way. When the request ends, usage is reported asynchronously to
  the metering service, and later priced into a ledger in billing.</desc>

  <defs>
    <marker id="hero-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
    <marker id="hero-arrow-accent" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
    <marker id="hero-arrow-money" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops, in reading order: 1 request, 2 forward, 3 call, 4 response.
       One asynchronous hop (usage) follows, then the money hop. -->
  <g id="hero-hops">
    <path id="hero-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M150 108 H236" marker-end="url(#hero-arrow-flow)"/>
    <path id="hero-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M376 108 H472" marker-end="url(#hero-arrow-flow)"/>
    <path id="hero-hop3" class="cmn-link cmn-link--flow cmn-dash"
          d="M612 108 H664" marker-end="url(#hero-arrow-flow)"/>
    <path id="hero-hop4" class="cmn-link cmn-link--accent cmn-dash"
          d="M664 140 H300 V176" marker-end="url(#hero-arrow-accent)"/>
    <path id="hero-hop5" class="cmn-link cmn-link--quiet"
          d="M300 204 V236 H216" marker-end="url(#hero-arrow-flow)"/>
    <path id="hero-hop6" class="cmn-link cmn-link--money"
          d="M96 236 H40 V204" marker-end="url(#hero-arrow-money)"/>
  </g>

  <!-- Clients -->
  <g class="cmn-node cmn-node--entry cmn-node--soft" id="hero-client"
     aria-labelledby="hero-client-label">
    <rect x="30" y="80" width="120" height="56" rx="10"/>
    <text id="hero-client-label" x="90" y="100">Client</text>
    <text class="cmn-sub" x="90" y="118">SDK or app</text>
  </g>

  <!-- The public edge -->
  <g class="cmn-node cmn-node--flow" id="hero-gateway" aria-labelledby="hero-gateway-label">
    <rect x="236" y="80" width="140" height="56" rx="10"/>
    <text id="hero-gateway-label" x="306" y="100">Gateway</text>
    <text class="cmn-sub" x="306" y="118">the only public port</text>
  </g>

  <!-- The inference service -->
  <g class="cmn-node cmn-node--flow" id="hero-inference" aria-labelledby="hero-inference-label">
    <rect x="472" y="80" width="140" height="56" rx="10"/>
    <text id="hero-inference-label" x="542" y="100">Inference</text>
    <text class="cmn-sub" x="542" y="118">admit, relay, meter</text>
  </g>

  <!-- The engine -->
  <g class="cmn-node cmn-node--accent" id="hero-engine" aria-labelledby="hero-engine-label">
    <rect x="664" y="80" width="76" height="56" rx="10"/>
    <text id="hero-engine-label" x="702" y="100">Engine</text>
    <text class="cmn-sub" x="702" y="118">vLLM</text>
  </g>

  <!-- Metering -->
  <g class="cmn-node cmn-node--flow" id="hero-usage" aria-labelledby="hero-usage-label">
    <rect x="216" y="176" width="150" height="56" rx="10"/>
    <text id="hero-usage-label" x="291" y="196">Usage</text>
    <text class="cmn-sub" x="291" y="214">what was consumed</text>
  </g>

  <!-- Money -->
  <g class="cmn-node cmn-node--money" id="hero-billing" aria-labelledby="hero-billing-label">
    <rect x="40" y="176" width="120" height="56" rx="10"/>
    <text id="hero-billing-label" x="100" y="196">Billing</text>
    <text class="cmn-sub" x="100" y="214">what it costs</text>
  </g>

  <!-- Payloads, one per hop -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M150 108 H236'); --cmn-travel: 1.1s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M376 108 H472'); --cmn-travel: 1.1s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M612 108 H664'); --cmn-travel: 1.1s; --cmn-delay: 0.55s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M664 140 H300 V176'); --cmn-travel: 1.8s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M300 204 V236 H216'); --cmn-travel: 1.6s; --cmn-delay: 1.5s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="4.5"
          style="offset-path: path('M96 236 H40 V204'); --cmn-travel: 1.6s; --cmn-delay: 2.1s;"></circle>

  <!-- Labels, above everything, each on its own plate -->
  <rect class="cmn-label-plate" x="146" y="82" width="96" height="16" rx="4"/>
  <text class="cmn-label" x="194" y="94">key + request</text>
  <rect class="cmn-label-plate" x="386" y="82" width="78" height="16" rx="4"/>
  <text class="cmn-label" x="425" y="94">forward</text>
  <rect class="cmn-label-plate" x="600" y="82" width="48" height="16" rx="4"/>
  <text class="cmn-label" x="624" y="94">prompt</text>
  <rect class="cmn-label-plate" x="404" y="150" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="464" y="162">tokens, streamed back</text>
  <rect class="cmn-label-plate" x="228" y="218" width="126" height="16" rx="4"/>
  <text class="cmn-label" x="291" y="230">usage event, at the end</text>
  <rect class="cmn-label-plate" x="20" y="218" width="120" height="16" rx="4"/>
  <text class="cmn-label" x="80" y="230">sealed window, priced</text>
</svg>
</div>
<figcaption>Steps 1 and 2 carry the request inward and step 3 asks the engine for an answer; step 4 brings the
tokens back along the same path. Step 5 reports usage once the request has ended, and step 6 turns a sealed
window into a ledger entry. Only the gateway is reachable from outside the network.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> a response (dashed)</span>
  <span><i class="is-async"></i> an asynchronous hop (dotted)</span>
  <span><i class="is-money"></i> money moving (dashed, gold)</span>
</div>

1. **The client sends an API key and a request** to the gateway — the only service with a published port.
2. **The gateway resolves the key**, checks the organization's credit flag, strips every identity header the
   client sent, and forwards the request with headers of its own.
3. **Inference admits the request** against a rate budget and a share of the engine's slots, then asks the
   engine for an answer.
4. **The tokens come back** down the same path as they are generated, to a client that may still be waiting.
5. **When the request ends, usage is reported** asynchronously: an event carrying ids and token counts, never
   the prompt or the answer.
6. **Later, a sealed window becomes money**: billing prices it and writes a ledger entry against a prepaid
   balance in micro-BRL.

Notice what is absent from that path: no database is touched while a token is being generated, and no service
other than the gateway is reachable from outside. Those two facts shape most of the pages that follow.

## Where to start

<div class="grid cards" markdown>

-   **I want the whole picture**

    ---

    [The shape of the system](architecture/topology.md) draws the services, the network boundary and the
    direction every dependency points.

-   **I want to follow one request**

    ---

    [The path of a request](requests/index.md) walks a single `POST /v1/chat/completions` from the socket to
    the last token, in five steps.

-   **I want to know how it stays correct**

    ---

    [Billing](services/billing.md) and [Metering](services/metering.md) explain how usage survives a crash and
    is billed exactly once.

-   **I want the honest version**

    ---

    [Known gaps](reference/gaps.md) lists what is unbuilt or deliberately deferred, and why.

</div>

## The one-paragraph summary

Ten Spring Boot services front two engines — vLLM on a GPU for the real model, llama.cpp on CPU for the
cheap one. A customer authenticates with an API key, and every request is admitted against a rate budget and
a share of the engine's slots before it can reach the model. While it runs, its usage is written to a durable
stream; when it ends, that usage becomes an event, the event becomes a sealed five-minute window, and the
window becomes a ledger entry against a prepaid balance in micro-BRL. If the balance runs out, a flag in
Valkey turns the next request into a 402. Nothing in that sentence touches a prompt: the platform stores ids
and counts, never content.
