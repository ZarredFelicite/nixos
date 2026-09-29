#!/usr/bin/env bash

# Continuously sample AMD GPU stats from sysfs
set -euo pipefail
shopt -s nullglob

readonly AMD_VENDOR="0x1002"
readonly SAMPLE_INTERVAL=3

find_amd_card() {
    for card in /sys/class/drm/card*; do
        [[ -d "$card/device" ]] || continue
        local base_name
        base_name=$(basename "$card")
        if [[ ! "$base_name" =~ ^card[0-9]+$ ]]; then
            continue
        fi
        local vendor_file="$card/device/vendor"
        if [[ -f "$vendor_file" ]]; then
            local vendor
            vendor=$(<"$vendor_file")
            if [[ "$vendor" == "$AMD_VENDOR" ]]; then
                echo "$card"
                return 0
            fi
        fi
    done
    return 1
}

find_hwmon_dir() {
    local card="$1"
    for hw in "$card/device/hwmon"/hwmon*; do
        [[ -d "$hw" ]] || continue
        echo "$hw"
        return 0
    done
    echo "$card/device"
}

sanitize_number() {
    local raw="${1:-0}"
    raw="${raw//[^0-9]/}"
    [[ -z "$raw" ]] && raw=0
    printf '%s' "$raw"
}

read_int() {
    local file="$1"
    if [[ -r "$file" ]]; then
        sanitize_number "$(<"$file")"
    else
        printf '0'
    fi
}

emit_stats() {
    local card="$1"
    local hwmon_dir="$2"

    local gpu_usage
    gpu_usage=$(read_int "$card/device/gpu_busy_percent")
    local mem_used
    mem_used=$(read_int "$card/device/mem_info_vram_used")
    local mem_total
    mem_total=$(read_int "$card/device/mem_info_vram_total")
    (( mem_total <= 0 )) && mem_total=1

    local memory_pct=$(( mem_used * 100 / mem_total ))
    (( memory_pct < 0 )) && memory_pct=0
    (( memory_pct > 100 )) && memory_pct=100

    local power_avg
    power_avg=$(read_int "$hwmon_dir/power1_average")
    local power_cap
    power_cap=$(read_int "$hwmon_dir/power1_cap")
    (( power_cap <= 0 )) && power_cap=1

    local power_pct=$(( power_avg * 100 / power_cap ))
    (( power_pct < 0 )) && power_pct=0
    (( power_pct > 100 )) && power_pct=100

    local temp_raw
    temp_raw=$(read_int "$hwmon_dir/temp1_input")
    local temp=$(( temp_raw / 1000 ))
    (( temp < 0 )) && temp=0

    local power_watts=$(( power_avg / 1000000 ))
    (( power_watts < 0 )) && power_watts=0

    (( gpu_usage < 0 )) && gpu_usage=0
    (( gpu_usage > 100 )) && gpu_usage=100

    local profile
    if command -v lact &> /dev/null; then
        profile=$(lact cli profile get 2>/dev/null || echo "unknown")
    else
        profile="unknown"
    fi

    printf '%d,%d,%d,%d,%d,%s\n' "$gpu_usage" "$memory_pct" "$power_pct" "$temp" "$power_watts" "$profile"
}

AMD_CARD=$(find_amd_card)
if [[ -z "$AMD_CARD" ]]; then
    echo "0,0,0,0,0"
    exit 0
fi

HWMON_DIR=$(find_hwmon_dir "$AMD_CARD")

monitor_loop() {
    while true; do
        emit_stats "$AMD_CARD" "$HWMON_DIR"
        sleep "$SAMPLE_INTERVAL"
    done
}

if [[ "${1:-}" == "--monitor" ]]; then
    monitor_loop
else
    emit_stats "$AMD_CARD" "$HWMON_DIR"
fi
