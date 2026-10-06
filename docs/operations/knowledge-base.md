# Knowledge base

The repository carries its own working notes in `.claude/skills/` — a set of skills an agent (or a person)
loads before touching a service. They are not customer documentation and not a specification: they are the
project's memory of what it decided, what it built and what it has not. This page is the index, and the rule
for trusting them.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dkb-title" aria-describedby="dkb-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dkb-title">The knowledge base, and what defers to what</title>
  <desc id="dkb-desc">Four skills across the top: carmonai holds the status and the pending decisions,
  carmonai-architecture holds the rules and the inference plan, carmonai-new-service holds the templates and
  the pitfalls, and batch-inference-design holds the video notes the plan came from. Below them sit the files
  they point at: templates, the phase logs, the inference plan and the plan review. The handoff document
  summarizes everything, and a dotted line runs from it to the repository, which wins whenever the notes and
  the code disagree.</desc>

  <defs>
    <marker id="dkb-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1-2 how the skills point at each other, 3 the handoff,
       4-5 the two reference sets, 6-7 inside the plan's set, 8 the repository. -->
  <g id="dkb-hops">
    <path id="dkb-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M146 62 H166" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M346 62 H366" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop3" class="cmn-link cmn-link--flow"
          d="M71 90 V224" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop4" class="cmn-link cmn-link--flow"
          d="M651 90 V112 H511 V134" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop5" class="cmn-link cmn-link--flow"
          d="M456 90 V124 H171 V134" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop6" class="cmn-link cmn-link--flow"
          d="M436 160 H416" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop7" class="cmn-link cmn-link--flow"
          d="M586 160 H606" marker-end="url(#dkb-arrow-flow)"/>
    <path id="dkb-hop8" class="cmn-link cmn-link--quiet"
          d="M176 248 H596" marker-end="url(#dkb-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="dkb-carmonai" aria-labelledby="dkb-carmonai-label">
    <rect x="16" y="34" width="130" height="56" rx="10"/>
    <text id="dkb-carmonai-label" x="81" y="54">carmonai</text>
    <text class="cmn-sub" x="81" y="72">status, decisions</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dkb-architecture" aria-labelledby="dkb-architecture-label">
    <rect x="166" y="34" width="180" height="56" rx="10"/>
    <text id="dkb-architecture-label" x="256" y="54">carmonai-architecture</text>
    <text class="cmn-sub" x="256" y="72">rules and the plan</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dkb-newservice" aria-labelledby="dkb-newservice-label">
    <rect x="366" y="34" width="180" height="56" rx="10"/>
    <text id="dkb-newservice-label" x="456" y="54">carmonai-new-service</text>
    <text class="cmn-sub" x="456" y="72">scaffold and pitfalls</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dkb-batchdesign" aria-labelledby="dkb-batchdesign-label">
    <rect x="566" y="34" width="170" height="56" rx="10"/>
    <text id="dkb-batchdesign-label" x="651" y="54">batch-inference</text>
    <text class="cmn-sub" x="651" y="72">the video notes</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dkb-templates" aria-labelledby="dkb-templates-label">
    <rect x="96" y="134" width="150" height="52" rx="10"/>
    <text id="dkb-templates-label" x="171" y="152">templates.md</text>
    <text class="cmn-sub" x="171" y="169">copy-paste</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dkb-phases" aria-labelledby="dkb-phases-label">
    <rect x="266" y="134" width="150" height="52" rx="10"/>
    <text id="dkb-phases-label" x="341" y="152">phase logs</text>
    <text class="cmn-sub" x="341" y="169">2 · 3 · 4 · 5 · 6 · 7</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dkb-plan" aria-labelledby="dkb-plan-label">
    <rect x="436" y="134" width="150" height="52" rx="10"/>
    <text id="dkb-plan-label" x="511" y="152">inference-plan</text>
    <text class="cmn-sub" x="511" y="169">phases, decisions</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dkb-review" aria-labelledby="dkb-review-label">
    <rect x="606" y="134" width="140" height="52" rx="10"/>
    <text id="dkb-review-label" x="676" y="152">plan-review</text>
    <text class="cmn-sub" x="676" y="169">ranked the gaps</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dkb-handoff" aria-labelledby="dkb-handoff-label">
    <rect x="16" y="224" width="160" height="48" rx="10"/>
    <text id="dkb-handoff-label" x="96" y="241">The handoff</text>
    <text class="cmn-sub" x="96" y="257">written 2026-10-04</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dkb-repo" aria-labelledby="dkb-repo-label">
    <rect x="596" y="224" width="148" height="48" rx="10"/>
    <text id="dkb-repo-label" x="670" y="241">The repository</text>
    <text class="cmn-sub" x="670" y="257">the source of truth</text>
  </g>

  <!-- Payloads -->
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M146 62 H166'); --cmn-travel: 0.4s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M346 62 H366'); --cmn-travel: 0.4s; --cmn-delay: 0.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M71 90 V224'); --cmn-travel: 1.5s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M651 90 V112 H511 V134'); --cmn-travel: 1.2s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M456 90 V124 H171 V134'); --cmn-travel: 1.4s; --cmn-delay: 0.85s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M436 160 H416'); --cmn-travel: 0.4s; --cmn-delay: 1.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M586 160 H606'); --cmn-travel: 0.4s; --cmn-delay: 1.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M176 248 H596'); --cmn-travel: 1.8s; --cmn-delay: 1.6s;"></circle>

  <!-- Labels -->
  <rect class="cmn-label-plate" x="270" y="112" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="345" y="124">copy-paste here</text>
  <rect class="cmn-label-plate" x="490" y="102" width="160" height="16" rx="4"/>
  <text class="cmn-label" x="570" y="114">the plan came from it</text>
  <rect class="cmn-label-plate" x="310" y="240" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="385" y="252">the repo wins</text>
