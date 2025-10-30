#!/usr/bin/env bash
set -euo pipefail

# Reinstall the wallpaper package into ~/.local/share/plasma/wallpapers
python3 "$(dirname "$0")/install.py"

echo "[reload] Restarting plasmashell to pick up QML changes…"

# Set environment variable to allow XMLHttpRequest to read local files
export QML_XHR_ALLOW_FILE_READ=1

# Prefer Plasma 6 tools; fall back if unavailable
if command -v kquitapp6 >/dev/null 2>&1 && command -v kstart6 >/dev/null 2>&1; then
  kquitapp6 plasmashell || true
  # Give it a moment to exit cleanly
  sleep 1
  QML_XHR_ALLOW_FILE_READ=1 kstart6 plasmashell
else
  # Fallback (may be Plasma 5 or environments without kstart6)
  kquitapp5 plasmashell || true
  sleep 1
  QML_XHR_ALLOW_FILE_READ=1 kstart5 plasmashell || QML_XHR_ALLOW_FILE_READ=1 plasmashell --replace &
fi

echo "[reload] Done. If desktop flashes, that’s normal during shell restart."
