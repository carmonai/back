# Operations

This section is for the person who has to make the platform run, prove it runs, and see what it is doing
while it does. It assumes the repository is checked out and Docker is installed; it does not assume anything
is already running.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dops-title" aria-describedby="dops-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dops-title">Building the stack, checking it, and watching it</title>
  <desc id="dops-desc">Maven verifies every module and its tests, then compose builds and starts the fourteen
  containers and waits for their health checks. The smoke test drives the whole stack through the gateway.
  Two further checks run against the same stack: a load bench on the GPU and a check of the books. Prometheus
  scrapes every service's management port and the engine's own metrics endpoint every fifteen seconds, Grafana
  draws the provisioned dashboards, and seven alert rules are evaluated with nowhere to send them.</desc>

  <defs>
    <marker id="dops-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1-2 the build, 3-5 the checks, 6 the scrape, 7 the dashboards. -->
  <g id="dops-hops">
    <path id="dops-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M144 76 H176" marker-end="url(#dops-arrow-flow)"/>
    <path id="dops-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M308 76 H340" marker-end="url(#dops-arrow-flow)"/>
    <path id="dops-hop3" class="cmn-link cmn-link--flow"
          d="M250 104 V176" marker-end="url(#dops-arrow-flow)"/>
    <path id="dops-hop4" class="cmn-link cmn-link--flow"
          d="M405 104 V176" marker-end="url(#dops-arrow-flow)"/>
    <path id="dops-hop5" class="cmn-link cmn-link--flow"
          d="M537 104 V176" marker-end="url(#dops-arrow-flow)"/>
    <path id="dops-hop6" class="cmn-link cmn-link--flow cmn-dash"
          d="M592 76 H624" marker-end="url(#dops-arrow-flow)"/>
    <path id="dops-hop7" class="cmn-link cmn-link--quiet"
          d="M242 48 V26 H537 V48" marker-end="url(#dops-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--flow" id="dops-verify" aria-labelledby="dops-verify-label">
    <rect x="16" y="48" width="128" height="56" rx="10"/>
    <text id="dops-verify-label" x="80" y="68">mvn -B verify</text>
    <text class="cmn-sub" x="80" y="86">unit + IT</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dops-compose" aria-labelledby="dops-compose-label">
    <rect x="176" y="48" width="132" height="56" rx="10"/>
    <text id="dops-compose-label" x="242" y="68">compose up</text>
    <text class="cmn-sub" x="242" y="86">14 containers</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dops-smoke" aria-labelledby="dops-smoke-label">
    <rect x="340" y="48" width="110" height="56" rx="10"/>
    <text id="dops-smoke-label" x="395" y="68">smoke.sh</text>
    <text class="cmn-sub" x="395" y="86">end to end</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dops-prometheus" aria-labelledby="dops-prometheus-label">
    <rect x="482" y="48" width="110" height="56" rx="10"/>
    <text id="dops-prometheus-label" x="537" y="68">Prometheus</text>
    <text class="cmn-sub" x="537" y="86">scrapes :8081</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dops-grafana" aria-labelledby="dops-grafana-label">
    <rect x="624" y="48" width="120" height="56" rx="10"/>
    <text id="dops-grafana-label" x="684" y="68">Grafana</text>
    <text class="cmn-sub" x="684" y="86">dashboards</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dops-bench" aria-labelledby="dops-bench-label">
    <rect x="200" y="176" width="120" height="56" rx="10"/>
    <text id="dops-bench-label" x="260" y="196">bench.sh</text>
    <text class="cmn-sub" x="260" y="214">the GPU load</text>
  </g>

  <g class="cmn-node cmn-node--money" id="dops-revenue" aria-labelledby="dops-revenue-label">
    <rect x="350" y="176" width="150" height="56" rx="10"/>
    <text id="dops-revenue-label" x="425" y="196">revenue-check</text>
    <text class="cmn-sub" x="425" y="214">the books</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dops-rules" aria-labelledby="dops-rules-label">
    <rect x="530" y="176" width="110" height="56" rx="10"/>
    <text id="dops-rules-label" x="585" y="196">rules.yml</text>
    <text class="cmn-sub" x="585" y="214">7 alerts</text>
  </g>

  <!-- Payloads -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M144 76 H176'); --cmn-travel: 0.6s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M308 76 H340'); --cmn-travel: 0.6s; --cmn-delay: 0.15s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M250 104 V176'); --cmn-travel: 0.9s; --cmn-delay: 0.4s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M405 104 V176'); --cmn-travel: 0.9s; --cmn-delay: 0.55s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M537 104 V176'); --cmn-travel: 0.9s; --cmn-delay: 0.7s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M592 76 H624'); --cmn-travel: 0.5s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M242 48 V26 H537 V48'); --cmn-travel: 1.6s; --cmn-delay: 1.1s;"></circle>

  <!-- Labels -->
  <rect class="cmn-label-plate" x="106" y="106" width="70" height="16" rx="4"/>
  <text class="cmn-label" x="141" y="118">green build</text>
  <rect class="cmn-label-plate" x="296" y="106" width="56" height="16" rx="4"/>
  <text class="cmn-label" x="324" y="118">healthy</text>
  <rect class="cmn-label-plate" x="592" y="106" width="64" height="16" rx="4"/>
  <text class="cmn-label" x="624" y="118">dashboards</text>
  <rect class="cmn-label-plate" x="140" y="150" width="100" height="16" rx="4"/>
  <text class="cmn-label" x="190" y="162">the GPU stack</text>
  <rect class="cmn-label-plate" x="300" y="150" width="100" height="16" rx="4"/>
  <text class="cmn-label" x="350" y="162">the books</text>
  <rect class="cmn-label-plate" x="440" y="150" width="90" height="16" rx="4"/>
  <text class="cmn-label" x="485" y="162">alert rules</text>
  <rect class="cmn-label-plate" x="330" y="18" width="140" height="16" rx="4"/>
  <text class="cmn-label" x="400" y="30">actuator, every 15 s</text>
