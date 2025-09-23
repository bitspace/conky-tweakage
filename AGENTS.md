# AGENTS.md — Conky on Arch + Hyprland (ThinkPad)

> **Purpose:** This file defines project intent, guardrails, repeatable procedures, and agent roles so OpenAI Codex CLI (and similar assistants) can act as an autonomous helper to build and maintain a polished Conky-based system monitor for an Arch Linux + Hyprland ThinkPad that sometimes docks to dual external displays over USB‑C/DisplayPort.

---

## 0) System Context (Facts the agent should always assume)

- **OS / Distro:** Arch Linux (prefer official repos and AUR when necessary; avoid Flatpak/Snap/AppImage unless explicitly allowed).
- **WM/Compositor:** Hyprland (Wayland).
- **Machine:** Lenovo ThinkPad laptop.
- **Display Modes:**
  - (A) *Undocked:* laptop panel only.
  - (B) *Docked-dual:* two external displays over USB‑C/DisplayPort (plus the laptop panel, optionally enabled/disabled).
- **Conky & Wayland Reality:** Conky is X11-first. On Hyprland it typically runs under **XWayland** in its own borderless, non-focusable window with pseudo-transparency. We will rely on **Hyprland window rules** to place and layer it (always below, no animations, no borders), one instance per target monitor.
- **User Preferences:** CLI-first, reproducible configs, clean minimal aesthetic, scriptability, no background agents that fight for focus, seamless profile switching when displays change.

---

## 1) Project Goals (what “success” looks like)

1. **Beautiful, Legible, Minimal:** A glassy, low-contrast panel style that is readable on light/dark wallpapers (uses subtle background with 8–15% opacity, rounded corners).
2. **Reliable on Hyprland:** Conky instances consistently pin to intended corners/regions across display profiles, never stealing focus.
3. **Profile-Aware:** Auto-switch layouts when docking/undocking (laptop-only vs dual-externals). No manual fiddling.
4. **Useful Metrics at a Glance:**
   - CPU: per‑core load + temp
   - Memory: used/free graph
   - GPU: basic usage + temp (works if iGPU/NVIDIA/AMD present)
   - Disk: root + /home usage; top I/O device
   - Network: primary interface up/down rate; SSID + signal when on Wi‑Fi
   - Battery: % / status / power draw / wear (ThinkPad-friendly)
   - Temps/Fans: from `lm_sensors`; ThinkPad fan if available
   - Time, date, uptime, hostname, kernel
5. **Single Source of Truth:** All configs live in `~/projects/conky-tweakage/` (or repo root), with profile-specific renders and helper scripts.
6. **No Fragile Manual Tweaks:** Add scripts to detect monitors and launch the right stack. Use systemd user units for startup.

---

## 2) Non‑Goals (explicitly out of scope unless asked)

- No global desktop widgets beyond Conky (e.g., eww) unless Conky limits hard-block a desired feature.
- No vendor lock‑in to non-Arch package managers.
- No intrusive polling frequencies (cap CPU usage < 1–2%).
- No heavy compositing tricks or hacks that break Hyprland animations.

---

## 3) Guardrails & Conventions

- **Idempotent scripts**: re-runnable without side effects.
- **Declarative configs**: author “desired state” where feasible; scripts reconcile.
- **LLM-friendly layout**: small files, clear headers, comments, numbered steps.
- **Naming**: `conky.<profile>.<region>.conf` (e.g., `conky.docked.left.conf`).
- **Fonts**: primary `Inter`, fallback `DejaVu Sans` (both widely packaged).
- **Colors**: rely on `rgba(255,255,255,0.90)` for text and `rgba(0,0,0,0.12)` panel background by default; expose palette in `theme.lua`.
- **Polling**: `update_interval = 1.0` (battery/net at 2–3s OK). Avoid < 0.5s.

---

## 4) Directory Layout (proposed)

> In the **symlink model**, `~/.config/conky` is a symlink to your repo (which may live anywhere, e.g., `~/projects/conky-tweakage`). The tree below is shown from the stable path `~/.config/conky/`.