</svg>
</div>
<figcaption>The four skills are the entry points, loaded by name: `carmonai` first for context,
`carmonai-architecture` before changing any service, `carmonai-new-service` when creating one, and
`batch-inference-design` when working on the inference path. Under them are the files they point at. The
inference plan is the one document the whole inference build came from, and it came from the video notes;
`plan-review` ranked the gaps the plan then closed. The handoff summarizes all of it — and the dotted line to
the repository is the rule that overrides everything above it.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> what to read, and what it points at (solid)</span>
  <span><i class="is-async"></i> a summary that defers to the code (dotted)</span>
  <span><i class="is-accent"></i> the documents that bind the others (teal outline)</span>
</div>

1. **`carmonai` is the first skill to load.** Product, repository map, what exists versus what is planned, and
   the decisions still open. It is the one that tells you the rest exist.
2. **`carmonai-architecture` holds the rules** — module split, layering, the hardening overrides, LGPD
   working rules and the stack — and the inference plan with its references.
3. **`carmonai-new-service` holds the scaffolding** and `references/templates.md`, including the pitfalls
   list, which is the most valuable file in the repository for anyone building a service here.
4. **`batch-inference-design` is the distilled source material** the inference plan was derived from, with its
   own caveat about what carries over from interview constraints and what does not.
5. **The plan's references** are where the detail lives: `inference-plan.md` for phases, decisions and the
   backlog; `plan-review-2026-10-02.md` for the ranked findings; the `phase-N-progress.md` files for what
   each phase actually did and where it deviated.
6. **The plan's progress notes are written into the plan itself**, at the top, above the phased sections — so
   the deviations are read before the original intent.
7. **The review ranked the gaps**, and the plan and the progress logs record which of them were closed.
8. **And when any of it disagrees with the repository, the repository wins.** The handoff says it, the
   `carmonai` skill says it, and the sections below show it happening.

## What it is

`.claude/skills/` holds five skills. Four are the project's own model of itself; the fifth, `carmonai-handson`,
is a thin index over the Insper course pages this architecture follows and is only fetched on demand.

