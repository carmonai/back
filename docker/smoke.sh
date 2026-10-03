#!/usr/bin/env bash
# End-to-end check through the gateway. Run after: docker compose up -d --build
# It ends by draining this IP's login bucket (refills 1/s): wait ~20 s before running it again.
set -euo pipefail
G=${GATEWAY:-http://localhost:8080}
BODY=$(mktemp)
trap 'rm -f "$BODY"' EXIT

# expect <status> <curl args...>
expect() {
  local want=$1; shift
  local got
  got=$(curl -s -o "$BODY" -w '%{http_code}' "$@")
  local shown="$*"
  [[ -n ${token:-} ]] && shown=${shown//$token/<token>}   # keep bearer tokens out of CI logs
  if [[ $got != "$want" ]]; then echo "FAIL want $want got $got: $shown"; cat "$BODY"; echo; exit 1; fi
  echo "ok   $want  $shown"
}
json() { sed -nE "s/.*\"$1\":\"([^\"]+)\".*/\1/p" "$BODY"; }

email="smoke-$RANDOM$RANDOM@example.com"
pass='correct-horse-battery'
J=(-H 'Content-Type: application/json')

expect 201 "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Smoke\",\"email\":\"$email\",\"password\":\"$pass\"}"
expect 409 "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Smoke\",\"email\":\"${email^^}\",\"password\":\"$pass\"}"
expect 400 "${J[@]}" -X POST "$G/auth/register" -d '{"name":"Smoke","email":"not-an-email","password":"correct-horse"}'
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"wrong-password\"}"
expect 401 "${J[@]}" -X POST "$G/auth/login" -d '{"email":"nobody@example.com","password":"wrong-password"}'
expect 200 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
token=$(json token)
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

expect 204 "${A[@]}" -X DELETE "$G/accounts/$id"
expect 404 "${A[@]}" "$G/accounts/$id"
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"

codes=$(for _ in $(seq 40); do curl -s -o /dev/null -w '%{http_code}\n' "${J[@]}" -X POST "$G/auth/login" -d '{}'; done)
grep -q 429 <<<"$codes" && echo "ok   429  burst of 40 logins is rate limited" || { echo "FAIL no 429 in burst"; exit 1; }

echo "smoke passed"