```
~/.config/conky/ -> /actual/path/to/your/repo
├─ bin/
│  ├─ conky-detect-profile.sh          # Decide display profile + launch
│  ├─ conky-launch.sh                  # Start/stop instances per profile
│  ├─ conky-env.sh                     # Common env (fonts, colors, paths)
│  └─ sensors-json.sh                  # Normalize lm_sensors → JSON
├─ hypr/
│  └─ window-rules.conf                # Rules to anchor Conky windows
├─ lua/
│  ├─ theme.lua                        # Colors, spacing, fonts
│  ├─ widgets/
│  │  ├─ cpu.lua
│  │  ├─ mem.lua
│  │  ├─ net.lua
│  │  ├─ disk.lua
│  │  ├─ battery.lua
│  │  ├─ temps.lua
│  │  ├─ gpu.lua
│  │  └─ clock.lua
│  └─ util.lua                         # helpers (draw panels, icons)
├─ profiles/
│  ├─ undocked/
│  │  ├─ top-right.conf
│  │  └─ bottom-right.conf
│  └─ docked/
│     ├─ left-top-right.conf
│     ├─ right-bottom-right.conf
│     └─ laptop-hidden.conf            # optional hide on laptop
├─ hosts/                               # per-machine overrides
│  ├─ <hostname1>/
│  │  └─ overrides.lua                 # battery name, GPU reader, DPI offsets
│  └─ <hostname2>/
│     └─ overrides.lua
├─ systemd/
│  ├─ conky@.service
│  └─ conky.target
└─ README.md
```

> The agent may rename/move files, but must update launch scripts and unit files accordingly.

---

## 5) Required Packages

- **Conky & tooling:** `conky`, `conky-lua-nv`, `jq`
- **Sensors & power:** `lm_sensors`, `acpi`, `upower`, `nvme-cli`, `smartmontools`
- **Net/Wi‑Fi:** `iw`, `iwctl` (if iwd), or `nmcli` (if NetworkManager)
- **Hyprland helpers:** `hyprland`, `hyprctl`, `wlr-randr` (or `hyprctl monitors`)
- **Fonts:** `inter` (AUR: `ttf-inter`), `noto-fonts`, `noto-fonts-emoji`

> Prefer official repos; if AUR is used (e.g., `ttf-inter`), annotate in scripts.

---

## 6) Hyprland Window Rules (pin Conky instances)

Add/merge into user's Hyprland config (or include with `source=`):

```ini
# conky pinning: borderless, no focus, no animations, bottom layer
windowrulev2 = noborder, class:^(Conky)$
windowrulev2 = nofullscreenrequest, class:^(Conky)$
windowrulev2 = float, class:^(Conky)$
windowrulev2 = nofocus, class:^(Conky)$
windowrulev2 = noinitialfocus, class:^(Conky)$
windowrulev2 = noanim, class:^(Conky)$
windowrulev2 = staybelow, class:^(Conky)$
windowrulev2 = opacity 0.99 override 0.99 override, class:^(Conky)$
# optional: pin to workspace per monitor if desired
# windowrulev2 = workspace 1, class:^(Conky)$, monitor:HDMI-A-1
```

> Positioning is done via Conky `own_window` + `alignment` + `gap_x/gap_y` and by launching one instance per target monitor region.

---

## 7) Conky Base Config Snippet (Wayland/XWayland-friendly)

```conf
conky.config = {
  own_window = true,
  own_window_type = 'dock',
  own_window_argb_visual = true,
  own_window_argb_value = 20,   # ~8% background opacity
  own_window_hints = 'undecorated,sticky,skip_taskbar,skip_pager,below',
  double_buffer = true,
  use_xft = true,
  xftalpha = 0.9,
  font = 'Inter:size=10',
  update_interval = 1.0,
  draw_shades = false,
  draw_outline = false,
  default_color = 'FFFFFF',
  alignment = 'top_right',
  gap_x = 32,
  gap_y = 48,
  minimum_width = 320, minimum_height = 220,
  lua_load = '~/.config/conky/lua/theme.lua',
  lua_draw_hook_post = 'draw_panel',
};

conky.text = [[
${voffset 8}${font Inter:style=Bold:size=11}SYSTEM ${font}${alignr}${time %a %b %d  %H:%M}
${hr}
CPU ${alignr}${cpu cpu0}%  ${execi 2 sensors | grep -m1 'Tdie\|Package id 0' | awk '{print $2}'}
RAM ${alignr}${mem} / ${memmax}
NET ${alignr}${downspeedf}↓  ${upspeedf}↑
DISK ${alignr}${fs_used /} / ${fs_size /}
BAT ${alignr}${battery_percent BAT0}% ${battery_time BAT0}
]]
```

