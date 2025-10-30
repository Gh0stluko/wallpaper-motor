#!/usr/bin/env bash
set -euo pipefail

echo "=== Wallpaper Engine Setup for KDE Plasma ==="
echo ""
echo "This script will configure your system to allow the wallpaper plugin"
echo "to read Wallpaper Engine files from Steam Workshop."
echo ""

# Create systemd override directory
SYSTEMD_DIR="$HOME/.config/systemd/user/plasma-plasmashell.service.d"
OVERRIDE_FILE="$SYSTEMD_DIR/wallpaper-engine.conf"

mkdir -p "$SYSTEMD_DIR"

echo "Creating systemd service override..."
cat > "$OVERRIDE_FILE" << 'EOF'
[Service]
Environment="QML_XHR_ALLOW_FILE_READ=1"
EOF

echo "✓ Created: $OVERRIDE_FILE"

# Reload systemd
echo "Reloading systemd configuration..."
systemctl --user daemon-reload

echo ""
echo "✓ Setup complete!"
echo ""
echo "To apply changes, restart plasmashell:"
echo "  kquitapp6 plasmashell && kstart6 plasmashell"
echo ""
echo "Or log out and log back in to KDE."
