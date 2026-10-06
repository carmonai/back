# Batch API design

The Batch API is the half-price lane: you upload a JSONL file, every line becomes a chat request, and the
answers come back as two files. It exists to sell capacity interactive traffic is not using, which is why a
line runs at the lowest priority and only while the model is at most half busy.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dbatch-title" aria-describedby="dbatch-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dbatch-title">A file becoming lines, a crash, a re-claim and two output files</title>
  <desc id="dbatch-desc">An uploaded JSONL file is validated in full, then split into one batch_line row per
  request. A worker claims a line with a row lock it holds for the whole call to inference-service. If the
  worker is killed mid-call the lock is released, the line becomes pending again and is claimed a second time.
  The finisher writes the answered lines into an output file, and each line produces one usage event whose id
  is derived from the batch and the line number, so it is billed once however often it runs.</desc>

  <defs>
    <marker id="dbatch-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1-3 the line's life, 4 the crash, 5 the finish, 6 the usage event. -->
  <g id="dbatch-hops">
    <path id="dbatch-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M140 99 H180" marker-end="url(#dbatch-arrow)"/>
    <path id="dbatch-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M310 99 H350" marker-end="url(#dbatch-arrow)"/>
    <path id="dbatch-hop3" class="cmn-link cmn-link--flow cmn-dash"
          d="M480 99 H520" marker-end="url(#dbatch-arrow)"/>
    <path id="dbatch-hop4" class="cmn-link cmn-link--flow"
          d="M585 128 V160 H475 V196" marker-end="url(#dbatch-arrow)"/>
    <path id="dbatch-hop5" class="cmn-link cmn-link--flow"
          d="M400 225 H350" marker-end="url(#dbatch-arrow)"/>
    <path id="dbatch-hop6" class="cmn-link cmn-link--quiet"
          d="M650 128 V268 H95 V254" marker-end="url(#dbatch-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="dbatch-upload"
     aria-labelledby="dbatch-upload-label">
    <rect x="20" y="70" width="120" height="58" rx="10"/>
    <text id="dbatch-upload-label" x="80" y="90">Upload</text>
    <text class="cmn-sub" x="80" y="108">POST /v1/files</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dbatch-lines" aria-labelledby="dbatch-lines-label">
    <rect x="180" y="70" width="130" height="58" rx="10"/>
    <text id="dbatch-lines-label" x="245" y="90">Lines</text>
    <text class="cmn-sub" x="245" y="108">batch_line rows</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dbatch-claim" aria-labelledby="dbatch-claim-label">
    <rect x="350" y="70" width="130" height="58" rx="10"/>
    <text id="dbatch-claim-label" x="415" y="90">Claim</text>
    <text class="cmn-sub" x="415" y="108">SKIP LOCKED</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dbatch-call" aria-labelledby="dbatch-call-label">
    <rect x="520" y="70" width="130" height="58" rx="10"/>
    <text id="dbatch-call-label" x="585" y="90">Call</text>
    <text class="cmn-sub" x="585" y="108">inference</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dbatch-reclaim" aria-labelledby="dbatch-reclaim-label">
    <rect x="400" y="196" width="150" height="58" rx="10"/>
    <text id="dbatch-reclaim-label" x="475" y="216">Re-claim</text>
    <text class="cmn-sub" x="475" y="234">lock released</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dbatch-output" aria-labelledby="dbatch-output-label">
    <rect x="200" y="196" width="150" height="58" rx="10"/>
    <text id="dbatch-output-label" x="275" y="216">Output file</text>
    <text class="cmn-sub" x="275" y="234">done + failed</text>
  </g>

  <g class="cmn-node cmn-node--money" id="dbatch-billed" aria-labelledby="dbatch-billed-label">
    <rect x="20" y="196" width="150" height="58" rx="10"/>
    <text id="dbatch-billed-label" x="95" y="216">Billed once</text>
    <text class="cmn-sub" x="95" y="234">batch + line UUID</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M140 99 H180'); --cmn-travel: 0.5s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M310 99 H350'); --cmn-travel: 0.5s; --cmn-delay: 0.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M480 99 H520'); --cmn-travel: 0.5s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M585 128 V160 H475 V196'); --cmn-travel: 1.3s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M400 225 H350'); --cmn-travel: 0.5s; --cmn-delay: 1.1s;"></circle>
  <circle class="cmn-packet cmn-packet--money cmn-travel" r="4"
          style="offset-path: path('M650 128 V268 H95 V254'); --cmn-travel: 2.2s; --cmn-delay: 1.4s;"></circle>

  <rect class="cmn-label-plate" x="104" y="50" width="88" height="16" rx="4"/>
  <text class="cmn-label" x="148" y="62">the 4 MB cap</text>
  <rect class="cmn-label-plate" x="288" y="50" width="86" height="16" rx="4"/>
  <text class="cmn-label" x="331" y="62">one row a line</text>
  <rect class="cmn-label-plate" x="500" y="50" width="74" height="16" rx="4"/>
  <text class="cmn-label" x="537" y="62">lock as lease</text>
  <rect class="cmn-label-plate" x="540" y="138" width="66" height="16" rx="4"/>
  <text class="cmn-label" x="573" y="150">SIGKILL</text>
  <rect class="cmn-label-plate" x="356" y="176" width="52" height="16" rx="4"/>
  <text class="cmn-label" x="382" y="188">writes</text>
  <rect class="cmn-label-plate" x="300" y="260" width="160" height="16" rx="4"/>
  <text class="cmn-label" x="380" y="272">one usage event</text>
