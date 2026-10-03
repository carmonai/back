---
name: carmonai
description: Carmonai project context — product, repo map, what exists vs planned, pending decisions. Load first for any task in this workspace (back/, logo/).
---

# Carmonai

Inference-as-a-Service for Brazil: the first of its kind, B2B, LGPD-friendly. Java 27 microservices. Design goals: scalable, fast, safe, resilient.

## Repo map

- `back/` — root git repo (backend).
  - `api/<name>` — git submodules, one repo per module (`carmonai/<name>` on GitHub).
  - `docker/` — compose files (empty today).
- `logo/` — brand explorations; `python build.py` regenerates `svg/` and `index.html`. Palette: ink `#07182E`, green `#0EA765`, yellow `#FFD23F`.
- `carmonai/` itself is a plain folder, not a repo.

## Status

| Piece | State |
|---|---|
| Core: `account`, `account-service`, `auth`, `auth-service`, `organization`, `organization-service`, `usage`, `usage-service`, `inference-service`, `gateway-service` + Valkey + llama.cpp | accounts and JWT login (2026-10-02); organizations, org-owned API keys (`cmn_test_…`, SHA-256 at rest, Valkey-cached lookup, immediate revocation), `/v1` API-key chain and erasure via organization-service (2026-10-03, inference-plan phase 1). `mvn verify` from `back/`, `docker compose up -d --build --wait` in `back/docker`, then `back/docker/smoke.sh` |
| nginx LB, Redis, Kafka, observability, K8s, CI | later; conventions pre-recorded in `carmonai-architecture/references/platform.md` |
| Inference | plan revision 2 (2026-10-02): `carmonai-architecture/references/inference-plan.md` — phases 0–7, decisions in its §12, review findings in `plan-review-2026-10-02.md`. Approved 2026-10-03. Phase 0 merged (CI green, `CARMONAI_TOKEN` reads the module repos). Phase 1 merged. Phase 2 built 2026-10-03 (inference-service + llama.cpp/Qwen3-0.6B on CPU, usage + usage-service, gateway /v1 route and hardening), PRs pending the token update. Next: phase 3 (vLLM on the laptop GPU). Prototype is local only: laptop RTX 3050 6 GB running `Qwen3-4B-Instruct-2507` (4-bit AWQ), llama.cpp CPU fallback, synthetic data |

## Naming

Root package and groupId: `ai.carmonai`. Service packages: `ai.carmonai.<name>`. Modules: `<name>` (library) and `<name>-service`.
The Insper reference this project follows uses `store` as its namespace; carmonai uses `ai.carmonai` in its place — packages, groupId, compose name, DB, cookies, config keys, JWT issuer.

## Pending decisions

Decided (2026-10-02): an account is a person for now (organization + membership comes later as its own aggregate); no version prefix on console routes, while the inference API is OpenAI-compatible under `/v1`; flat packages; vLLM engine; tiers trial/standard/enterprise, no free tier; prepaid credits; refresh token in an HttpOnly cookie (Bearer access token); explicit org creation; membership checks via organization-service; hosting deferred (local prototype). 2026-10-03: Java 25 LTS; one repo per module stays; all plan §12 recommendations accepted. Open items: plan §12.

Ask the user before assuming any of these:

- Token transport: `Authorization: Bearer` (built that way) or cookie. Logout is not built: with Bearer there is nothing to clear server-side; it needs a cookie or a Redis `jti` denylist.
- Refresh tokens: access tokens last 15 min and there is no refresh flow yet.
- Virtual threads on MVC services (`spring.threads.virtual.enabled`).
- Where libraries are published so services can depend on them (local `mvn install` in CI vs a registry).
- LGPD: data residency and cloud region, consent model, retention periods, prompt/output retention for inference.
- Cloud and CI target (the reference uses AWS/EKS + Jenkins).

## Next

- Design or review a service: `carmonai-architecture`.
- Create a service: `carmonai-new-service`.
- Need a Hands-on page from the Insper reference: `carmonai-handson` (fetches only on demand).
