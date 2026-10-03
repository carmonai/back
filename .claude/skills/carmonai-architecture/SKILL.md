---
name: carmonai-architecture
description: Carmonai architecture rules — module split, layering, security, resilience, LGPD, stack. Load before designing, reviewing, or changing any service, API, auth, or data code.
---

# Carmonai architecture

Source: the Insper "Platforms, Microservices, DevOps and APIs" course (2026.2 Classes + Hands-on; code in `repo-classes/pma.261*`). Its structure binds us; the **hardening overrides** below win where they conflict. Before inventing a pattern, find the matching page in [references/insper-map.md](references/insper-map.md) and follow it.

Scope today: account, auth, organization, gateway. Inference follows [references/inference-plan.md](references/inference-plan.md) (approved 2026-10-03; progress and deviations at its top; the `batch-inference-design` skill behind it).

## Shape

`client → gateway-service (WebFlux, the only published port) → auth-service / business services → Postgres`

- One schema per service, no shared tables. Services reach each other through the library's Feign client.
- Services are stateless, so replicas scale horizontally.
- The gateway validates the JWT, then sets `id-account` itself, stripping any inbound copy. Services trust that header from the gateway only.

## Module rules

- Two modules per service: `<name>` library + `<name>-service`.
  - Library: `XController` Feign interface (`@FeignClient(name="<name>", url="http://<name>:8080")`) and `XIn`/`XOut` records with `@Builder`. Dependencies: openfeign + lombok.
  - Service: depends on the library at `${project.version}`.
- Request flow in the service: `XResource` (`@RestController implements XController`) → `XService` → `XRepository` (Spring Data) → DB.
  - Domain class `X` and JPA class `XModel` stay separate (`new XModel(domain)`, `model.to()`).
  - Parse at each boundary: Resource turns `XIn` into `X` and `X` into `XOut`; Service turns `X` into `XModel` and back. `XService` never sees DTOs or HTTP types.
- IDs are UUID `String`. Each service owns a schema named after its aggregate plural (`accounts`). Flyway migrations are date-versioned (`V2026.10.02.001__create_table.sql`); Hibernate only validates.
- Configuration comes from env vars through `application.yaml`; port 8080; `spring.application.name=<name>`.

## Hardening overrides

1. **Passwords**: Argon2id (`Argon2PasswordEncoder`, spring-security-crypto + Bouncy Castle). The hash lives only in account-service; no `Out` record carries a password or hash. (Reference: unsalted SHA-256.)
2. **JWT**: asymmetric (RS256/ES256), access token 5–60 min. auth-service signs and publishes a JWKS; the gateway validates locally from the cached JWKS, so no request-path call to auth-service. (Reference: HS256 + `/auth/solve` on every request.)
3. **Resilience**: every outbound call has an explicit timeout (about the downstream P99.9, per dependency). Feign runs through Resilience4j (`spring.cloud.openfeign.circuitbreaker.enabled`):
   - circuit breaker opens at 50% failures over the last 10–20 calls, waits 30–60 s, probes with 3–5 half-open calls;
   - retry with exponential backoff + jitter on idempotent calls only (GET/PUT/DELETE; POST only with an idempotency key);
   - a bulkhead per dependency; token-bucket rate limiting at the gateway.
4. **Collections**: `page`/`size` with a maximum size. The existing `account` library's `findAll()` becomes paged.
5. **Containers**: pinned image tags, multi-stage Dockerfile, non-root user; K8s liveness/readiness probes (`/actuator/health/liveness|readiness`) with requests and limits.
6. **Actuator and Prometheus** run on a management port (8081) that is never published and never routed by the gateway. (Reference routes `/<svc>/actuator` through the gateway.)

## LGPD working rules (confirm with legal/DPO)

- Collect only fields a feature needs; record the purpose of each.
- Logs, traces, metrics and events carry ids; email, name, passwords, tokens and prompt content stay out.
- `DELETE /accounts/{id}` erases or irreversibly anonymizes the data and reaches every service holding it. Each service holding personal data states how it erases and how it exports.
- TLS in transit, encrypted DB volumes at rest, secrets from env or a secret manager, never in a repo or a default value.

## Stack

Versions come from `back/api/account/pom.xml` (Java 25 LTS — Boot 4.1 supports up to 26 —, Spring Boot 4.1, Spring Cloud 2025.1, Maven, Lombok). Tests: JUnit + Testcontainers 2; CI: `back/.github/workflows/ci.yaml` (`mvn -B verify`, compose up, `smoke.sh`). Postgres 17 + Flyway; gateway on WebFlux (`spring-cloud-starter-gateway-server-webflux`), other services on `spring-boot-starter-webmvc`. Boot 4 renamed several starters, so confirm artifact names with `mvn verify`.

Later phases (nginx, Redis, Kafka, observability, K8s, CI): read [references/platform.md](references/platform.md) before adding any of them.

## Review checklist

A change is done when each item holds:

- Every hardening override above is met.
- `grep -ri store` over the changed modules returns nothing.
- No `latest` image tag, no default password, no unbounded collection endpoint.
- No personal data in logs, events or caches that outlive an erasure.
