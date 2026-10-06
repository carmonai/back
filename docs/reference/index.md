# Reference

**The decision record, the ideas that were abandoned, the honest gaps, and the vocabulary — with the source
of every claim named.**

## What it is

This section is the argument behind the platform rather than a description of it. The rest of the site tells
you what the code does — [The shape of the system](../architecture/topology.md) is the shortest way in — and
these four pages tell you why it does that, which alternatives were weighed and dropped, what is still not
built, and what the project means by a word like *goodput* or *settlement*. It is the section to land on when a
mechanism elsewhere in the site makes you ask "why is it like that?".

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="ref-title" aria-describedby="ref-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="ref-title">A question, the four reference pages, and the file behind them</title>
  <desc id="ref-desc">A question enters from the left and travels to one of four pages — decisions,
  abandoned ideas, known gaps or the glossary — depending on what is being asked. Each of those pages is then
  checked against the repository: the plan, the review and the working logs. The solid hops carry the
  question; the dotted hops carry a page's claim to the file that backs it.</desc>

  <defs>
    <marker id="ref-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
    <marker id="ref-arrow-quiet" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- The question's route in, then the four hops it can take: reading order is the page order. -->
  <g id="ref-hops">
    <path id="ref-trunk" class="cmn-link cmn-link--flow" d="M160 140 H182 M182 50 V230"/>
    <path id="ref-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M182 50 H200"
          marker-end="url(#ref-arrow-flow)"/>
    <path id="ref-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M182 110 H200"
          marker-end="url(#ref-arrow-flow)"/>
    <path id="ref-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M182 170 H200"
          marker-end="url(#ref-arrow-flow)"/>
    <path id="ref-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M182 230 H200"
          marker-end="url(#ref-arrow-flow)"/>
  </g>

  <!-- The other half: every page's claim is checked against a file. No packets here. -->
  <g id="ref-sources" aria-hidden="true">
    <path class="cmn-link cmn-link--quiet" d="M420 50 H470"/>
    <path class="cmn-link cmn-link--quiet" d="M420 110 H470" marker-end="url(#ref-arrow-quiet)"/>
    <path class="cmn-link cmn-link--quiet" d="M420 170 H470"/>
    <path class="cmn-link cmn-link--quiet" d="M420 230 H470"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="ref-question" aria-labelledby="ref-question-label">
    <rect x="20" y="108" width="140" height="64" rx="10"/>
    <text id="ref-question-label" x="90" y="130">A question</text>
    <text class="cmn-sub" x="90" y="150">why is it like that</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="ref-decisions" aria-labelledby="ref-decisions-label">
    <rect x="200" y="24" width="220" height="52" rx="10"/>
    <text id="ref-decisions-label" x="310" y="44">Decisions</text>
    <text class="cmn-sub" x="310" y="62">the reason, and the alternative</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="ref-abandoned" aria-labelledby="ref-abandoned-label">
    <rect x="200" y="84" width="220" height="52" rx="10"/>
    <text id="ref-abandoned-label" x="310" y="104">Abandoned ideas</text>
    <text class="cmn-sub" x="310" y="122">what we did not build</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="ref-gaps" aria-labelledby="ref-gaps-label">
    <rect x="200" y="144" width="220" height="52" rx="10"/>
    <text id="ref-gaps-label" x="310" y="164">Known gaps</text>
    <text class="cmn-sub" x="310" y="182">built, deferred, unbuilt</text>
  </g>
  <g class="cmn-node cmn-node--flow" id="ref-glossary" aria-labelledby="ref-glossary-label">
    <rect x="200" y="204" width="220" height="52" rx="10"/>
    <text id="ref-glossary-label" x="310" y="224">Glossary</text>
    <text class="cmn-sub" x="310" y="242">the words in their own sense</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="ref-repository" aria-labelledby="ref-repository-label">
    <rect x="470" y="24" width="270" height="232" rx="10"/>
    <text id="ref-repository-label" x="605" y="132">The repository</text>
    <text class="cmn-sub" x="605" y="152">the plan, the review, the logs</text>
  </g>

  <!-- One packet per page, in reading order: the question travelling to its answer. -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M182 50 H200'); --cmn-travel: 0.8s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M182 110 H200'); --cmn-travel: 0.8s; --cmn-delay: 0.2s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M182 170 H200'); --cmn-travel: 0.8s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M182 230 H200'); --cmn-travel: 0.8s; --cmn-delay: 0.6s;"></circle>
