#!/usr/bin/env bash
set -euo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=bin/conky-env.sh
source "${script_dir}/conky-env.sh"

profile="${1:-$(${CFG_ROOT}/bin/conky-detect-profile.sh)}"

pkill -x conky 2>/dev/null || true
case "$profile" in
  docked)
    conky -c "${CFG_ROOT}/profiles/docked/left-top-right.conf" &
    conky -c "${CFG_ROOT}/profiles/docked/right-bottom-right.conf" &
    ;;
  *)
    conky -c "${CFG_ROOT}/profiles/undocked/top-right.conf" &
    conky -c "${CFG_ROOT}/profiles/undocked/bottom-right.conf" &
    ;;
 esac
wait