</svg>
</div>
<figcaption>Steps 1 and 2 upload the file and turn it into `batch_line` rows; step 3 is a worker claiming one
with `FOR UPDATE SKIP LOCKED` and holding that row lock for the whole call. Step 4 is a `SIGKILL` mid-call: the
connection closes, the transaction rolls back, and the line is claimable again — no lease to time out, no
reaper. Step 5 is the finisher writing the result files, and step 6 is the line's usage event, whose id comes
from the batch and the line number, so the second run of a cut line bills once.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a step in a line's life (solid)</span>
  <span><i class="is-money"></i> the usage event that bills it (dashed, gold)</span>
  <span><i class="is-accent"></i> the call into the inference service (teal outline)</span>
</div>

1. **`POST /v1/files`** stores the uploaded content and returns an id; the body must be under the gateway's
   4 MB `/v1` cap, and the file expires after 30 days.
2. **`POST /v1/batches` validates the whole file** before anything is written — every line is parsed, and a
   problem is a 400 naming the line number.
3. **The file becomes `batch_line` rows**, one per non-empty line, in one transaction with the batch row.
4. **A worker claims one line** with `FOR UPDATE SKIP LOCKED` and keeps that transaction open across the call
   to inference-service. The row lock *is* the lease.
5. **A `SIGKILL` mid-call costs nothing but the work.** PostgreSQL rolls the transaction back, the line is
   `pending` again, and the next pass claims it.
6. **The finisher completes the batch** once no line is pending, dropping the lines of a cancelled batch and
   failing the lines of an expired one, then writes `{batch}_output.jsonl` and `{batch}_error.jsonl` in input
   order.
7. **Each line produces one usage event**, carrying the batch's creation instant as `started_at` and an id
   derived from `(batch, line)` — so the partitioned primary key catches a re-run and the line is billed once.

## What it is

Six endpoints behind the gateway's API-key chain and a worker pool behind them: `POST /v1/files` (multipart,
`purpose` must be `batch`), `GET /v1/files/{id}/content`, `DELETE /v1/files/{id}`, `POST /v1/batches`,
`GET /v1/batches/{id}` and `POST /v1/batches/{id}/cancel`. Every read and write is scoped to the organization
that owns the row, so another organization's id answers **404**, as if it did not exist — the smoke test
asserts that for both a batch and its output file.

## Validate the whole file up front

`BatchService.lines()` walks the content once and refuses the batch unless every line is well formed:
`custom_id` non-empty, at most 512 characters and unique within the file; `method` exactly `POST` and `url`
exactly `/v1/chat/completions`; `body` a JSON object with a `model`; **one model for the whole batch**; at most
**50,000** lines; and `completion_window` exactly `24h`. Streaming is not an option for a batch line, so the
body is normalised on the way in — `stream` set to `false`, `stream_options` removed.

The error message is the design decision. OpenAI accepts a file into a `validating` state and fails the batch
asynchronously; this API refuses at creation, with the line number in the message: *Line 7: custom_id must be a
unique, non-empty string.* That is actionable in a way that `failed` after four minutes is not, and it costs
one pass over a file already in memory.

## A worker claims a line and holds the lock for the call

