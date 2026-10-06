# Batch

## What it is

`batch-service` implements OpenAI's Files and Batch API: you upload a JSONL file, create a batch, and poll it
until it finishes, then read an output file and an error file. It is the cheap lane — half the synchronous
price — and it runs only on capacity the interactive tiers are not using.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="batch-title" aria-describedby="batch-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="batch-title">A batch file becoming answers, with the row lock as the lease</title>
  <desc id="batch-desc">A file is uploaded and stored, validated as a whole, then split into lines. Two workers
  claim a line each by holding its database row lock for the whole call to inference-service; the answer and
  any error are written out by the finisher when the batch ends.</desc>

  <defs>
    <marker id="batch-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
            orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>

  <!-- Hop order: upload, validate, claim, call, finish. -->
  <g id="batch-hops">
    <path id="batch-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M126 92 H164" marker-end="url(#batch-arrow-flow)"/>
    <path id="batch-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M300 92 H338" marker-end="url(#batch-arrow-flow)"/>
    <path id="batch-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M476 74 V48 H522" marker-end="url(#batch-arrow-flow)"/>
    <path id="batch-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M476 110 V136 H522" marker-end="url(#batch-arrow-flow)"/>
    <path id="batch-hop5" class="cmn-link cmn-link--accent cmn-dash" d="M636 92 H676" marker-end="url(#batch-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="batch-client" aria-labelledby="batch-client-l">
    <rect x="14" y="68" width="112" height="48" rx="10"/>
    <text id="batch-client-l" x="70" y="88">Client</text>
    <text class="cmn-sub" x="70" y="104">uploads JSONL</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="batch-file" aria-labelledby="batch-file-l">
    <rect x="164" y="68" width="136" height="48" rx="10"/>
    <text id="batch-file-l" x="232" y="88">File</text>
    <text class="cmn-sub" x="232" y="104">validated whole</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="batch-lines" aria-labelledby="batch-lines-l">
    <rect x="338" y="68" width="138" height="48" rx="10"/>
    <text id="batch-lines-l" x="407" y="88">Lines</text>
    <text class="cmn-sub" x="407" y="104">one row each</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="batch-worker-a" aria-labelledby="batch-worker-a-l">
    <rect x="522" y="26" width="114" height="44" rx="10"/>
    <text id="batch-worker-a-l" x="579" y="44">Worker</text>
    <text class="cmn-sub" x="579" y="59">holds the lock</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="batch-worker-b" aria-labelledby="batch-worker-b-l">
    <rect x="522" y="114" width="114" height="44" rx="10"/>
    <text id="batch-worker-b-l" x="579" y="132">Worker</text>
    <text class="cmn-sub" x="579" y="147">the other line</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="batch-out" aria-labelledby="batch-out-l">
    <rect x="676" y="68" width="72" height="48" rx="10"/>
    <text id="batch-out-l" x="712" y="88">Output</text>
    <text class="cmn-sub" x="712" y="104">+ errors</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="batch-inference" aria-labelledby="batch-inference-l">
    <rect x="522" y="196" width="200" height="48" rx="10"/>
    <text id="batch-inference-l" x="622" y="216">inference-service</text>
    <text class="cmn-sub" x="622" y="232">priority 30, half price</text>
  </g>
  <path id="batch-hop6" class="cmn-link cmn-link--quiet" d="M579 158 V196" marker-end="url(#batch-arrow-flow)"/>
  <path id="batch-hop7" class="cmn-link cmn-link--quiet" d="M640 196 V158"/>

  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M126 92 H164'); --cmn-travel: 1.1s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M300 92 H338'); --cmn-travel: 1.1s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M476 74 V48 H522'); --cmn-travel: 1.3s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M476 110 V136 H522'); --cmn-travel: 1.3s; --cmn-delay: 0.8s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="5"
          style="offset-path: path('M636 92 H676'); --cmn-travel: 1.2s; --cmn-delay: 1.2s;"></circle>

  <rect class="cmn-label-plate" x="452" y="176" width="112" height="16" rx="4"/>
  <text class="cmn-label" x="508" y="188">one line at a time</text>
  <rect class="cmn-label-plate" x="150" y="46" width="164" height="16" rx="4"/>
  <text class="cmn-label" x="232" y="58">stored in Postgres</text>
  <rect class="cmn-label-plate" x="486" y="248" width="136" height="16" rx="4"/>
  <text class="cmn-label" x="554" y="260">admitted on spare capacity</text>
