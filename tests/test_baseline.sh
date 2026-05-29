#!/usr/bin/env bash
# Regression guard: no behavior change for VALID data. Compares current claudebar
# vs the pre-hardening base commit, same instant (tooltip embeds wall-clock time),
# normalizing the volatile "Updated HH:MM" minute.
source "$(dirname "$0")/lib.sh"
BASE_REF="${BASE_REF:-7630722}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
USAGE='{"five_hour":{"utilization":42,"resets_at":"2030-01-01T00:00:00+00:00"},"seven_day":{"utilization":27,"resets_at":"2030-01-01T00:00:00+00:00"}}'
norm(){ sed 's/Updated [0-9][0-9]:[0-9][0-9]/Updated XX:XX/g'; }
base="$(mktemp)"; git -C "$REPO" show "$BASE_REF:claudebar" > "$base" && chmod +x "$base"
SCRIPT="$base" run_claudebar "$USAGE"; b="$(norm <<<"$OUT")"
run_claudebar "$USAGE";                 n="$(norm <<<"$OUT")"
rm -f "$base"
[[ "$b" == "$n" ]] && _ok "no-flag output unchanged vs $BASE_REF" || _no "no-flag output unchanged vs $BASE_REF" "$(diff <(printf '%s' "$b") <(printf '%s' "$n") | head -40)"
finish
