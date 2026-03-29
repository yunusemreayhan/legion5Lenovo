#!/bin/bash
#
# Setup brightness control for Lenovo Legion 5 (hybrid graphics)
# This script:
#   1. Creates /etc/brightnessctl.conf to set default device to amdgpu_bl2
#   2. Creates udev rule to allow user to control brightness without sudo
#
# Run this ONCE after installation:
#   sudo ./setup_brightness_permissions.sh
#
# Then configure FN brightness keys in MATE:
#   System -> Preferences -> Hardware -> Keyboard Shortcuts
#   Add commands:
#     /path/to/brightness_setter.py +10   (for brightness up)
#     /path/to/brightness_setter.py -10   (for brightness down)
#

DEVICE="amdgpu_bl2"
DEVICE_PATH="/sys/class/backlight/${DEVICE}"
CONFIG_FILE="/etc/brightnessctl.conf"
UDEV_RULE="/etc/udev/rules.d/90-backlight.rules"

echo "Setting up brightness control for ${DEVICE}..."

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

echo "[1/3] Creating brightnessctl config..."
mkdir -p /etc
echo "device=${DEVICE}" > ${CONFIG_FILE}
echo "  Created ${CONFIG_FILE}"

echo "[2/3] Creating udev rule for permissions..."
cat > ${UDEV_RULE} << 'EOF'
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl2", RUN+="/bin/chmod 666 /sys/class/backlight/amdgpu_bl2/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl0", RUN+="/bin/chmod 666 /sys/class/backlight/amdgpu_bl0/brightness"
EOF
echo "  Created ${UDEV_RULE}"

echo "[3/3] Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

echo ""
echo "Done! You may need to reboot for permissions to take effect."
echo "After reboot, run: brightnessctl set 50% (without sudo)"
