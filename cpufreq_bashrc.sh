# CPU Frequency Control Functions for Lenovo Legion
# Add these functions to your ~/.bashrc
# Source this file: source /path/to/cpufreq_bashrc.sh

# Set scaling_max_freq to 900000 for all CPU policies
setcpufreq() {
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        echo 900000 | sudo tee "$policy/scaling_max_freq" > /dev/null
    done
    echo "CPU scaling_max_freq set to 900000 for all policies"
}

# Set scaling_max_freq to a custom frequency (in kHz)
setcpufreq_custom() {
    local freq=${1:-900000}
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        echo "$freq" | sudo tee "$policy/scaling_max_freq" > /dev/null
    done
    echo "CPU scaling_max_freq set to $freq kHz for all policies"
}

# Show current scaling_max_freq for all policies
showcpufreq() {
    echo "Current CPU scaling_max_freq values:"
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        echo -n "$policy: "
        cat "$policy/scaling_max_freq" 2>/dev/null || echo "N/A"
    done
}

# Reset to maximum available frequency
resetcpufreq() {
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        cat "$policy/cpuinfo_max_freq" | sudo tee "$policy/scaling_max_freq" > /dev/null
    done
    echo "CPU scaling_max_freq reset to maximum for all policies"
}