The claim is `SELECT … WHERE l.status = 'pending' AND b.status = 'in_progress' AND b.expires_at > now()
ORDER BY b.created_at, l.batch_id, l.line LIMIT 1 FOR UPDATE OF l SKIP LOCKED`, run inside a transaction that
stays open for the call. Ordering by the batch's creation time first runs batches roughly in the order they
arrived, and `SKIP LOCKED` lets the second worker take the next line instead of blocking on the first.

`carmonai.batch.workers: 2` and `poll-every: 500ms`: two lines in flight per instance, an idle worker looking
twice a second. Because each worker holds a connection for the whole call, the pool is sized from that fact
rather than from a throughput estimate — `maximum-pool-size: 10`, with the comment *"each worker holds one for
its whole call: keep above workers + 4"*.

The call goes to `carmonai.batch.inference-url` (`http://inference:8080`) with the batch's stored identity —
`id-organization`, `id-api-key`, `tier`, and `batch-line: {batchId} {line} {batchCreatedAt}` — and an
11-minute client timeout, deliberately above inference-service's own 10-minute ceiling for a non-streamed
answer. The `batch-line` marker is what makes the line run at vLLM priority 30 and at batch prices, and a
client cannot forge it: the gateway strips the header, and the smoke test sends `batch-line: forged` and
asserts the request is served as an ordinary one.

## Outcomes, per status

| Response | What happens |
|---|---|
| `200` | the line is `done`, the answer stored as its output-file line |
| another `4xx` | the line is `failed` with the engine's answer, and goes to the error file |
| `429`, `402`, `503` | **rollback**: the line stays `pending`, unchanged, and the worker backs off |
| `5xx`, or unreachable | retried up to `MAX_ATTEMPTS = 3`, then `failed` |

`429`, `402` and `503` are not the line's fault — the model was busy, the organization has no credit, the relay
was unavailable — so the transaction is rolled back and the line is exactly as it was, `attempts` included. The
back-off honours what the server asked for, from `retry-after-ms` or `retry-after`, clamped to
`Math.clamp(millis, 100, 5000)` so a misconfigured header cannot park a worker for an hour or spin it.

## Billed once, however often a line runs

Two things have to agree. **The event id is a function of the line**:
`UUID.nameUUIDFromBytes(("batch " + batchId + " " + line).getBytes(UTF_8))` — a name-based UUID, so the same
batch and line produce the same id on any instance, after any restart. (Version 3, MD5-based, rather than the
v5 variant the plan named; both are name-based and the progress note records it.) **And `started_at` is the
batch's creation time**, not the moment the line ran — which matters because `usage_event`'s primary key is
`(event_id, started_at)` and it is partitioned by day on `started_at`. Both halves are stable, so a resend
lands in the same partition, hits the same primary key, and `ON CONFLICT DO NOTHING` makes it a no-op.

Only the run that answered reports: a line cut short by a crash reports no usage at all, so the partial run is
never billed and the answer is never free. That was a fix, not the original design — the first version billed
the partial run and gave the answer away, which is what killing batch-service mid-call found.

## What a SIGKILL proved

`docker/batch-bench.sh` creates a 10,000-line batch with ten deliberately slow lines just past the middle,
starts an enterprise worker and a trial worker alongside it, and halfway through kills batch-service while a
worker holds one of those lines. Finding the held line is done with the mechanism under test: `held_slow()`
counts pending slow lines and subtracts the ones a `SELECT … FOR UPDATE SKIP LOCKED` can see — exactly the set
nobody is holding — and the kill is issued only when that count is positive.

On the RTX 3050: **10,000 lines in 999 seconds, 10.0 lines/s**, with usage-service holding exactly 10,000
events, 10,000 distinct ids, and every one of them the run that answered. Beside it the enterprise worker kept
100 % goodput at TTFT p95 80 ms. The logs recorded the cut line as `batch … line … cut short`, and the pass mark
is that the count is greater than zero — a bench that never managed to interrupt anything proves nothing.

## The finisher

`BatchFinisher.finish()` runs every `carmonai.batch.finish-every` (2 s). For each running batch it takes the
batch row with `FOR UPDATE SKIP LOCKED` — one finisher at a time — and asks what it needs: `cancelling`,
`expired` (past `expires_at`), or `in_progress`. A `cancelling` batch has its pending lines **deleted**; an
`expired` one has them **failed** with a `batch_expired` line in the error file; lines currently being run are
locked and skipped by both statements, so they finish normally. If anything is still pending the finisher
returns and tries again next tick. Otherwise it writes the output and error files —
`string_agg(result, E'\n' ORDER BY line)` into a new `file` row, so a large result never passes through the
JVM — stores the counts, sets the final status and `finished_at`, and deletes the lines, all in one transaction.

