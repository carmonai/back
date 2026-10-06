# Status: which document to trust

This project keeps its working notes in the repository, and some of them are **behind the code**. That is
normal for a fast-moving prototype and it is worth stating plainly, because a reader who trusts the wrong
document will believe something false about the system.

Two rules settle every conflict, and both are the project's own:

1. **When a note and the repository disagree, the repository wins.**
2. **When two notes disagree, the one with the newer dated block wins**, and the code settles what remains.

## Current

| Document | What it holds |
|---|---|
| [`inference-plan.md`](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/inference-plan.md) | The plan itself, plus a block at the top, **newest first**, recording every change and its deliberate deviations. This is the project's single best engineering record. |
| [`observability.md`](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/observability.md) | The SLIs, SLOs, metric contract, dashboards and alerts, written with the Prometheus/Grafana work. |
| The phase logs — `phase-2-progress.md` … `phase-7-progress.md`, `revenue-leaks-progress.md` | One working log per phase: the checklist, the decisions to keep consistent, and everything found on the way. |
| [`templates.md`](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-new-service/references/templates.md) | The service template **and the pitfalls list** — the place to look before debugging anything. |
| `.github/workflows/` | What CI actually does. Read the workflow, not a description of it. |

## Behind, and by how much

| Document | State |
|---|---|
| `.claude/skills/carmonai/SKILL.md` | **Stale.** It still describes observability as "later" and says there is no refresh flow, which phase 7a part 2 built. Treat its status table as history. |
| `plan-review-2026-10-02.md` | **A snapshot, not a status.** It is the review that produced the ranked gaps. Its findings are the *input* to the work; the plan's top block says what happened to them. |
| The handoff | **Behind by one pass.** It was written at the end of phase 7a, so its gaps list still shows the fairness work and the instant 429 as open — both were built later. It also contradicts itself on whether the demo console's pull request is merged. It is not kept in this repository. |

## Why this page exists

Three specific claims were carried into early drafts of this site from summaries rather than from the code,
and all three were wrong:

- *"The gateway's flood brake is per-replica, in memory."* It is not. The bucket is one Lua round trip in
  Valkey, shared by every replica; the in-memory bucket survives only on the fail-open path taken when Valkey
  itself is unreachable. See [the gateway](../services/gateway.md).
- *"There is no observability."* There is: recording rules, seven alert rules and three provisioned
  dashboards. What is missing is the alerting *destination*. See
  [observability](../operations/observability.md) and [known gaps](gaps.md).
- *"The customer money endpoints still need gateway routes."* They have them. See
  [the gateway](../services/gateway.md).

Each of those was true at some point and stopped being true when the code changed. That is the failure mode
this page is meant to prevent: a note that was accurate when written, read later as if it still were.

## The habit that avoids it

Before repeating a claim from any note, open the file it describes. The repository is small enough that this
costs a minute, and every page on this site was written that way — which is how the three errors above were
caught instead of published.
