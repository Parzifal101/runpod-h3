#!/usr/bin/env bash
# Keeps WanGP running: restarts it 5 s after any exit (crash, OOM kill, mem_guard).
source "$(dirname "$0")/common.sh"
source "$VENV/bin/activate"
cd "$WAN"

args=(--listen --server-port "$PORT" --public-url "$(public_url)" --profile "$PROFILE")
[ -n "${ATTENTION:-}" ] && args+=(--attention "$ATTENTION")
# shellcheck disable=SC2206
[ -n "${EXTRA_ARGS:-}" ] && args+=($EXTRA_ARGS)

while true; do
  echo "$(date '+%F %T') start: python wgp.py ${args[*]}" >> "$LOGS/restarts.log"
  echo "===== $(date '+%F %T') WanGP start =====" >> "$LOGS/wgp.log"
  python wgp.py "${args[@]}" >> "$LOGS/wgp.log" 2>&1
  echo "$(date '+%F %T') WanGP exited, code $?" >> "$LOGS/restarts.log"
  sleep 5
done
