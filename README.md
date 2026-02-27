# claudebar

Waybar widget that shows your Claude AI usage limits -- session, weekly, and per-model -- with colored progress bars and countdown timers.

![screenshot](screenshot.png)

## Features

- Session (5h) and weekly (7d) usage with countdown timers
- Per-model tracking (Sonnet) when available
- Extra usage tracking (spending, limit, balance) when enabled
- Pacing indicators -- are you using too fast or too slow?
- Colored progress bars in tooltip (Pango markup)
- Customizable bar text and tooltip via `--format` / `--tooltip-format` placeholders
- Granular CSS classes (`low`, `mid`, `high`, `critical`) for bar styling
- Response cache (60s TTL) -- fast even on multi-monitor setups
- Auto-refreshes OAuth token (no manual re-auth needed)
- Pure bash -- no runtime dependencies beyond `curl`, `jq`, and GNU `date`
- Works with any Waybar setup (Hyprland, Sway, etc.)

## Requirements

- [Claude CLI](https://github.com/anthropics/claude-code) -- must be logged in (`claude` command)
- Claude Pro or Max subscription
- `curl`, `jq`, GNU `date` (standard on most Linux systems)
- [Waybar](https://github.com/Alexays/Waybar)
- A [Nerd Font](https://www.nerdfonts.com/) for tooltip icons
- (Optional) [Font Awesome](https://fontawesome.com/) ≥ 7.2.0 OTF for the Claude brand icon

## Installation

### Arch Linux (AUR)

```bash
yay -S claudebar
```

### From source

```bash
git clone https://github.com/mryll/claudebar.git
cd claudebar
make install PREFIX=~/.local
```

Or system-wide:

```bash
sudo make install
```

To uninstall:

```bash
make uninstall PREFIX=~/.local
```

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/mryll/claudebar/main/claudebar \
  -o ~/.local/bin/claudebar && chmod +x ~/.local/bin/claudebar
```

## Waybar configuration

Add the module to your `~/.config/waybar/config.jsonc`:

```jsonc
"modules-right": ["custom/claudebar", ...],

// Without icon (default)
"custom/claudebar": {
    "exec": "claudebar",
    "return-type": "json",
    "interval": 60,
    "tooltip": true,
    "on-click": "xdg-open https://claude.ai/settings/usage"
}
```

### Adding an icon

You can add any icon via waybar's `format` field. The `{}` placeholder is replaced with the widget text.

**No icon** (default):

```jsonc
"custom/claudebar": {
    "exec": "claudebar",
    "return-type": "json",
    "interval": 60,
    "tooltip": true,
    "on-click": "xdg-open https://claude.ai/settings/usage"
}
// => 42% · 1h 30m
```

**Nerd Font icon** (any Nerd Font glyph):

```jsonc
"custom/claudebar": {
    "exec": "claudebar",
    "format": "󰚩 {}",
    "return-type": "json",
    "interval": 60,
    "tooltip": true,
    "on-click": "xdg-open https://claude.ai/settings/usage"
}
// => 󰚩 42% · 1h 30m
```

**Claude brand icon** (requires [Font Awesome](https://fontawesome.com/) ≥ 7.2.0 OTF):

```jsonc
"custom/claudebar": {
    "exec": "claudebar",
    "format": "<span font='Font Awesome 7 Brands'>\ue861</span> {}",
    "return-type": "json",
    "interval": 60,
    "tooltip": true,
    "on-click": "xdg-open https://claude.ai/settings/usage"
}
```

> **Note:** On Arch Linux, install the OTF package (`sudo pacman -S otf-font-awesome`).
> The WOFF2 variant (`woff2-font-awesome`) does not render in Waybar due to a
> [Pango compatibility issue](https://github.com/Alexays/Waybar/issues/4381).

### Colors

The bar text is colored by severity level out of the box (One Dark palette):

| Class | Range | Default color |
|---|---|---|
| `low` | 0-49% | `#98c379` (green) |
| `mid` | 50-74% | `#e5c07b` (yellow) |
| `high` | 75-89% | `#d19a66` (orange) |
| `critical` | 90-100% | `#e06c75` (red) |

To override, pass `--color-*` flags in the `exec` field:

```jsonc
"custom/claudebar": {
    "exec": "claudebar --color-low '#50fa7b' --color-critical '#ff5555'",
    ...
}
```

Available flags: `--color-low`, `--color-mid`, `--color-high`, `--color-critical`.

CSS classes (`low`, `mid`, `high`, `critical`) are also emitted for additional styling via `~/.config/waybar/style.css`.

## Format customization

Use `--format` to control what the widget outputs as bar text:

```bash
# Default (session usage + countdown)
claudebar
# => 42% · 1h 30m

# Weekly usage
claudebar --format '{weekly_pct}% · {weekly_reset}'
# => 27% · 4d 1h

# Session + weekly
claudebar --format 'S:{session_pct}% W:{weekly_pct}%'
# => S:42% W:27%

# With pacing indicator
claudebar --format '{session_pct}% {session_pace} · {session_reset}'
# => 42% ↑ · 1h 30m

# Minimal
claudebar --format '{session_pct}%'
# => 42%
```

> **Tip:** For icons, use waybar's `format` field (see [Adding an icon](#adding-an-icon))
> instead of embedding them in `--format`. This lets you use Pango markup to select
> the font, which is necessary for brand icons like Font Awesome.

Use `--tooltip-format` for a custom plain-text tooltip (overrides the default rich tooltip):

```bash
claudebar --tooltip-format 'Session: {session_pct}% ({session_reset}) | Weekly: {weekly_pct}% ({weekly_reset})'
```

Pass the format in your waybar config:

```jsonc
"custom/claudebar": {
    "exec": "claudebar --format '{session_pct}% {session_pace}'",
    "return-type": "json",
    "interval": 60,
    "tooltip": true,
    "on-click": "xdg-open https://claude.ai/settings/usage"
}
```

### Available placeholders

| Placeholder | Description | Example |
|---|---|---|
| `{icon}` | Claude icon (Nerd Font) | `󰚩` |
| `{plan}` | Plan label | Max 5x |
| `{session_pct}` | Session (5h) usage % | 42 |
| `{session_reset}` | Session countdown | 1h 30m |
| `{session_elapsed}` | Session time elapsed % | 58 |
| `{session_pace}` | Session pacing icon | ↑ / ↓ / → |
| `{session_pace_pct}` | Session pacing deviation | 12% ahead |
| `{weekly_pct}` | Weekly (7d all models) usage % | 27 |
| `{weekly_reset}` | Weekly countdown | 4d 1h |
| `{weekly_elapsed}` | Weekly time elapsed % | 42 |
| `{weekly_pace}` | Weekly pacing icon | ↑ / ↓ / → |
| `{weekly_pace_pct}` | Weekly pacing deviation | 5% under |
| `{sonnet_pct}` | Sonnet-only weekly usage % | 4 |
| `{sonnet_reset}` | Sonnet countdown | 2h 24m |
| `{extra_spent}` | Extra usage spent | $2.50 |
| `{extra_limit}` | Extra usage monthly limit | $50.00 |
| `{extra_balance}` | Extra usage balance | $47.50 |
| `{extra_pct}` | Extra usage spent % | 5 |

### Pacing indicators

Pacing compares your actual usage against where you "should" be if you spread your quota evenly across the window. It answers: "at this rate, will I run out before the window resets?"

- **↑** -- ahead of pace (using faster than sustainable)
- **→** -- on track
- **↓** -- under pace (plenty of room left)

**How it works:** if 30% of the session time has elapsed, you "should" have used ~30% of your quota. The widget divides your actual usage by the expected usage and flags deviations beyond a tolerance band:

| Scenario | Time elapsed | Usage | Pacing | Icon |
|---|---|---|---|---|
| Burning through quota | 25% | 60% | 140% ahead | ↑ |
| Slightly ahead | 50% | 52% | on track (within tolerance) | → |
| Perfectly even | 50% | 50% | on track | → |
| Conserving | 70% | 30% | 57% under | ↓ |

By default the tolerance is **±5%** -- deviations of 5% or less show as "on track" to avoid noise. `--pace-tolerance` accepts a non-negative integer (e.g. 0–50). You can tune it like this:

```bash
# More sensitive (±2%) -- flags smaller deviations
claudebar --pace-tolerance 2

# More relaxed (±10%) -- only flags large deviations
claudebar --pace-tolerance 10

# Default (±5%)
claudebar
```

In your waybar config:

```jsonc
"custom/claudebar": {
    "exec": "claudebar --pace-tolerance 3",
    "return-type": "json",
    "interval": 60,
    "tooltip": true
}
```

The `{session_pace_pct}` / `{weekly_pace_pct}` placeholders show the deviation (e.g. "12% ahead", "5% under", "on track").

## How it works

1. Reads OAuth credentials from `~/.claude/.credentials.json` (created by Claude CLI)
2. Auto-refreshes the access token if it expires within 5 minutes
3. Calls `api.anthropic.com/api/oauth/usage` for live usage data (cached for 60s)
4. Outputs JSON with `text`, `tooltip` (Pango markup), and `class` for Waybar

The tooltip shows colored progress bars for each usage window (session, weekly, sonnet) with countdown timers, time elapsed, and pacing info. Colors change from green to yellow to orange to red as usage increases.

### Cache

API responses are cached in `~/.cache/claudebar/usage.json` for 60 seconds. This keeps the widget fast (~40ms from cache vs ~1s from API), which matters if you run multiple Waybar instances (e.g. multi-monitor).

## Troubleshooting

| Bar shows | Meaning | Fix |
|---|---|---|
| `󰚩` ↻ | Syncing | Normal at boot -- data appears on next refresh |
| `󰚩` ⚠ | Auth error | Run `claude` to log in |
| `󰚩` ⚠ | Token expired | Run `claude` to re-authenticate |
| `󰚩` ⚠ | API error | Check your internet connection |
| Nothing | Module not loaded | Check waybar config and restart waybar |

## Color thresholds

| Usage | Bar color | Waybar class |
|---|---|---|
| 0-49% | Green (`#98c379`) | `low` |
| 50-74% | Yellow (`#e5c07b`) | `mid` |
| 75-89% | Orange (`#d19a66`) | `high` |
| 90-100% | Red (`#e06c75`) | `critical` |

To override these defaults, use `--color-*` flags (see [Colors](#colors)).

## License

[MIT](LICENSE)

## Related

- [ClaudeBar](https://github.com/andresreibel/ClaudeBar) -- Similar widget using TypeScript/Bun
- [waybar-ai-usage](https://github.com/NihilDigit/waybar-ai-usage) -- Claude + Codex monitor (Python, uses browser cookies)
- [Waybar](https://github.com/Alexays/Waybar) -- Status bar for Wayland compositors
