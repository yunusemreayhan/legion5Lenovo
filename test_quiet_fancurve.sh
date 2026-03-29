#!/bin/bash
# Test script to apply quiet fan curve with proper temperature thresholds

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing Quiet Fan Curve              ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Find hwmon path
HWMON_PATH=$(ls -d /sys/module/legion_laptop/drivers/platform:legion/*/hwmon/hwmon* 2>/dev/null | head -1)

if [ -z "$HWMON_PATH" ]; then
    echo -e "${RED}ERROR: legion_laptop module not loaded!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found hwmon at: $HWMON_PATH${NC}"
echo ""

# Fan curve PWM values (0-255)
declare -a FAN1_VALUES=(0 15 30 45 65 90 130 170)
declare -a FAN2_VALUES=(0 15 30 45 65 90 130 170)

# Temperature thresholds (Celsius)
declare -a CPU_TEMP_VALUES=(50 55 59 68 77 82 87 89)
declare -a GPU_TEMP_VALUES=(50 55 59 68 77 82 87 89)
declare -a IC_TEMP_VALUES=(50 55 59 68 77 82 87 89)

# Hysteresis values
declare -a CPU_HYST_VALUES=(0 46 50 55 65 72 78 82)
declare -a GPU_HYST_VALUES=(0 46 50 55 65 72 78 82)
declare -a IC_HYST_VALUES=(0 46 50 55 65 72 78 82)

echo "Applying fan curve..."
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

    # PWM
    echo "$PWM1" > "$HWMON_PATH/pwm1_auto_point${i}_pwm"
    echo "$PWM2" > "$HWMON_PATH/pwm2_auto_point${i}_pwm"

    # CPU temps
    echo "$CPU_TEMP" > "$HWMON_PATH/pwm1_auto_point${i}_temp"
    echo "$CPU_HYST" > "$HWMON_PATH/pwm1_auto_point${i}_temp_hyst"

    # GPU temps
    echo "$GPU_TEMP" > "$HWMON_PATH/pwm2_auto_point${i}_temp"
    echo "$GPU_HYST" > "$HWMON_PATH/pwm2_auto_point${i}_temp_hyst"

    # IC temps
    echo "$IC_TEMP" > "$HWMON_PATH/pwm3_auto_point${i}_temp"
    echo "$IC_HYST" > "$HWMON_PATH/pwm3_auto_point${i}_temp_hyst"

    echo -e "  Point $i: PWM=${PWM1}/${PWM2}  CPU=${CPU_TEMP}°C  GPU=${GPU_TEMP}°C  IC=${IC_TEMP}°C  ${GREEN}✓${NC}"
done

echo ""
echo -e "${GREEN}✓ Fan curve applied successfully${NC}"
echo ""

echo "Fan Curve Summary:"
echo "  Point 1 (0-50°C):   0/0   PWM - Fans OFF (silent)"
echo "  Point 2 (50-55°C):  15/15 PWM - Nearly silent"
echo "  Point 3 (55-59°C):  30/30 PWM - Very quiet"
echo "  Point 4 (59-68°C):  45/45 PWM - Quiet"
echo "  Point 5 (68-77°C):  65/65 PWM - Moderate"
echo "  Point 6 (77-82°C):  90/90 PWM - Medium"
echo "  Point 7 (82-87°C):  130/130 PWM - Higher"
echo "  Point 8 (87°C+):    170/170 PWM - Max"
echo ""

echo -e "${BLUE}Current Status:${NC}"
sensors legion_hwmon-isa-0000 2>/dev/null || echo "(Reading sensors...)"
echo ""

echo -e "${YELLOW}Monitor with: watch -n 2 sensors${NC}"