</svg>
</div>
<figcaption>Step 1 stores the file; step 2 validates it as a whole and splits it into lines; step 3 has each
worker claim one line by holding that row's lock; step 4 runs the line through inference-service at the batch
price; step 5 writes the output and error files when the batch ends.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a line moving through the batch lane (solid)</span>
  <span><i class="is-accent"></i> the finished output (dashed)</span>
  <span><i class="is-async"></i> the call into inference (dotted)</span>
</div>

1. **You upload a file** to `POST /v1/files` with `purpose=batch`. It is stored as bytes and expires after
   30 days.
2. **You create a batch**, and the file is validated then and there: unique `custom_id`s, every line a POST to
   `/v1/chat/completions`, one model, at most 50,000 lines, and a 24-hour window. A bad line is a `400` that
   names it.
3. **Workers claim lines** — two of them, one line each — by taking that row's lock and holding it for the
   whole call.
4. **Each line runs** through `inference-service` with the batch's identity and a `batch-line` marker, which
   means priority 30, no rate buckets, and admission only while the model is at most half busy.
5. **The finisher ends it** and writes the output and error files.

## Why it is like this

**The row lock is the lease.** A worker holds the line's lock for the entire call rather than writing a
heartbeat or a claim timestamp. If the worker dies, the transaction dies with it and the line simply becomes
claimable again — no reaper, no timeout to tune, no stale-lease window. The cost is that a line's transaction
stays open for as long as an inference call takes, which is why there are two workers and not fifty.

**A line is billed once, for the run that answered.** The line's usage event id is a name-based UUID of
(batch, line) and its `started_at` is the batch's creation time, so usage-service's primary key
`(event_id, started_at)` makes a re-run idempotent. A run that fails or is cut short reports nothing, so the
re-run is what gets billed. `docker/batch-bench.sh` proved this by `SIGKILL`-ing the service mid-call: the cut
line ran again and usage held exactly 10,000 events.

**A 429 is not a failure.** When a line meets a full engine it is a `429`, `402` or `503`, and the line goes
back to `pending` with a backoff. Only other `4xx` answers fail the line, because those are the engine's
judgement on the request itself; a `5xx` is retried up to three times.

**Files live in Postgres.** They are `bytea` rows, capped at 4 MB because that is the gateway's `/v1` body
limit. OpenAI allows 200 MB. Object storage is the fix and it waits on the hosting decision.

## What would change it

| Ceiling | Would change if |
|---|---|
| Files capped at 4 MB, in Postgres | object storage arrives, and the gateway's `/v1` body cap is raised per route |
| Two workers, one line each | per-line transaction cost drops (no lock held across the call) or throughput matters more than crash-simplicity |
| Lines take only idle capacity (trial's share), FIFO across batches | one organization's batch starves another's — there is no fairness between batches yet |
| No per-line rate buckets | batch traffic ever needed to be limited for a tenant's own good |
| Validation is synchronous at create | a 50,000-line file's validation becomes slow enough to need OpenAI's asynchronous `validating` state |

## Where to look

- [`BatchWorker.java`](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchWorker.java) — the claim, the call, the outcome per status.
- [`BatchService.java`](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchService.java) — the up-front validation and the batch lifecycle.
- [`BatchFinisher.java`](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchFinisher.java) — completing, cancelling, expiring, and writing the output files.
- [`BatchRepository.java`](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchRepository.java) — `FOR UPDATE SKIP LOCKED`, which is the whole lease mechanism.
- [Batch API design](../operations/batch-api.md) — the same design argued against OpenAI's, with the exit-check numbers.
