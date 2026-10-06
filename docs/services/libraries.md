# Libraries

## What it is

Five of the thirteen modules under `api/` are libraries: `auth`, `account`, `organization`, `usage` and
`billing`. Each one holds a single `XController` Feign interface and the `In`/`Out` records that cross the
wire, so that a caller and the service implementing it compile against one definition of the contract.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="lib-title" aria-describedby="lib-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="lib-title">The five contract libraries and every service that depends on them</title>
  <desc id="lib-desc">Five libraries on the left, eight services on the right, with one line per dependency
  and no line running back from a service to a library it does not use. The only library-to-library
  dependency is the auth contract using the account contract.</desc>
  <defs>
    <marker id="lib-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: the auth contract, the account contract, the organization hub, usage and
       billing, and last the one library-to-library edge. -->
  <g id="lib-hops">
    <path id="lib-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M380 76 H390 V98 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M380 76 H400 V128 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M380 108 H410 V134 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop4" class="cmn-link cmn-link--flow cmn-dash" d="M380 140 H420 V106 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M380 140 H430 V140 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop6" class="cmn-link cmn-link--flow cmn-dash" d="M380 140 H440 V166 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop7" class="cmn-link cmn-link--flow cmn-dash" d="M380 140 H450 V192 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop8" class="cmn-link cmn-link--flow cmn-dash" d="M380 140 H460 V224 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop9" class="cmn-link cmn-link--flow cmn-dash" d="M380 140 H470 V262 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop10" class="cmn-link cmn-link--flow cmn-dash" d="M380 172 H480 V198 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop11" class="cmn-link cmn-link--flow cmn-dash" d="M380 172 H490 V230 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop12" class="cmn-link cmn-link--flow cmn-dash" d="M380 204 H500 V236 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop13" class="cmn-link cmn-link--flow cmn-dash" d="M380 204 H510 V204 H540" marker-end="url(#lib-arrow)"/>
    <path id="lib-hop14" class="cmn-link cmn-link--flow cmn-dash" d="M230 76 H205 V108 H230" marker-end="url(#lib-arrow)"/>
  </g>
  <g class="cmn-node cmn-node--entry cmn-node--flow" id="lib-auth" aria-labelledby="lib-auth-label"><rect x="230" y="62" width="150" height="28" rx="10"/><text id="lib-auth-label" x="305" y="76">api/auth</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-account" aria-labelledby="lib-account-label"><rect x="230" y="94" width="150" height="28" rx="10"/><text id="lib-account-label" x="305" y="108">api/account</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-organization" aria-labelledby="lib-organization-label"><rect x="230" y="126" width="150" height="28" rx="10"/><text id="lib-organization-label" x="305" y="140">api/organization</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-usage" aria-labelledby="lib-usage-label"><rect x="230" y="158" width="150" height="28" rx="10"/><text id="lib-usage-label" x="305" y="172">api/usage</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-billing" aria-labelledby="lib-billing-label"><rect x="230" y="190" width="150" height="28" rx="10"/><text id="lib-billing-label" x="305" y="204">api/billing</text></g>
  <g class="cmn-node cmn-node--soft" id="lib-gateway" aria-labelledby="lib-gateway-label"><rect x="540" y="24" width="170" height="28" rx="10"/><text id="lib-gateway-label" x="625" y="38">gateway-service</text></g>
  <g class="cmn-node cmn-node--soft" id="lib-inference" aria-labelledby="lib-inference-label"><rect x="540" y="56" width="170" height="28" rx="10"/><text id="lib-inference-label" x="625" y="70">inference-service</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-auth-service" aria-labelledby="lib-auth-service-label"><rect x="540" y="88" width="170" height="28" rx="10"/><text id="lib-auth-service-label" x="625" y="102">auth-service</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-account-service" aria-labelledby="lib-account-service-label"><rect x="540" y="120" width="170" height="28" rx="10"/><text id="lib-account-service-label" x="625" y="134">account-service</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-org-service" aria-labelledby="lib-org-service-label"><rect x="540" y="152" width="170" height="28" rx="10"/><text id="lib-org-service-label" x="625" y="166">organization-service</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-usage-service" aria-labelledby="lib-usage-service-label"><rect x="540" y="184" width="170" height="28" rx="10"/><text id="lib-usage-service-label" x="625" y="198">usage-service</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-billing-service" aria-labelledby="lib-billing-service-label"><rect x="540" y="216" width="170" height="28" rx="10"/><text id="lib-billing-service-label" x="625" y="230">billing-service</text></g>
  <g class="cmn-node cmn-node--flow" id="lib-batch-service" aria-labelledby="lib-batch-service-label"><rect x="540" y="248" width="170" height="28" rx="10"/><text id="lib-batch-service-label" x="625" y="262">batch-service</text></g>
  <!-- One packet per library, on the edge to the service that implements it. -->
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M380 76 H390 V98 H540'); --cmn-travel: 1.2s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M380 108 H410 V134 H540'); --cmn-travel: 1.2s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M380 140 H440 V166 H540'); --cmn-travel: 1.2s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M380 172 H480 V198 H540'); --cmn-travel: 1.2s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M380 204 H500 V236 H540'); --cmn-travel: 1.2s; --cmn-delay: 1.2s;"></circle>
  <rect class="cmn-label-plate" x="230" y="2" width="150" height="16" rx="4"/><text class="cmn-label" x="305" y="14">start here: the contract</text>
  <rect class="cmn-label-plate" x="540" y="2" width="170" height="16" rx="4"/><text class="cmn-label" x="625" y="14">and who depends on it</text>
  <rect class="cmn-label-plate" x="168" y="84" width="36" height="16" rx="4"/><text class="cmn-label" x="186" y="96">uses</text>
