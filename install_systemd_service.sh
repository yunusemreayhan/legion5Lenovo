#!/bin/bash
#
# Install systemd service for Legion Quiet Mode
# Run this script with sudo to install the service
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/legion-quiet-mode.service"
MODULES_CONF="$SCRIPT_DIR/legion_laptop.conf"
SYSTEMD_DIR="/etc/systemd/system"
MODULES_LOAD_DIR="/etc/modules-load.d"

echo "Installing Legion Quiet Mode systemd service..."
echo ""

# Copy service file to systemd directory
sudo cp "$SERVICE_FILE" "$SYSTEMD_DIR/"
echo "✓ Service file copied to $SYSTEMD_DIR"

# Copy modules-load.d configuration
sudo cp "$MODULES_CONF" "$MODULES_LOAD_DIR/"
echo "✓ Module auto-load config copied to $MODULES_LOAD_DIR"

# Reload systemd daemon
sudo systemctl daemon-reload
echo "✓ Systemd daemon reloaded"

# Enable service (start on boot)
sudo systemctl enable legion-quiet-mode.service
echo "✓ Service enabled (will start on boot)"

# Start service now
sudo systemctl start legion-quiet-mode.service
echo "✓ Service started"

echo ""
echo "Service status:"
sudo systemctl status legion-quiet-mode.service --no-pager

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Useful commands:"
echo "  Check status:  sudo systemctl status legion-quiet-mode.service"
echo "  Stop:          sudo systemctl stop legion-quiet-mode.service"
echo "  Start:         sudo systemctl start legion-quiet-mode.service"
echo "  Disable:       sudo systemctl disable legion-quiet-mode.service"
echo "  View logs:     journalctl -u legion-quiet-mode.service"
echo ""
