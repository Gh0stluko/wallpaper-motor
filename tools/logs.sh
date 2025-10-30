#!/usr/bin/env bash
set -euo pipefail

# Enable verbose QML/Qt logging to help diagnose why UI doesn't render
export QT_LOGGING_RULES="qt.qml=true;qt.qml.binding.removal.info=true;qt.qml.connections=true;qt.scenegraph.general=true;org.kde.plasma.*=true;org.kde.kcm*=true"

# Detect the plasmashell systemd user unit (Plasma 6 typically uses plasma-plasmashell)
UNIT="plasmashell"
if systemctl --user list-units --type=service | grep -q "plasma-plasmashell"; then
  UNIT="plasma-plasmashell"
fi

echo "[logs] Following logs for user unit: $UNIT"
echo "[logs] Press Ctrl-C to stop."
echo "[logs] Tip: keep this open while running tools/watch.sh to see QML errors live."

journalctl --user -f -o cat -u "$UNIT" --since "now"