| Skill | Holds | Load it when |
|---|---|---|
| `carmonai` | product, repository map, built-versus-planned, pending decisions | starting anything in this workspace |
| `carmonai-architecture` | architecture rules, hardening overrides, LGPD rules, the inference plan | designing, reviewing or changing a service |
| `carmonai-new-service` | how to scaffold a `<name>` + `<name>-service` pair, plus templates and pitfalls | creating or restructuring a service |
| `batch-inference-design` | the distilled system design the inference plan came from | designing or reviewing the inference path |
| `carmonai-handson` | an index of the reference course's hands-on pages | you want the course material behind a pattern |

Each is a `SKILL.md` with YAML front matter (`name`, `description`) and a `references/` directory of longer
files. The front matter matters: the description is what decides whether an agent loads the skill at all,
which is why every one of them says when to use it rather than what it contains.

## What each one holds

**`carmonai` — status and decisions.** A repository map naming every module and what it owns; a status table
with a date against each phase; a pending-decisions section; and a pointer to the handoff. It is the only place
that lists the decisions the user has to make — hosting, PSP, retention, legal entity, where libraries are
published — as opposed to the ones the project already made.

**`carmonai-architecture` — the rules, and the plan.** The rules half is short and binding: one schema per
service, a `XController` Feign interface per library, `XResource → XService → XRepository`, ids as UUID
strings, Flyway date-versioned migrations, `ai.carmonai` everywhere, then six hardening overrides that win
where the reference course's patterns conflict with them. The references half is the inference plan (286 lines:
phases 0–7, decisions, backlog), the plan review, a progress log per phase, and `observability.md`.

**`carmonai-new-service` — the scaffold.** Three numbered steps with a *done when* line each, and
`references/templates.md`: a service pom, tests, `application.yaml`, a Dockerfile, the compose block, and a
**pitfalls list** of thirty-seven things that already went wrong here — Boot 4 renaming starters, Jackson 3's
`asString()`, `retryWhen` wrapping the real error, `MockServerHttpRequest` not parsing cookies, Git Bash
rewriting container paths, unicast sinks dropping concurrent emits. Read it before writing a service.

**`batch-inference-design` — the source material.** A distillation of a 52-minute system-design video with a
caveat at the top that the video's constraints are interview constraints. It carries an explicit table of which
ideas survive contact with a real engine and which do not, and the plan's §1 is that table applied.

**The handoff document.** An artifact, not a file in the repository, written 2026-10-04 at the end of phase 7a.
It summarises the status, the built-versus-planned picture and the known gaps, and both the `carmonai` skill
and `revenue-leaks-progress.md` refer to it by URL. Treat it as a snapshot with a date on it: everything after
2026-10-04 — flex processing, the bounded admission wait, the capacity metrics, API key expiry and rotation,
the money endpoints, the observability stack — postdates it.

## What is built versus planned

Worth stating plainly, because the skills disagree with each other about it.

**Built.** Ten Spring Boot services and their libraries; the gateway with API-key authentication, identity
headers, rate limiting and the Marco Civil access log; accounts, sessions, JWTs and API keys with expiry and
rotation; organizations, memberships and tiers; inference on two engines with admission control, tier
priorities and `cache_salt`; usage metering through a durable Valkey stream with 90-day partitioned events and
sealed 5-minute windows; billing with an append-only ledger in micro-BRL, balances and the `no_credit` flag;
the Files and Batch API; erasure and export; Prometheus, Grafana, three dashboards and seven alert rules; and
the CI workflow.

**Planned, not built.** Hosting and Kubernetes; a payment rail (credit comes from a staff grant); a customer
console; `GET /v1/embeddings`; tracing; an Alertmanager destination; a second replica of anything; per-email
throttling on password resets; invitations; `last_used_at` on API keys. The plan's §13 backlog and §12 open
list are the authoritative version of that paragraph.

## The pending decisions

