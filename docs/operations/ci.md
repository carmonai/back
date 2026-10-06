# CI and shipping

Work reaches `main` through pull requests against thirteen repositories, and one GitHub Actions workflow in
`back` decides whether any of them is shippable: it fetches the private modules, builds and tests everything,
starts the stack and runs the smoke test against it. This page is that workflow, the token it needs, and the
order the merges have to happen in.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="dci-title" aria-describedby="dci-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="dci-title">The workflow, and the merge order it depends on</title>
  <desc id="dci-desc">The upper lane is the merge order: a library repository is merged first, then the
  service that depends on it, then the commit in back that points at both. CARMONAI_TOKEN is a read-only
  fine-grained token for the thirteen private module repositories. The lower lane is the workflow: checkout,
  fetch the modules with that token, build and test with Maven, write a fresh environment file, start the
  stack with compose, and run the smoke test.</desc>

  <defs>
    <marker id="dci-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/>
    </marker>
  </defs>

  <!-- Hops in reading order: 1-2 the merge order, 3-4 how the two lanes connect,
       5-8 the workflow itself. -->
  <g id="dci-hops">
    <path id="dci-hop1" class="cmn-link cmn-link--flow cmn-dash"
          d="M136 80 H156" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop2" class="cmn-link cmn-link--flow cmn-dash"
          d="M276 80 H296" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop3" class="cmn-link cmn-link--flow"
          d="M336 108 V120 H71 V176" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop4" class="cmn-link cmn-link--flow"
          d="M520 108 V150 H286 V176" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop5" class="cmn-link cmn-link--flow cmn-dash"
          d="M126 204 H156" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop6" class="cmn-link cmn-link--flow cmn-dash"
          d="M296 204 H326" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop7" class="cmn-link cmn-link--flow cmn-dash"
          d="M456 204 H486" marker-end="url(#dci-arrow-flow)"/>
    <path id="dci-hop8" class="cmn-link cmn-link--flow cmn-dash"
          d="M606 204 H636" marker-end="url(#dci-arrow-flow)"/>
  </g>

  <g class="cmn-node cmn-node--entry cmn-node--soft" id="dci-library" aria-labelledby="dci-library-label">
    <rect x="16" y="52" width="120" height="56" rx="10"/>
    <text id="dci-library-label" x="76" y="72">Library repo</text>
    <text class="cmn-sub" x="76" y="90">the contract</text>
  </g>

  <g class="cmn-node cmn-node--soft" id="dci-service" aria-labelledby="dci-service-label">
    <rect x="156" y="52" width="120" height="56" rx="10"/>
    <text id="dci-service-label" x="216" y="72">Service repo</text>
    <text class="cmn-sub" x="216" y="90">the service</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dci-back" aria-labelledby="dci-back-label">
    <rect x="296" y="52" width="140" height="56" rx="10"/>
    <text id="dci-back-label" x="366" y="72">back (pointer)</text>
    <text class="cmn-sub" x="366" y="90">the submodule SHAs</text>
  </g>

  <g class="cmn-node cmn-node--accent" id="dci-token" aria-labelledby="dci-token-label">
    <rect x="496" y="52" width="190" height="56" rx="10"/>
    <text id="dci-token-label" x="591" y="72">CARMONAI_TOKEN</text>
    <text class="cmn-sub" x="591" y="90">Contents: read, 13 repos</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dci-checkout" aria-labelledby="dci-checkout-label">
    <rect x="16" y="176" width="110" height="56" rx="10"/>
    <text id="dci-checkout-label" x="71" y="196">checkout</text>
    <text class="cmn-sub" x="71" y="214">v7, no creds</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dci-fetch" aria-labelledby="dci-fetch-label">
    <rect x="156" y="176" width="140" height="56" rx="10"/>
    <text id="dci-fetch-label" x="226" y="196">fetch modules</text>
    <text class="cmn-sub" x="226" y="214">fail fast, then init</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dci-verify" aria-labelledby="dci-verify-label">
    <rect x="326" y="176" width="130" height="56" rx="10"/>
    <text id="dci-verify-label" x="391" y="196">mvn -B verify</text>
    <text class="cmn-sub" x="391" y="214">Temurin 25</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dci-compose" aria-labelledby="dci-compose-label">
    <rect x="486" y="176" width="120" height="56" rx="10"/>
    <text id="dci-compose-label" x="546" y="196">compose up</text>
    <text class="cmn-sub" x="546" y="214">fresh .env</text>
  </g>

  <g class="cmn-node cmn-node--flow" id="dci-smoke" aria-labelledby="dci-smoke-label">
    <rect x="636" y="176" width="110" height="56" rx="10"/>
    <text id="dci-smoke-label" x="691" y="196">smoke.sh</text>
    <text class="cmn-sub" x="691" y="214">end to end</text>
  </g>

  <!-- Payloads -->
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M136 80 H156'); --cmn-travel: 0.4s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5"
          style="offset-path: path('M276 80 H296'); --cmn-travel: 0.4s; --cmn-delay: 0.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M336 108 V120 H71 V176'); --cmn-travel: 1.6s; --cmn-delay: 0.35s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M520 108 V150 H286 V176'); --cmn-travel: 1.6s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M126 204 H156'); --cmn-travel: 0.4s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M296 204 H326'); --cmn-travel: 0.4s; --cmn-delay: 1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M456 204 H486'); --cmn-travel: 0.4s; --cmn-delay: 1.1s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5"
          style="offset-path: path('M606 204 H636'); --cmn-travel: 0.4s; --cmn-delay: 1.2s;"></circle>

  <!-- Labels -->
  <rect class="cmn-label-plate" x="110" y="34" width="74" height="16" rx="4"/>
  <text class="cmn-label" x="147" y="46">depends on</text>
  <rect class="cmn-label-plate" x="248" y="34" width="76" height="16" rx="4"/>
  <text class="cmn-label" x="286" y="46">points at</text>
  <rect class="cmn-label-plate" x="110" y="112" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="185" y="124">CI reads the pointers</text>
  <rect class="cmn-label-plate" x="528" y="110" width="150" height="16" rx="4"/>
  <text class="cmn-label" x="603" y="122">CARMONAI_TOKEN</text>
  <rect class="cmn-label-plate" x="114" y="158" width="54" height="16" rx="4"/>
  <text class="cmn-label" x="141" y="170">modules</text>
  <rect class="cmn-label-plate" x="291" y="158" width="40" height="16" rx="4"/>
  <text class="cmn-label" x="311" y="170">tests</text>
  <rect class="cmn-label-plate" x="451" y="158" width="40" height="16" rx="4"/>
  <text class="cmn-label" x="471" y="170">stack</text>
  <rect class="cmn-label-plate" x="601" y="158" width="40" height="16" rx="4"/>
  <text class="cmn-label" x="621" y="170">smoke</text>
