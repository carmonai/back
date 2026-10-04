#!/usr/bin/env bash
# Phase-5 exit check on the GPU (inference-plan §11): three loads at once through the gateway, one
# organization and key per tier, for 60 s:
#   enterprise: 4 workers back to back (C = 4)
#   standard:   4 workers, a pause of 0.5 s between requests
#   trial:      12 workers (3 x C), a pause of 1.5 s (keeps it under the gateway's 10 requests/s per key)
# Each request streams up to 128 tokens. Pass: every trial 429 in < 100 ms, enterprise goodput >= 95%
# (TTFT <= 2 s and TPOT <= 100 ms), and no request hits inference-service's TTFT timeout.
# Workers are curl in the llama container, not vllm bench: a second Python/torch process next to vLLM
# ran the laptop's Docker VM out of memory. TTFT = time to the first byte (inference-service sends the
# headers with the first event). Laptop numbers: they size the caps, they are not prices.
# Run after: docker compose -f compose.yaml -f compose.gpu.yaml up -d --build --wait
set -euo pipefail
cd "$(dirname "$0")"

DC=(docker compose -f compose.yaml -f compose.gpu.yaml)
G=http://localhost:8080
J=(-H 'Content-Type: application/json')
M=carmonai/qwen3-4b
DURATION=60
RESULTS=${TMPDIR:-/tmp}/carmonai-bench.txt   # kept for a closer look; the next run overwrites it