> The agent will specialize per‑profile configs, expand to per‑core, add graphs, and switch to `lua` widgets from `lua/widgets/*` for richer visuals.

---

## 8) Profile Detection & Launcher (high‑level behavior)

### `bin/conky-detect-profile.sh`

1. Read `hyprctl monitors -j` (fallback to `wlr-randr`) and count **active** external displays.
2. If ≥2 externals: profile = `docked`.
3. Else: profile = `undocked`.
4. Echo the profile name; exit 0. On error, default to `undocked`.

### `bin/conky-launch.sh`

- Stop any existing `conky@*.service` (systemd user) instances.
- For the chosen profile, start one Conky process per region/monitor with the appropriate config.
- Optionally offset by DPI/scale read from `hyprctl monitors -j`.

### Systemd user units

`systemd/conky@.service`:

```ini
[Unit]
Description=Conky instance %i
After=graphical-session.target
PartOf=conky.target

[Service]
Type=simple
ExecStart=%h/.config/conky/bin/conky-launch.sh %i
Restart=on-failure

[Install]
WantedBy=conky.target
```

`systemd/conky.target`:

```ini
[Unit]
Description=All Conky instances
```

> The agent may alternatively launch raw `conky -c profiles/<profile>/<widget>.conf` processes directly; the `%i` indirection is to keep things tidy.

---

## 9) Data Sources & Commands (normalize to JSON when possible)

- **Sensors:** `sensors -j` (preferred), `sensors` (parse fallback)
- **Battery:** `upower -i $(upower -e | grep BAT)` (primary), `acpi -V` (fallback)
- **Network:**
  - active iface: `ip route get 1.1.1.1 | awk '{print $5; exit}'`
  - Wi‑Fi SSID: `iwgetid -r` or `nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2}'`
- **Disk:** `lsblk -J`, `df -hP / /home`, `iostat -dx 1 2` (optional)
- **GPU:**
  - Intel: `intel_gpu_top -J -s 1000` (if available)
  - NVIDIA: `nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits`
  - AMD: `/sys/class/drm/card*/device/hwmon/hwmon*/temp1_input`

> Agent must feature-detect and degrade gracefully (no hard failure if a tool isn’t present). Prefer `jq` to slice JSON.

---

## 10) Visual Design Notes

- **Panels:** rounded rect backdrop (drawn in `lua`), margin 12–16px, radius 14–18px.
- **Typography:** `Inter` normal 10–11pt, section headers bold 11–12pt.
- **Spacing:** use vertical rhythm; avoid dense clutter; group related stats.
- **Graphs:** small sparkline bars for CPU/mem/net using Conky’s built‑ins or custom Lua drawing.
- **Icons:** optional Nerd Font glyphs; if used, ensure the font is installed & referenced.

---

## 11) Tasks & Procedures (for the Agent)

### T1. Bootstrap

1. Ensure packages: `sudo pacman -S conky conky-lua-nv jq lm_sensors upower acpi nvme-cli smartmontools` (and `ttf-inter` if desired via AUR).
2. Run `sudo sensors-detect` once; accept safe defaults.
3. Clone/create the project repo anywhere you like (e.g., `~/projects/conky-tweakage`).
4. Create/refresh the **symlink** (per device):
   ```bash
   ln -sfn "${REPO_ROOT:-$HOME/projects/conky-tweakage}" "$HOME/.config/conky"
   ```
