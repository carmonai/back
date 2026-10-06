# Organization

## What it is

`organization-service` owns the `organizations` schema and holds the tenant: a name, a status, a tier, and the
memberships that say which accounts may act for it. Every other service that needs to know who belongs to what
asks this one; nobody reads these tables but this service.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="org-title" aria-describedby="org-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="org-title">An organization's two states, and what closing it changes elsewhere</title>
  <desc id="org-desc">An organization is created active and an owner can close it, which sets its status to
  closed. After that the tenant lookup answers closed, API keys stop authenticating with a 403, and a
  scheduled sweep in batch-service asks for that status and erases the organization's batch data.</desc>
  <defs>
    <marker id="org-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: creation to closed, then the three things closing changes. -->
  <g id="org-hops">
    <path id="org-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M210 68 H330" marker-end="url(#org-arrow-flow)"/>
    <path id="org-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M415 96 V140 H325 V176" marker-end="url(#org-arrow-flow)"/>
    <path id="org-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M415 140 H505 V176" marker-end="url(#org-arrow-flow)"/>
    <path id="org-hop4" class="cmn-link cmn-link--quiet" d="M415 140 H675 V176" marker-end="url(#org-arrow-flow)"/>
  </g>
  <g class="cmn-node cmn-node--entry cmn-node--flow" id="org-active" aria-labelledby="org-active-label"><rect x="40" y="40" width="170" height="56" rx="10"/><text id="org-active-label" x="125" y="60">active</text><text class="cmn-sub" x="125" y="78">trial tier at creation</text></g>
  <g class="cmn-node cmn-node--soft" id="org-closed" aria-labelledby="org-closed-label"><rect x="330" y="40" width="170" height="56" rx="10"/><text id="org-closed-label" x="415" y="60">closed</text><text class="cmn-sub" x="415" y="78">nothing is deleted</text></g>
  <g class="cmn-node cmn-node--flow" id="org-tenant" aria-labelledby="org-tenant-label"><rect x="250" y="176" width="150" height="56" rx="10"/><text id="org-tenant-label" x="325" y="196">tenant(id)</text><text class="cmn-sub" x="325" y="214">status and tier</text></g>
  <g class="cmn-node cmn-node--danger" id="org-keys" aria-labelledby="org-keys-label"><rect x="430" y="176" width="150" height="56" rx="10"/><text id="org-keys-label" x="505" y="196">API keys stop</text><text class="cmn-sub" x="505" y="214">403 organization_not_active</text></g>
  <g class="cmn-node cmn-node--soft" id="org-batch" aria-labelledby="org-batch-label"><rect x="610" y="176" width="130" height="56" rx="10"/><text id="org-batch-label" x="675" y="196">Batch erased</text><text class="cmn-sub" x="675" y="214">within a minute</text></g>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M210 68 H330'); --cmn-travel: 1.2s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M415 96 V140 H325 V176'); --cmn-travel: 1.4s; --cmn-delay: 0.5s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M415 140 H505 V176'); --cmn-travel: 1.2s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M415 140 H675 V176'); --cmn-travel: 1.4s; --cmn-delay: 1.3s;"></circle>
  <rect class="cmn-label-plate" x="242" y="46" width="56" height="16" rx="4"/><text class="cmn-label" x="270" y="58">DELETE</text>
  <rect class="cmn-label-plate" x="521" y="145" width="84" height="16" rx="4"/><text class="cmn-label" x="563" y="157">the sweep polls</text>
</svg>
</div>
<figcaption>An organization is created active on the trial tier, and its owner can close it. Closing deletes
nothing here: it changes one column. Everything else follows from readers noticing that column — the gateway
refuses its API keys, and a scheduled sweep in batch-service asks for the status and erases that
organization's batch data.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a state change and the reads that follow it (solid)</span>
  <span><i class="is-async"></i> a scheduled poll (dotted)</span>
</div>

