# Account

## What it is

`account-service` owns the `accounts` schema and holds the person: a name, a verified email address, an
Argon2id password hash, the single-use links mailed to that address, and the LGPD export and erasure that go
with them. It holds nothing about usage or money — those belong to organizations, and they carry ids.

<figure class="cmn-figure">
<div class="cmn-flow" markdown="0">
<svg viewBox="0 0 760 280" role="img" aria-labelledby="acct-title" aria-describedby="acct-desc"
     xmlns="http://www.w3.org/2000/svg">
  <title id="acct-title">The order of an account erasure, and the one thing that stops it</title>
  <desc id="acct-desc">An erasure request removes the account's memberships first, then its console
  sessions, then the account row with its tokens. Organization-service refuses the first step with 409 when
  the account is the only owner of an organization that is not closed.</desc>
  <defs>
    <marker id="acct-arrow-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
    <marker id="acct-arrow-accent" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="cmn-arrow" d="M0 0 L10 5 L0 10 z"/></marker>
  </defs>
  <!-- Hops in reading order: the three deletions, then the refusal branch, then the end. -->
  <g id="acct-hops">
    <path id="acct-hop1" class="cmn-link cmn-link--flow cmn-dash" d="M140 68 H188" marker-end="url(#acct-arrow-flow)"/>
    <path id="acct-hop2" class="cmn-link cmn-link--flow cmn-dash" d="M338 68 H386" marker-end="url(#acct-arrow-flow)"/>
    <path id="acct-hop3" class="cmn-link cmn-link--flow cmn-dash" d="M536 68 H584" marker-end="url(#acct-arrow-flow)"/>
    <path id="acct-hop4" class="cmn-link cmn-link--accent cmn-dash" d="M263 96 V176" marker-end="url(#acct-arrow-accent)"/>
    <path id="acct-hop5" class="cmn-link cmn-link--flow cmn-dash" d="M662 96 V176" marker-end="url(#acct-arrow-flow)"/>
  </g>
  <g class="cmn-node cmn-node--entry cmn-node--soft" id="acct-request" aria-labelledby="acct-request-label"><rect x="20" y="40" width="120" height="56" rx="10"/><text id="acct-request-label" x="80" y="60">Erasure</text><text class="cmn-sub" x="80" y="78">DELETE /accounts/{id}</text></g>
  <g class="cmn-node cmn-node--flow" id="acct-memberships" aria-labelledby="acct-memberships-label"><rect x="188" y="40" width="150" height="56" rx="10"/><text id="acct-memberships-label" x="263" y="60">Memberships</text><text class="cmn-sub" x="263" y="78">organization-service</text></g>
  <g class="cmn-node cmn-node--flow" id="acct-sessions" aria-labelledby="acct-sessions-label"><rect x="386" y="40" width="150" height="56" rx="10"/><text id="acct-sessions-label" x="461" y="60">Sessions</text><text class="cmn-sub" x="461" y="78">auth-service</text></g>
  <g class="cmn-node cmn-node--flow" id="acct-row" aria-labelledby="acct-row-label"><rect x="584" y="40" width="156" height="56" rx="10"/><text id="acct-row-label" x="662" y="60">Account</text><text class="cmn-sub" x="662" y="78">row, tokens cascade</text></g>
  <g class="cmn-node cmn-node--danger" id="acct-refused" aria-labelledby="acct-refused-label"><rect x="188" y="176" width="150" height="56" rx="10"/><text id="acct-refused-label" x="263" y="196">Refused 409</text><text class="cmn-sub" x="263" y="214">sole owner, not closed</text></g>
  <g class="cmn-node cmn-node--soft" id="acct-complete" aria-labelledby="acct-complete-label"><rect x="584" y="176" width="156" height="56" rx="10"/><text id="acct-complete-label" x="662" y="196">Erasure complete</text><text class="cmn-sub" x="662" y="214">204, and the account is gone</text></g>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M140 68 H188'); --cmn-travel: 1.1s; --cmn-delay: 0s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M338 68 H386'); --cmn-travel: 1.1s; --cmn-delay: 0.3s;"></circle>
  <circle class="cmn-packet cmn-travel" r="5" style="offset-path: path('M536 68 H584'); --cmn-travel: 1.1s; --cmn-delay: 0.6s;"></circle>
  <circle class="cmn-packet cmn-packet--accent cmn-travel" r="4.5" style="offset-path: path('M263 96 V176'); --cmn-travel: 1.1s; --cmn-delay: 0.9s;"></circle>
  <circle class="cmn-packet cmn-travel" r="4.5" style="offset-path: path('M662 96 V176'); --cmn-travel: 1.1s; --cmn-delay: 1.2s;"></circle>
  <rect class="cmn-label-plate" x="144" y="46" width="40" height="16" rx="4"/><text class="cmn-label" x="164" y="58">first</text>
  <rect class="cmn-label-plate" x="342" y="46" width="38" height="16" rx="4"/><text class="cmn-label" x="361" y="58">then</text>
  <rect class="cmn-label-plate" x="540" y="46" width="38" height="16" rx="4"/><text class="cmn-label" x="559" y="58">then</text>
  <rect class="cmn-label-plate" x="269" y="120" width="38" height="16" rx="4"/><text class="cmn-label" x="288" y="132">unless</text>
  <rect class="cmn-label-plate" x="668" y="120" width="38" height="16" rx="4"/><text class="cmn-label" x="687" y="132">then</text>
