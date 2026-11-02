#!/usr/bin/env bash
# One-screen health check.
source "$(dirname "$0")/common.sh"

echo "URL:        $(public_url)"
if pgrep -f "python wgp.py" >/dev/null; then echo "WanGP:      running (pid $(pgrep -f 'python wgp.py' | head -1))"; else echo "WanGP:      NOT running"; fi
pgrep -f supervisor.sh >/dev/null && echo "supervisor: on" || echo "supervisor: off"
pgrep -f mem_guard.sh >/dev/null && echo "mem_guard:  on" || echo "mem_guard:  off"
echo "HTTP:       $(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://localhost:$PORT")"
nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader | sed 's/^/GPU:        /'
if [ -f /sys/fs/cgroup/memory.stat ]; then
  awk -v lim="$(cat /sys/fs/cgroup/memory.max)" '$1=="anon"{a=$2} $1=="file"{f=$2} END{printf "RAM:        process %.1f GB | file cache %.1f GB | limit %s GB\n", a/2^30, f/2^30, (lim=="max"?"none":sprintf("%.1f", lim/2^30))}' /sys/fs/cgroup/memory.stat
  awk '$1=="oom_kill"{print "OOM kills:  " $2}' /sys/fs/cgroup/memory.events
fi
echo "Disk:       $(du -sh "$WORK" 2>/dev/null | cut -f1) in $WORK, $(df -h "$WORK" | awk 'NR==2{print $4}') free"
echo "Videos:     $(find "$WAN/outputs" -name '*.mp4' 2>/dev/null | wc -l) in $WAN/outputs"
echo "--- last restarts"; tail -n 5 "$LOGS/restarts.log" 2>/dev/null
echo "--- last log lines"; tail -n 5 "$LOGS/wgp.log" 2>/dev/null
