#!/usr/bin/env bash
# Phase-6 exit check on the GPU (inference-plan §11): a 10,000-line batch completes while interactive
# traffic keeps its SLOs, and a line re-run after a crash is billed once.
#   batch:       10k tiny lines (2 output tokens) from a standard organization; the 10 lines just past the
#                middle are slow (256 tokens, ~6 s) so the kill below lands mid-call
#   interactive: 1 enterprise worker (0.5 s pause) and 1 trial worker (2 s pause), 128-token streams
# Halfway, while a worker holds one of the slow lines, batch-service is killed (SIGKILL) and started again:
# the lines it was running roll back and run again. Pass: the batch completes with every line answered, vLLM
# ran some line twice, usage-service holds exactly one event per line (the run that answered), enterprise
# goodput >= 95% (TTFT <= 2 s, TPOT <= 100 ms), no TTFT timeouts.
# Run after: docker compose -f compose.yaml -f compose.gpu.yaml up -d --build --wait
set -euo pipefail
cd "$(dirname "$0")"
# Container paths go through MSYS_NO_PATHCONV=1: Git Bash would rewrite /tmp/... into a Windows path.
# (Only there: curl's -o /dev/null needs the rewrite.)

DC=(docker compose -f compose.yaml -f compose.gpu.yaml)
G=http://localhost:8080
J=(-H 'Content-Type: application/json')
M=carmonai/qwen3-4b
LINES=${LINES:-10000}
RESULTS=${TMPDIR:-/tmp}/carmonai-batch-bench.txt   # interactive requests; kept for a closer look

