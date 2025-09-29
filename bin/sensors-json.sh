#!/usr/bin/env bash
set -euo pipefail

if command -v sensors >/dev/null 2>&1 && sensors -j >/dev/null 2>&1; then
  sensors -j
elif command -v sensors >/dev/null 2>&1; then
  sensors
else
  printf '{}\n'
fi
