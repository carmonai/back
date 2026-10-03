---
name: carmonai-handson
description: Lazy lookup of the Insper 2026.2 Hands-on pages — an index with fetch flags; a page is pulled only when the task needs it. Load before reading any Hands-on page, or when a Hands-on topic is named by id or title.
argument-hint: "<id from the index, e.g. 3b>"
---

# Hands-on lookup

The Hands-on pages are fetched one at a time, when a task needs them. [index.md](index.md) lists every page with a flag; with no argument, show the user the index.

## Flags

- `cached` — content already saved (the index names where). Read that; fetch only for a detail it lacks.
- `now` — needed for phase 1 (account, auth, gateway) and not yet saved. Fetch when the task touches it.
- `later` — not needed yet. Fetch only when the current task is that topic, and say so in one line; a gist may already sit in `carmonai-architecture/references/platform.md`.

## Pull a page

1. Resolve the id in the index (from the argument or the topic named). A `cached` row: read its location and stop.
2. Fetch with Firecrawl (`firecrawl_scrape`, url = base + Path):
   - exact code or config needed → `formats: ["markdown"]`, `onlyMainContent: true` (1 credit);
   - a few specific rules needed → `formats: ["query"]` with `queryOptions.prompt` naming what the task needs (5 credits).

   The limit is about 11 requests a minute: fetch in batches of 4–5 and retry after the reset time the error gives.
3. Convert before using: `ai.carmonai` namespace and the hardening overrides in `carmonai-architecture` apply. The pages are teaching material with shortcuts (SHA-256 passwords, HS256 tokens, `latest` tags, `store` names).
4. Save a note to `notes/<id>.md`: the rules, minimal snippets, the source URL, and what Carmonai overrides. Keep it under about 40 lines; link to the page for the rest. Then set the index row to `cached` with that path.

Done when: `notes/<id>.md` exists, the index row reads `cached` with its path, and the task used the note's rules.
