# CLAUDE.md

## Tooling

- Install: `make install PREFIX=~/.local` (or `sudo make install`)
- No build step, linter, or test suite — this is a single bash script (`claudebar`)

## Non-Obvious Rules

- The script must **always exit 0**, even on errors — Waybar hides modules that exit non-zero. Use `die()` for error output.
- All output must be valid Waybar JSON: `{"text":"...", "tooltip":"...", "class":"..."}`
- Tooltip uses **Pango markup** for rich formatting (colors, bold, box-drawing borders)
- `set -euo pipefail` is enforced — all variables must be set before use
- Bar text is wrapped in Pango `<span foreground='...'>` for coloring — raw text won't render colors
- OAuth client ID (`9d1c250a-...`) is the public Claude CLI client ID, not a secret
- Cache writes use atomic `mktemp` + `mv` to avoid partial reads from concurrent Waybar instances
- `flock` serializes API calls across multi-monitor Waybar instances sharing the same cache