5. Add Hypr include: `source = ~/.config/conky/hypr/window-rules.conf`.
6. Place base `profiles/undocked/top-right.conf` and `profiles/docked/*` with sane defaults.
7. Install systemd user units; `systemctl --user enable --now conky.target`.
. Install systemd user units; `systemctl --user enable --now conky.target`.
. Install systemd user units; `systemctl --user enable --now conky.target`.

### T2. Profile Logic

- Implement robust monitor parsing via `hyprctl monitors -j | jq`.
- Map monitor names to roles: `left`, `right`, `laptop`.
- For each role, launch a matching Conky config with DPI-aware gaps.

### T3. Widgets & Metrics

- Port metrics to modular Lua widgets; each returns a small block for inclusion.
- Add per-core CPU bars, temps, top 3 processes by CPU (nice-to-have), mem graph, primary net rates + SSID, disk usage + root inode %, battery with wear level.

### T4. Performance Budget

- Target **< 2% CPU** average when idle. Increase `update_interval`; cache data from shell helpers.

### T5. QA Scenarios

- Undock → auto relaunch in `undocked` profile; Dock with two displays → auto `docked`.
- Hyprland reload (`hyprctl reload`) does not orphan Conky windows.
- Missing sensors does not render raw errors on screen.

### T6. Docs & Help

- Keep `README.md` updated with screenshots + troubleshooting.
- Add `make screenshot` target using `grimshot` or `grim` + `slurp` if installed.

---

## 12) Agent Roles (multi‑agent optional)

- **Architect** – owns layout, profiles, and window rules; ensures deterministic placement.
- **Themer** – owns fonts, palette, spacing, Lua drawing helpers.
- **Integrator** – writes shell helpers; normalizes metrics to JSON; ensures graceful fallbacks.
- **Perf Tuner** – measures CPU/mem impact; adjusts intervals & caches.
- **QA Engineer** – validates docking/undocking, missing-sensor cases, systemd startup.
- **Doc Writer** – curates README and code comments for future self.

> Single-agent mode: perform these roles sequentially and record decisions under **Decision Log**.

---

## 13) Commands the Agent May Run (and how)

- **Read‑only / harmless:** `hyprctl monitors -j`, `sensors -j`, `upower -e/-i`, `iwgetid -r`, `ip -o link show`, `df -hP`, `lsblk -J`.
- **Write / configure:** create/modify files under repo path and `$HOME/.config/conky/` (or symlink from repo); append to Hyprland config using a guarded include; install user systemd units.
- **Never do without explicit instruction:** system upgrades; GPU driver changes; power‑management kernel params.

---

## 14) Prompts & Memory for Codex CLI

### System Prompt

```
You are an autonomous engineering assistant configuring Conky for Arch Linux on Hyprland (ThinkPad). Optimize for clean, reproducible, Wayland‑friendly setups using XWayland windows pinned via Hyprland rules. Prefer official Arch repos; AUR only when necessary. All artifacts must be small, well‑commented, and idempotent. Be conservative with CPU usage and fail gracefully when sensors or tools are missing.
```

### Project Memory (append-only YAML)

```yaml
profiles:
  undocked:
    regions: [top-right, bottom-right]
  docked:
    regions: [left-top-right, right-bottom-right]
fonts:
  primary: Inter
  fallback: DejaVu Sans
palette:
  text: rgba(255,255,255,0.90)
  panel: rgba(0,0,0,0.12)
intervals:
  default: 1.0
  battery: 2.0
  net: 1.0
perf_budget:
  cpu_pct_idle_target: 2
paths:
  stable_root: ~/.config/conky    # symlink to the real repo on each device
  hypr_rules: ~/.config/conky/hypr/window-rules.conf
sensors:
  prefer_json: true
fallbacks:
  battery: acpi
  wifi_ssid: nmcli|iwgetid
```

### Step Prompt Template

```
Goal: <short task>
Constraints: keep CPU idle <2%%, no focus stealing, Hyprland rules honored.
Plan:
1) …
2) …
3) …
Deliverables:
- Paths and files created
- Exact commands to run
- Diffs for modified files
- Rollback instructions
```

