# Running it locally

This page is meant to be followed top to bottom on a machine that has never run Carmonai. Every command is the
one in the repository, and every file it names is one that exists. When you are done you have fourteen
containers, a passing smoke test, and two model engines — one of them on your GPU, if you have one.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="drun-title" aria-describedby="drun-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="drun-title">The order the stack starts in, and the health check that gates each wave</title>
  <desc id="drun-desc">Six waves of containers. The database, Valkey, Mailpit and the CPU engine start with
  nothing to wait for. The tenant services wait for the database. Authentication, billing and inference wait
  for the services and engines they call. The batch service waits for inference. The gateway waits for
  everything above it. Prometheus and Grafana start after the stack they scrape.</desc>

  <defs>
    <marker id="drun-arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- The boot order, with one hop into each wave. Reading order is top to bottom. -->
  <g id="drun-hops">
    <path id="drun-spine" class="cmn-link cmn-link--quiet" d="M184 29 V254"/>
    <path id="drun-hop1" class="cmn-link cmn-link--flow" d="M184 29 H200" marker-end="url(#drun-arrow)"/>
    <path id="drun-hop2" class="cmn-link cmn-link--flow" d="M184 74 H200" marker-end="url(#drun-arrow)"/>
    <path id="drun-hop3" class="cmn-link cmn-link--flow" d="M184 119 H200" marker-end="url(#drun-arrow)"/>
    <path id="drun-hop4" class="cmn-link cmn-link--flow" d="M184 164 H200" marker-end="url(#drun-arrow)"/>
    <path id="drun-hop5" class="cmn-link cmn-link--flow" d="M184 209 H200" marker-end="url(#drun-arrow)"/>
    <path id="drun-hop6" class="cmn-link cmn-link--flow" d="M184 254 H200" marker-end="url(#drun-arrow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="drun-w1" aria-labelledby="drun-w1-label">
    <rect x="200" y="10" width="540" height="38" rx="10"/>
    <text id="drun-w1-label" x="470" y="24">db · valkey · mailpit · llama</text>
    <text class="cmn-sub" x="470" y="38">nothing to wait for</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="drun-w2" aria-labelledby="drun-w2-label">
    <rect x="200" y="55" width="540" height="38" rx="10"/>
    <text id="drun-w2-label" x="470" y="69">account · organization · usage</text>
    <text class="cmn-sub" x="470" y="83">gate: db, mailpit</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="drun-w3" aria-labelledby="drun-w3-label">
    <rect x="200" y="100" width="540" height="38" rx="10"/>
    <text id="drun-w3-label" x="470" y="114">auth · billing · inference</text>
    <text class="cmn-sub" x="470" y="128">gate: valkey, usage, llama</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="drun-w4" aria-labelledby="drun-w4-label">
    <rect x="200" y="145" width="540" height="38" rx="10"/>
    <text id="drun-w4-label" x="470" y="159">batch</text>
    <text class="cmn-sub" x="470" y="173">gate: db, organization, inference</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="drun-w5" aria-labelledby="drun-w5-label">
    <rect x="200" y="190" width="540" height="38" rx="10"/>
    <text id="drun-w5-label" x="470" y="204">gateway</text>
    <text class="cmn-sub" x="470" y="218">gate: everything above</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="drun-w6" aria-labelledby="drun-w6-label">
    <rect x="200" y="235" width="540" height="38" rx="10"/>
    <text id="drun-w6-label" x="470" y="249">prometheus · grafana</text>
    <text class="cmn-sub" x="470" y="263">gate: prometheus first</text>
  </g>

  <circle class="cmn-packet cmn-travel" r="4"
          style="offset-path: path('M184 29 V254'); --cmn-travel: 2.2s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M184 29 H200'); --cmn-travel: 0.35s; --cmn-delay: 0.05s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M184 119 H200'); --cmn-travel: 0.35s; --cmn-delay: 0.85s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M184 209 H200'); --cmn-travel: 0.35s; --cmn-delay: 1.65s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M184 254 H200'); --cmn-travel: 0.35s; --cmn-delay: 2.05s;"></circle>

  <rect class="cmn-label-plate" x="8" y="21" width="168" height="16" rx="4"/>
  <text class="cmn-label" x="92" y="33">wave 1</text>
  <rect class="cmn-label-plate" x="8" y="66" width="168" height="16" rx="4"/>
  <text class="cmn-label" x="92" y="78">wave 2</text>
  <rect class="cmn-label-plate" x="8" y="111" width="168" height="16" rx="4"/>
  <text class="cmn-label" x="92" y="123">wave 3</text>
  <rect class="cmn-label-plate" x="8" y="156" width="168" height="16" rx="4"/>
  <text class="cmn-label" x="92" y="168">wave 4</text>
  <rect class="cmn-label-plate" x="8" y="201" width="168" height="16" rx="4"/>
  <text class="cmn-label" x="92" y="213">wave 5</text>
  <rect class="cmn-label-plate" x="8" y="246" width="168" height="16" rx="4"/>
  <text class="cmn-label" x="92" y="258">wave 6</text>
