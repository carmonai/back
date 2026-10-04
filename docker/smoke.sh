#!/usr/bin/env bash
# End-to-end check through the gateway. Run after: docker compose up -d --build --wait
# It ends by draining this IP's login bucket (refills 1/s): wait ~20 s before running it again.
# It stops and restarts valkey once (API-key lookups must fail closed with 503), runs chats on the
# CPU engine (llama.cpp + Qwen3-0.6B), and greps every log and a database dump for a canary string.
set -euo pipefail
G=${GATEWAY:-http://localhost:8080}
# MODEL/ENGINE pick the engine the inference checks run against: the CPU one by default (CI), or
# MODEL=carmonai/qwen3-4b ENGINE=vllm with the stack started from compose.yaml + compose.gpu.yaml.
M=${MODEL:-carmonai/qwen3-0.6b}
ENGINE=${ENGINE:-llama}
DC=(docker compose -f "$(dirname "$0")/compose.yaml")
[[ $ENGINE == vllm ]] && DC+=(-f "$(dirname "$0")/compose.gpu.yaml")
BODY=$(mktemp)
HDRS=$(mktemp)
trap 'rm -f "$BODY" "$HDRS"' EXIT

# expect <status> <curl args...>. Credentials (JWTs, API keys, refresh cookies, emailed tokens) never
# reach the output.
expect() {
  local want=$1; shift
  local got shown
  got=$(curl -s -o "$BODY" -w '%{http_code}' "$@")
  shown=$(sed -E 's/Bearer [^ ]+/Bearer <redacted>/g; s/(carmonai-rt=)[^ ]+/\1<redacted>/g; s/("token":")[^"]+/\1<redacted>/g' <<<"$*")
  if [[ $got != "$want" ]]; then echo "FAIL want $want got $got: $shown"; cat "$BODY"; echo; exit 1; fi
  echo "ok   $want  $shown"
}
json() { sed -nE "s/.*\"$1\":\"([^\"]+)\".*/\1/p" "$BODY"; }

pass='correct-horse-battery'
J=(-H 'Content-Type: application/json')

# Mailpit, inside the network: every email to $1, newest first, as JSON.
mails() {
  local id
  for id in $("${DC[@]}" exec -T llama curl -s "http://mailpit:8025/api/v1/search?query=to:%22${1/@/%40}%22" | grep -oE '"ID":"[^"]+"' | cut -d'"' -f4); do
    "${DC[@]}" exec -T llama curl -s "http://mailpit:8025/api/v1/message/$id"
  done
}
# The token of the newest {$2} link (verify-email, reset-password) mailed to $1. The emails are captured
# before grepping: under pipefail, a reader that stops early (grep -q, head) fails the writer's pipe.
mail_token() {
  local token="" all
  for _ in $(seq 20); do
    all=$(mails "$1")
    token=$(grep -oE "/$2\?token=[A-Za-z0-9_-]+" <<<"$all" | sed -n '1s/.*=//p')
    [[ -n $token ]] && break
    sleep 0.5
  done
  [[ -n $token ]] || { echo "FAIL no $2 email for $1"; exit 1; }
  echo "$token"
}
# The refresh cookie the last response (-D "$HDRS") set.
cookie() { sed -nE 's/^set-cookie: (__Host-carmonai-rt=[^;]+);.*/\1/ip' "$HDRS" | tr -d '\r' | tail -1; }

# register, verify the email (Mailpit), login a fresh account; sets $email, $token and $rt (refresh cookie)
account() {
  email="smoke-$RANDOM$RANDOM@example.com"
  expect 202 "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Smoke\",\"email\":\"$email\",\"password\":\"$pass\"}"
  expect 403 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"   # not verified yet
  expect 204 "${J[@]}" -X POST "$G/accounts/verify-email" -d "{\"token\":\"$(mail_token "$email" verify-email)\"}"
  expect 200 -D "$HDRS" "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
  token=$(json token)
  rt=$(cookie)
}

## Accounts and login
account
# A known email answers like a new one (no account enumeration); its owner gets an email instead.
expect 202 "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Smoke\",\"email\":\"${email^^}\",\"password\":\"$pass\"}"
for _ in $(seq 20); do all=$(mails "$email"); grep -q 'You already have a Carmonai account' <<<"$all" && break; sleep 0.5; done
grep -q 'You already have a Carmonai account' <<<"$all" && echo "ok   the owner of the known email was told by email" \
  || { echo "FAIL no 'already registered' email"; exit 1; }
expect 400 "${J[@]}" -X POST "$G/auth/register" -d '{"name":"Smoke","email":"not-an-email","password":"correct-horse"}'
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"wrong-password\"}"
expect 401 "${J[@]}" -X POST "$G/auth/login" -d '{"email":"nobody@example.com","password":"wrong-password"}'
A=(-H "Authorization: Bearer $token")

## Console sessions: the refresh cookie rotates, a copied one ends its session, logout ends it, other sites can't post
first=$rt
expect 200 -D "$HDRS" -X POST "$G/auth/refresh" -H "Cookie: $first"
rotated=$(cookie)
[[ -n $(json token) && -n $rotated && $rotated != "$first" ]] && echo "ok   refresh: a new access token and a rotated cookie" \
  || { echo "FAIL refresh did not rotate"; exit 1; }
expect 401 -X POST "$G/auth/refresh" -H "Cookie: $first"                 # used twice: it was copied
expect 401 -X POST "$G/auth/refresh" -H "Cookie: $rotated"               # so the session is gone for both
expect 200 -D "$HDRS" "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
live=$(cookie)
expect 403 -H 'Origin: https://evil.example' -X POST "$G/auth/refresh" -H "Cookie: $live"
expect 204 -H 'Origin: http://localhost:3000' -X POST "$G/auth/logout" -H "Cookie: $live"
expect 401 -X POST "$G/auth/refresh" -H "Cookie: $live"
expect 200 -D "$HDRS" "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
keep=$(cookie)                                                           # ends with the account (erasure)

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

# Internal endpoints have no gateway route: the smoke test reaches them from inside the network (the
# llama container has curl). Prepaid credit (R$10, in micro-BRL) pays for the chats below.
internal() { "${DC[@]}" exec -T llama curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' "$@"; }
grant() { internal -X POST http://billing:8080/billing/grants -d "{\"organizationId\":\"$1\",\"amountMicroBrl\":$2,\"reason\":\"smoke\",\"idempotencyKey\":\"$3\"}"; }
code=$(grant "$org" 10000000 smoke-start)
[[ $code == 200 ]] && echo "ok   200  R\$10 of credit granted (internal)" || { echo "FAIL credit grant got $code"; exit 1; }
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

## Inference through the gateway: $M on $ENGINE, behind inference-service
K2=(-H "Authorization: Bearer $key2")
chat() { echo "{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"$1\"}],\"max_tokens\":$2${3:-}}"; }
expect 200 "${K2[@]}" "$G/v1/models"
grep -q "\"$M\"" "$BODY" || { echo "FAIL $M is not listed"; exit 1; }
expect 200 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)"
grep -q '"usage"' "$BODY" || { echo "FAIL no usage in the answer"; exit 1; }
stream=$(curl -sN "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Count to five.' 16 ',"stream":true')")
events=$(grep -c '^data:' <<<"$stream" || true)
if [[ $events -lt 3 ]] || ! grep -qE '^data: ?\[DONE\]' <<<"$stream"; then echo "FAIL stream: $events events"; exit 1; fi
echo "ok   200  streamed $events events, ending in [DONE]"
expect 404 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d '{"model":"nope","messages":[{"role":"user","content":"x"}]}'
expect 400 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'x' 8 ',"n":2')"
expect 400 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"image_url\",\"image_url\":{\"url\":\"http://example.com/a.png\"}}]}]}"
expect 400 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'x' 5000)"
expect 400 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d '{"model":'
expect 400 "${K2[@]}" "${J[@]}" -H 'Transfer-Encoding: chunked' -X POST "$G/v1/chat/completions" -d "$(chat 'x' 8)"
expect 400 "${K2[@]}" "$G/v1/models?api_key=cmn_test_x"