### Decision Log (append entries)

```
[YYYY-MM-DD] <decision> — <reasoning>
```

---

## 15) Example: `bin/conky-detect-profile.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

mon_json=$(hyprctl monitors -j 2>/dev/null || true)
if [[ -z "$mon_json" ]]; then
  # fallback
  if wlr-randr >/dev/null 2>&1; then
    externals=$(wlr-randr | awk '/^\s+\+/ {print prev} {prev=$0}' | grep -cv eDP || true)
  else
    echo undocked
    exit 0
  fi
else
  externals=$(printf '%s' "$mon_json" | jq '[ .[] | select(.name != null and (.name | test("eDP|LVDS")) | not) | select(.enabled==true) ] | length')
fi

if [[ ${externals:-0} -ge 2 ]]; then
  echo docked
else
  echo undocked
fi
```

---

## 16) Example: `hypr/window-rules.conf`

```ini
# Include this from your main Hyprland config (symlink model):
#   source = ~/.config/conky/hypr/window-rules.conf
windowrulev2 = noborder, class:^(Conky)$
windowrulev2 = nofocus, class:^(Conky)$
windowrulev2 = noinitialfocus, class:^(Conky)$
windowrulev2 = noanim, class:^(Conky)$
windowrulev2 = staybelow, class:^(Conky)$
windowrulev2 = float, class:^(Conky)$
```

---

## 17) Example: `bin/sensors-json.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
if sensors -j >/dev/null 2>&1; then
  sensors -j
else
  sensors | awk 'BEGIN{print "{"} {gsub(" ","_"); print} END{print "}"}' # crude fallback
fi
```

---

## 18) Risks & Mitigations

- **Conky focus/stacking glitches** → Strict Hyprland rules; use `own_window_type=dock` and `staybelow`.
- **Transparency mismatch** → Prefer argb visual + subtle panel bg; avoid true transparency if wallpaper changes often.
- **High CPU from fast polling** → Cache shell outputs; raise intervals; avoid expensive regex in tight loops.
- **Monitor name churn** → Detect by `description`/`make` where possible; allow user override mapping.

---

## 19) Next Actions (for the Agent)

1. Scaffold repo with the directory layout above.
2. Write initial undocked and docked configs using the base snippet.
3. Implement profile detection + launcher and wire systemd user units.
4. Add Lua theme + 2–3 widgets (CPU/mem/net) and verify placement.
5. Iterate visuals; add battery/disk/temps; optimize intervals.
6. Document and capture screenshots.

---

---

## 20) Symlink Model (finalized)

- **Stable path:** `~/.config/conky` is a symlink to your repo (path may differ per device).
- **Portability:** Conky configs, Hypr includes, and systemd units all target the stable path, so no edits are needed when the repo lives elsewhere.

### Bootstrap per device
```bash
REPO_ROOT="$HOME/projects/conky-tweakage"   # adjust per device
mkdir -p "$HOME/.config"
ln -sfn "$REPO_ROOT" "$HOME/.config/conky"
```

### Launcher
The launcher uses the stable root so relative paths or `~/.config/conky/...` both work:
```bash
#!/usr/bin/env bash
set -euo pipefail
CFG_ROOT="$HOME/.config/conky"
PROFILE="${1:-$("$CFG_ROOT/bin/conky-detect-profile.sh") }"
cd "$CFG_ROOT"
pkill -x conky 2>/dev/null || true
case "$PROFILE" in
  docked)
    conky -c "$CFG_ROOT/profiles/docked/left-top-right.conf" &
    conky -c "$CFG_ROOT/profiles/docked/right-bottom-right.conf" &
    ;;
  *)
    conky -c "$CFG_ROOT/profiles/undocked/top-right.conf" &
    conky -c "$CFG_ROOT/profiles/undocked/bottom-right.conf" &
    ;;
 esac
wait
```

### Multi‑Device Overrides
Keep `hosts/<hostname>/overrides.lua` in the repo; it’s visible under the symlink on all machines.

*End of AGENTS.md*