</svg>
</div>
<figcaption>The upper lane is the merge order and the token, not a workflow. A library repository is merged
before the service that depends on it, and the commit in `back` that points at both is merged last — which is
what step 3 shows CI doing: reading the pointers. Step 4 is the one credential the workflow needs, a
fine-grained token with `Contents: read` on the thirteen module repositories. The lower lane is the workflow
in order: checkout without credentials, fetch the modules, build and test, write a fresh `.env`, start the
stack, run the smoke test.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a step, or a merge, in order (solid)</span>
  <span><i class="is-accent"></i> a credential (teal outline)</span>
</div>

1. **A library repository is merged first.** It holds the `XController` Feign interface and the `In`/`Out`
   records that both the service and its callers compile against.
2. **Then the service repository**, which depends on that library at `${project.version}`.
3. **Then the commit in `back`** that moves the submodule pointers. CI's `git submodule update` reads exactly
   those SHAs, so a pointer merged before its target exists makes a fresh clone unbuildable.
4. **`CARMONAI_TOKEN` is the read credential** for the thirteen private module repositories —
   `Contents: read-only`, on the module repos and not on `back`.
5. **`actions/checkout@v7` with `persist-credentials: false`** clones `back` itself with the default
   `GITHUB_TOKEN`, which cannot read the siblings.
6. **The fetch step checks access first, then initialises.** One API call per module, and a failure names the
   repository and its status code.
7. **`mvn -B verify`** on Temurin 25 builds all thirteen modules in dependency order and runs the unit tests
   and the Testcontainers integration tests.
8. **A generated `.env`, `docker compose up -d --build --wait` and `bash smoke.sh`** — the same three
   commands this page's sibling tells a person to run, on the CPU engine, with fresh secrets.

## What it is

One workflow, `.github/workflows/ci.yaml`, triggered on every pull request and on every push to `main`. It
runs on `ubuntu-latest` (Docker is preinstalled and Testcontainers needs a Linux runner), has a
30-minute timeout, and declares `permissions: contents: read` — the workflow itself only ever reads.

The comment at the top states its purpose in terms of what it catches: *a broken migration, a Resource/Feign
mismatch or a security regression in the smoke test fails it.* Those are the three failure modes that are
invisible in a code review and obvious in a running stack.

## Why the module fetch needs a token at all

