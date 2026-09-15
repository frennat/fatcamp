#!/bin/sh
# One-command funnel read: prints the live metrics CSV (subs, revenue, installs,
# forges, banks, shares, opens by ?p= source) as an aligned table.
#
# The key stays out of this public repo. Either export FATCAMP_METRICS_KEY or
# put it in ~/.config/fatcamp/metrics.key (one line). The endpoint can answer
# "JWT issued at future" on a cold start; a second run succeeds.
KEY="${FATCAMP_METRICS_KEY:-$(cat "$HOME/.config/fatcamp/metrics.key" 2>/dev/null)}"
if [ -z "$KEY" ]; then
  echo "no metrics key: export FATCAMP_METRICS_KEY or write ~/.config/fatcamp/metrics.key" >&2
  exit 1
fi
URL="https://chghvwnytjlakuvkkluv.supabase.co/functions/v1/metrics?k=$KEY"
OUT=$(curl -fsS "$URL" 2>/dev/null) || OUT=$(sleep 2; curl -fsS "$URL") || { echo "metrics endpoint failed twice" >&2; exit 1; }
printf '%s\n' "$OUT" | awk -F, 'NF >= 2 { printf "%-24s %s\n", $1, $2 } NF < 2 { print }'
