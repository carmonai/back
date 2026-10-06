# 2 · Who is calling

Step 2 of [the path of a request](index.md). [The edge](edge.md) left the request past its framing and size
checks, with a request id of ours attached, and about to be authenticated.

## What it is

The gateway turns `Authorization: Bearer cmn_…` into a triple — organization, API key id, tier — and refuses
the request if the organization is not active or its prepaid balance is used up. Almost every request is
answered from one Valkey lookup; auth-service is asked only when the cache does not have the answer.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="id-title" aria-describedby="id-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="id-title">Resolving an API key, on a cache hit and on a cache miss</title>
  <desc id="id-desc">The gateway checks the key's shape and CRC with no I/O, hashes it with SHA-256 and
  looks the hash up in Valkey. On a hit the answer is used at once; on a miss auth-service is asked by hash
  and its answer is cached for sixty seconds, refusals included. The resolved organization's status and
  credit flag are checked next, and only then are the identity headers set for the services downstream. A
  Valkey failure at any point is a 503, a used-up balance is a 402.</desc>

  <defs>
    <marker id="id-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Reading order: the resolution inward, then the miss path, then the two refusals. -->
  <g id="id-hops">
    <path id="id-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M136 100 H164"
          marker-end="url(#id-arrow)"/>
    <path id="id-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M290 100 H318"
          marker-end="url(#id-arrow)"/>
    <path id="id-miss" class="cmn-link cmn-link--flow cmn-dash" d="M350 128 V198"
          marker-end="url(#id-arrow)"/>
    <path id="id-refill" class="cmn-link cmn-link--flow cmn-dash" d="M412 198 V128"
          marker-end="url(#id-arrow)"/>
    <path id="id-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M444 100 H472"
          marker-end="url(#id-arrow)"/>
    <path id="id-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M598 100 H626"
          marker-end="url(#id-arrow)"/>
    <path id="id-down" class="cmn-link" d="M330 128 V178 H110 V198" marker-end="url(#id-arrow)"/>
    <path id="id-nocredit" class="cmn-link" d="M570 128 V160 H660 V198" marker-end="url(#id-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="id-bearer" aria-labelledby="id-bearer-label">
    <rect x="20" y="72" width="116" height="56" rx="10"/>
    <text id="id-bearer-label" x="78" y="92">Bearer cmn_…</text>
    <text class="cmn-sub" x="78" y="110">one header</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="id-format" aria-labelledby="id-format-label">
    <rect x="164" y="72" width="126" height="56" rx="10"/>
    <text id="id-format-label" x="227" y="92">Shape, then hash</text>
    <text class="cmn-sub" x="227" y="110">CRC first, no I/O</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="id-cache" aria-labelledby="id-cache-label">
    <rect x="318" y="72" width="126" height="56" rx="10"/>
    <text id="id-cache-label" x="381" y="92">Valkey cache</text>
    <text class="cmn-sub" x="381" y="110">apikey:{hash}</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="id-credit" aria-labelledby="id-credit-label">
    <rect x="472" y="72" width="126" height="56" rx="10"/>
    <text id="id-credit-label" x="535" y="92">Status, credit</text>
    <text class="cmn-sub" x="535" y="110">active · no_credit</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="id-headers" aria-labelledby="id-headers-label">
    <rect x="626" y="72" width="118" height="56" rx="10"/>
    <text id="id-headers-label" x="685" y="92">Identity</text>
    <text class="cmn-sub" x="685" y="110">set, then stripped</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="id-auth" aria-labelledby="id-auth-label">
    <rect x="306" y="198" width="150" height="56" rx="10"/>
    <text id="id-auth-label" x="381" y="218">auth-service</text>
    <text class="cmn-sub" x="381" y="236">GET /api-keys/{hash}</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="id-valkeydown" aria-labelledby="id-valkeydown-label">
    <rect x="20" y="198" width="180" height="56" rx="10"/>
    <text id="id-valkeydown-label" x="110" y="218">503 Valkey down</text>
    <text class="cmn-sub" x="110" y="236">refuse, do not guess</text>
  </g>

  <g class="cmn-node cmn-node--danger" id="id-nocreditnode" aria-labelledby="id-nocreditnode-label">
    <rect x="576" y="198" width="168" height="56" rx="10"/>
    <text id="id-nocreditnode-label" x="660" y="218">402 no credit</text>
    <text class="cmn-sub" x="660" y="236">insufficient_balance</text>
  </g>

  <!-- Packets, staggered so resolution reads as a sequence. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M136 100 H164'); --cmn-travel: 0.5s; --cmn-delay: 0.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M290 100 H318'); --cmn-travel: 0.5s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M350 128 V198'); --cmn-travel: 0.6s; --cmn-delay: 1.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M412 198 V128'); --cmn-travel: 0.6s; --cmn-delay: 1.7s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M444 100 H472'); --cmn-travel: 0.5s; --cmn-delay: 2.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M598 100 H626'); --cmn-travel: 0.5s; --cmn-delay: 2.8s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M330 128 V178 H110 V198'); --cmn-travel: 0.7s; --cmn-delay: 3.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M570 128 V160 H660 V198'); --cmn-travel: 0.7s; --cmn-delay: 3.3s;"></circle>

  <!-- Labels last, each on its own plate. -->
  <rect class="cmn-label-plate" x="240" y="156" width="60" height="16" rx="4"/>
  <text class="cmn-label" x="270" y="168">miss</text>
  <rect class="cmn-label-plate" x="424" y="156" width="100" height="16" rx="4"/>
  <text class="cmn-label" x="474" y="168">cached 60 s</text>
  <rect class="cmn-label-plate" x="412" y="52" width="92" height="16" rx="4"/>
  <text class="cmn-label" x="458" y="64">hit or refilled</text>