- the PSP and the NFS-e provider for when the first customer pays;
- retention periods, to confirm with legal;
- before any outside user: a legal entity, the Marco Civil access-log duty, LGPD "small agent" status, and
  whether inference counts as high-risk processing;
- where the libraries are published so services can depend on them (today they resolve from the reactor);
- the hosting and CI target.

Two entries in `carmonai`'s pending list are already answered by the code and should be read as closed: token
transport (a Bearer access token **and** an HttpOnly refresh cookie both exist, and `POST /auth/logout` is
built), and refresh tokens (access tokens are 15 minutes and `POST /auth/refresh` rotates the cookie).

## Where the source of truth lives

The rule is one sentence, and it appears in the `carmonai` skill and in the progress logs: **when the notes
and the repository disagree, the repository wins.**

That is not a formality. The notes are written at the end of a phase and are not edited when a later phase
changes the thing they describe. Four live examples, all verifiable by opening two files:

| The note says | The repository says |
|---|---|
| `carmonai` calls them "Java 27 microservices" | every `pom.xml` targets Java 25 (`<java.version>25</java.version>`) |
| `carmonai`'s repository map: "`docker/` — compose files (empty today)" | fourteen services in `docker/compose.yaml` |
| `carmonai`'s status table: "observability, K8s, CI — later" | `ci.yaml` runs; `docker/prometheus` and `docker/grafana` exist |
| plan §12: the `/rotate` gateway route and the cached-key expiry check are "pending (task C)" | both are in `gateway-service`'s `application.yaml` and `ApiKeyAuthenticationManager` |
| `observability.md` §Gaps 1–2: the `carmonai_inference_*` metrics "do not exist yet" | `Metrics.java` publishes them all, `reconcile_mismatch` included |

The same table applies to `carmonai-architecture`'s "Scope today: account, auth, organization, gateway", which
predates the inference, usage, billing and batch work.

The practical rule: use the notes to find the *why* and the *history* — a decision, a rejected alternative, a
pitfall that cost a day — and use the repository for the *what*. When they conflict, the difference is itself
worth reporting, because a note that is behind is usually a note nobody has updated since the phase that
changed it.

## Why it is like this

**Notes in the repository, not in a wiki.** They are versioned with the code, visible in a pull request that
changes a decision, and readable by an agent that has only cloned the repository.

**Skills rather than documents.** The `description` in a skill's front matter is a load trigger, so the
knowledge arrives when it is relevant instead of being read once and forgotten. That is why the files are
written as instructions ("load before designing, reviewing or changing any service") rather than as prose.

**Progress logs with dates and deviations.** Every phase log records not just what was built but where it
departed from the plan and why. Those deviations are the most useful part: they are the places where the plan
met reality, and several — the file size cap, the name-based UUID, the per-day summary pricing — are now
permanent features with a recorded reason.

## What would change it

- **Hosting.** The repository map, the status table and the "later phases" lists all assume one laptop; they get
  rewritten together when the platform leaves it.
- **A second person.** The pending-decisions list is one user's; a team would need an owner and a date against
  each item rather than a list.
- **A note that gets edited after its phase.** The rule works because notes are snapshots; editing them in
  place to stay current would remove the history the progress logs exist to keep.
- **The handoff artifact.** It lives outside the repository, so it cannot be diffed or linked from a pull
  request, and it will drift first.

## Where to look

- [carmonai/SKILL.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai/SKILL.md) — status,
  repository map and pending decisions; load it first.
- [carmonai-architecture/SKILL.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/SKILL.md)
  — the architecture rules and the six hardening overrides that win over the reference.
- [inference-plan.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/inference-plan.md)
  — the plan every inference page on this site is derived from, with its progress notes at the top.
- [plan-review-2026-10-02.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/plan-review-2026-10-02.md)
  — the ranked findings, including the three billing bugs found before any of it was built.
- [templates.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-new-service/references/templates.md)
  — the templates, and the thirty-seven-entry pitfalls list.
