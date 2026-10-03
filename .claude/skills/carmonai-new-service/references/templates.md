# Templates

Artifact names and versions: take them from `back/api/account/pom.xml` and confirm with `mvn verify` (Spring Boot 4 renamed starters, e.g. `starter-web` → `starter-webmvc`).

## Service pom — additions to the library pom

Copy parent, properties and compiler plugin from `back/api/account/pom.xml`; set artifactId `<name>-service`. Add:

- `spring-boot-starter-webmvc`, `spring-boot-starter-data-jpa`, `org.postgresql:postgresql`
- `flyway-core` + `flyway-database-postgresql`
- `spring-boot-starter-actuator`, `micrometer-registry-prometheus` (runtime)
- `spring-cloud-starter-circuitbreaker-resilience4j`
- `spring-security-crypto` + `org.bouncycastle:bcprov-jdk18on` (account-service only)
- the library: `ai.carmonai:<name>:${project.version}`
- `spring-boot-maven-plugin` excluding lombok
- tests: `spring-boot-starter-test` (test); with a DB also `org.testcontainers:testcontainers-postgresql` (test, Testcontainers 2.x: class `org.testcontainers.postgresql.PostgreSQLContainer`) and the `maven-failsafe-plugin`, so `*IT` classes run in `mvn verify` but not in `mvn package`

## Tests

- Plain JUnit, no mocks, for logic with branches (examples: `RateLimitFilterTest`, `IdempotentRetryerTest`, `JwtServiceTest`).
- One `XServiceIT` per DB service, modelled on `back/api/account-service/src/test/java/ai/carmonai/account/AccountServiceIT.java`:
  - a static Postgres container pinned to the compose digest; `@DynamicPropertySource` feeds the same `DATABASE_*` env names compose sets, so the real datasource URL is under test;
  - `@SpringBootTest(webEnvironment = RANDOM_PORT, properties = "management.server.port=0")`;
  - the service is called through its library's Feign interface with `new FeignClientBuilder(context).forType(XController.class, "x-it").url("http://localhost:" + port).build()`: that is the Resource/Feign contract check;
  - one test that hits a DB constraint directly with `JdbcTemplate`.
- Money and security paths get one integration test each.

## application.yaml

```yaml
server:
  port: 8080
spring:
  application:
    name: <name>
  datasource:
    url: jdbc:postgresql://${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_DB}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
  flyway:
    baseline-on-migrate: true
    schemas: <schema>            # aggregate plural, e.g. accounts
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        default_schema: <schema>
  cloud:
    openfeign:
      circuitbreaker:
        enabled: true
      client:
        config:
          default:
            connect-timeout: 1000   # starting values; tune per dependency
            read-timeout: 3000
management:
  server:
    port: 8081                      # never published, never routed
  endpoint:
    health:
      probes:
        enabled: true
  endpoints:
    web:
      exposure:
        include: health,prometheus
logging:
  structured:
    format:
      console: ecs                  # JSON lines on stdout; ids only, never request bodies
```

## Dockerfile

CI builds the jar first (`mvn verify` from `back/`), which resolves the library; the image only packages it. Java 25 LTS runtime: `eclipse-temurin:25-jre-noble` pinned by digest (copy the `FROM` lines from an existing service; refresh with `docker buildx imagetools inspect`).

```dockerfile
FROM eclipse-temurin:<25-jre-noble-pinned> AS builder
WORKDIR /builder
COPY target/*.jar application.jar
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

FROM eclipse-temurin:<25-jre-noble-pinned>
RUN useradd --system --uid 10001 app
WORKDIR /application
COPY --from=builder --chown=app /builder/extracted/dependencies/ ./
COPY --from=builder --chown=app /builder/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=app /builder/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=app /builder/extracted/application/ ./
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "application.jar"]
```

Health checking is the orchestrator's job: compose `healthcheck` and K8s probes call the actuator on 8081. The JRE image has no curl; compose probes with bash's `/dev/tcp` (see `x-readiness` in `back/docker/compose.yaml`).

## Pitfalls already hit