</svg>
</div>
<figcaption>Compose starts in waves, and each wave is gated by `depends_on` with `condition: service_healthy`.
The spine descends in the order the waves become ready. `llama` is in the first wave but reports healthy last:
its health check has a 600 s start period because the first run downloads the model.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-async"></i> the boot order (dotted)</span>
  <span><i class="is-flow"></i> a container becoming ready (solid)</span>
  <span><i class="is-accent"></i> the operator tools (teal outline)</span>
</div>

1. **`db`, `valkey`, `mailpit` and `llama` start immediately** — none of them depends on anything.
2. **`account`, `organization` and `usage` wait for `db`** to report healthy; `account` also waits for
   `mailpit`, which it sends verification and reset mail through.
3. **`auth`, `billing` and `inference` wait for what they call.** `auth` needs `db`, `valkey`, `account` and
   `organization`; `billing` needs `db`, `valkey` and `usage`; `inference` needs `valkey`, `llama` and `usage`.
4. **`batch` waits for `db`, `organization` and `inference`** — it runs every line of a batch through
   inference-service, and asks organization-service whether an organization is closed before erasing.
5. **`gateway` waits for `valkey`, `auth`, `account`, `organization`, `inference` and `batch`.** Only then does
   port 8080 start answering. **`prometheus` starts with the stack and `grafana` waits for it**; neither gates
   anything.

## What it is

A single-machine deployment of fourteen containers plus, optionally, a fifteenth for the GPU engine. Every
service is built from a jar you compile first; every secret comes from `docker/.env`; every container reports
readiness through `/actuator/health/readiness` on the management port rather than through an HTTP header.
`docker compose up -d --build --wait` returns only when all of them are healthy.

## Prerequisites

- **Docker Desktop on WSL2.** On Windows this is the supported path, and it is also what exposes the NVIDIA
  runtime to containers, so `compose.gpu.yaml` works without a second toolchain.
- **A JDK that can compile with `--release 25`.** Every `pom.xml` sets `<java.version>25</java.version>` and
  passes it as `source`, `target` **and** `release` to `maven-compiler-plugin`. A newer build JDK is fine — the
  local machine compiles with JDK 27 — because `--release 25` produces Java 25 bytecode against the Java 25
  API. Lombok is pinned to `1.18.48` for exactly this reason: the `1.18.46` Spring Boot 4.1 manages fails on a
  JDK 27 build, and the pom's comment says so.
- **Maven** and **bash**. On Windows, Git Bash is what the scripts are written for; several need
  `MSYS_NO_PATHCONV=1` on individual calls, and they set it themselves.
- **Disk and memory**: about 8 GB of images for the CPU stack, plus 3.3 GiB of weights for the GPU overlay.

## The environment file

```bash
cd docker
cp .env.example .env
```

`.env.example` has no defaults and neither does compose: every variable is read as `${NAME:?set in .env}`, so
a missing one refuses to start rather than falling back to something insecure. Fill it in with the commands
the file itself suggests:

| Key | Command |
|---|---|
| `DB_PASSWORD` | `openssl rand -base64 24` |
| `JWT_PRIVATE_KEY` | `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \| grep -v -- ----- \| tr -d '\r\n'` |
| `VALKEY_PASSWORD` | `openssl rand -hex 24` |
| `ENGINE_API_KEY` | `openssl rand -hex 24` |
| `VLLM_API_KEY` | `openssl rand -hex 24` (only with `compose.gpu.yaml`) |
| `GRAFANA_ADMIN_PASSWORD` | `openssl rand -base64 18` |

`DB_NAME` and `DB_USER` are plain values (`carmonai` in the example). The JWT key must be the **body** of a
PKCS#8 PEM on one line, which is what the `grep -v -- -----` and `tr -d '\r\n'` produce; `openssl genpkey`
writes PKCS#8, and some builds write `-outform DER` as PKCS#1 instead, which auth-service will refuse. `.env`
is untracked, CI generates its own with fresh secrets, and nothing in the repository contains a credential.

## Build, start, check

```bash
mvn -B clean verify                      # from the repository root
cd docker
docker compose up -d --build --wait
bash smoke.sh
```

The build has to come first. Each service's Dockerfile is `COPY target/*.jar application.jar` — the image
packages a jar, it does not compile one — so `docker compose up --build` against an unbuilt tree fails at the
`COPY`. `verify` runs the unit tests and one Testcontainers integration test per database service, and leaves
the jars behind. `--wait` then matters as much: without it compose returns as soon as the containers are
created and `smoke.sh` would race the readiness probes.

`smoke.sh` drives the whole stack through the gateway: it registers an account, verifies the email by reading
the link out of Mailpit, logs in, creates three organizations, grants credit, issues API keys, runs inference
on the CPU engine, checks the stream, stops usage-service and `SIGKILL`s inference-service to prove no usage
event is lost, runs a batch, checks the canary sweep, and closes everything. It ends with `smoke passed`.

Two things to know before running it twice. It drains this IP's login bucket on purpose, and that bucket
refills at one request per second, so **wait about 20 seconds** before a second run. And it stops and restarts
`valkey` in the middle, to prove API-key lookups fail closed — that is expected, not a fault.