</svg>
</div>
<figcaption>Every line runs from a contract to a service that compiles against it, and none runs back. The
packet on each library's own line marks the service that implements it; the travelling dashes on the rest show
the same direction, from the contract to its consumers. The two grey nodes have no incoming line at all, and
the one short edge on the left is the only place where a library uses another library.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a compile-time dependency, contract to service (solid, dashes travelling)</span>
</div>

1. **Read left to right.** A line means the service on the right has this library on its classpath; there is no
   line from a service back to a library, and no cycle anywhere in the graph.
2. **`api/auth` is the entry point of this diagram** — the one library that itself depends on another, because
   `AuthController.whoami` returns an `AccountOut` from `api/account`.
3. **`api/organization` has six consumers**, the most of any library, because a membership check is needed
   wherever an organization's data is read or written.
4. **`api/usage` and `api/billing` do not depend on each other.** Their *services* do: usage-service reads
   billing's prices to explain a charge, and billing-service reads usage's sealed windows to make one.
5. **`gateway-service` and `inference-service` have no line at all.** Neither has a library, because no Java
   caller needs its types.
6. **Each packet travels the line from a library to the service that implements it** — `api/auth` to
   auth-service, `api/organization` to organization-service, and so on for the other three.

## Why a library exists at all

A service's contract has two ends: the code that calls it and the code that implements it. Written twice, the
two ends drift — a field is renamed on one side, a `String` becomes an `Instant` on the other, and the
compiler has nothing to say about it until something fails in production. With a library the contract is
written once: `AuthResource implements AuthController`, `AccountResource implements AccountController`, and a
change to a record breaks the build on both sides at the same time. The compiler is the integration test that
never gets skipped.

## What belongs in one

A library module contains:

- **one `@FeignClient` interface**, the `XController`, which the service implements;
- **the `In`/`Out` records** that interface exchanges — Lombok `@Builder` records, so the wire shape and the
  constructor are the same declaration;
- **shared value types both sides compute with.** `Price` is the one example: billing-service bills a window
  with `Price.cost`, and usage-service explains that same charge to the customer with it, so the record and its
  rounding live in `api/billing` rather than in either service.

It contains no entity, no repository, no `@Service` and no `@SpringBootApplication`. Its dependencies are
`spring-cloud-starter-openfeign` and Lombok, and nothing else.

| Library | Interface | Records |
|---|---|---|
| `api/account` | `AccountController` | `AccountIn`, `AccountOut`, `AccountExportOut` (with `Membership`), `TokenIn`, `PasswordResetIn`, `PasswordResetConfirmIn` |
| `api/auth` | `AuthController` | `RegisterIn`, `LoginIn`, `TokenOut`, `ApiKeyIn`, `ApiKeyCreatedOut`, `ApiKeyOut`, `ApiKeyPrincipalOut` |
| `api/organization` | `OrganizationController` | `OrganizationIn`, `OrganizationOut`, `MemberOut`, `TenantOut` |
| `api/usage` | `UsageController` | `UsageEventIn`, `UsageWindowOut`, `UsageTotalOut`, `UsageSummaryOut` |
| `api/billing` | `BillingController` | `GrantIn`, `BalanceOut`, `Price` |

The split between public and internal is visible in the interfaces themselves. `AuthController` carries both
`POST /auth/login`, which the gateway routes, and `GET /api-keys/{hash}`, which is internal only;
`AccountController` carries `POST /accounts`, which auth-service calls, and `POST /accounts/verify-email`,
which the gateway routes. The library does not mark which is which — the gateway's route table does, and
[Gateway](gateway.md) lists it.

## The `url` convention

Every interface declares its target the same way:

```java
@FeignClient(name = "organization", url = "${carmonai.organization.url:http://organization:8080}")
```

Two things are happening in that one string. The default, `http://organization:8080`, is what the compose
network resolves — the service name is the hostname. The property placeholder, `carmonai.organization.url`, is
what a test sets to point the same client at a stub, so an integration test can exercise account-service's
erasure without a real organization-service behind it. The source comments say exactly this: *"url is a
placeholder so tests can point the client at a stub; compose resolves the default."*

The same trick appears outside the libraries, which is why it is worth knowing. `GatewayApplication` builds its
`WebClient` with `baseUrl("http://auth:8080")`, and its JWT decoder takes
`@Value("${carmonai.jwt.jwks-uri:http://auth:8080/auth/jwks}")` so the gateway's integration test can point it
at a JWKS stub.

