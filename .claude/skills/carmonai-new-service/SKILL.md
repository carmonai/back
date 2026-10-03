---
name: carmonai-new-service
description: Scaffold a Carmonai microservice — the `<name>` library + `<name>-service` pair (account, auth, gateway, any new one): modules, pom, Resource/Service/Repository/Model, Flyway, Dockerfile, compose. Load when creating or restructuring a service.
---

# New Carmonai service

Rules live in `carmonai-architecture`; copy-paste material in [references/templates.md](references/templates.md). Each step ends on its **done when** line.

## 0. Namespace (once)

Done 2026-10-02: every module uses groupId `ai.carmonai`. Add new modules to `back/pom.xml` (the aggregator) so `mvn package` from `back/` builds them in order.

## 1. Library `<name>`

- Repo `carmonai/<name>`, added as a submodule at `back/api/<name>`.
- pom copied from `back/api/account/pom.xml` with artifactId `<name>`.
- `XController`, `XIn`, `XOut` in `ai.carmonai.<name>`; collection endpoints take `page`/`size`.

Done when: `mvn -q verify` passes and the library depends on openfeign + lombok only.

## 2. Service `<name>-service`

- Repo `carmonai/<name>-service`, submodule at `back/api/<name>-service`.
- Classes `XApplication`, `XResource`, `XService`, `XRepository`, `X`, `XModel` in `ai.carmonai.<name>`.
- Flyway migration, `application.yaml`, Dockerfile from the templates.
- Tests from the templates: unit tests on branchy logic and, with a DB, one `XServiceIT` (Testcontainers + the library's Feign client).

Done when: `mvn -q verify` passes (unit + IT), the image builds, and the readiness probe reports `UP` from inside the container network.

## 3. Compose and gateway

- Add the service to `back/docker/compose.yaml`: no published port, shared `internal` network, DB healthcheck gating startup.
- Add its route to gateway-service.

- Extend `back/docker/smoke.sh` with the new routes' happy path and their 401/403/404 cases.
- The new submodule must be readable by CI's `SUBMODULES_TOKEN` (add the repo to the token's repository list).

Done when: a request through the gateway reaches the service, the service port is unreachable from the host, and CI (`.github/workflows/ci.yaml` in `back`) is green.

## Variants

- **gateway-service**: no library, no DB. WebFlux + `spring-cloud-starter-gateway-server-webflux`; routes in yaml; JWT validated with Spring Security's resource server against auth's JWKS; open routes (login, register) whitelisted; sets `id-account` from the token subject and strips any inbound copy.
- **auth**: library `auth` + `auth-service`, no DB of its own. Verifies credentials through the `account` library, signs JWTs, serves the JWKS; endpoints login, register, logout.

## Finish

Run the review checklist in `carmonai-architecture`; the service is done when it passes.
