#!/usr/bin/env bash
# runpod-h3: MiniMax H3 (and everything else WanGP runs) on a RunPod pod.
#   bash start.sh            install if needed, start WanGP + supervisor + mem_guard
#   bash start.sh --update   also pull the latest WanGP (or WANGP_REF) and reinstall deps
#   bash start.sh --stop     stop everything
#   bash start.sh --status   health check
#   bash start.sh --logs     follow the WanGP log
#   bash start.sh --pack     pack generated videos into a .tar for download
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/scripts/common.sh"

stop_all() {
  pkill -f "$DIR/scripts/mem_guard.sh" 2>/dev/null || true
  pkill -f "$DIR/scripts/supervisor.sh" 2>/dev/null || true
  pkill -f "python wgp.py" 2>/dev/null || true
  sleep 3
}

case "${1:-}" in
  --stop)   stop_all; echo "stopped"; exit 0 ;;
  --status) exec bash "$DIR/scripts/status.sh" ;;
  --logs)   exec tail -n 50 -f "$LOGS/wgp.log" ;;
  --pack)   exec bash "$DIR/scripts/pack_outputs.sh" ;;
  --update) [ -d "$WAN/.git" ] && [ -z "${WANGP_REF:-}" ] && git -C "$WAN" pull -q --ff-only ;;
  "") ;;
  *) sed -n '2,8p' "$0"; exit 1 ;;
esac

bash "$DIR/scripts/setup.sh"
stop_all
nohup bash "$DIR/scripts/supervisor.sh" >/dev/null 2>&1 &
nohup bash "$DIR/scripts/mem_guard.sh" >/dev/null 2>&1 &

echo "==> waiting for WanGP on :$PORT"
for _ in $(seq 1 120); do
  if [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://localhost:$PORT")" = "200" ]; then
    cat <<EOF

  WanGP is up:  $(public_url)
  status:       bash $DIR/start.sh --status
  logs:         bash $DIR/start.sh --logs
  stop:         bash $DIR/start.sh --stop

  No password on the UI: don't share the link.
EOF
    exit 0
  fi
  sleep 3
done
echo "WanGP did not answer in 6 min. Check: bash $DIR/start.sh --logs"
exit 1