The wire details that Feign makes awkward are decided once, here, rather than in each caller:

- **Cookies travel as a header.** Spring has no Feign equivalent of `@CookieValue`, so `AuthController.refresh`
  and `logout` take `@RequestHeader("Cookie") String`.
- **Instants travel in the body, not as query parameters.** `ApiKeyIn.expiresAt` is an `Instant` in the JSON
  body, and the comment explains why: `@DateTimeFormat` on an `Instant` breaks the Feign side.
  `UsageController.nextWindow(@RequestParam Instant after)` is the other case — an ISO-8601 instant in the
  query string with no `@DateTimeFormat` at all, because its formatter fails on an `Instant`, which has no
  zone.

## The two services with no library

`inference-service` and `batch-service` have none, and the reason is the same for both: **no Java caller needs
their types.**

- **inference-service** is spoken to in HTTP by the gateway, which is a proxy and not a Feign client, and by
  batch-service, which posts the customer's own JSON. There is no Java type to share — the body is the
  contract, and it is OpenAI's.
- **batch-service** uses the JDK's `java.net.http.HttpClient`, not Feign: `BatchWorker` posts the line's body
  to `carmonai.batch.inference-url` + `/v1/chat/completions` with the `batch-line` header the gateway would
  otherwise strip. A shared interface would only get in the way of passing a body through untouched.
- **gateway-service** is in the same position from the other side. It calls auth-service's internal
  `GET /api-keys/{hash}` and account-service over plain HTTP, with its own `WebClient`, because a gateway filter
  has nothing to gain from a typed client.

The rule that falls out: a library exists where a Java caller and a Java implementation share types, and
nowhere else. Five services, five libraries.

## What a change costs

Each library is its own Git repository, pinned by commit in `back`'s `.gitmodules`. So adding one field to one
record is a sequence, not a single commit: change the record in the library's repository and merge it there,
update the submodule pointer in `back`, then rebuild the implementing service and every caller, which now
either compiles or does not.

That last step is where the arrangement pays for itself. CI runs `mvn -B verify` at the root, and the
aggregator `pom.xml` lists all thirteen modules so the reactor builds them in dependency order: `api/account`
before `api/auth`, `api/organization` before the six services that call it. A contract change that breaks a
caller fails the build rather than a request.

The cost is real and worth stating plainly: a change to a record that five services use is a change in six
repositories, and the libraries are not versioned — every module carries version `1.0.0` and the reactor builds
them together, so there is no released-version negotiation to fall back on.

## Why it is like this

**The contract lives in the middle, not in the service.** A library owned by the implementing service would
tempt the implementer to change it unilaterally. A separate repository makes a contract change a visible event
in its own history.

**Records, not entities.** No `Out` record in any of the five libraries has a password field, a token hash or a
secret — `AccountOut` is `(id, name, email)`, `ApiKeyOut` carries a four-character `hint` and never the key
itself, and `TenantOut` is `(id, status, tier)` with no name. The wire shape is a deliberate subset of the
table, and writing it down in a library is what keeps it a subset.

**One shape, two implementations, deliberately.** The gateway's `ApiKeyFormat` mirrors auth-service's `ApiKeys`
— prefix, 43 base62 characters, a 6-character CRC32 — and both files say "change both together". The gateway
cannot depend on auth-service's jar and must validate a key with no I/O, so the shape is written twice; it is
the one duplication in the arrangement, and it is commented as such.

## What would change it

- **The key format is duplicated between `ApiKeys` and `ApiKeyFormat`.** Moving it into a sixth library would
  remove the duplication and give the gateway a dependency on a module whose only other purpose is to be
  implemented by a service it must not call synchronously.
- **The libraries are unversioned and built from one reactor.** Thirteen modules in one build means a contract
  change rebuilds everything, which is safe and slow. Publishing them as versioned artifacts would make the
  upgrade explicit per consumer, at the cost of tracking which service is on which version.
- **`url` placeholders are per-service configuration.** A service registry or discovery would replace them, and
  would also take away the property a test uses to point a client at a stub.
- **A change still spans repositories.** One Git repository per module is the user's decision, and its cost
  lands squarely on the contracts: the more services share a record, the more submodule pointers move together.

## Where to look

- [AuthController.java](https://github.com/carmonai/back/blob/main/api/auth/src/main/java/ai/carmonai/auth/AuthController.java) — the largest contract, public and internal.
- [OrganizationController.java](https://github.com/carmonai/back/blob/main/api/organization/src/main/java/ai/carmonai/organization/OrganizationController.java) — the six-consumer contract, in full.
- [Price.java](https://github.com/carmonai/back/blob/main/api/billing/src/main/java/ai/carmonai/billing/Price.java) — the one type both sides of the money compute with.
- [organization/pom.xml](https://github.com/carmonai/back/blob/main/api/organization/pom.xml) — everything a library module is allowed to depend on.
- [pom.xml](https://github.com/carmonai/back/blob/main/pom.xml) — the thirteen modules the reactor builds in order.
