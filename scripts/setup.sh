#!/usr/bin/env bash
# Idempotent install of WanGP + Python env into /workspace. Fast no-op when everything is already there.
set -euo pipefail
source "$(dirname "$0")/common.sh"

if ! command -v ffmpeg >/dev/null || ! command -v git >/dev/null; then
  echo "==> apt: ffmpeg git"
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ffmpeg git curl >/dev/null
fi
command -v uv >/dev/null || pip install -q uv

if [ ! -d "$WAN/.git" ]; then
  echo "==> clone WanGP"
  git clone https://github.com/deepbeepmeep/Wan2GP.git "$WAN"
fi
if [ -n "${WANGP_REF:-}" ]; then
  git -C "$WAN" fetch -q origin && git -C "$WAN" checkout -q "$WANGP_REF"
fi

if ! "$VENV/bin/python" -V >/dev/null 2>&1; then
  echo "==> python 3.11 venv"
  rm -rf "$VENV"
  uv venv --python 3.11 "$VENV"
fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"

if [ "$(cat "$VENV/.torch" 2>/dev/null)" != "$TORCH_SPEC $TORCH_INDEX" ]; then
  echo "==> $TORCH_SPEC"
  # shellcheck disable=SC2086
  uv pip install $TORCH_SPEC --index-url "$TORCH_INDEX"
  echo "$TORCH_SPEC $TORCH_INDEX" > "$VENV/.torch"
fi

req_hash=$(sha1sum "$WAN/requirements.txt" | cut -d' ' -f1)
if [ "$(cat "$VENV/.req" 2>/dev/null)" != "$req_hash" ]; then
  echo "==> WanGP requirements"
  uv pip install -r "$WAN/requirements.txt"
  echo "$req_hash" > "$VENV/.req"
fi

echo "==> setup ok ($(git -C "$WAN" describe --tags --always 2>/dev/null))"
