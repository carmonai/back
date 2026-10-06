# How to write a page for the Carmonai site

You are writing one section of a documentation site that explains a real production-shaped platform. Five
writers work in parallel, so this file is the shared contract: follow it exactly and the pages will read as
one site.

Read `FACT-SHEET.md` before you write. **Write from it.** If a page needs a fact it does not contain, open
the source file and read it — never invent a number, a class name, an endpoint or a behaviour.

---

## The reader

A competent engineer who has never seen this repository: a new colleague, a reviewer, a customer's architect.
They know what HTTP, Postgres and a JWT are. They do not know Carmonai's decisions. Write for someone who will
ask "why is it like that?" after every sentence they read.

## Voice

- **Plain and concrete.** Short sentences. "The gateway strips it, then sets its own." Not "leveraging a
  header-sanitisation strategy".
- **Explain the why, always.** A page that only lists what the code does is a worse `git log`. Every mechanism
  earns a sentence on the problem it solves and, where it exists, the alternative that was rejected.
- **Honest about limits.** If something is a prototype shortcut, or a gap, say so in the same voice as the rest.
  This project's credibility rests on not overselling; a page that hides a ceiling is off-brand.
- **No marketing.** No "seamless", "powerful", "cutting-edge", "blazing fast", "robust solution". Numbers
  instead: "TTFT p95 253 ms at 4 concurrent requests".
- Second person for the reader ("you send"), first person plural only for the project ("we chose"). Never
  "one might consider".

## Every page has this shape

1. **`## What it is`** — two or three sentences, the plainest possible statement of the thing's job. No
   history, no preamble.
2. **The mechanism**, in `##` sections that follow the reader's questions, not the file layout.
3. **`## Why it is like this`** — the decisions and the rejected alternatives, with the alternative named.
4. **`## What would change it`** — the ceiling and the upgrade path, from the fact sheet's shortcuts table.
5. **`## Where to look`** — a short list of the two to five files that matter, as repo-relative paths, each
   with a six-word reason. Link them: `[ChatHandler.java](https://github.com/carmonai/back/blob/main/api/inference-service/src/main/java/ai/carmonai/inference/ChatHandler.java)`.

Not every page needs all five headings verbatim, but the *information* must be there. A page of 120–220 lines
of Markdown is the target: dense, not padded.

## Visuals — the part that must be beautiful

Each page carries **exactly one hero diagram** plus, where it genuinely helps, one supporting Mermaid diagram.
The hero is hand-authored inline SVG using the shared classes — read `VISUAL-SPEC.md` and copy an example
from it. The rules that matter most:

- The hero diagram is an **animated flow**: it shows how a request or data moves, not a static org chart.
- It must be legible in **both light and dark** themes without hardcoding colours — use the shared classes and
  `var(--…)` tokens only.
- Every node label is short (1–4 words). Detail belongs in the prose, not inside a box.
- The diagram must state its entry point and its direction so a reader knows where to start.

Mermaid is for **sequence and state**, and must be themed for dark mode: start the block with the init line
shown in `VISUAL-SPEC.md`. Do not fight Mermaid's layout — if a diagram needs precise placement, make it SVG.

## Code references

- Name real classes, endpoints and config keys, exactly as they are spelled in the code.
- Link to files rather than quoting long excerpts. When quoting, quote fewer than 15 lines and only when the
  reader must see the exact shape.
- Endpoints: show the method and path (`POST /v1/chat/completions`).
- Numbers carry units and, where it matters, the conditions they were measured under ("output tok/s at 4
  concurrent requests on an RTX 3050").

## Linking

Relative links between pages, no trailing `.md`: `[Admission](../requests/admission.md)` →
`[…](../requests/admission.md)`. MkDocs resolves these; a broken one fails `--strict`, which is how the site
is verified. Link to source files on GitHub with an absolute URL, as above.

## Do not

- Do not invent a diagram of a mechanism you have not read the code for.
- Do not restate the fact sheet wholesale; use the parts your page needs.
- Do not add a page, rename a page, or change `mkdocs.yml` — the navigation is fixed and owned by the
  orchestrator. If a page seems to be missing, say so in your report instead.
- Do not add a dependency, a plugin, or a font from a CDN.
- Do not use emoji as section markers or bullet points.
- Do not write "TODO", "coming soon", or a placeholder of any kind. If something is unbuilt, state it as a gap.
