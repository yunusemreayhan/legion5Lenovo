#!/bin/bash
#
# Install systemd service for Legion CPU Frequency Scaling
# Run this script with sudo to install the service
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/legion-cpufreq.service"
SYSTEMD_DIR="/etc/systemd/system"

echo "Installing Legion CPU Frequency Scaling systemd service..."
echo ""

# Copy service file to systemd directory
sudo cp "$SERVICE_FILE" "$SYSTEMD_DIR/"
echo "✓ Service file copied to $SYSTEMD_DIR"

# Reload systemd daemon
sudo systemctl daemon-reload
echo "✓ Systemd daemon reloaded"

# Enable service (start on boot)
sudo systemctl enable legion-cpufreq.service
echo "✓ Service enabled (will start on boot)"

# Start service now
sudo systemctl start legion-cpufreq.service
echo "✓ Service started"

echo ""
echo "Service status:"
sudo systemctl status legion-cpufreq.service --no-pager

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Useful commands:"
echo "  Check status:  sudo systemctl status legion-cpufreq.service"
echo "  Stop:          sudo systemctl stop legion-cpufreq.service"
echo "  Start:         sudo systemctl start legion-cpufreq.service"
echo "  Disable:       sudo systemctl disable legion-cpufreq.service"
echo "  View logs:     journalctl -u legion-cpufreq.service"
echo ""
