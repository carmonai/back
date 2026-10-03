# Phase 7 progress (production), part a: what needs no outside decision

Working log started 2026-10-03. Plan: [inference-plan.md](inference-plan.md) §9 (LGPD: deletion on termination, access log, rights), §11 row 7. The user chose (2026-10-03) to start phase 7 with the local work: erasure across services and export, access log, then console sign-in flows. Hosting, Kubernetes, payments (Pix, NFS-e) and the legal checklist wait for the user's decisions. Rules: `phase-7` branches only; commit and push when green; PRs at the end; never merge without the user's go-ahead.

## Checklist

- [x] Branches `phase-7`: back, batch-service, account, account-service, gateway-service, inference-service
- [x] batch-service erases a closed organization's batch data: files deleted, running batches stopped, no output written (sweep via the `organization` library); IT
- [x] Data export: `GET /accounts/{id}/export` (account + its organizations and roles), routed by the gateway; IT
- [x] Gateway access log (Marco Civil art. 15): one JSON line per request in its own file, 6-month rolling retention, ids only; gateway sets `X-Request-Id` and inference-service keeps it
- [x] smoke: closing an org erases its batch files; export; access log written and free of secrets
- [x] `mvn clean verify` + CPU smoke green; logs clean
- [x] Docs: plan progress/deviations, skills, templates
- [x] Commit + push, PRs
- [ ] Next (part b): console sessions: refresh cookie, logout, email verification, password reset (local mail catcher)

## Design decisions (keep consistent when resuming)

- **Erasure on close is pulled, not pushed.** batch-service sweeps (`carmonai.batch.erase-every`, 1 min) the organizations it holds data for (files, running batches), asks organization-service for each one's status through the existing `organization` library (`tenant`), and erases those `closed` (only an explicit `closed`: an unknown id or an unreachable organization-service never erases, so a misrouted URL answering 404 can't wipe everyone's data): deletes their files, marks their running batches `cancelling` with `erase = true`. The finisher ends an erased batch without writing output or error files and deletes its lines. A push (organization-service calling batch-service) would need a `batch` library repo and an event saga; the sweep needs neither, heals itself after any failure, and bounds the delay at one sweep. ponytail: one status call per organization with data per sweep; an `organization.closed` event when that count grows.
- **Keys of a closed organization** are not revoked one by one: the gateway refuses keys of an organization that isn't active, within its 60 s cache. Keys hold no personal data.
- **Ledger and usage stay** after closing (ids only; the ledger is kept for tax).
- **Export** (LGPD art. 18): the account's own data (id, name, email, created) and its organizations (id, name, status, tier, role). Usage and billing belong to organizations and carry no personal data. Same caller rule as `GET /accounts/{id}`: yourself only.
- **Access log**: a gateway `WebFilter` at the highest precedence (outside the security chain, so refused requests count too; `/actuator/**` probes skipped) writes one line per request on logger `access` (method, path without query, status, duration, client IP, account or organization + key ids, request id) to `/var/log/carmonai/access.log` through `logback-spring.xml`: daily files, `maxHistory` 184 (≈ 6 months), never on stdout. Restricted by being only in the gateway's volume; production ships it to a store with access control. Never headers, bodies or query strings.
- **Request id**: the gateway overwrites any client `X-Request-Id` with its own UUID on every route; inference-service uses it (instead of minting one) for the answer and the usage event, so the access log, the client's support handle and usage line up. Calls that don't come through the gateway (batch-service) still get one minted by inference-service.

## Notes

- Tests: batch-service IT 7 (+1: a closed organization's files go, its held batch ends cancelled without files and without lines; an active and an unknown organization keep theirs); account-service IT 6 (+1: export, 403 for someone else); inference-service IT 17 (+1: the gateway's request id is the answer's and the usage event's); gateway `AccessLogFilterTest` (client request id replaced, one response header even when a service echoes it, ids logged, no secrets or query string).
- Smoke (CPU): request id from the gateway to the usage event; access log line with organization and key, absent from stdout; access log included in the canary/secret/query-string leak check; export (owner 200, stranger 403); closing the organization erases its batch files within the 5 s sweep.
- Spring Security's principal isn't visible to a `WebFilter` outside its chain (it decorates the exchange further in): the access log reads the caller's ids from exchange attributes that `IdentityHeadersFilter` sets; attributes are shared by every decorated exchange.
- Spring Cloud Gateway appends the routed response's headers: an `X-Request-Id` set early came back twice (ours + inference-service's copy). Set it in `beforeCommit` instead.
- `docker compose up --build <svc>` also recreates the dependencies it rebuilt: billing's debit failed for ~50 s while usage-service was recreated (breaker open 30 s), then recovered. Not a bug; BillingJobs only logs the exception class, which hid the cause for a minute.
- The erasure sweep warned every 5 s about two synthetic organizations from the phase-6 kill experiments (unknown to organization-service, 404): unknown is now a debug line; their files expire with the 30 days.