- Lombok: Boot 4.1 manages 1.18.46, which fails when the build JDK is 27 (the local machine has 24 and 27, no 25); every pom with Lombok sets `<lombok.version>1.18.48</lombok.version>`. Code targets Java 25 (`<java.version>25</java.version>`); CI and images run 25.
- Stale library jars: after changing `java.version` (or anything a library's jar should reflect), build with `mvn clean install -DskipTests` from `back/`. The jar plugin can skip re-creating an "up to date" jar, and `-pl <service>` without `-am` resolves the library from `~/.m2`. Symptom: `Failed to read candidate component class` at startup (class file too new for the runtime).
- Boot 4 split the HTTP clients out: the auto-configured `WebClient.Builder` needs `spring-boot-starter-webclient` (without it: "required a bean of type WebClient$Builder").
- Boot 4 uses Jackson 3 (`tools.jackson.databind`): `JsonNode.asString()`/`isString()` replace `asText()`/`isTextual()`; `JsonMapper` is the bean to inject.
- Spring 7 renamed 413: use `HttpStatus.CONTENT_TOO_LARGE` (`PAYLOAD_TOO_LARGE` is a deprecated alias, and `HttpStatus.resolve(413)` returns the new name).
- Reactor `retryWhen(Retry.max(n))` wraps the last error in "retries exhausted"; add `.onRetryExhaustedThrow((spec, signal) -> signal.failure())` so the real error maps to the right status.
- A service that calls another one in its IT: stub the other side with the JDK's `com.sun.net.httpserver.HttpServer` (no extra dependency) and point the Feign/WebClient URL at it (libraries declare `url="${carmonai.<name>.url:http://<name>:8080}"`).
- `MockServerHttpRequest` has no native request: code that reads one (e.g. the HTTP version) must tolerate its absence.
- llama.cpp server: the API key env var is `LLAMA_API_KEY` (not `LLAMA_ARG_API_KEY`); always check an engine refuses a request without its key.
- vLLM in compose (`vllm/vllm-openai`): the entrypoint is `vllm serve`, so `command` starts with the model; the key comes from `VLLM_API_KEY`; no curl in the image (health checks use `python3`); GPUs via `deploy.resources.reservations.devices` (driver nvidia).
- vLLM on a Windows laptop GPU: Windows keeps ~1 GB of VRAM for the desktop and CUDA under WSL2 costs ~0.9 GiB more, so size `--gpu-memory-utilization` from the free memory at startup (vLLM refuses to start otherwise) and read "Available KV cache memory" in its log. `--kv-cache-dtype fp8` halves the KV cache per token when a full-length request doesn't fit.
- `vllm bench serve --help` only lists groups; `--help=all` shows every flag. Pass the key with `--header "Authorization=Bearer $VLLM_API_KEY"`, expanded inside the container.
- Feign + Resilience4j: add `resilience4j-bulkhead` (the starter lacks it, so no bulkhead runs) and set `spring.cloud.circuitbreaker.resilience4j.disable-time-limiter`, `disable-thread-pool` and `enable-semaphore-default-bulkhead` to true; with the thread pool on, a downstream 4xx arrives wrapped in `ExecutionException`. Ignore `feign.FeignException$FeignClientException` in the breaker so 4xx answers don't open it.
- Gateway security also guards the management port: permit `/actuator/health/**` and `/actuator/prometheus`.
- `JWT_PRIVATE_KEY` must be PKCS#8: take the body of `openssl genpkey` PEM output; some openssl builds write `-outform DER` as PKCS#1.
- Instant query parameters on a shared `@FeignClient` interface: no `@DateTimeFormat` (Feign formats through it and fails with `UnsupportedTemporalTypeException`); plain `Instant` round-trips as ISO-8601 on both sides.
- Anything taken per request and given back at the end (a permit, a slot): `Flux/Mono.usingWhen(acquire, use, release)`. A `doFinally` on the body never runs if the client leaves before WebFlux subscribes the body, and the slot leaks.
- vLLM with `continuous_usage_stats`: every stream chunk carries `usage`; read the last one, not the first.
- Docker Desktop's VM (7.6 GB here) holds vLLM, llama.cpp and nine JVMs with little room left: no second Python/torch process beside them (`vllm bench serve` twice ran it out of memory, hung WSL and got vLLM OOM-killed). Load-test with curl from the llama container.
- curl uploads from Git Bash on Windows: `-F "file=@/tmp/x"` can't open the MSYS path (exit 26); send the file on stdin, `-F "file=@-;filename=x.jsonl" < /tmp/x`.
- `mvn -pl api/<service> verify` resolves the `ai.carmonai` libraries from `~/.m2`: add `-am` to build them in the same run.
- Reactor `Sinks.many().unicast()` takes one emitter at a time: `tryEmitNext` from several threads at once returns `FAIL_NON_SERIALIZED` and the value is lost. Serialize the emit (`synchronized`) or use `emitNext` with `EmitFailureHandler.busyLooping`.
- Scripts that pass container paths from Git Bash (`docker compose exec svc touch /tmp/x`): prefix that one call with `MSYS_NO_PATHCONV=1`, or MSYS rewrites `/tmp/x` into a Windows path. Not globally: Windows curl then can't open `-o /dev/null` (exit 23).
- vLLM's finish counters (`request_success_total`, `request_prompt_tokens_count`) skip aborted requests, even with `finished_reason="abort"` listed: a cancelled request vanishes from them. `num_requests_running` shows the abort.
- Reactor `bufferTimeout(size, time)` in front of a slow consumer (`concatMap`): a timer flush with no demand throws `OverflowException` and kills the pipeline for good. Use `bufferTimeout(size, time, true)` (fair backpressure).
- Gateway `WebFilter` outside the security chain (e.g. an access log that must see refused requests too): `exchange.getPrincipal()` is empty there; pass the caller's ids through exchange attributes set further in.
- Spring Cloud Gateway appends the routed response's headers to what a filter already set: set a response header in `beforeCommit` to have exactly one.
- A separate log file next to Boot's structured console logging: `logback-spring.xml` including `defaults.xml` + `console-appender.xml` (keeps `logging.structured.*`), plus an appender with `org.springframework.boot.logging.logback.StructuredLogEncoder` (`<format>ecs</format>`) for the file; key-value pairs (`log.atInfo().addKeyValue(…)`) become JSON fields. A named volume mounted on a directory the image creates (`install -d -o app`) keeps that ownership.
- Timeouts nest: the gateway's `response-timeout` must exceed the worst case of the service behind it, retries included.

## back/docker/compose.yaml

Service names are hostnames (`account`, `auth`, `gateway`), because the Feign clients use `http://<name>:8080`.

```yaml
name: carmonai
services:
  db:
    image: postgres:17.<pinned>
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes: [db-data:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
    networks: [internal]
  account:
    build: ../api/account-service
    environment:
      DATABASE_HOST: db
      DATABASE_PORT: 5432
      DATABASE_DB: ${DB_NAME}
      DATABASE_USERNAME: ${DB_USER}
      DATABASE_PASSWORD: ${DB_PASSWORD}
    depends_on:
      db: { condition: service_healthy }
    networks: [internal]
  gateway:
    build: ../api/gateway-service
    ports: ["8080:8080"]
    networks: [internal]
networks:
  internal: {}
volumes:
  db-data: {}
```

`.env` stays untracked; commit `.env.example` with placeholder values only. No default passwords anywhere.