json() { sed -nE "s/.*\"$1\":\"?([^\",}]+)\"?.*/\1/p" <<<"$2"; }
sql() { "${DC[@]}" exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "$1"' sh "$1" | tr -d '\r'; }
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

# Synthetic account: a standard organization for the batch, enterprise and trial ones for interactive load.
email="bench-$RANDOM$RANDOM@example.com"
pass='correct-horse-battery'
curl -s -o /dev/null "${J[@]}" -X POST "$G/auth/register" -d "{\"name\":\"Bench\",\"email\":\"$email\",\"password\":\"$pass\"}"
verify_email "$email"
token=$(json token "$(curl -s "${J[@]}" -X POST "$G/auth/login" -d "{\"email\":\"$email\",\"password\":\"$pass\"}")")
A=(-H "Authorization: Bearer $token")
account=$(json id "$(curl -s "${A[@]}" "$G/auth/whoami")")
declare -A KEY ORG
for tier in standard enterprise trial; do
  ORG[$tier]=$(json id "$(curl -s "${A[@]}" "${J[@]}" -X POST "$G/organizations" -d "{\"name\":\"Bench $tier\"}")")
  sql "UPDATE organizations.organization SET tier = '$tier' WHERE id = '${ORG[$tier]}'" >/dev/null
  grant "${ORG[$tier]}"
  KEY[$tier]=$(json key "$(curl -s "${A[@]}" "${J[@]}" -X POST "$G/organizations/${ORG[$tier]}/api-keys" -d '{"name":"bench"}')")
done
B=(-H "Authorization: Bearer ${KEY[standard]}")

# The batch: one tiny request per line, and 10 slow ones (line indexes SLOW .. SLOW+9) just past the middle.
SLOW=$((LINES / 2))
for i in $(seq "$LINES"); do
  prompt="Reply with one word: $i" tokens=2
  (( i > SLOW && i <= SLOW + 10 )) && prompt="Count from 1 to 500, separated by commas." tokens=256
  echo "{\"custom_id\":\"line-$i\",\"method\":\"POST\",\"url\":\"/v1/chat/completions\",\"body\":{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}],\"max_tokens\":$tokens}}"
done > "$RESULTS.jsonl"
file=$(json id "$(curl -s "${B[@]}" -F purpose=batch -F "file=@-;filename=bench.jsonl" "$G/v1/files" < "$RESULTS.jsonl")")
rm -f "$RESULTS.jsonl"
batch=$(json id "$(curl -s "${B[@]}" "${J[@]}" -X POST "$G/v1/batches" \
  -d "{\"input_file_id\":\"$file\",\"endpoint\":\"/v1/chat/completions\",\"completion_window\":\"24h\"}")")
[[ $batch == batch_* ]] || { echo "FAIL batch not created"; exit 1; }
start=$(date -u +%Y-%m-%dT%H:%M:%SZ)
began=$SECONDS
echo "bench: $LINES-line batch $batch, with enterprise and trial traffic alongside ..."

# Interactive workers in the llama container until /tmp/stop-bench appears; one line per request:
# tier status ttfb_s total_s output_tokens
MSYS_NO_PATHCONV=1 "${DC[@]}" exec -T llama rm -f /tmp/stop-bench
trap 'MSYS_NO_PATHCONV=1 "${DC[@]}" exec -T llama touch /tmp/stop-bench >/dev/null 2>&1 || true' EXIT   # workers stop however this ends
"${DC[@]}" exec -T -e ENTERPRISE="${KEY[enterprise]}" -e TRIAL="${KEY[trial]}" -e M="$M" llama bash -c '
  body="{\"model\":\"$M\",\"messages\":[{\"role\":\"user\",\"content\":\"Count from 1 to 200, separated by commas.\"}],"
  body+="\"max_tokens\":128,\"temperature\":0,\"stream\":true,\"stream_options\":{\"include_usage\":true}}"
  worker() {   # tier key pause
    while [[ ! -e /tmp/stop-bench ]]; do
      out=$(curl -sN -w "\n%{http_code} %{time_starttransfer} %{time_total}" -H "Authorization: Bearer $2" \
        -H "Content-Type: application/json" -d "$body" http://gateway:8080/v1/chat/completions)
      last=${out##*\"completion_tokens\":}; tokens=${last%%[!0-9]*}
      echo "$1 ${out##*$'\''\n'\''} ${tokens:-0}"
      sleep "$3"
    done
  }
  worker enterprise "$ENTERPRISE" 0.5 & worker trial "$TRIAL" 2 &
  wait' > "$RESULTS" &
workers=$!

# Follow the batch; kill batch-service once, while a worker runs a slow line. A pending line nobody holds
# shows up under FOR UPDATE SKIP LOCKED; one a worker is running doesn't.
held_slow() {
  sql "SELECT (SELECT count(*) FROM batch.batch_line WHERE batch_id = '$batch' AND line BETWEEN $SLOW AND $((SLOW + 9)) AND status = 'pending')
    - (SELECT count(*) FROM (SELECT 1 FROM batch.batch_line WHERE batch_id = '$batch' AND line BETWEEN $SLOW AND $((SLOW + 9))
       AND status = 'pending' FOR UPDATE SKIP LOCKED) free)"
}
killed=0
status=in_progress
while [[ $status == in_progress ]] && (( SECONDS - began < 5400 )); do
  sleep 15
  status=$(json status "$(curl -s "${B[@]}" "$G/v1/batches/$batch")")
  done_lines=$(sql "SELECT count(*) FROM batch.batch_line WHERE batch_id = '$batch' AND status <> 'pending'")
  printf '%5ds  %s lines done\n' $((SECONDS - began)) "${done_lines:-?}"
  if (( killed == 0 && ${done_lines:-0} >= SLOW - 300 )); then
    for _ in $(seq 180); do
      held=$(held_slow)
      (( ${held:-0} > 0 )) && break
      sleep 1
    done
    "${DC[@]}" kill batch >/dev/null 2>&1 && "${DC[@]}" up -d --wait batch >/dev/null 2>&1
    killed=1
    echo "       batch-service killed and started again"
  fi
done
MSYS_NO_PATHCONV=1 "${DC[@]}" exec -T llama touch /tmp/stop-bench
wait "$workers" || true
elapsed=$((SECONDS - began))
# Each run the kill cut short is logged by inference-service (ids only) and runs again.
reruns=$("${DC[@]}" logs --no-color --since "$start" inference 2>&1 | grep -c "batch $batch line .* cut short" || true)

final=$(curl -s "${B[@]}" "$G/v1/batches/$batch")
completed=$(sed -nE 's/.*"completed":([0-9]+).*/\1/p' <<<"$final")
failed=$(sed -nE 's/.*"failed":([0-9]+).*/\1/p' <<<"$final")
rows=$(sql "SELECT count(*) || ' ' || count(DISTINCT event_id) || ' ' || count(*) FILTER (WHERE status = 'ok') FROM usage.usage_event WHERE organization_id = '${ORG[standard]}' AND mode = 'batch'")
read -r events distinct answered_events <<<"$rows"
echo "batch: $status in ${elapsed}s ($(awk -v n="${completed:-0}" -v t="$elapsed" 'BEGIN { printf "%.1f", t ? n / t : 0 }') lines/s), ${completed:-0} answered, ${failed:-0} failed"
echo "kill: $reruns line(s) cut short mid-call, run again"
echo "usage: $events batch events, $distinct distinct ids"
for tier in enterprise trial; do
  awk -v tier="$tier" '$1 == tier {
      n++
      if ($2 == 200) { ok++; ttft[ok] = $3; tpot = $5 > 1 ? ($4 - $3) / ($5 - 1) : 0; tp[ok] = tpot; if ($3 <= 2 && tpot <= 0.1) good++ }
      else refused[$2]++ }
    function p95(a, m,   i, j, t) {
      for (i = 2; i <= m; i++) { t = a[i]; for (j = i - 1; j > 0 && a[j] > t; j--) a[j + 1] = a[j]; a[j + 1] = t }
      i = int(0.95 * m); return m ? a[i < 1 ? 1 : i] : 0 }
    END {
      printf "%-10s %4d requests, %4d answered, goodput %3.0f%%, TTFT p95 %5.0f ms, TPOT p95 %3.0f ms; refused:",
        tier, n, ok, n ? 100 * good / n : 0, 1000 * p95(ttft, ok), 1000 * p95(tp, ok)
      for (c in refused) printf " %s=%d", c, refused[c]
      printf "\n" }' "$RESULTS"
done
timeouts=$("${DC[@]}" logs --no-color --since "$start" inference 2>&1 | grep -c 'engine_timeout' || true)

good=$(awk '$1 == "enterprise" { n++; if ($2 == 200 && $3 <= 2 && ($5 > 1 ? ($4 - $3) / ($5 - 1) : 0) <= 0.1) g++ }
  END { print (n && g >= 0.95 * n) ? 1 : 0 }' "$RESULTS")
fails=0
check() { if [[ $2 == 1 ]]; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }
check "the batch completed with every line answered" "$(( ${completed:-0} == LINES ))"
check "one usage event per line, the run that answered ($events rows, $distinct ids, $answered_events ok)" \
  "$(( events == LINES && distinct == LINES && answered_events == LINES ))"
check "enterprise goodput >= 95% alongside the batch" "$good"
check "no TTFT timeouts ($timeouts)" "$(( timeouts == 0 ))"
check "the kill cut $reruns line(s) short; they ran again and were billed once" "$(( reruns > 0 ))"

# Synthetic data out again: the batch's files, the organizations, the account.
for f in "$file" "$(json output_file_id "$final")" "$(json error_file_id "$final")"; do
  curl -s -o /dev/null "${B[@]}" -X DELETE "$G/v1/files/$f"
done
for tier in standard enterprise trial; do curl -s -o /dev/null "${A[@]}" -X DELETE "$G/organizations/${ORG[$tier]}"; done
curl -s -o /dev/null "${A[@]}" -X DELETE "$G/accounts/$account"
[[ $fails == 0 ]] && echo "bench passed" || { echo "bench failed"; exit 1; }