</svg>
</div>
<figcaption>Steps 1 and 2 are the build: Maven verifies every module and its tests, then compose builds the
images, starts the fourteen containers and waits for their health checks before returning. Step 3 is `smoke.sh`
driving the running stack through the gateway. Steps 4 and 5 are the two checks that need a running stack and
a reason to run them — the GPU load bench and the books. Step 6 is the metrics flow, which is asynchronous and
independent of every check: Prometheus scrapes each service's management port and the engine's own `/metrics`
every 15 s. Step 7 is Grafana drawing the provisioned dashboards, and `rules.yml` evaluating seven alert rules
with nowhere to send them.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a step you run, in order (solid)</span>
  <span><i class="is-async"></i> a scrape, happening on its own (dotted)</span>
  <span><i class="is-money"></i> a check of the money (dashed, gold)</span>
  <span><i class="is-accent"></i> the observability stack (teal outline)</span>
</div>

1. **`mvn -B clean verify` from the repository root** builds all thirteen modules in dependency order and runs
   the unit tests plus one Testcontainers integration test per database service.
2. **`docker compose up -d --build --wait`** starts fourteen containers and blocks until every health check
   passes. `.env` must exist first; compose refuses to start without it.
3. **`bash smoke.sh`** drives the stack through the gateway end to end — accounts, sessions, organizations,
   API keys, inference on both engines, usage, billing, the Batch API, erasure and a canary sweep.
4. **`bash bench.sh`** runs the load check on the GPU stack: three tiers at once, 60 s, with goodput and
   refusal-latency pass marks.
5. **`bash revenue-check.sh`** calls billing's reconciliation on its management port and exits non-zero when
   any balance differs from the sum of its ledger.
6. **Prometheus scrapes** every service's `:8081/actuator/prometheus` and the engine's `/metrics` every 15 s.
   Nothing is published: the metrics stay on the internal network, like the port they come from.
7. **Grafana draws three provisioned dashboards and lists the seven alert rules** Prometheus evaluates. No
   notification leaves the machine, because no destination has been chosen.

## What it is

Three things, in the order you meet them. **Running it** is a `.env` file, Maven and one compose command.
**Checking it** is four shell scripts with pass marks, each of which fails loudly. **Watching it** is a
Prometheus and a Grafana on the internal network, scraping the same management ports the health checks use.

## What you need

Docker Desktop on WSL2 with the NVIDIA runtime if you want the GPU model, a JDK that can compile with
`--release 25`, and about an hour the first time — the two model images download roughly 3.6 GB between them.
The exact prerequisites, the `openssl` commands `.env` needs, and the memory the stack actually consumes are
in [Running it locally](running.md), which is written to be followed top to bottom.