</svg>
</div>
<figcaption>A question enters once, and which page it lands on depends on what is being asked: why something
is the way it is, what was rejected, what is missing, or what a word means. Every page is then checked
against the repository — the plan, the review and the working logs — which is what the dotted hops stand for.
Those carry no packet, because reading a file is not a hop through the system.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a question travelling to the page that answers it (solid)</span>
  <span><i class="is-async"></i> a claim checked against a file in the repository (dotted)</span>
</div>

1. A question arrives — usually "why is it like that?", and usually while reading another section of the site.
2. It lands on one of four pages: the decision record, the abandoned ideas, the gaps, or the glossary.
3. Each page is checked against the repository: the plan, the review of it and the working logs of each phase.
4. Where those sources disagree — and they do, because some are dated snapshots — the page says which one it
   followed instead of quietly picking the tidier claim.

## The four pages

<div class="grid cards" markdown>

-   **Why is it like that?**

    ---

    [Decisions](decisions.md) records every decision with the reason and the alternative that was rejected,
    and marks the questions that are still open as open.

-   **What did we reject, and why?**

    ---

    [Abandoned ideas](abandoned.md) lists what was considered and deliberately not built, what it would have
    bought, what it would have cost, and the trigger that would bring it back.

-   **What is missing?**

    ---

    [Known gaps](gaps.md) is the honest list, ranked by what blocks a paying customer, with each gap labelled
    a defect, a deliberate deferral or unbuilt scope. When a note and the code disagree,
    [which notes to trust](status.md) says which one lags and which claims it got wrong.

-   **What does that word mean?**

    ---

    [Glossary](glossary.md) defines the vocabulary in the sense this project uses it, from `C` and `q` to the
    reconciliation, each with the page that uses it.

</div>

## How to read the record

Three conventions hold across the four pages, and they are what make the section worth reading rather than
skimming:

- **A decision carries its reason and its rejected alternative.** "Batch files live in Postgres" is a fact.
  "Batch files live in Postgres because object storage needs the hosting decision first, and the ceiling is a
  4 MB upload" is a decision — and only the second one tells you when to revisit it.
- **A gap carries its kind as well as its fix.** A defect is a bug. A deliberate deferral is a decision with a
  trigger. Unbuilt scope is a product that does not exist. Calling all three "future work" hides the one row
  that actually blocks launch.
- **A claim carries its source.** Every page in this section ends with the two to five files it was read from,
  as paths in the repository, and the plan and the review are linked where they are used.

## Why it is like this

The project keeps its own memory, and this section is that memory rewritten for someone who has the
repository open. The memory itself lives in four places: the "Phase N built" blocks at the top of the
inference plan, one working log per phase, the `ponytail:` comments that name each shortcut's ceiling, and
the pitfalls list that every new service is built against. Nothing here is a reconstruction from memory or
from a summary — if a page could not be traced to a file, it was not written.

Two habits follow from that, and they are the reason this section can be trusted with the uncomfortable
parts:

- **Honesty is cheaper than optimism.** A gap described as "future work" when it blocks launch is a lie with
  a polite name, so the gaps page ranks by customer impact and says plainly that there is no payment rail and
  no console. The same voice describes the parts that work.
- **Open questions are shown as open.** The payment provider, the retention periods and the legal questions
  are marked undecided in the decision record, not resolved by whichever default happened to be convenient.

## What would change it

These pages change when the code does. Each of them names its own triggers: a gap leaves the list when its
fix lands, a deferred shortcut moves up when its ceiling is reached, and a decision that is reversed is edited
in place with the ceiling it hit kept beside it. Two specific edits are already visible — the output bucket
now reserves `max_tokens` at admission, and usage events now go through a durable Valkey stream — and both are
recorded with their dates rather than silently corrected.

## Where to look

- [inference-plan.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/inference-plan.md) — §12 the decisions, §13 the backlog, and one deviation block per phase at the top.
- [plan-review-2026-10-02.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/plan-review-2026-10-02.md) — the second planning pass, topic by topic, with the sources each finding was read from.
- [observability.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/observability.md) — the metrics contract, the SLOs, and a gaps section that names its own holes.
- [templates.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-new-service/references/templates.md) — the conventions for a new service, and "Pitfalls already hit", read before debugging anything.
- [revenue-leaks-progress.md](https://github.com/carmonai/back/blob/main/.claude/skills/carmonai-architecture/references/revenue-leaks-progress.md) — the working log of the two leaks that were found, ranked first, and fixed.

The four pages were written from those files plus the handoff the project wrote for its next engineer at the
end of phase 7a. The plan, the review and the logs are files in `back`; the handoff is not, so it is named
here rather than linked — and because some of these notes are behind the code, [which notes to trust](status.md)
records where each one lags and which claims it got wrong.
