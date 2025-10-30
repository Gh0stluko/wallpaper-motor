#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "inotifywait (inotify-tools) is required for watch mode."
  echo "Install it (e.g., sudo apt install inotify-tools) or run tools/reload.sh manually."
  exit 1
fi

echo "[watch] Watching for changes in wallpaper-engine (QML, XML, metadata)…"
echo "[watch] Press Ctrl-C to stop."

while inotifywait -q -r \
  -e modify,create,delete,move \
  --format '%w%f' \
  "$ROOT_DIR/wallpaper-engine"; do
  # Only act on relevant file types to avoid noisy rebuilds
  if ls "$ROOT_DIR"/wallpaper-engine/**/*.{qml,xml,json} >/dev/null 2>&1; then
    echo "[watch] Change detected → reinstalling and restarting plasmashell…"
    bash "$ROOT_DIR/tools/reload.sh"
  else
    # Unknown change; still reinstall to be safe
    bash "$ROOT_DIR/tools/reload.sh"
  fi
done