## The checks

| Command | Environment | Passes when | Typical duration |
|---|---|---|---|
| `mvn -B clean verify` | any | every module builds, unit tests and Testcontainers ITs pass | a few minutes |
| `bash smoke.sh` | CPU stack (CI) or GPU stack | every assertion in 443 lines holds, including the canary sweep | 2–4 minutes |
| `bash bench.sh` | GPU stack only | enterprise goodput ≥ 95%, every trial 429 under 100 ms, no TTFT timeouts | ~90 s |
| `bash batch-bench.sh` | GPU stack only | a 10,000-line batch completes with one usage event per line, killed mid-call | ~20 minutes |
| `bash revenue-check.sh` | either | every balance equals the sum of its ledger | seconds |

`smoke.sh` is the one that matters most: it is the only check that exercises a real request end to end, and it
ends by grepping every container log, a `pg_dumpall`, the gateway's access log and Valkey's append-only file
for a canary string, a bearer token, the API key and a query string. A leak anywhere fails the run.

## What is watched

Prometheus and Grafana are part of `docker/compose.yaml`, provisioned entirely from files in `docker/`:
`docker/prometheus/prometheus.yml`, `docker/prometheus/rules.yml`, `docker/grafana/provisioning/` and
`docker/grafana/dashboards/`. Nothing is clicked into a container, and `allowUiUpdates: false` means a change
made in the browser will not survive the next restart — so it is not allowed to look like it did.

Both are operator tools on the internal network. Neither publishes a port, which is the same rule the
management ports follow, and the only host binding in the whole compose file is the gateway's `8080`.

[Metering what runs](observability.md) has the SLI list, the reconciliation tolerance and the gaps.

## How work ships

One GitHub Actions workflow in `back`, on every pull request and every push to `main`: fetch the thirteen
private module repositories with `CARMONAI_TOKEN`, `mvn -B verify`, generate a fresh `.env`, bring the stack
up, run `smoke.sh`, and dump the container logs when something failed. The docs site has its own workflow.
Both are described in [CI and shipping](ci.md).

## Why it is like this

**Checks that fail loudly, in scripts.** Every check here is a bash script with explicit pass marks that
exits non-zero. They are readable, they need no test framework, and they can be run by a person who has just
cloned the repository. The alternative — a CI-only test suite — would make "does it work?" a question you
have to push a branch to answer.

**The same checks locally and in CI.** CI runs the same `mvn -B verify`, the same `compose up`, and the same
`smoke.sh`, on the CPU engine. The GPU-only checks are excluded because GitHub's runners have no GPU; that is
the one genuine difference, and it is stated rather than papered over with a stub.

**Observability as operator tools, not as a product.** Prometheus and Grafana run inside the compose network,
hold no data worth keeping (15 days of local TSDB) and publish nothing. That keeps the prototype's attack
surface to the gateway, at the cost of having to be on the machine to look at a dashboard.

## What would change it

- **A second machine.** The metrics, the dashboards and the alert rules assume the internal compose network.
  Kubernetes replaces the scrape targets and the provisioning paths, not the rules.
- **Someone who has to be woken up.** There is no Alertmanager and no destination. Firing state in Grafana
  and Prometheus is the deliverable until a channel is chosen.
- **Hosting.** The memory arithmetic on this page is the laptop's. A machine with more headroom changes the
  container limits, and possibly the decision to keep the engine on the same host as the services.
- **Per-service latency SLOs.** The RED dashboard shows max and mean, because `http_server_requests_seconds`
  is published without histogram buckets. Turning `percentiles-histogram` on in each service is the fix.

## Where to look

- [Running it locally](running.md) — prerequisites, `.env`, compose, the GPU overlay, memory reality.
- [Metering what runs](observability.md) — the SLIs, the dashboards, the alerts and the gaps.
- [CI and shipping](ci.md) — the workflow, the module token and the merge order.
- [Batch API design](batch-api.md) — how the asynchronous path works and what a crash proved.
- [Knowledge base](knowledge-base.md) — the project's own notes, and which of them to trust.
- [compose.yaml](https://github.com/carmonai/back/blob/main/docker/compose.yaml) — all fourteen services,
  their health checks and their dependencies, in one file.