</svg>
</div>
<figcaption>An erasure walks three steps in a fixed order. Memberships go first because organization-service
is the only party that can refuse the request — it answers 409 while the account is the sole owner of an
organization that is not closed, and nothing else is deleted. Only when all three steps have succeeded is the
account gone.</figcaption>
</figure>

<div class="cmn-legend">
  <span><i class="is-flow"></i> a step that deletes something (solid)</span>
  <span><i class="is-accent"></i> the refusal written in answer (dashed)</span>
</div>

1. **`DELETE /accounts/{id}` arrives.** The service refuses it with 403 unless `id-account`, set by the
   gateway from the console session, equals the id in the path.
2. **Memberships are removed first**, by calling organization-service's internal
   `DELETE /organizations/members/{idAccount}`.
3. **Sessions are removed next**, through auth-service's internal
   `DELETE /auth/sessions/accounts/{idAccount}`, so no console session outlives its account.
4. **The account row goes last**, and the answer is 204. Its verification and reset tokens are deleted with it
   by `ON DELETE CASCADE`, so no mailed link survives the account it was for.
5. **If step 2 is refused, nothing happens.** organization-service answers 409, account-service passes that
   status through unchanged, and the account stays — which is the honest answer, because deleting it would
   leave an organization with no owner at all.

## Registering, and why the answer is uninformative

The public face of registration is `POST /auth/register`, and it **always answers 202** — whether the email is
new, already registered, or being registered twice at the same instant. That is enumeration resistance: the
endpoint cannot be used to ask whether an address has an account.

Behind it, the two cases are genuinely different, and `POST /accounts` shows it:

| Case | What happens | Status |
|---|---|---|
| new email | the account is saved and a verification email is sent in the same transaction | 201, `Location: /accounts/{id}` |
| known email | the owner is sent a "you already have an account" email instead | 202 |
| two at once | the loser hits the unique constraint and answers like a known email | 202 |
| the mail server is down | `MailException` rolls the whole thing back | 503 |

`POST /accounts` is not routed by the gateway: only auth-service calls it. The public 202 comes from
`AuthResource.register`, which returns `accepted()` regardless of which of those happened. The input rules
are small and explicit: the name is 1–256 characters after stripping, the email is normalised to lower case
and must match `^[^@\s]+@[^@\s]+\.[^@\s]+$` within 256 characters, and the password is 8–128 characters.

## Passwords

`Argon2PasswordEncoder` is constructed as `(16, 32, 1, 19 * 1024, 2)` — a 16-byte salt, a 32-byte hash,
parallelism 1, 19 MiB of memory and 2 iterations. That is the OWASP minimum for Argon2id, and the code says so
where it is written.

Two details make the login path uninformative in the other direction too:

- **An unknown email costs the same as a known one.** The service hashes against a `DUMMY_HASH` of
  `"carmonai-timing-dummy"` when the lookup misses, so the response time does not reveal whether the address
  exists.
- **Only a correct password learns that the email is unverified.** `POST /accounts/login` answers 401 for a
  wrong password, and 403 with "verify your email first: follow the link we sent" for a right password on an
  unverified account.

The hash never leaves the service: `AccountOut` is `(id, name, email)`, and no `Out` record in the library has
a field for it.

## The two links

`AccountTokens` issues 32 random bytes, base64url-encoded, and stores only the SHA-256:

