#!/usr/bin/env bash
# WanGP leaks RAM across generations (~1.3 GB pinned per job) and gets OOM-killed after a few hours.
# Restart it pre-emptively, only while the GPU is idle, so no running job is lost.
source "$(dirname "$0")/common.sh"

anon_gb() {
  if [ -f /sys/fs/cgroup/memory.stat ]; then
    awk '$1=="anon"{printf "%d", $2/1073741824}' /sys/fs/cgroup/memory.stat
  else
    awk '$1=="total_rss"{printf "%d", $2/1073741824}' /sys/fs/cgroup/memory/memory.stat
  fi
}

while true; do
  sleep 30
  pgrep -f "python wgp.py" >/dev/null || continue
  mem=$(anon_gb)
  gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1 | tr -d ' ')
  # two idle readings in a row, to skip short pauses between steps
  if [ "$mem" -gt "$MEM_GUARD_GB" ] && [ "$gpu" -lt 5 ]; then
    sleep 10
    gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1 | tr -d ' ')
    if [ "$gpu" -lt 5 ]; then
      echo "$(date '+%F %T') mem_guard: ${mem} GB > ${MEM_GUARD_GB} GB, GPU idle -> restart" >> "$LOGS/restarts.log"
      pkill -f "python wgp.py"
      sleep 120
    fi
  fi
done
