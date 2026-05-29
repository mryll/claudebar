#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
GOOD='{"five_hour":{"utilization":40,"resets_at":"2030-01-01T00:00:00+00:00"},"seven_day":{"utilization":20,"resets_at":"2030-01-01T00:00:00+00:00"}}'
chk(){ assert_exit0 "$1: exit 0"; assert_json_valid "$1: valid JSON"; }

# --- malformed usage payloads ---
run_claudebar '{"five_hour":1,"seven_day":{"utilization":20,"resets_at":"2030-01-01T00:00:00+00:00"}}'; chk "five_hour non-object"
run_claudebar '{"five_hour":{"utilization":"high","resets_at":5},"seven_day":{"utilization":20}}'; chk "string utilization + non-string resets_at"
run_claudebar '{"five_hour":{"utilization":20},"seven_day":{"utilization":20},"seven_day_sonnet":7}'; chk "seven_day_sonnet non-object"
run_claudebar '{"five_hour":{"utilization":20},"seven_day":{"utilization":20},"extra_usage":9}'; chk "extra_usage non-object"
run_claudebar '{"five_hour":{"utilization":20},"seven_day":{"utilization":20},"extra_usage":{"is_enabled":true,"monthly_limit":"x","used_credits":[1]}}'; chk "extra_usage string/array fields"
run_claudebar '123'; chk "usage is a scalar"
run_claudebar '[]'; chk "usage is an array"
run_claudebar '{"seven_day":{"utilization":20}}'; chk "missing five_hour"

# --- malformed creds (valid JSON, wrong types) ---
run_claudebar_creds '{"claudeAiOauth":"not-an-object"}' "$GOOD"; chk "claudeAiOauth non-object"
run_claudebar_creds '{"claudeAiOauth":{"accessToken":"x","expiresAt":"soon","subscriptionType":["a"],"rateLimitTier":5}}' "$GOOD"; chk "wrong-typed creds fields"
run_claudebar_creds '{"claudeAiOauth":{}}' "$GOOD"; chk "empty claudeAiOauth"

# --- syntactically INVALID json cache (try/catch can't catch parse errors) ---
run_claudebar 'not json at all'; chk "invalid-JSON usage cache"
run_claudebar '{"five_hour":{"utilization":20'; chk "truncated/invalid JSON cache"

# --- huge numbers (1e100) that jq emits in scientific notation, breaking (( )) ---
run_claudebar '{"five_hour":{"utilization":1e100,"resets_at":"2030-01-01T00:00:00+00:00"},"seven_day":{"utilization":20,"resets_at":"2030-01-01T00:00:00+00:00"}}'; chk "1e100 utilization"
run_claudebar '{"five_hour":{"utilization":20},"seven_day":{"utilization":20},"extra_usage":{"is_enabled":true,"monthly_limit":1e100,"used_credits":1e100}}'; chk "1e100 extra credits"

# --- negative numbers must not make a negative-width bar (printf crash) ---
run_claudebar '{"five_hour":{"utilization":-100000,"resets_at":"2030-01-01T00:00:00+00:00"},"seven_day":{"utilization":-5,"resets_at":"2030-01-01T00:00:00+00:00"}}'; chk "negative utilization"
run_claudebar '{"five_hour":{"utilization":20},"seven_day":{"utilization":20},"extra_usage":{"is_enabled":true,"monthly_limit":1000,"used_credits":-100000}}'; chk "negative used_credits"

# --- multi-document JSON stream in the cache (jq -e . alone would accept it) ---
run_claudebar '{"five_hour":{"utilization":10},"seven_day":{"utilization":20}} {"five_hour":{"utilization":30},"seven_day":{"utilization":40}}'; chk "multi-document usage stream"
finish