# A client that hangs up stops the generation upstream, and is recorded as cancelled.
curl -sN --max-time 2 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Count from 1 to 1000, separated by commas.' 1000 ',"stream":true,"temperature":0')" >/dev/null || true
# Requests the engine is generating right now, from its own metrics.
engine_busy() {
  if [[ $ENGINE == vllm ]]; then
    "${DC[@]}" exec -T vllm python3 -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/metrics').read().decode())" \
      | sed -nE 's/^vllm:num_requests_running\{[^}]*\} ([0-9.]+).*/\1/p' | head -1
  else
    "${DC[@]}" exec -T llama sh -c 'curl -s -H "Authorization: Bearer $LLAMA_API_KEY" http://127.0.0.1:8080/metrics' \
      | sed -nE 's/^llamacpp:requests_processing ([0-9.]+).*/\1/p'
  fi
}
busy=1
for _ in $(seq 20); do
  busy=$(engine_busy)
  [[ ${busy%.*} == 0 ]] && break
  sleep 0.5
done
[[ ${busy%.*} == 0 ]] && echo "ok   engine idle again after the client hung up" || { echo "FAIL engine still busy ($busy)"; exit 1; }

# Usage reaches usage-service once per request that reached the engine: 2 answered, 1 cancelled.
sql() { "${DC[@]}" exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "$1"' sh "$1"; }
usage=""
for _ in $(seq 20); do
  usage=$(sql "SELECT status || '=' || count(*) FROM usage.usage_event WHERE organization_id = '$org' GROUP BY status ORDER BY status" | tr -d '\r' | tr '\n' ' ')
  [[ $usage == "cancelled=1 ok=2 " ]] && break
  sleep 0.5
done
[[ $usage == "cancelled=1 ok=2 " ]] && echo "ok   usage recorded once each: $usage" || { echo "FAIL usage rows: '$usage'"; exit 1; }
cancelled=$(sql "SELECT output_tokens FROM usage.usage_event WHERE organization_id = '$org' AND status = 'cancelled'" | tr -d '\r')
[[ ${cancelled:-0} -gt 0 ]] && echo "ok   the cancelled stream is billed for its $cancelled generated tokens" \
  || { echo "FAIL the cancelled stream recorded no output tokens"; exit 1; }

# Usage survives a crash: with usage-service down, the events wait in Valkey's stream; inference-service
# is killed (no graceful flush) and restarted; each event then reaches usage-service once.
"${DC[@]}" stop usage >/dev/null 2>&1
rids=()
for _ in 1 2 3; do
  expect 200 -D "$HDRS" "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)"
  rids+=("'$(sed -nE 's/^x-request-id: ([0-9a-f-]{36}).*/\1/ip' "$HDRS")'")
done
sleep 1
"${DC[@]}" kill -s SIGKILL inference >/dev/null 2>&1
"${DC[@]}" up -d --wait usage inference >/dev/null 2>&1
stored=""
for _ in $(seq 40); do
  stored=$(sql "SELECT count(*) FROM usage.usage_event WHERE request_id IN ($(IFS=,; echo "${rids[*]}"))" | tr -d '\r')
  [[ $stored == 3 ]] && break
  sleep 1
done
[[ $stored == 3 ]] && echo "ok   usage-service down and inference-service killed: all 3 usage events arrived, once each" \
  || { echo "FAIL $stored of 3 usage events arrived after the crash"; exit 1; }

# GPU engine only: tool calls, and the engine's port stays off the host.
if [[ $ENGINE == vllm ]]; then
  tools='"tools":[{"type":"function","function":{"name":"get_weather","description":"Current weather in a city","parameters":{"type":"object","properties":{"city":{"type":"string"}},"required":["city"]}}}],"tool_choice":{"type":"function","function":{"name":"get_weather"}}'
  expect 200 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'What is the weather in Recife?' 64 ",$tools")"
  grep -q '"tool_calls"' "$BODY" && grep -q 'get_weather' "$BODY" || { echo "FAIL no tool call in the answer"; cat "$BODY"; exit 1; }
  echo "ok   tool call returned"
  if curl -s -m 2 -o /dev/null http://localhost:8000/health; then echo "FAIL vLLM is reachable from the host"; exit 1; fi
  echo "ok   vLLM's port is not published"
