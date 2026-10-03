# Phase 3 progress (real engine on the laptop GPU)

Working log started 2026-10-03. Plan: [inference-plan.md](inference-plan.md) §6, §11 row 3. Rules: `phase-3` branches only; commit and push when green; PRs at the end; never merge or push to `main` without the user's go-ahead.

## Checklist

- [x] Disk: Docker build cache and unused images pruned (user's choice); ~90 GB free inside Docker's disk
- [x] vLLM image pinned: `vllm/vllm-openai:v0.30.0@sha256:8a69ffad015f138d7170c4ddc429e230a3bc1c1719f67e14324749df200a4b90` (≥ 0.26.0 for the security fixes)
- [x] Model pinned: `cyankiwi/Qwen3-4B-Instruct-2507-AWQ-4bit` revision `c46e2277ae3dee7d030f45c58987b291edc5c1d6` (Apache-2.0, `model.safetensors` only, no custom code)
- [x] inference-service: `engine` per model (`llama` | `vllm`); for vLLM set `priority` from tier (trial 20, standard 10, enterprise 0) and `cache_salt` = organization id; Spring profile `gpu` lists both models; IT covers both engines
- [x] `docker/compose.gpu.yaml`: `vllm` service (GPU, shm, HF cache volume, key via `VLLM_API_KEY`, health check, internal only); inference gets `SPRING_PROFILES_ACTIVE=gpu`; `VLLM_API_KEY` in `.env` and `.env.example`
- [x] vLLM boots on the RTX 3050 6 GB and refuses requests without its key
- [x] `smoke.sh` parametrised by model (`MODEL`, `ENGINE`); vLLM run passes incl. a tool call, priority accepted, cancelled stream with measured usage, engine port not published
- [x] `vllm bench serve` on the GPU: throughput, TTFT/ITL at several concurrencies → C and q recorded in the plan (not prices)
- [x] `mvn clean verify` + default (CPU) smoke still green
- [x] Docs: plan progress/deviations, skills, templates
- [x] Commit + push `phase-3` branches, PRs with merge order

## Notes

- vLLM image entrypoint is `["vllm","serve"]`; the container sees the RTX 3050 (5.6 GiB free, compute 8.6).
- `--gpu-memory-utilization 0.85` refused: only 5.03 GiB free at startup (Windows keeps ~1 GB for the desktop). 0.78 works.
- Memory at 0.78 (4.7 GiB): weights 3.29 GiB (embeddings not quantized), CUDA graphs 0.03 GiB, ~0.9 GiB CUDA/WSL overhead, KV cache 0.44 GiB. bf16 KV needs 0.56 GiB for one 4096-token request: refused. `--max-num-batched-tokens 1024` changed nothing (overhead isn't activations).
- `--kv-cache-dtype fp8` fixes it: FlashInfer backend, KV 0.4 GiB = 5,888 tokens, max concurrency 1.44x at 4096 tokens per request. First start downloads 3.3 GiB (~7 min); later starts ~1 min.
- Key enforced through `VLLM_API_KEY`: no key or wrong key → 401, key → 200. Usage includes `prompt_tokens_details.cached_tokens`.
- GPU smoke (`MODEL=carmonai/qwen3-4b ENGINE=vllm`): passes — 17 streamed events, engine idle after hang-up, usage once each, cancelled stream billed for the 94 tokens vLLM reported, tool call returned, port 8000 not published, canary clean. Priority accepted (trial key → 20 on every request).
- One-off: the first GPU smoke run got 503 on register right after vLLM's startup (auth → account `RetryableException`, read timeout 3 s with Argon2 hashing on a busy laptop). Not retried by design (POST). The rerun passed. Watch the account read timeout if it repeats.
- Bench (`vllm bench serve`, openai-chat, random 256 in / 128 out with ignore-eos, 40 prompts, goodput = TTFT ≤ 2 s and TPOT ≤ 100 ms):

  | concurrency | output tok/s | TTFT p95 | TPOT p95 | goodput |
  |---|---|---|---|---|
  | 1 | 46 | 254 ms | 21 ms | 100% |
  | 2 | 88 | 314 ms | 22 ms | 100% |
  | 4 | 157 | 801 ms | 24 ms | 100% |
  | 8 | 159 | 4,033 ms | 24 ms | 10% |

  C = 4 (= `--max-num-seqs`); past it requests only queue (TTFT ~4 s), so the waiting queue must stay short (q ≤ ~2 for a 2 s TTFT). Laptop numbers: they size the prototype's caps, not prices.