</svg>
</div>
<figcaption>Hops 1 and 2 are arithmetic — a shape check and a CRC, then SHA-256 — and cost nothing. Hop 3 is
the one network lookup, and the miss beside it is the only path that reaches auth-service; its answer is
written back into the cache for sixty seconds, refusals included. Hops 4 and 5 check the organization and
then set the headers the services downstream trust. The two refusal paths are the only places this step can
end the request.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a request travelling (solid)</span>
  <span><i class="is-accent"></i> headers handed downstream (dashed)</span>
  <span><i></i> a refusal (neutral line, outlined node)</span>
</div>

1. **The key's shape is checked first, with no I/O.** `cmn_` or `cmn_test_`, then 43 base62 characters,
   then a 6-character base62 CRC32 of those 43. A typo, a truncated key or a random string fails here and
   costs nothing — not a cache lookup, not an auth-service call.
2. **SHA-256 of the key becomes the cache key.** The key itself is never stored, in Valkey or anywhere
   else; auth-service keeps only the same hash.
3. **One Valkey lookup: `apikey:{hash}`.** The value is the key id, the organization id, the organization's
   status, the tier, and the key's expiry, space-separated.
4. **On a hit, resolution is over** — no service was called on the request path.
5. **On a miss, auth-service answers `GET /api-keys/{hash}`.** A 404 is cached as the literal `none`, so
   garbage keys cannot hammer auth-service either; a hit is cached for 60 s. Every answer is cached, and it
   is the only cache write on this path.
6. **The organization's status is checked from the cached value.** Anything other than `active` is a
   `DisabledException` → **403** `organization_not_active`. A key past its `expires_at` is a **401**
   `invalid_api_key`, deliberately the same answer as an unknown key.
7. **The credit flag is a second lookup: `no_credit:{org}`.** Present means the prepaid balance is used up
   → **402** `insufficient_quota` / `insufficient_balance`.
8. **The identity headers are set**: `id-organization`, `id-api-key` and `tier` from the key.
   `IdentityHeadersFilter` strips every inbound copy of those and of `Cookie`, `Forwarded`, `X-Forwarded-*`,
   `traceparent`, `tracestate`, `baggage` and `batch-line` first — and the route removes `Authorization`, so
   the key itself never travels past the gateway.

## Why it is like this

**The cheap check comes before the expensive one.** A CRC32 over 43 characters is nanoseconds; a Valkey
round trip is a network hop; auth-service is a hop plus a database read. Ordering them this way means an
attacker with a garbage key never gets past the first line, and an honest caller with a live key usually
gets past the second.

**Hashes are the cache key because the cache is not a secret store.** Valkey holds no credential material —
`apikey:{hash}` maps a hash to ids. Someone reading a Valkey dump learns which keys exist, not what they
are.

**Misses are cached too.** A cache that only remembers successes turns every bogus key into an
auth-service call, which makes the cache a load amplifier rather than a shield. The `none` value costs one
string and closes that hole.

**Sixty seconds is the price of not calling auth-service.** Every request pays up to a minute of staleness:
an organization suspended, closed, or a key revoked has to wait out the TTL unless the delete reaches
Valkey first — which it does for revocation, because auth-service deletes the entry. The alternative,
asking auth-service per request, puts a database read in front of every token and is the thing this design
exists to avoid.

**Valkey down is 503, not 401 — fail closed.** If the lookup cannot be done, the gateway cannot know the
caller is legitimate, and answering 401 would tell a paying customer their key is broken. A 503 with
`Retry-After: 5` says the platform is unwell; an SDK retries it. The flood brake's own bucket in
`RateLimitFilter` fails the other way — **open** — because a Valkey blip must not turn into a total outage
when the real limits are enforced further in.

**402 for no credit, not OpenAI's 429.** OpenAI answers `insufficient_quota` with 429; the OpenAI SDKs
retry 429s, and retrying cannot add credit. 402 is outside the SDKs' retry paths and says what is actually
wrong.

**Expired and revoked are the same 401 on purpose.** A distinct code would tell a caller that a key they
found was once real.

## What would change it

- **A production environment has to refuse `cmn_test_` keys.** Today `ApiKeyFormat` accepts both prefixes;
  the plan is that production refuses the test prefix before any lookup, and today it does not.
- **The cache TTL is the staleness budget.** Shortening it trades auth-service load for faster suspension;
  a suspension that has to bite immediately needs a push to Valkey, not a shorter TTL.
- **`last_used_at` on a key** is not written. It needs either a write on the request path or a throttled
  writer fed by usage events, and neither exists yet.
- **A second resolution path** — an OAuth client, a service account — would need its own filter, because
  `IdentityHeadersFilter` switches on the principal type and only knows a JWT and an API key.

## Where to look

- [`ApiKeyAuthenticationManager.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ApiKeyAuthenticationManager.java)
  — the lookup order, the TTL, the expiry check and the credit flag.
- [`ApiKeyFormat.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/ApiKeyFormat.java)
  — the key's shape and its CRC32, mirrored from auth-service.
- [`IdentityHeadersFilter.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/IdentityHeadersFilter.java)
  — what is stripped, and what is set from the principal.
- [`RateLimitFilter.java`](https://github.com/carmonai/back/blob/main/api/gateway-service/src/main/java/ai/carmonai/gateway/RateLimitFilter.java)
  — the per-caller flood brake, and why it fails open.
- [`Caller.java`](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/Caller.java)
  — the other side of the contract: three headers or a 401.

**Next:** [3 · Admission](admission.md) — the caller is known, and now the request has to earn a share of
the engine before it is allowed near it.
