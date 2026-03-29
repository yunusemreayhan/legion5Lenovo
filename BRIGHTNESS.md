# Brightness Control

After running `setup_brightness_permissions.sh`, brightness can be controlled using `brightctl`:

```bash
# Decrease brightness by 10%
brightnessctl -d amdgpu_bl2 s 10%-

# Increase brightness by 10%
brightnessctl -d amdgpu_bl2 s +10%
```

The device `amdgpu_bl2` is the AMD GPU backlight interface.
