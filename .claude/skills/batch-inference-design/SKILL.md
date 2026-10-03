---
name: batch-inference-design
description: Distilled system design from the ShowOffer video "Design Batch Inference System" (Anthropic/OpenAI interview question) — requirements, entities, GPU batching math, request flow, batcher scaling, autoscaling, queue-depth load shedding, GPU failure retries. Load when designing or reviewing Carmonai's inference path, together with carmonai-architecture/references/inference-plan.md, which says what changes for real LLM serving.
---

# Batch inference system design (video distillation)

Source: ShowOffer, *Design Batch Inference System – Anthropic & OpenAI System Design Question*, 2026-03-22, 52 min — https://www.youtube.com/watch?v=CYFs6mR--KE. Extracted with the `youtube` skill; the whiteboard frames were checked against the transcript. Summarized in our own words; numbers are the speaker's.

**Caveat before using any of it:** the video works under interview constraints — a GPU runs one batch at a time, a batch takes a fixed ~100 ms whatever its size (1–100), and each request gets one complete answer. Real LLM serving is different: the engine (vLLM, SGLang, TensorRT-LLM) batches continuously at every generated token, answers stream, and GPU memory for the KV cache, not batch size, is the limit. The ideas that carry over (edge backpressure, tier queues, priority shedding, asymmetric autoscaling, retry discipline, no DB on the hot path) and the ones that don't (a hand-written batcher, index demux, fixed latency math) are sorted in [../carmonai-architecture/references/inference-plan.md](../carmonai-architecture/references/inference-plan.md).

## Why batching

One GPU per user is unaffordable: a high-end cloud GPU costs ~US$2–3/hour, so a 10k-user spike is ~US$30k/hour. A GPU runs thousands of small cores at once, so 100 requests in one call cost the same time as 1. Batching is the economics of the product.

## Requirements

| Functional | Non-functional |
|---|---|
| FR1 synchronous contract: client POSTs and waits on the same connection; batching is invisible | NFR1 P95 < 500 ms end to end |
| FR2 requests grouped into batches internally | NFR2 1k RPS at launch, 10k RPS without redesign |
| FR3 tier priority from day one: enterprise > paid > free; free is shed first | NFR3 99.9% availability; a GPU loss degrades cleanly, no silent failures |
| | NFR4 GPU utilization target 70–80%, never 100% |
| | NFR5 backpressure: reject early with 429, never hang |

## Entities and APIs

- **Request**: input, tier, arrival time, deadline (dropped if it waited too long).
- **Batch**: requests sent to a GPU as one unit; assembled internally.
- **GPU worker**: one GPU with a status: idle/healthy, busy with a batch, offline. Drives routing.
- **Response**: output mapped back to the exact connection that sent the request — the core problem.
- Client API: `POST /v1/inference {model, input, params}` → `{request_id, output, latency_ms, queue_wait_ms}`; connection held open, no polling.
- Internal API (batcher → GPU): `POST /internal/batch {batch_id, inputs[]}` → results in the same order. Outputs are matched by **position**, not by request id.

## GPU facts the design rests on (given as constraints)

1. One batch at a time per GPU; anything else waits → a queue and a batcher are needed.
2. Within a batch everything runs in parallel; a batch of 1 wastes ~99% of a 100-slot batch at the same time cost.
3. Output *i* is the answer to input *i*: CUDA lays input *i* in memory slot *i*, and threads run in warps of 32 reading and writing sequential addresses (coalesced). Tagging inputs with ids would force scattered, non-coalesced access, ~10–20× slower. So the GPU sees plain arrays; the CPU-side batcher keeps the index → caller map.

One cycle: ~40 ms assembly + ~5 ms PCIe in + ~100 ms kernel + ~5 ms PCIe out ≈ 150 ms, whatever the batch size.

**Capacity math** (derive it, never assert it): 1000 / 150 ≈ 6.7 batches/s × 100 ≈ 670 req/s per GPU. 1k RPS needs ~1.5 GPUs raw, ~3 at 70% utilization; 10k RPS needs ~28–30. A new GPU takes ~5 min to come up, so the 30% headroom is what absorbs a spike meanwhile.

## Request flow