1. **An organization is created `active` on the `trial` tier**, and the account that created it becomes its
   `owner`, in one transaction.
2. **An owner closes it** with `DELETE /organizations/{id}`, which sets `status` to `closed` and answers 204.
3. **The tenant lookup starts answering `closed`.** Other services read status and tier through `tenant(id)`;
   the name is not in that answer on purpose.
4. **API keys belonging to it stop working.** auth-service hands the status to the gateway inside the key
   lookup, and the gateway refuses anything that is not `active` with 403 `organization_not_active`.
5. **batch-service erases its data.** A sweep asks `tenant(id)` about every organization it holds data for,
   and only an explicit `closed` erases.

## Two tables

```sql
CREATE TABLE organization (
    id   VARCHAR(36) PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    status VARCHAR(16) NOT NULL CHECK (status IN ('active', 'suspended', 'closed')),
    tier   VARCHAR(16) NOT NULL CHECK (tier IN ('trial', 'standard', 'enterprise')),
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE membership (
    organization_id VARCHAR(36) NOT NULL REFERENCES organization (id),
    account_id      VARCHAR(36) NOT NULL,
    role            VARCHAR(16) NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    created_at      TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (organization_id, account_id)
);
```

One migration has been enough. `membership.account_id` is commented as "who may act for the organization;
deleted on account erasure" and `organization.name` as "console label; can name a person" — the two columns
that touch LGPD, both labelled at the schema level.

**Status is a word, not a boolean.** `active`, `suspended`, `closed` rather than `is_active`, because the
readers ask three different questions and a boolean would have to be re-derived at each of them. Worth
knowing: `suspended` is in the constraint and every reader handles it — the gateway refuses any status that is
not `active` — but nothing in the code sets it. It is a state with no writer, waiting for the operations that
would use it.

**Tier** is `trial`, `standard` or `enterprise`. It is not enforced here at all: the gateway copies it into the
`tier` identity header, and inference-service turns it into rate buckets, in-flight caps and a share of the
engine's slots. This service only remembers it.

## Memberships and the three roles

| Operation | Endpoint | `owner` | `admin` | `member` |
|---|---|---|---|---|
| create the organization | `POST /organizations` | — (the creator becomes owner) | | |
| list mine | `GET /organizations` | yes | yes | yes |
| read one | `GET /organizations/{id}` | yes | yes | yes |
| close it | `DELETE /organizations/{id}` | yes | no | no |
| manage API keys | `/organizations/{id}/api-keys…` | yes | yes | read only |

The role checks are not made here for API keys: auth-service calls `member(id, idAccount)` and compares the
role itself, with `MANAGERS = Set.of("owner", "admin")`. Keeping the rule in the caller that needs it means
one source of truth for "who is a member" and no second copy of "who may manage keys".

`POST /organizations` is the only write that creates a membership, and it does both in one transaction:
`organization` first, then a `membership` row with role `owner`.

## The two internal lookups

These are the calls the rest of the platform makes, and they are shaped by who is asking.

**`member(id, idAccount)`** → `GET /organizations/{id}/members/{idAccount}` →
`MemberOut(organizationId, accountId, role)`. A non-member gets the same **404** as a missing organization id,
so the endpoint cannot be used to discover which organizations exist. Callers: auth-service before any API-key
operation, usage-service before showing a usage summary, billing-service before showing a balance.

**`tenant(id)`** → `GET /organizations/{id}/tenant` → `TenantOut(id, status, tier)`. Ids only — no name. That
is deliberate: its purpose is API-key authentication, where the gateway needs to know whether the organization
may spend and at what tier, and has no business knowing what it is called. A name in that response would be a
piece of customer data crossing two services on every cache miss, for nothing.

`tenant(id)` is what auth-service's `GET /api-keys/{hash}` composes into `ApiKeyPrincipalOut`, and therefore
what the gateway caches under `apikey:{hash}` for 60 seconds. It is also read by `ApiKeyService.create`, which
refuses to issue a key for an organization that is not `active`.

