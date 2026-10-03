# Insper reference map

Read pages with Firecrawl. Base: `https://insper.github.io/platform/2026.2/`. Code (2026.1 Overview): `https://github.com/repo-classes/` + `pma.261` (root), `pma.261.account`, `pma.261.account-service`, `pma.261.auth`, `pma.261.auth-service`, `pma.261.gateway-service`.

| Need | Page |
|---|---|
| Component roles, best practices | `classes/microservices/architecture/` |
| Service boundaries, aggregates | `classes/microservices/ddd/` |
| Ports/adapters, dependency rule | `classes/architectures/hexagonal/` (also `clean/`, `solid/`) |
| Resilience numbers | `classes/reliability/patterns/` (also `sli-slo-sla/`, `chaos/`) |
| OAuth2, zero trust, secrets | `classes/security/` |
| Events vs sync calls | `classes/event_driven/` |
| Metrics, logs, traces | `classes/observability/` |
| REST rules, status codes | `classes/api/rest/` (also `swagger/`) |
| Any Hands-on page (module, gateway, JWT, CI, K8s, observability, nginx, cache, Kafka, tracing) | skill `carmonai-handson` — indexed, fetched on demand |

Distilled into the skills: the architecture, hexagonal, resilience, security, events, observability and REST classes, plus the auth flow from the repos. Read in full before use: `classes/distributed_systems/`, `classes/architectures/clean/` and `solid/`, `classes/deployment/`. Hands-on status lives in `carmonai-handson`.
