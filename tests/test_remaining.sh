#!/usr/bin/env bash
# Simulated-API battery for --remaining mode. No network, no secrets.
source "$(dirname "$0")/lib.sh"

# --- Unit: remaining_pct_for clamps 0..100 (sourced indirectly via the script's behavior) ---
# 100 - used, clamped. Verified through the {session_remaining_pct} placeholder below;
# here we assert the boundary directly using --format.
run_claudebar '{"five_hour":{"utilization":40,"resets_at":"2030-01-01T00:00:00+00:00"},"seven_day":{"utilization":10,"resets_at":"2030-01-01T00:00:00+00:00"}}' --format '{session_remaining_pct}'
assert_exit0 "remaining_pct basic: exit 0"; assert_text_has "remaining_pct 40->60" "60"

run_claudebar '{"five_hour":{"utilization":150,"resets_at":"2030-01-01T00:00:00+00:00"},"seven_day":{"utilization":10,"resets_at":"2030-01-01T00:00:00+00:00"}}' --format '{session_remaining_pct}'
assert_exit0 "remaining_pct >100 clamp: exit 0"; assert_text_has "remaining_pct 150->0" "0"

finish