fi

# One request id from the gateway to the answer and the usage event (any client copy is replaced).
rid=$(curl -s -D - -o /dev/null "${K2[@]}" "${J[@]}" -H 'X-Request-Id: client-chosen' -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)" \
  | sed -nE 's/^x-request-id: ([0-9a-f-]{36}).*/\1/ip' | head -1)
[[ -n $rid ]] && echo "ok   200  X-Request-Id $rid (the gateway's)" || { echo "FAIL no gateway request id"; exit 1; }

## Admission: rate-limit headers, and each tier only gets its share of the engine
remaining=$(curl -s -D - -o /dev/null "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)" | sed -nE 's/^x-ratelimit-remaining-requests: ([0-9]+).*/\1/ip')
[[ -n $remaining ]] && echo "ok   200  x-ratelimit-remaining-requests: $remaining" || { echo "FAIL no rate-limit headers"; exit 1; }
# Tiers are staff-set (no API yet): an enterprise organization, its tier set before its key is first used.
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations" -d '{"name":"Smoke Enterprise"}'
corp=$(json id)
sql "UPDATE organizations.organization SET tier = 'enterprise' WHERE id = '$corp'" >/dev/null
[[ $(grant "$corp" 10000000 corp-start) == 200 ]] || { echo "FAIL corp credit grant"; exit 1; }
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations/$corp/api-keys" -d '{"name":"corp"}'
K4=(-H "Authorization: Bearer $(json key)")
# Trial may fill half the engine's slots (llama.cpp 2 -> 1, vLLM 4 -> 2). With those taken, one more trial
# request is refused at once, while an enterprise one still runs.
[[ $ENGINE == vllm ]] && share=2 || share=1
for _ in $(seq $share); do
  curl -sN --max-time 8 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Count from 1 to 1000, separated by commas.' 1000 ',"stream":true,"temperature":0')" >/dev/null &