`back` holds thirteen git submodules under `api/`, one Git repository per module. They are private, and
`GITHUB_TOKEN` — the token Actions issues automatically — is scoped to the repository the workflow runs in. It
cannot read a sibling, so `git submodule update --init --recursive` would fail on the first module.

`CARMONAI_TOKEN` is a fine-grained personal access token with `Contents: read-only`, granted on the module
repositories and not on `back`. Read-only is the whole permission set: the workflow never pushes, and the
submodules are checked out detached.

The step does the access check before it does the clone, on purpose. It walks every `url` in `.gitmodules`,
asks the API for each repository, prints the status code, and exits with a `::error::` annotation naming the
repository if the answer is not 200:

```bash
for repo in $(git config -f .gitmodules --get-regexp '\.url$' | sed -E 's#.*github\.com/(.*)\.git$#\1#'); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$repo")
  [ "$code" = 200 ] || { echo "::error::CARMONAI_TOKEN cannot read $repo (HTTP $code)"; exit 1; }
done
```

A module added to `back` but not to the token's repository list fails here, in about a second, instead of
minutes later inside a Maven resolution error that says nothing about permissions. That is not hypothetical:
adding a module is a documented step in the `carmonai-new-service` skill precisely because the token has to be
updated by hand.

The clone rewrites the URL rather than passing credentials per command —
`git config --global url."https://x-access-token:${TOKEN}@github.com/carmonai/".insteadOf
"https://github.com/carmonai/"`, then `git submodule update --init --recursive`, then
`git config --global --remove-section` on the same key. `git -c` settings do not reliably reach the
`git submodule` child processes, so the rewrite has to be global, and it is removed immediately afterwards so
the token is not in any later step's `git config --list`.

## Build and test

`actions/setup-java@v6` installs Temurin **25** with `cache: maven`, then `mvn -B verify` runs. Temurin 25 is
the LTS the project targets and the same JDK the runtime images use. `verify` builds the thirteen modules in
the order the aggregator's `pom.xml` declares, runs the unit tests on branchy logic, and runs one Testcontainers
integration test per database service against a pinned Postgres image.

There is no `mvn install` and no package registry. Each service depends on its library at version `1.0.0`,
resolved from the reactor in the same run — which is also why the merge order above is not a preference:
`api/account` has to be in the reactor before `api/account-service` compiles.

## A generated environment file, every run

```bash
{
  echo "DB_NAME=carmonai"
  echo "DB_USER=carmonai"
  echo "DB_PASSWORD=$(openssl rand -hex 24)"
  echo "VALKEY_PASSWORD=$(openssl rand -hex 24)"
  echo "ENGINE_API_KEY=$(openssl rand -hex 24)"
  echo "JWT_PRIVATE_KEY=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 | grep -v -- ----- | tr -d '\r\n')"
} > .env
```

Six secrets, generated per run, written into the untracked `docker/.env`, and gone when the runner is. No
secret is stored in the repository, and none is a repository secret except the token.

**This step is behind the compose file and CI fails on it as written.** `docker/compose.yaml` gained the
observability stack after this workflow was last touched, and the `grafana` service reads
`${GRAFANA_ADMIN_PASSWORD:?set in .env}`. The block above does not set it, so `docker compose up` stops at
variable interpolation with *"GRAFANA_ADMIN_PASSWORD: set in .env"* before a single container starts. The
one-line fix is another `echo "GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 18)"` in that block, matching
`docker/.env.example`. `VLLM_API_KEY` is *not* needed: it is only read by `compose.gpu.yaml`, which CI does
not use. The step is reproduced above exactly as it is written, defect included, because a page that showed
the fixed version would hide the thing you are about to hit.

## Starting the stack and running the smoke test

The workflow then runs `docker compose up -d --build --wait` and `bash smoke.sh`, both with
`working-directory: docker`. `--wait` is what makes the next step meaningful: `smoke.sh` immediately issues
real requests through `localhost:8080` and would race the readiness probes without it. CI runs the CPU engine
— GitHub's runners have no GPU — so `smoke.sh` uses its defaults, `MODEL=carmonai/qwen3-0.6b ENGINE=llama`.

Two cleanup steps follow, with conditions that matter. A *Service logs* step runs
`docker compose logs --no-color` on `failure() && steps.stack.outcome != 'skipped'` — a green run does not need
fourteen containers' output, and an earlier failure leaves nothing to show. A *Stop the stack* step runs
`docker compose down -v` on `always()` under the same condition, so the volumes go with it. On an ephemeral
runner that is tidiness; on a self-hosted one it is the difference between two runs sharing state and not.

