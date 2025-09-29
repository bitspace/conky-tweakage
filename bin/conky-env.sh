#!/usr/bin/env bash
set -euo pipefail

# Common environment helpers shared by launcher scripts.
CFG_ROOT="${CFG_ROOT:-$HOME/.config/conky}"
EXPORT_FONT_PRIMARY="${EXPORT_FONT_PRIMARY:-Inter}"
EXPORT_FONT_FALLBACK="${EXPORT_FONT_FALLBACK:-DejaVu Sans}"

export CFG_ROOT EXPORT_FONT_PRIMARY EXPORT_FONT_FALLBACK