done
sleep 2
read -r code took < <(curl -s -o "$BODY" -w '%{http_code} %{time_total}\n' "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)")
[[ $code == 429 ]] && grep -q '"model_busy"' "$BODY" && awk "BEGIN { exit !($took < 0.5) }" \
  && echo "ok   429  trial over its share of the engine, refused in ${took}s" \
  || { echo "FAIL trial over its share got $code in ${took}s"; cat "$BODY"; exit 1; }
expect 200 "${K4[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)"   # enterprise still served
wait

## Batch API: a JSONL file runs line by line at the lowest priority; the results come back as files
bline() { echo "{\"custom_id\":\"$1\",\"method\":\"POST\",\"url\":\"/v1/chat/completions\",\"body\":{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hi.\"}],\"max_tokens\":$2}}"; }
input=$(mktemp)
{ bline one 8; bline two 8; bline too-long 5000; } > "$input"
expect 200 "${K2[@]}" -F purpose=batch -F "file=@-;filename=smoke.jsonl" "$G/v1/files" < "$input"   # stdin: no path translation on Windows
rm -f "$input"
input_id=$(json id)
expect 200 "${K2[@]}" "${J[@]}" -X POST "$G/v1/batches" -d "{\"input_file_id\":\"$input_id\",\"endpoint\":\"/v1/chat/completions\",\"completion_window\":\"24h\"}"
batch_id=$(json id)
status=""
for _ in $(seq 120); do
  curl -s -o "$BODY" "${K2[@]}" "$G/v1/batches/$batch_id"
  status=$(json status)
  [[ $status == completed ]] && break
  sleep 1