## The GPU overlay

```bash
cd docker
docker compose -f compose.yaml -f compose.gpu.yaml up -d --build --wait
MODEL=carmonai/qwen3-4b ENGINE=vllm bash smoke.sh
```

`compose.gpu.yaml` adds a `vllm` service serving `cyankiwi/Qwen3-4B-Instruct-2507-AWQ-4bit` — the planned
Qwen3-4B-Instruct-2507 in 4-bit AWQ, revision pinned — as `carmonai/qwen3-4b`, and switches inference-service
to the `gpu` profile so it lists both models. The flags encode everything the 6 GB card forced:
`--max-model-len 4096 --max-num-seqs 4 --max-num-queued-reqs 8 --kv-cache-dtype fp8
--gpu-memory-utilization 0.78 --scheduling-policy priority --enable-prompt-tokens-details
--enable-auto-tool-choice --tool-call-parser hermes`.

`C = 4` comes from `--max-num-seqs`: four concurrent requests is where output throughput stops rising and TTFT
p95 is still 801 ms. Eight measured 159 output tok/s against 157 at four — the same throughput with a TTFT p95
of 4,033 ms and 10% goodput. The engine's port is not published, and `smoke.sh` asserts that: on the GPU stack
it curls `localhost:8000` and fails if anything answers.

## The memory reality

Docker Desktop's VM is **7.6 GB** on the reference machine, and the GPU stack asks it for roughly **5.2 GB**
before the services are counted. The arithmetic is in `compose.gpu.yaml`: `--gpu-memory-utilization 0.78` of
the 6 GB card is about 4.7 GiB, split by the file's own comment into 3.29 GiB of weights, ~0.9 GiB of CUDA/WSL
overhead and 0.44 GiB of KV cache, with `shm_size: 2gb` on top.

Two rules follow, and both were learned the hard way. **Never run a second Python or torch process beside
vLLM**: `vllm bench serve` was tried twice on this machine and both times exhausted the VM, hung WSL and got
vLLM OOM-killed — which is why `bench.sh` drives load with `curl` workers inside the `llama` container. And
**leave the GPU stack down when the host is short on memory**: after it had run for hours the Docker VM stopped
answering the API with under a gigabyte free on the host, and `docker desktop restart` brought it back with its
volumes intact. Under about 3 GB free, do not start it. `prometheus` and `grafana` are capped at 512m/0.5 cpu
and 384m/0.5 cpu for the same reason: this VM also runs twelve JVMs.

## Stopping and starting over

`docker compose down` stops and removes the containers and keeps the volumes; `docker compose down -v` also
drops `db-data`, `valkey-data`, `models`, `access-logs` and `prometheus-data`. CI runs `down -v` so a run never
inherits state. Locally, `down` is usually what you want — the `models` volume alone is worth keeping, and
`hf-cache` in the GPU overlay holds another 3 GB.

## Why it is like this

**`--wait` instead of a sleep.** Every service already reports readiness on its management port for
Kubernetes' benefit later; compose reads the same probe. That removes the guesswork from a script that has to
be correct on a laptop and in CI with no change.

**No curl in the JRE images.** The readiness check is `bash`'s `/dev/tcp` against `127.0.0.1:8081`, while the
llama.cpp and vLLM checks use `curl` and `python3` because those images have them and the JRE images do not.
Adding curl to a runtime image just to satisfy a health check is a package you then have to patch.

**Fresh secrets in CI, a file locally.** CI writes a `.env` with `openssl rand` on every run, so no secret is
stored anywhere. Locally, `.env` is a file you create once — which is also why every variable has `:?` on it:
forgetting one is a startup error with a readable message rather than a service running with an empty password.

## What would change it

- **Hosting.** Ports, volumes and the compose network all assume one machine; Kubernetes replaces the
  deployment mechanism, and the health checks are already shaped for it.
- **A machine without an NVIDIA GPU.** The CPU engine is the default and the one the smoke test covers, which
  makes it the configuration CI always exercises.
- **More memory.** The container limits, `--gpu-memory-utilization` and the decision to run the engine beside
  the services are all consequences of 7.6 GB; on a larger host they should be re-derived rather than copied.
- **A real mail provider.** Mailpit stands in for SMTP; the credentials wait for hosting, and
  `spring.mail.host` already comes from the environment.

## Where to look

- [compose.yaml](https://github.com/carmonai/back/blob/main/docker/compose.yaml) — fourteen services, the
  shared `x-readiness` health check, and every `depends_on` condition this page draws.
- [.env.example](https://github.com/carmonai/back/blob/main/docker/.env.example) — the six secrets and the
  `openssl` command for each.
- [compose.gpu.yaml](https://github.com/carmonai/back/blob/main/docker/compose.gpu.yaml) — the vLLM service
  and the reasoning behind every flag in its command line.
- [account/pom.xml](https://github.com/carmonai/back/blob/main/api/account/pom.xml) — the Java 25 target, the
  `<release>` flag and the pinned Lombok version.