## Closing, and what closing actually erases

`DELETE /organizations/{id}` answers 204 and sets the status. **It deletes nothing.** The organization row,
its memberships and its history all stay; the tenant simply stops spending. Three things follow from readers
noticing:

- **API keys stop authenticating.** The key is still a valid row in auth-service; it is the organization's
  status that fails the check, in the gateway, as 403 `organization_not_active`.
- **batch-service erases its copy.** See below.
- **Nothing else changes.** Usage and ledger rows stay, because tax records are kept and they hold ids and
  amounts, not personal data.

Closing is owner-only: a non-owner gets 403 `only owners close an organization`.

## Why the batch sweep asks this service

`BatchFinisher.eraseClosed` runs on `carmonai.batch.erase-every` (1 minute). It reads the organizations that
have batch data, and for each one calls `tenant(id)`: an explicit `closed` erases that organization's files
and stops its batches, while an **unknown** id or an **unreachable** organization-service never erases. A
misrouted URL answering 404 must not wipe everyone's data.

It is a **pull, not a push**, and that is the project's standing rule: a missed or failed run is simply done by
the next one, and there is no broker because Kafka arrives when an event gets a second consumer. The price is
one status call per organization with data, per run — which the code marks as the shortcut it is, with an
`organization.closed` event named as the upgrade when the number of tenants makes it expensive.

Note the shape of the dependency: batch-service depends on this service's *library* and calls it, but
organization-service depends on nobody. It is the leaf, and every question about tenancy ends here.

## Why it is like this

**Status stored once, interpreted by each reader.** A `closed` column is a fact; "refuse the key" is a policy.
Putting the policy here would mean pushing to every interested service, which is a broker in disguise.

**404 for a non-member, not 403.** A 403 confirms that the organization exists. Callers pass the 404 through
unchanged — billing-service and usage-service both document that a stranger reads exactly the answer
organization-service gave.

**Ids only in `tenant(id)`.** The narrowest response that answers the question, because it is on the path that
authenticates every API request.

**The organization row is locked before its owners are counted.** In `removeMember`, each organization the
account owns is locked first, so two owners erasing their accounts at the same time cannot both see "there is
another owner" and leave the organization with none: the second waits on the row lock, then sees one owner
left.

## What would change it

- **The erasure sweep is one call per organization per run.** It is a poll of every tenant with batch data,
  once a minute. Past a few thousand tenants the answer is an `organization.closed` event, which is the first
  thing in this platform that would justify a broker.
- **`suspended` has no writer.** The status, the constraint and the gateway's refusal all exist; the operation
  that would set it does not. If suspension is never wanted, the value should leave the constraint.
- **There is no route to reopen or rename an organization.** Closing is one-way through the API, and the name
  is fixed at creation.
- **Tier is never validated against a payment state**, because there is no payment rail.

## Where to look

- [OrganizationController.java](https://github.com/carmonai/back/blob/main/api/organization/src/main/java/ai/carmonai/organization/OrganizationController.java) — the contract, public and internal endpoints.
- [OrganizationService.java](https://github.com/carmonai/back/blob/main/api/organization-service/src/main/java/ai/carmonai/organization/OrganizationService.java) — creation, closing and the lock-before-count erasure.
- [create_tables.sql](https://github.com/carmonai/back/blob/main/api/organization-service/src/main/resources/db/migration/V2026.10.03.001__create_tables.sql) — the two tables and the LGPD comments on them.
- [TenantOut.java](https://github.com/carmonai/back/blob/main/api/organization/src/main/java/ai/carmonai/organization/TenantOut.java) — the three fields that authenticate an API key.
- [BatchFinisher.java](https://github.com/carmonai/back/blob/main/api/batch-service/src/main/java/ai/carmonai/batch/BatchFinisher.java) — the sweep that asks this service for status.