done
counts=$(sed -nE 's/.*"request_counts":\{([^}]*)\}.*/\1/p' "$BODY")
[[ $status == completed && $counts == '"total":3,"completed":2,"failed":1' ]] && echo "ok   batch completed: $counts" \
  || { echo "FAIL batch $status: $counts"; cat "$BODY"; exit 1; }
output_id=$(json output_file_id)
error_id=$(json error_file_id)
expect 200 "${K2[@]}" "$G/v1/files/$output_id/content"
[[ $(grep -c '"status_code":200' "$BODY") == 2 ]] && grep -q '"custom_id":"one"' "$BODY" || { echo "FAIL batch output"; cat "$BODY"; exit 1; }
expect 200 "${K2[@]}" "$G/v1/files/$error_id/content"
grep -q '"custom_id":"too-long".*"status_code":400' "$BODY" || { echo "FAIL batch error file"; cat "$BODY"; exit 1; }
batch_usage=""
for _ in $(seq 10); do
  batch_usage=$(sql "SELECT count(*) FROM usage.usage_event WHERE organization_id = '$org' AND mode = 'batch' AND status = 'ok'" | tr -d '\r')
  [[ $batch_usage == 2 ]] && break
  sleep 1
done
[[ $batch_usage == 2 ]] && echo "ok   usage: the 2 answered lines, mode=batch" || { echo "FAIL batch usage rows: $batch_usage"; exit 1; }
expect 404 "${K4[@]}" "$G/v1/batches/$batch_id"                       # another organization's batch
expect 404 "${K4[@]}" "$G/v1/files/$output_id/content"                 # and its files
expect 200 "${K2[@]}" -X DELETE "$G/v1/files/$input_id"
expect 404 "${K2[@]}" "$G/v1/files/$input_id"
# batch-line is batch-service's internal marker (batch prices, lowest priority): a client's copy is
# stripped by the gateway, so this malformed one never reaches inference-service (which would answer 400).
expect 200 "${K2[@]}" "${J[@]}" -H 'batch-line: forged' -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8)"

## service_tier flex: a live request in the half-price lane (billed as mode batch); other tiers are refused
expect 200 -D "$HDRS" "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8 ',"service_tier":"flex"')"
flex_rid=$(sed -nE 's/^x-request-id: ([0-9a-f-]{36}).*/\1/ip' "$HDRS")
expect 400 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Say hi.' 8 ',"service_tier":"priority"')"
flex_mode=""
for _ in $(seq 20); do
  flex_mode=$(sql "SELECT mode FROM usage.usage_event WHERE request_id = '$flex_rid'" | tr -d '\r')
  [[ -n $flex_mode ]] && break
  sleep 0.5
done
[[ $flex_mode == batch ]] && echo "ok   the flex request is billed in the half-price lane (mode batch)" \
  || { echo "FAIL flex request usage mode '$flex_mode'"; exit 1; }