Two more sweeps live in the same class. `expireFiles()` (cron `0 17 * * * *`) deletes files past their 30 days.
`eraseClosed()` runs every `carmonai.batch.erase-every` (1 minute; 5 s in compose), asks organization-service's
`tenant(id)` about every organization that still has batch data here, and erases the `closed` ones: their files
go immediately and their running batches are marked `cancelling` with `erase = true`, so the finisher ends them
**without** writing output or error files. Only an explicit `closed` erases anything — a 404 keeps the data,
because a misrouted URL answering 404 must not wipe everyone's files.

## The 4 MB cap, and why it exists

`V1RequestFilter` in the gateway caps every `/v1` body at **4 MB**, requires a `Content-Length` and refuses
`Transfer-Encoding` outright; batch-service sets `spring.servlet.multipart.max-file-size: 4MB` as well and
answers 413 `file_too_large` if reached anyway. The cap is not about the Batch API — it is the `/v1` body limit
that protects the chat path from a request that cannot fit a context window, applied to a route that reuses the
same prefix.

**OpenAI allows 200 MB**, and that is a real gap. It is also why file content is `bytea` in the `batch` schema
rather than in object storage: the migration's own `ponytail:` comment names object storage as the upgrade
"when files outgrow the gateway's 4 MB body cap". At 4 MB a JSONL of small chat requests is roughly 10,000 to
20,000 lines, so the 50,000-line cap is the one that never binds in practice.

## Differences from OpenAI's Batch API

| | OpenAI | Carmonai |
|---|---|---|
| Upload size | 200 MB | 4 MB (the gateway's `/v1` body cap) |
| Validation | asynchronous: `validating` → `failed` | synchronous: a 400 naming the line |
| List endpoints, `metadata` | supported | not built |
| Models per batch | not restricted | one, enforced at creation |
| Completion window | `24h` and longer | `24h` only |
| File lifetime | until deleted | 30 days, then deleted by a sweep |
| Order a line runs in | not visible | vLLM priority 30, only while the model is half idle |

The last row is the one that matters commercially. A batch line is admitted through the same `Admission` code
as an interactive request, but it skips the organization's rate buckets and in-flight cap and is capped at the
trial share of the model's slots instead. It fills idle capacity; it does not compete for busy capacity, and it
is the first traffic refused when the model is busy. The 50 % discount is its own `price` rows, `mode = 'batch'`.

## Why it is like this

**The row lock as the lease.** The alternative — a `claimed_at` column, a worker id and a reaper that returns
stale claims — is three mechanisms where this is none, and every one of them can be wrong. A lock cannot go
stale: it is released by a commit, a rollback, or the connection dying.

**Validate on create, not on run.** A batch is a file whose whole value is that it finishes. Refusing it up
front saves a customer from discovering line 9,731 was malformed after an hour of GPU time.

**Content in Postgres, and an 11-minute client timeout.** `bytea` in a table that is already there needs no new
infrastructure, no credentials and no lifecycle policy. The timeout sits above inference-service's own 600 s
ceiling because a timeout that fired first would abandon a call whose answer was still coming.

## What would change it

- **Object storage.** The upgrade for the 4 MB cap, blocked on the hosting decision.
- **More workers.** The claim query is already correct across instances; what changes is the pool sizing and
  inference-service's own batch share of the model.
- **Fairness between batches.** Run order is the batch's creation time, globally, so one organization with a
  large batch delays another's.
- **A revoked key stopping a running batch.** A batch runs with the identity recorded at creation; only credit
  is checked per line. Closing the organization does stop it, through the erasure sweep.
- **`GET /v1/files` and `/v1/batches` listings.** Not built; a caller has to keep its own ids.

## Where to look

- [BatchService.java](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchService.java)
  — upload, the line-by-line validation and the errors it produces.
- [BatchWorker.java](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchWorker.java)
  — the claim, the held transaction, the per-status outcomes and the back-off clamp.
- [BatchRepository.java](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchRepository.java)
  — `claim()`, `writeFile()` and the sweep queries, in SQL.
- [BatchFinisher.java](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchFinisher.java)
  — completing, cancelling, expiring and erasing, plus the 30-day file sweep.
- [batch-bench.sh](https://github.com/carmonai/back/blob/main/docker/batch-bench.sh) — the exit check,
  including the kill and the usage-event count.
