#!/usr/bin/env bash
set -euo pipefail

# Decide which display profile is active (undocked/docked).
repo_root="${CFG_ROOT:-$HOME/.config/conky}"
mon_json="$(hyprctl monitors -j 2>/dev/null || true)"

if [[ -z ${mon_json} ]]; then
  if command -v wlr-randr >/dev/null 2>&1; then
    externals=$(wlr-randr | awk '/^\s+\+/ {print prev} {prev=$0}' | grep -cvE 'eDP|LVDS' || true)
  else
    externals=0
  fi
else
  externals=$(printf '%s' "$mon_json" | jq '[ .[] | select(.name != null and (.name | test("eDP|LVDS")) | not) | select(.enabled==true) ] | length')
fi

if [[ ${externals:-0} -ge 2 ]]; then
  printf 'docked\n'
else
  printf 'undocked\n'
fi