## Canary: sync prompts and keys never reach a log, the database or Valkey's file (batch files are stored on purpose, 30 days)
canary="CANARY-$RANDOM$RANDOM"
expect 200 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat "Repeat exactly: $canary" 16)"
curl -sN "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat "Repeat exactly: $canary" 16 ',"stream":true')" >/dev/null
expect 400 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "{\"model\":\"$M\",\"messages\":\"$canary"
big=$(mktemp)
chat "$canary $(head -c 70000 /dev/zero | tr '\0' x)" 8 > "$big"
code=$(curl -s -o /dev/null -w '%{http_code}' "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" --data-binary @"$big")
rm -f "$big"
[[ $code == 413 ]] && echo "ok   413  over-context prompt" || { echo "FAIL over-context prompt got $code"; exit 1; }
curl -sN --max-time 1 "${K2[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat "$canary Write a long story." 500 ',"stream":true')" >/dev/null || true
expect 400 "${K2[@]}" "$G/v1/models?api_key=cmn_test_$canary"
sleep 2   # let batches and logs flush
access_log() { MSYS_NO_PATHCONV=1 "${DC[@]}" exec -T gateway sh -c 'cat /var/log/carmonai/access.log'; }
valkey_file() { MSYS_NO_PATHCONV=1 "${DC[@]}" exec -T valkey sh -c 'cat /data/appendonlydir/*'; }
leaks=$( { "${DC[@]}" logs --no-color 2>&1; "${DC[@]}" exec -T db sh -c 'pg_dumpall -U "$POSTGRES_USER"'; access_log; valkey_file; } \
  | grep -acF -e "$canary" -e "Bearer " -e "$key2" -e "api_key=" -e "${keep#*=}" || true)
[[ $leaks == 0 ]] && echo "ok   the canary, bearer headers, the API key and query strings are in no log (access log included), nowhere in the database and nowhere in Valkey's file" \
  || { echo "FAIL $leaks lines leak the canary, a bearer header, the key or a query string"; exit 1; }
# Marco Civil access log: the request above, with its ids, in the gateway's own file (not on stdout).
grep -q "$rid" <(access_log) && grep "$rid" <(access_log) | grep -q "\"organization_id\":\"$org\"" \
  && echo "ok   access log: request $rid with its organization and key" || { echo "FAIL request $rid not in the access log"; exit 1; }
"${DC[@]}" logs --no-color gateway 2>&1 | grep -q "$rid" && { echo "FAIL the access log reached stdout"; exit 1; }
[[ $(sql "SELECT count(*) FROM usage.usage_event WHERE request_id = '$rid'" | tr -d '\r') == 1 ]] \
  && echo "ok   usage event carries the same request id" || { echo "FAIL usage has no event for $rid"; exit 1; }

## Money: sealed usage windows are billed, and a used-up balance gets 402 until credit is added
balance=""
for _ in $(seq 60); do
  balance=$(sql "SELECT amount FROM billing.balance WHERE organization_id = '$org'" | tr -d '\r')
  [[ -n $balance && $balance -lt 10000000 ]] && break
  sleep 1
done
[[ -n $balance && $balance -lt 10000000 ]] && echo "ok   usage billed: R\$10 credit is now $balance micro-BRL" \
  || { echo "FAIL the usage was not billed (balance '$balance')"; exit 1; }
same=$(sql "SELECT (SELECT amount FROM billing.balance WHERE organization_id = '$org') = (SELECT sum(amount) FROM billing.ledger_entry WHERE organization_id = '$org')" | tr -d '\r')
[[ $same == t ]] && echo "ok   balance = sum of the ledger" || { echo "FAIL balance differs from the ledger"; exit 1; }

# A second organization gets 1 micro-BRL: one chat uses it up, then /v1 answers 402 until a grant.
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations" -d '{"name":"Smoke Tiny"}'
tiny=$(json id)
expect 201 "${A[@]}" "${J[@]}" -X POST "$G/organizations/$tiny/api-keys" -d '{"name":"tiny"}'
K3=(-H "Authorization: Bearer $(json key)")
code=$(grant "$tiny" 1 tiny-start)
[[ $code == 200 ]] || { echo "FAIL tiny grant got $code"; exit 1; }
expect 200 "${K3[@]}" "${J[@]}" -X POST "$G/v1/chat/completions" -d "$(chat 'Write two sentences about the sea.' 64)"
code=""
for _ in $(seq 60); do
  code=$(curl -s -o "$BODY" -w '%{http_code}' "${K3[@]}" "$G/v1/models")
  [[ $code == 402 ]] && break
  sleep 1
