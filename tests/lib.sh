#!/usr/bin/env bash
# Test harness for claudebar. Runs the real script against crafted creds + usage
# with NO network: fake $HOME, far-future expiresAt (no refresh), fresh cache,
# and a `curl` stub (exits 1) so refresh/fetch can't reach the network.
set -uo pipefail
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/claudebar"
PASS=0; FAIL=0

VALID_CREDS='{"claudeAiOauth":{"accessToken":"x","refreshToken":"y","expiresAt":4102444800000,"subscriptionType":"max","rateLimitTier":"default"}}'

_run() {  # <creds-json> <usage-json> [args...]
    local creds="$1" usage="$2"; shift 2
    local home; home="$(mktemp -d)" || { echo "HARNESS SETUP FAILED" >&2; exit 1; }
    mkdir -p "$home/.claude" "$home/.cache/claudebar" "$home/bin" || { echo "HARNESS SETUP FAILED" >&2; exit 1; }
    printf '#!/usr/bin/env bash\nexit 1\n' > "$home/bin/curl" && chmod +x "$home/bin/curl" || { echo "HARNESS SETUP FAILED" >&2; exit 1; }
    printf '%s' "$creds" > "$home/.claude/.credentials.json"      || { echo "HARNESS SETUP FAILED" >&2; exit 1; }
    printf '%s' "$usage" > "$home/.cache/claudebar/usage.json"     || { echo "HARNESS SETUP FAILED" >&2; exit 1; }
    touch "$home/.cache/claudebar/usage.json"
    OUT=$(HOME="$home" PATH="$home/bin:$PATH" "$SCRIPT" "$@"); RC=$?
    rm -rf "$home"
    return 0
}
# run_claudebar '<usage-json>' [args...]  — valid creds
run_claudebar() { _run "$VALID_CREDS" "$@"; }
# run_claudebar_creds '<creds-json>' '<usage-json>' [args...]
run_claudebar_creds() { _run "$@"; }

_ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
_no()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n    %s\n' "$1" "${2:-}"; }
assert_exit0()      { [[ "$RC" -eq 0 ]] && _ok "$1" || _no "$1" "exit=$RC"; }
assert_json_valid() { jq -e . >/dev/null 2>&1 <<<"$OUT" && _ok "$1" || _no "$1" "invalid JSON: $OUT"; }
_plain() { jq -r "$1" <<<"$OUT" | sed 's/<[^>]*>//g'; }
assert_text_has()  { _plain .text | grep -qF -- "$2" && _ok "$1" || _no "$1" "text lacks: $2"; }
assert_class() { local c; c=$(jq -r .class <<<"$OUT"); [[ "$c" == "$2" ]] && _ok "$1" || _no "$1" "class=$c want=$2"; }
assert_tip_has()  { _plain .tooltip | grep -qF -- "$2" && _ok "$1" || _no "$1" "tooltip lacks: $2"; }
finish() { printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"; [[ "$FAIL" -eq 0 ]]; }