## The merge order

Ordering across repositories is the one thing a green workflow cannot prove, because each repository's CI
passes on its own branch while the combination is still broken.

1. **The library repository** (`api/account`, `api/auth`, `api/organization`, `api/usage`, `api/billing`) —
   it is what the service compiles against.
2. **The service repository** (`api/account-service`, and so on) — it depends on the library at
   `${project.version}`.
3. **`back`'s pointer commit** — the submodule gitlinks. Nothing else in `back` changes when a module changes;
   the whole repository is an aggregator `pom.xml`, `docker/`, `.github/` and thirteen pointers.

The reason is mechanical. `git submodule update` checks out the exact commit a pointer names, and Maven
resolves `ai.carmonai:account:1.0.0` from the reactor. A `back` pointer that names a service commit whose
library commit is not merged yet gives a fresh clone that cannot build, even though every individual
repository is green — and the failure appears in CI, not in the PR that caused it.

The user's rule sits on top of the mechanics: never push to `main`, open a pull request, and merge only when
the user says merge. The workflow is what makes that rule safe to follow.

## The docs workflow

`.github/workflows/docs.yaml` publishes this site, separately and independently of the code workflow. It
triggers on a push to `main` touching `docs/**`, `mkdocs.yml`, `requirements.txt` or the workflow itself, and
on `workflow_dispatch` so the site can be rebuilt from the Actions tab without an empty commit.

```yaml
concurrency:
  group: docs
  cancel-in-progress: false   # a half-pushed gh-pages is a broken site, not a slow one
```

The job checks out with `fetch-depth: 0`, installs Python 3.12 and `requirements.txt`, runs
`mkdocs build --strict`, and publishes with `mkdocs gh-deploy --force`. `fetch-depth: 0` is not optional: the
`git-revision-date-localized` plugin dates every page from its last commit, and a shallow clone has no history
to read. `--strict` turns a broken internal link, an unknown anchor or a missing nav page into a failure, so a
page cannot silently disappear from the published site.

Two repository settings are needed and neither is in the file, which the workflow's own header says:
**Settings → Actions → General → Workflow permissions** must be *Read and write*, or the push to `gh-pages` is
refused, and **Settings → Pages → Source** must be *Deploy from a branch*, branch `gh-pages`, folder `/`.

## Why it is like this

**One workflow, not one per module.** Thirteen repositories with thirteen workflows would be thirteen places
to keep a Java version in step. The integration test is what actually needs to run, and only `back` can run
it — it is the only repository that sees all thirteen modules at once.

**The full stack, on every pull request.** Starting fourteen containers and running 443 lines of smoke test
takes minutes, and it is the only check that catches a broken migration, a route predicate that no longer
matches its path, or a filter that stopped stripping a header. Cheaper checks would be faster and would miss
exactly those.

**Fresh secrets rather than repository secrets, and `persist-credentials: false`.** Nothing pins CI to a
credential that has to be rotated, no run can inherit another run's state, and the one long-lived secret is a
read token that cannot write anything.

## What would change it

- **The `GRAFANA_ADMIN_PASSWORD` line above.** Until it is added, the stack step fails; that is a one-line
  change to `ci.yaml`.
- **A published library.** Services resolve their library from the reactor, which is why the merge order is
  strict. A package registry would make a pointer commit independently buildable, at the cost of a publishing
  step — the plan considered GitHub Packages and rejected it, because cross-repo reads need a classic token
  and `1.0.0` cannot be republished.
- **GPU coverage in CI.** GitHub's runners have no GPU, so `bench.sh` and `batch-bench.sh` are not run there.
  A self-hosted runner is the upgrade, and it would need the model cache to be warm.
- **A second person.** `CARMONAI_TOKEN` is one person's fine-grained token; a GitHub App installation token
  would not expire with their account.

## Where to look

- [ci.yaml](https://github.com/carmonai/back/blob/main/.github/workflows/ci.yaml) — the whole workflow, 80
  lines, including the generated `.env` this page flags.
- [docs.yaml](https://github.com/carmonai/back/blob/main/.github/workflows/docs.yaml) — the site build and
  the two repository settings it needs.
- [pom.xml](https://github.com/carmonai/back/blob/main/pom.xml) — the thirteen modules in dependency order,
  which is the merge order written down.
- [.gitmodules](https://github.com/carmonai/back/blob/main/.gitmodules) — the repositories the token has to
  be able to read.
- [smoke.sh](https://github.com/carmonai/back/blob/main/docker/smoke.sh) — what the workflow is actually
  asserting, in 443 lines.