done
[[ $code == 402 ]] && grep -q '"insufficient_balance"' "$BODY" && echo "ok   402  balance used up, /v1 refused" \
  || { echo "FAIL expected 402 after the balance ran out, got $code"; cat "$BODY"; exit 1; }
code=$(grant "$tiny" 1000000 tiny-topup)
[[ $code == 200 ]] || { echo "FAIL top-up grant got $code"; exit 1; }
expect 200 "${K3[@]}" "$G/v1/models"                                 # credit back: allowed at once

## LGPD access: the account and its organizations, to its owner only
expect 200 "${A[@]}" "$G/accounts/$id/export"
grep -q "\"email\":\"$email\"" "$BODY" && grep -q "\"id\":\"$org\"" "$BODY" && ! grep -qi 'password' "$BODY" \
  || { echo "FAIL export content"; cat "$BODY"; exit 1; }

## Someone else's organization is invisible to a stranger
first_token=$token
first_email=$email
account
S=(-H "Authorization: Bearer $token")
expect 404 "${S[@]}" "$G/organizations/$org"
expect 404 "${S[@]}" "${J[@]}" -X POST "$G/organizations/$org/api-keys" -d '{"name":"x"}'
expect 404 "${S[@]}" -X DELETE "$G/organizations/$org"
expect 403 "${S[@]}" "$G/accounts/$id/export"

## Password reset: always 202; the link sets a new password and ends every session of the account
expect 202 "${J[@]}" -X POST "$G/accounts/password-reset" -d '{"email":"nobody-at-all@example.com"}'
expect 202 "${J[@]}" -X POST "$G/accounts/password-reset" -d "{\"email\":\"$email\"}"
expect 204 "${J[@]}" -X POST "$G/accounts/password-reset/confirm" \
  -d "{\"token\":\"$(mail_token "$email" reset-password)\",\"password\":\"a-new-smoke-passphrase\"}"
expect 401 -X POST "$G/auth/refresh" -H "Cookie: $rt"                    # the stranger's session ended
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
expect 200 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"a-new-smoke-passphrase\"}"
token=$first_token

## Erasure waits until no open organization would be left without an owner
expect 409 "${A[@]}" -X DELETE "$G/accounts/$id"
expect 204 "${A[@]}" -X DELETE "$G/organizations/$org"               # close all three
expect 204 "${A[@]}" -X DELETE "$G/organizations/$tiny"
expect 204 "${A[@]}" -X DELETE "$G/organizations/$corp"
# Closing deletes the organization's batch files (the batch section left its output and error files).
files=""
for _ in $(seq 30); do
  files=$(sql "SELECT count(*) FROM batch.file WHERE organization_id = '$org'" | tr -d '\r')
  [[ $files == 0 ]] && break
  sleep 1
done
[[ $files == 0 ]] && echo "ok   closing the organization erased its batch files" || { echo "FAIL $files batch files left after closing"; exit 1; }
expect 204 "${A[@]}" -X DELETE "$G/accounts/$id"
expect 401 -X POST "$G/auth/refresh" -H "Cookie: $keep"                  # its sessions ended with it
expect 404 "${A[@]}" "$G/accounts/$id"
expect 401 "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$first_email\",\"password\":\"$pass\"}"   # erased: gone

codes=$(for _ in $(seq 40); do curl -s -o /dev/null -w '%{http_code}\n' "${J[@]}" -X POST "$G/auth/login" -d '{}'; done)
grep -q 429 <<<"$codes" && echo "ok   429  burst of 40 logins is rate limited" || { echo "FAIL no 429 in burst"; exit 1; }

echo "smoke passed"
