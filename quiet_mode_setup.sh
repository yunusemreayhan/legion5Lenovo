#!/bin/bash
#
# Lenovo Legion 5 - Quiet Mode Setup Script
# For BIOS: EUCN41WW (and other EUCN variants)
#
# This script configures your laptop for quiet operation
# by setting quiet power mode and a custom quiet fan curve.
#

set -e

# Parse arguments
NO_PROMPT=false
for arg in "$@"; do
    case $arg in
        --no-prompt)
            NO_PROMPT=true
            shift
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lenovo Legion 5 - Quiet Mode Setup   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs sudo privileges. Please enter your password when prompted.${NC}"
    echo ""
fi

# Find the hwmon path
HWMON_PATH=$(ls -d /sys/module/legion_laptop/drivers/platform:legion/*/hwmon/hwmon* 2>/dev/null | head -1)

if [ -z "$HWMON_PATH" ]; then
    echo -e "${RED}ERROR: legion_laptop module not loaded!${NC}"
    echo ""
    echo "Please load the module first:"
    echo "  cd /home/yunus/repos/LenovoLegionLinux/kernel_module"
    echo "  sudo make && sudo make reloadmodule"
    exit 1
fi

echo -e "${GREEN}✓ Found legion_hwmon at: $HWMON_PATH${NC}"
echo ""

# ============================================
# Step 1: Set Quiet Power Mode
# ============================================
echo -e "${YELLOW}[Step 1/3] Setting quiet power mode...${NC}"
POWERMODE_PATH="/sys/module/legion_laptop/drivers/platform:legion/PNP0C09:00/powermode"

if [ -f "$POWERMODE_PATH" ]; then
    echo 1 | tee "$POWERMODE_PATH" > /dev/null
    CURRENT_MODE=$(cat "$POWERMODE_PATH")
    if [ "$CURRENT_MODE" = "1" ]; then
        echo -e "${GREEN}✓ Quiet mode activated (mode 1 - Blue LED)${NC}"
    else
        echo -e "${YELLOW}⚠ Mode set to: $CURRENT_MODE${NC}"
    fi
else
    echo -e "${RED}✗ Power mode path not found${NC}"
fi
echo ""

# ============================================
# Step 2: Apply Custom Quiet Fan Curve
# ============================================
echo -e "${YELLOW}[Step 2/3] Applying custom quiet fan curve...${NC}"
echo ""

# Fan curve values (PWM 0-255, lower = quieter)
# Format: Point | Fan1 PWM | Fan2 PWM | Temp Range (approximate)
declare -a FAN1_VALUES=(0 15 30 45 65 90 130 170)
declare -a FAN2_VALUES=(0 15 30 45 65 90 130 170)

# Temperature thresholds (Celsius)
declare -a CPU_TEMP_VALUES=(50 55 59 68 77 82 87 89)
declare -a GPU_TEMP_VALUES=(50 55 59 68 77 82 87 89)
declare -a IC_TEMP_VALUES=(50 55 59 68 77 82 87 89)

# Hysteresis values (lower temp to drop to previous fan level)
declare -a CPU_HYST_VALUES=(0 46 50 55 65 72 78 82)
declare -a GPU_HYST_VALUES=(0 46 50 55 65 72 78 82)
declare -a IC_HYST_VALUES=(0 46 50 55 65 72 78 82)

echo "Setting fan curve points (PWM values and temperature thresholds):"
echo ""

for i in {1..8}; do
    PWM1=${FAN1_VALUES[$((i-1))]}
    PWM2=${FAN2_VALUES[$((i-1))]}
    CPU_TEMP=${CPU_TEMP_VALUES[$((i-1))]}
    GPU_TEMP=${GPU_TEMP_VALUES[$((i-1))]}
    IC_TEMP=${IC_TEMP_VALUES[$((i-1))]}
    CPU_HYST=${CPU_HYST_VALUES[$((i-1))]}
    GPU_HYST=${GPU_HYST_VALUES[$((i-1))]}
    IC_HYST=${IC_HYST_VALUES[$((i-1))]}

    # Set fan1 PWM for this point
    echo "$PWM1" | tee "$HWMON_PATH/pwm1_auto_point${i}_pwm" > /dev/null 2>&1 && \
        echo -e "  Point $i: ${GREEN}✓${NC}" || \
        echo -e "  Point $i: ${RED}✗${NC}"

    # Set fan2 PWM for this point
    echo "$PWM2" | tee "$HWMON_PATH/pwm2_auto_point${i}_pwm" > /dev/null 2>&1

    # Set temperature thresholds for CPU (pwm1)
    echo "$CPU_TEMP" | tee "$HWMON_PATH/pwm1_auto_point${i}_temp" > /dev/null 2>&1
    echo "$CPU_HYST" | tee "$HWMON_PATH/pwm1_auto_point${i}_temp_hyst" > /dev/null 2>&1

    # Set temperature thresholds for GPU (pwm2)
    echo "$GPU_TEMP" | tee "$HWMON_PATH/pwm2_auto_point${i}_temp" > /dev/null 2>&1
    echo "$GPU_HYST" | tee "$HWMON_PATH/pwm2_auto_point${i}_temp_hyst" > /dev/null 2>&1

    # Set temperature thresholds for IC (pwm3)
    echo "$IC_TEMP" | tee "$HWMON_PATH/pwm3_auto_point${i}_temp" > /dev/null 2>&1
    echo "$IC_HYST" | tee "$HWMON_PATH/pwm3_auto_point${i}_temp_hyst" > /dev/null 2>&1
done

echo ""
echo -e "${GREEN}✓ Fan curve applied successfully${NC}"
echo ""

# Fan curve explanation
echo -e "${BLUE}Fan Curve Summary:${NC}"
echo "  Point 1 (0-50°C):   0/0    PWM - Fans off (silent)"
echo "  Point 2 (50-55°C):  15/15  PWM - Nearly silent"
echo "  Point 3 (55-59°C):  30/30  PWM - Very quiet"
echo "  Point 4 (59-68°C):  45/45  PWM - Quiet"
echo "  Point 5 (68-77°C):  65/65  PWM - Moderate"
echo "  Point 6 (77-82°C):  90/90  PWM - Medium"
echo "  Point 7 (82-87°C):  130/130 PWM - Higher speed"
echo "  Point 8 (87°C+):    170/170 PWM - Max safe speed"
echo ""

# ============================================
# Step 3: Show Current Status
# ============================================
echo -e "${YELLOW}[Step 3/3] Current System Status:${NC}"
echo ""

# Show sensors
if command -v sensors &> /dev/null; then
    echo -e "${BLUE}Temperature and Fan Speeds:${NC}"
    sensors legion_hwmon-isa-0000 2>/dev/null || echo "  (Reading sensors...)"
    echo ""
else
    echo -e "${YELLOW}Install lm-sensors for detailed monitoring: sudo apt install lm-sensors${NC}"
    echo ""
fi

# Show power mode
CURRENT_MODE=$(cat "$POWERMODE_PATH" 2>/dev/null || echo "unknown")
MODE_NAMES=("Unknown" "Quiet (Blue)" "Balanced (White)" "Performance (Red)" "Custom")
MODE_NAME=${MODE_NAMES[$CURRENT_MODE]:-"Unknown"}
echo -e "${BLUE}Power Mode:${NC} $CURRENT_MODE ($MODE_NAME)"
echo ""

# ============================================
# Optional: Make Permanent
# ============================================
if [ "$NO_PROMPT" = false ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Optional: Make Settings Permanent    ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    read -p "Do you want to make the module load automatically on boot? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! grep -q "legion_laptop" /etc/modules 2>/dev/null; then
            echo "legion_laptop" | tee -a /etc/modules > /dev/null
            echo -e "${GREEN}✓ Module will load on boot${NC}"
        else
            echo -e "${YELLOW}⚠ Module already configured for auto-load${NC}"
        fi
    else
        echo -e "${YELLOW}Skipped auto-load configuration${NC}"
    fi
    echo ""
fi

echo ""
echo -e "${YELLOW}Note: Fan curve settings reset on reboot. To make them permanent, add this script to startup.${NC}"
echo ""

# ============================================
# Create Startup Script Info
# ============================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quick Commands                       ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Switch power modes:"
echo "  Quiet (Blue):      echo 1 | sudo tee /sys/module/legion_laptop/drivers/platform:legion/PNP0C09:00/powermode"
echo "  Balanced (White):  echo 2 | sudo tee /sys/module/legion_laptop/drivers/platform:legion/PNP0C09:00/powermode"
echo "  Performance (Red): echo 3 | sudo tee /sys/module/legion_laptop/drivers/platform:legion/PNP0C09:00/powermode"
echo ""
echo "Monitor temperatures:"
echo "  watch -n 2 sensors"
echo ""
echo "Re-apply this quiet curve anytime:"
echo "  sudo bash /home/yunus/repos/LenovoLegionLinux/quiet_mode_setup.sh"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete! Enjoy Quiet Mode!    ${NC}"
echo -e "${GREEN}========================================${NC}"
