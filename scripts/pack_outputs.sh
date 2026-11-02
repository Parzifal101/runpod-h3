#!/usr/bin/env bash
# Pack generated videos into one archive to download via Jupyter (File browser -> right click -> Download).
source "$(dirname "$0")/common.sh"
out="$WORK/h3-videos-$(date +%F-%H%M).tar"
tar -cf "$out" -C "$WAN" outputs
echo "$out ($(du -h "$out" | cut -f1))"