```sql
CREATE TABLE account_token (
    token_hash VARCHAR(64) PRIMARY KEY,
    account_id VARCHAR(36) NOT NULL REFERENCES account (id) ON DELETE CASCADE,
    purpose    VARCHAR(16) NOT NULL CHECK (purpose IN ('verify_email', 'reset_password')),
    expires_at TIMESTAMPTZ NOT NULL
);
```

| Link | Purpose | Lives for | Endpoint |
|---|---|---|---|
| verify the email | `verify_email` | 24 h (`VERIFY_FOR`) | `POST /accounts/verify-email` |
| reset the password | `reset_password` | 1 h (`RESET_FOR`) | `POST /accounts/password-reset/confirm` |

Both lifetimes are constants in `AccountService`, not configuration keys. Single use is not a flag: spending
the token and reading it are the same statement.

```sql
DELETE FROM accounts.account_token WHERE token_hash = ? AND purpose = ?
RETURNING CASE WHEN expires_at > now() THEN account_id END
```

So the token is consumed whatever happens next — a wrong purpose, an expired token and a guessed token all
leave the table unchanged and return nothing. Asking for a reset answers 202 whether the address exists or
not, and only a known one gets mail.

A successful reset does two extra things inside the same transaction: it marks the email as verified, since
receiving the link proves the mailbox, and it calls `closeSessions` on auth-service, so every console session
ends. If that call fails, the transaction rolls back and the link still works.

Mail goes out over SMTP: `MAIL_HOST`, `MAIL_PORT` defaulting to 1025 (Mailpit in compose), a 2 s connect and
3 s read/write timeout, from `carmonai.mail.from`. The bodies are plain text and the links point at
`carmonai.console.url` (default `http://localhost:3000`), because the console is what posts the token back to
the service. Addresses and tokens are never logged.

## Export

`GET /accounts/{id}/export`, self only, answers `AccountExportOut(account, organizations, exportedAt)` where
each membership is `(id, name, status, tier, role)` — LGPD art. 18 access and portability. The organizations
are read from organization-service's `findMine` one page of `EXPORT_PAGE` = 100 at a time.

What the export does *not* contain is the point: no prompts, no answers, no per-request usage. The platform
never stored them. Usage and billing rows belong to organizations and carry ids and counts.

## Why it is like this

**Erasure is three steps and no transaction.** Each step is idempotent, so a retry after a partial failure
finishes the job; wrapping three calls to two other services in one transaction would hold locks across the
network and still not make them atomic. The order is chosen so the step that can refuse runs first, while
nothing has been destroyed yet.

**Memberships before the account, and 409 rather than a cascade.** An organization with no owner is a tenant
nobody can administer, so the service refuses instead of orphaning it. Closing the organization is a
deliberate act by its owner, and the message says so.

**202 for a known email instead of 409.** "This address is taken" is exactly the answer an attacker wants. The
customer who forgot they had signed up gets an email telling them so, which is more useful than an error and
reveals nothing to anyone else.

**An email failure rolls the registration back.** An account whose owner never received the verification link
is an account nobody can log into; leaving it behind would also occupy the address.

## What would change it

- **Password resets have a per-IP throttle and no per-email one.** The gateway's anonymous bucket is 1 request
  per second per client IP, so an attacker with many addresses can still send many reset mails to one mailbox.
  A per-address counter is the missing half.
- **Both link lifetimes are constants**, so changing them is a code change and a redeploy of this service.
- **The export reads organizations a page at a time.** At the 100-per-page cap that is a call per hundred
  memberships, which is fine at today's sizes and would not be at a large one.
- **Mail is plain text over SMTP with a two-second connect timeout.** A provider that is slow to accept a
  connection makes registration answer 503 rather than delay it.

## Where to look

- [AccountController.java](https://github.com/carmonai/back/blob/main/api/account/src/main/java/ai/carmonai/account/AccountController.java) — the contract, including the public and internal endpoints.
- [AccountService.java](https://github.com/carmonai/back/blob/main/api/account-service/src/main/java/ai/carmonai/account/AccountService.java) — Argon2id, the dummy hash and the erasure order.
- [AccountTokens.java](https://github.com/carmonai/back/blob/main/api/account-service/src/main/java/ai/carmonai/account/AccountTokens.java) — issue and spend, in one statement.
- [Mailer.java](https://github.com/carmonai/back/blob/main/api/account-service/src/main/java/ai/carmonai/account/Mailer.java) — the three emails and the console links.
- [email_flows.sql](https://github.com/carmonai/back/blob/main/api/account-service/src/main/resources/db/migration/V2026.10.03.001__email_flows.sql) — the token table and the verified column.
