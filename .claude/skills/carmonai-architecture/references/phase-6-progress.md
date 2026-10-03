# Phase 6 progress (Batch API)

Working log started 2026-10-03. Plan: [inference-plan.md](inference-plan.md) §1 (batch at the lowest priority), §4 (File, BatchJob), §7 (batch: priority 30, smallest cap, backs off on 429), §11 row 6; revision-1 models: File `id · org · purpose(batch) · bytes · storage_key · expires_at` (customer data, ≤ 30 days), BatchJob `id · org · model · input_file · output_file · status(validating|in_progress|completed|failed|expired|cancelled) · counts(total|completed|failed) · window(24h) · created_at · completed_at`. Rules: `phase-6` branches only (`batch-service` new, `inference-service`, `gateway-service`, `billing-service`, `back`); commit and push when green; PRs at the end; never merge without the user's go-ahead. The new repo `batch-service` must be added to `CARMONAI_TOKEN` by the user.

## Checklist

- [x] Repo `batch-service` created, submodule added, `phase-6` branches
- [x] batch-service: files (upload, get, content, delete; 30-day expiry), batches (create with validation, get, cancel), worker, finisher; IT
- [x] inference-service: `batch-line` header → priority 30, no rate buckets, credit check, batch share of the model, mode `batch`, event id per (batch, line), started_at = batch creation; IT
- [x] gateway: routes `/v1/files…`, `/v1/batches…` → batch-service; strip `batch-line` from clients
- [x] billing-service: batch prices (half of sync)
- [x] compose: `batch` service
- [x] smoke: upload → batch → completed with 2 answers and 1 failed line; usage `mode=batch`; another org gets 404; file delete
- [ ] GPU exit check (`docker/batch-bench.sh`): 10k-line JSONL completes while interactive SLOs hold; batch-service restarted mid-run, every line billed once
- [ ] `mvn clean verify` + CPU smoke green; logs clean
- [ ] Docs: plan progress/deviations, skills, templates
- [ ] Commit + push, PRs

## Design decisions (keep consistent when resuming)

- **batch-service** (new; MVC + plain JDBC, schema `batch`). OpenAI-compatible routes through the gateway's API-key chain: `POST /v1/files` (multipart `file` + `purpose=batch`), `GET /v1/files/{id}`, `GET /v1/files/{id}/content`, `DELETE /v1/files/{id}`, `POST /v1/batches`, `GET /v1/batches/{id}`, `POST /v1/batches/{id}/cancel`. Everything scoped to the caller's organization (another org's id → 404). No library: no Java caller. List endpoints and `metadata`: later.
- **Files in Postgres `bytea`** (ponytail: object storage when files outgrow the gateway's 4 MB `/v1` body cap or hosting is decided). Content is customer data: deleted on `DELETE`, expires 30 days after upload (hourly job), never logged.
- **Create validates synchronously** (400 instead of OpenAI's async `validating` → `failed`): JSONL, 1–50,000 lines, each `{custom_id (unique), method POST, url = endpoint, body {model, …}}`, one model for all lines, endpoint `/v1/chat/completions` only, `completion_window` `24h`. Lines are copied into `batch_line` (body with `stream: false`), the batch starts `in_progress` at once.
- **Worker**: `carmonai.batch.workers` virtual threads; each claims one pending line of an in-progress, unexpired batch (oldest batch first) `FOR UPDATE SKIP LOCKED` and keeps the row lock for the call: the lock is the lease, so a crash re-dispatches the line, which still bills once (below). Calls inference-service directly with the batch's identity headers plus `batch-line`. 200 → done; 429/402/503 → roll back, sleep `retry-after-ms` (≤ 5 s); other 4xx → failed with the engine's answer; 5xx or no answer → attempt + 1, failed after 3.
- **Finisher** (every 2 s): in-progress batch with no pending line → `completed`; `cancelling` → unlocked pending lines dropped, `cancelled` when none is left; past `expires_at` → unlocked pending lines failed `batch_expired`, `expired` when none is left. Finalizing writes the output file (done lines, input order, OpenAI's line shape) and the error file (failed lines), stores the counts and deletes the lines, in one transaction. Counts of a running batch are counted on read.
- **inference-service** reads `batch-line: {batchId} {line} {batchCreatedAt}` (internal only; the gateway strips it from clients, or a client could buy sync answers at batch prices). For a batch line: vLLM priority 30; no rate buckets (the worker and the cap pace it); `no_credit:{org}` checked here because internal calls never pass the gateway's 402 (Valkey error → 503 so the worker backs off); admitted only while the model's in-flight count is under the trial share (`max(1, C/2)`), and not counted against the organization's own cap; usage event `mode=batch`, `event_id` = name-based UUID of (batch, line) (`UUID.nameUUIDFromBytes`, v3, stdlib, instead of v5), `started_at` = the batch's creation time, so a re-dispatched line hits the same primary key in usage-service and bills once. Error events of batch lines are not reported: they aren't billed, and one would take the event id before the retry's `ok`.
- **Batch prices** half of sync (OpenAI's batch discount), seeded by a billing-service migration that switches the future-only trigger off for that one insert.

## Notes

- Tests: batch-service `BatchServiceIT` 6 (real Postgres, stub inference: output/error files, 429 back-off re-runs the same line, cancel lets running lines finish, expiry fails the lines not run, invalid files → 400, another org → 404, delete); inference-service IT 14 (+2: batch priority 30, no buckets, one event id and start per line; 402 without credit, failed line not reported, malformed header 400); billing-service IT 7 (+1: batch at half price, trigger back on after the seed).
- CPU and GPU smoke pass with the batch section (3 lines → 2 answered + 1 failed at 400, usage `mode=batch` × 2, other org 404, delete, forged `batch-line` stripped by the gateway).
- Smoke found: the enterprise org of the admission section had no credit; on the slower GPU run its first chat was billed before the batch section, so it was flagged and got 402. It now gets a grant like the main org.
- `curl -F "file=@/tmp/…"` from Git Bash on Windows can't open the MSYS path (curl exit 26); the smoke sends the file on stdin (`file=@-;filename=…`), which works everywhere.
- Building one service with `mvn -pl <service>` needs `-am` (or a prior `install`) for the `ai.carmonai` libraries it uses.
