#!/usr/bin/env bash
# Run this AFTER pasting schema.sql into the Supabase SQL editor.
#
# It checks the thing that actually matters: that the publishable key — which is
# public, and sits in index.html in a public repo — cannot read anybody's data.
# Every check below uses only that key, exactly like a stranger would.

set -u
URL="https://chghvwnytjlakuvkkluv.supabase.co"
KEY="sb_publishable_H69bdgZ5FdZIojX5LHK3aQ_2Vz2CZif"
pass=0; fail=0

check () { # name, expected-substring, actual
  if grep -qi -- "$2" <<< "$3"; then
    printf "  \033[32mPASS\033[0m  %s\n" "$1"; pass=$((pass+1))
  else
    printf "  \033[31mFAIL\033[0m  %s\n        got: %s\n" "$1" "${3:0:150}"; fail=$((fail+1))
  fi
}

echo
echo "Tables exist"
for t in lifters sessions standings; do
  body=$(curl -s "$URL/rest/v1/$t?select=*&limit=1" -H "apikey: $KEY")
  if grep -q "PGRST205" <<< "$body"; then
    printf "  \033[31mFAIL\033[0m  %s is missing — has schema.sql been run?\n" "$t"; fail=$((fail+1))
  else
    printf "  \033[32mPASS\033[0m  %s exists\n" "$t"; pass=$((pass+1))
  fi
done

echo
echo "Anonymous reads are refused (RLS is the security boundary)"
for t in lifters sessions standings; do
  body=$(curl -s "$URL/rest/v1/$t?select=*&limit=5" -H "apikey: $KEY")
  # with RLS on and no policy for anon, PostgREST returns an empty array
  if [ "$body" = "[]" ]; then
    printf "  \033[32mPASS\033[0m  %s leaks nothing to an anonymous key\n" "$t"; pass=$((pass+1))
  else
    printf "  \033[31mFAIL\033[0m  %s returned data anonymously: %s\n" "$t" "${body:0:150}"; fail=$((fail+1))
  fi
done

echo
echo "Anonymous writes are refused"
body=$(curl -s -X POST "$URL/rest/v1/standings" -H "apikey: $KEY" \
  -H "Content-Type: application/json" \
  -d '[{"lifter":"00000000-0000-0000-0000-000000000000","handle":"cheater","total_xp":999999}]')
check "standings cannot be written directly" "violates\|denied\|permission\|policy\|42501\|401\|403" "$body"

body=$(curl -s -X POST "$URL/rest/v1/lifters" -H "apikey: $KEY" \
  -H "Content-Type: application/json" \
  -d '[{"id":"00000000-0000-0000-0000-000000000000","handle":"nobody"}]')
check "lifters cannot be written anonymously" "violates\|denied\|permission\|policy\|42501\|401\|403" "$body"

echo
echo "Auth is reachable"
code=$(curl -s -o /dev/null -w "%{http_code}" "$URL/auth/v1/settings" -H "apikey: $KEY")
check "auth settings respond" "200" "$code"

echo
printf "%d passed, %d failed\n\n" "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
