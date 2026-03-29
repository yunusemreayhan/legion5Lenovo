#!/bin/bash

echo "Applying AMD GPU brightness fix for Ubuntu..."

if grep -q "amdgpu.backlight=0" /etc/default/grub; then
    echo "Brightness fix already applied!"
else
    sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/"$/ amdgpu.backlight=0"/' /etc/default/grub
    sudo update-grub
    echo "Brightness fix applied. Please reboot."
fi
