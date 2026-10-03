#!/usr/bin/env bash
# End-to-end check through the gateway. Run after: docker compose up -d --build --wait
# It ends by draining this IP's login bucket (refills 1/s): wait ~20 s before running it again.
# It stops and restarts valkey once (API-key lookups must fail closed with 503).
set -euo pipefail
G=${GATEWAY:-http://localhost:8080}
DC=(docker compose -f "$(dirname "$0")/compose.yaml")
BODY=$(mktemp)
trap 'rm -f "$BODY"' EXIT

# expect <status> <curl args...>. Bearer credentials (JWTs, API keys) never reach the output.
expect() {
  local want=$1; shift
  local got shown
  got=$(curl -s -o "$BODY" -w '%{http_code}' "$@")
  shown=$(sed -E 's/Bearer [^ ]+/Bearer <redacted>/g' <<<"$*")
  if [[ $got != "$want" ]]; then echo "FAIL want $want got $got: $shown"; cat "$BODY"; echo; exit 1; fi
  echo "ok   $want  $shown"
}
json() { sed -nE "s/.*\"$1\":\"([^\"]+)\".*/\1/p" "$BODY"; }

pass='correct-horse-battery'
J=(-H 'Content-Type: application/json')

# register + login a fresh account; sets $email and $token
account() {
  email="smoke-$RANDOM$RANDOM@example.com"
  expect 201 "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Smoke\",\"email\":\"$email\",\"password\":\"$pass\"}"
  expect 200 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
  token=$(json token)
}

## Accounts and login
account
expect 409 "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Smoke\",\"email\":\"${email^^}\",\"password\":\"$pass\"}"
expect 400 "${J[@]}" -X POST "$G/auth/register" -d '{"name":"Smoke","email":"not-an-email","password":"correct-horse"}'
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"wrong-password\"}"
expect 401 "${J[@]}" -X POST "$G/auth/login" -d '{"email":"nobody@example.com","password":"wrong-password"}'
A=(-H "Authorization: Bearer $token")

expect 401 "$G/auth/whoami"
expect 401 -H "Authorization: Bearer ${token}x" "$G/auth/whoami"
expect 200 "${A[@]}" "$G/auth/whoami"
id=$(json id)
expect 200 "${A[@]}" "$G/accounts/$id"
other=00000000-0000-0000-0000-000000000000
expect 403 "${A[@]}" "$G/accounts/$other"
expect 403 "${A[@]}" -H "id-account: $other" "$G/accounts/$other"   # forged header is stripped
expect 404 "${A[@]}" "$G/accounts"                                  # list stays internal
expect 404 "${A[@]}" "${J[@]}" -X POST "$G/accounts/login" -d '{}'  # credential check stays internal
expect 404 "${A[@]}" "$G/auth/jwks"

## Organizations
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations" -d '{"name":"Smoke Org"}'
org=$(json id)
expect 200 "${A[@]}" "$G/organizations"
expect 200 "${A[@]}" "$G/organizations/$org"
expect 404 "${A[@]}" "$G/organizations/$org/tenant"                 # internal
expect 404 "${A[@]}" "$G/organizations/$org/members/$id"            # internal

## API keys: shown once, /v1 takes keys only, revocation is immediate
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations/$org/api-keys" -d '{"name":"smoke"}'
key=$(json key)
key_id=$(json id)
K=(-H "Authorization: Bearer $key")
expect 200 "${A[@]}" "$G/organizations/$org/api-keys"
if grep -q "$key" "$BODY"; then echo "FAIL the key is listed after creation"; exit 1; fi
expect 200 "${K[@]}" "$G/v1/models"
expect 200 "${K[@]}" -H "id-organization: $other" -H "tier: enterprise" "$G/v1/models"   # forged headers stripped
expect 401 "$G/v1/models"                                            # no key
expect 401 "${A[@]}" "$G/v1/models"                                  # a JWT is not an API key
[[ ${key: -1} == A ]] && typo="${key%?}B" || typo="${key%?}A"
expect 401 -H "Authorization: Bearer $typo" "$G/v1/models"           # a typo fails the checksum
expect 401 "${K[@]}" "$G/auth/whoami"                                # an API key is not a JWT
expect 404 "${A[@]}" "$G/api-keys/0"                                 # the lookup by hash stays internal
expect 204 "${A[@]}" -X DELETE "$G/organizations/$org/api-keys/$key_id"
expect 401 "${K[@]}" "$G/v1/models"                                  # revoked: refused at once

## API-key lookups fail closed when valkey is down
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations/$org/api-keys" -d '{"name":"smoke-2"}'
key2=$(json key)
"${DC[@]}" stop valkey >/dev/null 2>&1
expect 503 -H "Authorization: Bearer $key2" "$G/v1/models"
"${DC[@]}" up -d --wait valkey >/dev/null 2>&1
expect 200 -H "Authorization: Bearer $key2" "$G/v1/models"

## Someone else's organization is invisible to a stranger
first_token=$token
first_email=$email
account
S=(-H "Authorization: Bearer $token")
expect 404 "${S[@]}" "$G/organizations/$org"
expect 404 "${S[@]}" "${J[@]}" -X POST "$G/organizations/$org/api-keys" -d '{"name":"x"}'
expect 404 "${S[@]}" -X DELETE "$G/organizations/$org"
token=$first_token

## Erasure waits until no open organization would be left without an owner
expect 409 "${A[@]}" -X DELETE "$G/accounts/$id"
expect 204 "${A[@]}" -X DELETE "$G/organizations/$org"               # close it
expect 204 "${A[@]}" -X DELETE "$G/accounts/$id"
expect 404 "${A[@]}" "$G/accounts/$id"
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$first_email\",\"password\":\"$pass\"}"   # erased: gone

codes=$(for _ in $(seq 40); do curl -s -o /dev/null -w '%{http_code}\n' "${J[@]}" -X POST "$G/auth/login" -d '{}'; done)
grep -q 429 <<<"$codes" && echo "ok   429  burst of 40 logins is rate limited" || { echo "FAIL no 429 in burst"; exit 1; }

echo "smoke passed"
