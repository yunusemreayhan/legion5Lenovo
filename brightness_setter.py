#!/usr/bin/env python3
#
# Brightness setter for Lenovo Legion 5 (AMD iGPU + NVIDIA dGPU hybrid mode)
#
# Usage:
#   python3 brightness_setter.py 30        # Set brightness to 30%
#   python3 brightness_setter.py +10       # Increase by 10%
#   python3 brightness_setter.py -10       # Decrease by 10%
#   python3 brightness_setter.py i         # Show current brightness
#
# To bind FN brightness keys in MATE desktop:
#   1. Run: sudo ./setup_brightness_permissions.sh
#   2. Open: System -> Preferences -> Hardware -> Keyboard Shortcuts
#   3. Add "Brightness Up" with command:   /full/path/to/brightness_setter.py +10
#   4. Add "Brightness Down" with command: /full/path/to/brightness_setter.py -10
#   5. Bind to your FN+F5/F6 keys
#

import sys
import subprocess
import re
import os

DEVICE = "amdgpu_bl2"
BRIGHTNESS_PATH = f"/sys/class/backlight/{DEVICE}/brightness"
MAX_BRIGHTNESS_PATH = f"/sys/class/backlight/{DEVICE}/max_brightness"

def get_max_brightness():
    try:
        with open(MAX_BRIGHTNESS_PATH, 'r') as f:
            return int(f.read().strip())
    except (FileNotFoundError, PermissionError, ValueError):
        return None

def get_current_brightness():
    try:
        with open(BRIGHTNESS_PATH, 'r') as f:
            return int(f.read().strip())
    except (FileNotFoundError, PermissionError, ValueError):
        return None

def set_brightness_sysfs(percentage):
    max_brightness = get_max_brightness()
    if max_brightness is None:
        print(f"Error: Cannot read {MAX_BRIGHTNESS_PATH}")
        return False
    
    value = int((percentage / 100.0) * max_brightness)
    try:
        with open(BRIGHTNESS_PATH, 'w') as f:
            f.write(str(value))
        return True
    except PermissionError:
        return False
    except Exception as e:
        print(f"Error writing to {BRIGHTNESS_PATH}: {e}")
        return False

def set_brightnessctl(percentage):
    result = subprocess.run(
        ["brightnessctl", "-d", DEVICE, "set", f"{percentage}%"],
        capture_output=True,
        text=True
    )
    return result.returncode == 0

def set_brightness(percentage):
    if not 0 <= percentage <= 100:
        print("Error: Brightness must be between 0 and 100")
        return False

    if os.geteuid() == 0:
        return set_brightness_sysfs(percentage)
    else:
        if set_brightnessctl(percentage):
            return True
        
        if set_brightness_sysfs(percentage):
            return True
        
        print("Error: Failed to set brightness (try running with sudo)")
        return False

def show_current():
    max_brightness = get_max_brightness()
    current = get_current_brightness()
    
    if max_brightness and current:
        percentage = round((current / max_brightness) * 100)
        print(f"Brightness: {percentage}% ({current}/{max_brightness})")
    else:
        print("Error: Cannot read current brightness")

def main():
    if len(sys.argv) == 1:
        show_current()
        return

    arg = sys.argv[1]
    
    if arg in ['-h', '--help']:
        print("Usage: brightness_setter.py [percentage|up|down|+|i]")
        print("  30         - Set brightness to 30%")
        print("  up         - Increase brightness by 10%")
        print("  down       - Decrease brightness by 10%")
        print("  +10        - Increase by 10%")
        print("  -10        - Decrease by 10%")
        print("  i          - Show current brightness info")
        return

    if arg == 'i':
        show_current()
        return

    current = get_current_brightness()
    max_brightness = get_max_brightness()
    
    if arg == 'up' or arg == '+':
        if current and max_brightness:
            new_percentage = min(100, round((current / max_brightness) * 100) + 10)
            set_brightness(new_percentage)
        return
    elif arg == 'down' or arg == '-':
        if current and max_brightness:
            new_percentage = max(0, round((current / max_brightness) * 100) - 10)
            set_brightness(new_percentage)
        return

    if arg.startswith('+') or arg.startswith('-'):
        try:
            delta = int(arg[1:])
            if current and max_brightness:
                current_percentage = round((current / max_brightness) * 100)
                new_percentage = max(0, min(100, current_percentage + delta))
                set_brightness(new_percentage)
            return
        except ValueError:
            pass

    try:
        percentage = int(arg)
        set_brightness(percentage)
    except ValueError:
        print(f"Error: Invalid argument '{arg}'")
        print("Usage: brightness_setter.py [percentage|+|-|up|down|i]")

if __name__ == "__main__":
    main()