1. Client POSTs; the server parks the socket on a **future** (a handle resolved later from another code path).
2. Gateway: validate token (401), resolve the tier (stays on the request for life), check the tier's rate limit; queue full → **429 at the edge**, before anything downstream.
3. Enqueue (Redis `RPUSH`) into one of **three queues** — enterprise, paid, free — rather than one queue with a priority field: picking the next item is O(1), no scanning, and free traffic sheds naturally.
4. Batcher pops in priority order with `BRPOPLPUSH` (atomic move into a processing list, so a batcher crash leaves the item recoverable) and flushes at **100 items or 40 ms after the first item**.
5. Batcher snapshots the index map and POSTs the batch to a GPU; the GPU is locked for it.
6. GPU returns `outputs[]`.
7. Batcher resolves `future[i]` with `outputs[i]`; each resolve wakes its parked socket.
8. Client gets `200 {output, latency_ms, queue_wait}`. Happy path ~150–180 ms: queue ~20, batch window ~40, GPU ~100, demux + network ~10 — over 300 ms of headroom under the 500 ms target.
9. Queue-depth zones drive rejections (see deep dive 3).

Components: clients → load balancer → API gateway (auth, tier, 429) → tier queues → request batcher → GPU worker pool → response handler → back down the open connection.

**No database on the hot path.** Nothing outlives the request. Billing, audit and long-window rate limits are asynchronous writes after the response; a synchronous write costs 5–20 ms per request and breaks the latency budget.

## Deep dive 1 — the batcher

- **Park, don't close**: append `(input, future)` to a shared pending buffer and suspend; the HTTP server keeps the socket open. A closed HTTP connection can't be reopened toward the client.
- **Flush on size OR time**: size-only starves quiet hours (the first user at 3 a.m. waits ~20 s for 99 others). 5 ms → tiny batches, higher cost per request; 200 ms → users feel it; 40 ms keeps P95 under target. At 1k RPS batches fill in ~50–100 ms anyway, so the timeout is a quiet-hour safety net, not the steady state.
- **Demux by snapshot**: copy pending inputs and futures into batch-local variables, clear the shared buffer (new arrivals go to the next batch), call the GPU, resolve by position. The minimal correct batcher is a buffer, a flush loop and a map of futures — no Redis, no Kafka on that path.

## Deep dive 2 — scaling batchers without double sends

At ~10k RPS one batcher runs out of CPU/memory. Several batchers on one shared queue can claim the same requests: duplicate GPU work, or crossed futures that hand one user another user's output. Each request must be owned by exactly one batcher when it flushes.

| Option | How | Verdict |
|---|---|---|
| A. Kafka consumer groups | Partition by hash(request id); each partition read by one consumer; heartbeat loss → rebalance reassigns partitions | Production choice when durability and failover matter. Costs Kafka ops, +5–20 ms, pauses during rebalances |
| B. Redis lock per flush window | `SET NX` with ~50 ms TTL; winner flushes, losers wait a cycle | Contention grows with load, windows get missed, tail latency climbs — degrades exactly when needed. Never the primary design |
| C. Partitioned gateway routing | Gateway consistent-hashes the request to one batcher; each batcher owns its own buffer; GPU pool stays shared | Simplest: no shared state, no lock, no queue. Risk: hot spots if a few callers dominate |

A and C combine: route at the gateway, keep Kafka for durability per shard.

## Deep dive 3 — capacity and GPU failure

- **Autoscaling is asymmetric.** Up fast: utilization > 80% for 2 min, or queue depth > 200 → add a GPU. Down slow: utilization < 50% for 10 min, one GPU at a time. Growing queues compound and a cold start is ~5 min, so provision before users notice; aggressive scale-down followed by a spike costs another cold start.
- **Load shedding by queue depth** (reacts faster than utilization and tracks what users feel):
  - green, depth 0–100: accept every tier;
  - yellow, 100–500: throttle free to 50%; this window is when new GPUs get provisioned;
  - red, > 500: free gets 429 immediately, paid throttled proportionally, enterprise fully protected.
  A monitor writes the current zone to a Redis key every few seconds; every gateway instance reads it on its own, with no coordinator.
- **GPU dies mid-batch**: wrap the GPU call in a timeout (~500 ms) → mark the GPU unhealthy → re-queue each request **individually** (spreads the retry over several cycles) with **at most one retry** → a second failure resolves the future with **503**. More retries cause a storm: 100 requests × 3 retries piling onto the surviving GPUs collapses the fleet.

## Follow-ups the video says to be ready for

Why not close the connection and reopen it later? Why 40 ms and not 10? Traffic triples right now — what happens, in order?
