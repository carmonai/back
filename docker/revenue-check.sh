#!/usr/bin/env bash
# The books, on demand: calls billing-service's reconciliation on its management port (8081). That port is
# never published and never routed, so the check goes through the internal network. Exits non-zero when any
# balance differs from the sum of its ledger, so cron or CI can fail on drift. The answer carries ids and
# amounts only: no organization name, no account.
# Run after: docker compose up -d --build --wait
set -euo pipefail
DC=(docker compose -f "$(dirname "$0")/compose.yaml")

# The JRE images have no curl; the llama container does (smoke.sh asks the internal network from there too).
answer=$("${DC[@]}" exec -T llama curl -sS -w '\n%{http_code}' http://billing:8081/actuator/reconcile)
code=${answer##*$'\n'}
body=${answer%$'\n'*}
[[ $code == 200 ]] || { echo "FAIL reconcile got $code"; echo "$body"; exit 1; }

organizations=$(sed -nE 's/.*"organizations":([0-9]+).*/\1/p' <<<"$body")
mismatched=$(sed -nE 's/.*"mismatched":([0-9]+).*/\1/p' <<<"$body")
# The counts, then only the organizations that disagree (they come first): 99 healthy rows are noise.
sed -nE 's/,"checks":\[.*$/}/p' <<<"$body"
grep -oE '\{"organizationId":"[^"]*","amountMicroBrl":-?[0-9]+,"ledgerMicroBrl":-?[0-9]+,"agree":false\}' <<<"$body" || true

grep -q '"balanced":true' <<<"$body" \
  && echo "ok   the books balance: $organizations organization(s) checked, each equal to its ledger" \
  || { echo "FAIL $mismatched of $organizations organization(s) differ from their ledger"; exit 1; }