json() { sed -nE "s/.*\"$1\":\"([^\"]+)\".*/\1/p" <<<"$2"; }
sql() { "${DC[@]}" exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "$1"' sh "$1" >/dev/null; }
grant() {
  "${DC[@]}" exec -T llama curl -s -o /dev/null -H 'Content-Type: application/json' -X POST http://billing:8080/billing/grants \
    -d "{\"organizationId\":\"$1\",\"amountMicroBrl\":100000000,\"reason\":\"bench\",\"idempotencyKey\":\"bench\"}"
}

# Accounts verify their email before login: follow the link Mailpit caught, as a user would.
verify_email() {
  local token="" id
  for _ in $(seq 20); do
    for id in $("${DC[@]}" exec -T llama curl -s "http://mailpit:8025/api/v1/search?query=to:%22${1/@/%40}%22" | grep -oE '"ID":"[^"]+"' | cut -d'"' -f4); do
      token=$("${DC[@]}" exec -T llama curl -s "http://mailpit:8025/api/v1/message/$id" | grep -oE '/verify-email\?token=[A-Za-z0-9_-]+' | sed -n '1s/.*=//p')
      [[ -n $token ]] && break 2
    done
    sleep 0.5
  done
  curl -s -o /dev/null "${J[@]}" -X POST "$G/accounts/verify-email" -d "{\"token\":\"$token\"}"
}

# Synthetic account; each tier's organization gets R$100 and its tier (staff-set, before the key is used).
email="bench-$RANDOM$RANDOM@example.com"
pass='correct-horse-battery'
curl -s -o /dev/null "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Bench\",\"email\":\"$email\",\"password\":\"$pass\"}"
verify_email "$email"
token=$(json token "$(curl -s "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}")")
A=(-H "Authorization: Bearer $token")
account=$(json id "$(curl -s "${A[@]}" "$G/auth/whoami")")
declare -A KEY ORG
for tier in trial standard enterprise; do
  ORG[$tier]=$(json id "$(curl -s "${A[@]}" "${J[@]}" -X POST "$G/organizations" -d "{\"name\":\"Bench $tier\"}")")
  sql "UPDATE organizations.organization SET tier = '$tier' WHERE id = '${ORG[$tier]}'"
  grant "${ORG[$tier]}"
  KEY[$tier]=$(json key "$(curl -s "${A[@]}" "${J[@]}" -X POST "$G/organizations/${ORG[$tier]}/api-keys" -d '{"name":"bench"}')")
done

start=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "bench: enterprise 4 workers, standard 4, trial 12, for ${DURATION}s through the gateway ..."
# One line per request: tier status ttfb_s total_s output_tokens error_code started_at
"${DC[@]}" exec -T -e TRIAL="${KEY[trial]}" -e STANDARD="${KEY[standard]}" -e ENTERPRISE="${KEY[enterprise]}" \
  -e M="$M" -e END="$DURATION" llama bash -c '
  body="{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Count from 1 to 200, separated by commas.\"}],"
  body+="\"max_tokens\":128,\"temperature\":0,\"stream\":true,\"stream_options\":{\"include_usage\":true}}"
  worker() {   # tier key pause
    while (( SECONDS < END )); do
      began=$EPOCHREALTIME
      out=$(curl -sN -w "\n%{http_code} %{time_starttransfer} %{time_total}" -H "Authorization: Bearer $2" \
        -H "Content-Type: application/json" -d "$body" http://gateway:8080/v1/chat/completions)
      last=${out##*\"completion_tokens\":}; tokens=${last%%[!0-9]*}   # the last usage (every chunk carries one)
      [[ $out =~ \"code\":\"([a-z_]+)\" ]] && code=${BASH_REMATCH[1]} || code=-
      echo "$1 ${out##*$'\''\n'\''} ${tokens:-0} $code $began"
      sleep "$3"
    done
  }
  for _ in 1 2 3 4; do worker enterprise "$ENTERPRISE" 0 & done
  for _ in 1 2 3 4; do worker standard "$STANDARD" 0.5 & done
  for _ in $(seq 12); do worker trial "$TRIAL" 1.5 & done
  wait' > "$RESULTS"

# Per tier: answered, refused by reason, latency of the answered ones.
for tier in enterprise standard trial; do
  awk -v tier="$tier" -v duration="$DURATION" '$1 == tier {
      n++
      if ($2 == 200) { ok++; ttft[ok] = $3; tokens += $5; tpot = $5 > 1 ? ($4 - $3) / ($5 - 1) : 0; tp[ok] = tpot
                       if ($3 <= 2 && tpot <= 0.1) good++ }
      else if ($2 == 429) { refused[$6 == "-" ? "gateway" : $6]++; late += ($3 >= 0.1); r[++k] = $3 }
      else other++ }
    function p95(a, m,   i, j, t) {   # insertion sort, fine for a few hundred values
      for (i = 2; i <= m; i++) { t = a[i]; for (j = i - 1; j > 0 && a[j] > t; j--) a[j + 1] = a[j]; a[j + 1] = t }
      i = int(0.95 * m); return m ? a[i < 1 ? 1 : i] : 0 }
    END {
      printf "%-10s %4d requests, %4d answered, goodput %3.0f%%, TTFT p95 %5.0f ms, TPOT p95 %3.0f ms, %4.0f output tok/s; refused:",
        tier, n, ok, n ? 100 * good / n : 0, 1000 * p95(ttft, ok), 1000 * p95(tp, ok), tokens / duration
      for (c in refused) printf " %s=%d", c, refused[c]
      if (k) printf " (429 p95 %.0f ms, max %.0f ms, %d >= 100 ms)", 1000 * p95(r, k), 1000 * r[k], late
      printf "; other errors %d\n", other }' "$RESULTS"
done
timeouts=$("${DC[@]}" logs --no-color --since "$start" inference 2>&1 | grep -c 'engine_timeout' || true)

# Pass marks.
good=$(awk '$1 == "enterprise" { n++; if ($2 == 200 && $3 <= 2 && ($5 > 1 ? ($4 - $3) / ($5 - 1) : 0) <= 0.1) g++ }
  END { print (n && g >= 0.95 * n) ? 1 : 0 }' "$RESULTS")
slow=$(awk '$1 == "trial" && $2 == 429 && $3 >= 0.1' "$RESULTS" | wc -l)
shed=$(awk '$1 == "trial" && $2 == 429' "$RESULTS" | wc -l)
fails=0
check() { if [[ $2 == 1 ]]; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }
check "enterprise goodput >= 95%" "$good"
check "trial is refused under load ($shed)" "$(( shed > 0 ))"
check "every trial 429 under 100 ms ($slow slower)" "$(( slow == 0 ))"
check "no TTFT timeouts ($timeouts)" "$(( timeouts == 0 ))"

# Synthetic data out again: close the organizations, erase the account.
for tier in trial standard enterprise; do curl -s -o /dev/null "${A[@]}" -X DELETE "$G/organizations/${ORG[$tier]}"; done
curl -s -o /dev/null "${A[@]}" -X DELETE "$G/accounts/$account"
[[ $fails == 0 ]] && echo "bench passed" || { echo "bench failed"; exit 1; }
