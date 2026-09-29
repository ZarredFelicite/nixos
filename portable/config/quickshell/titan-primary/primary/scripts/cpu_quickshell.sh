#!/usr/bin/env bash

# Wrapper to provide a --quickshell interface for the CPU icon.
# Outputs: USAGE,TEMP,PROFILE
# For --switch-mode it forwards to the original waybar script to change profile.

set -e

ORIG_SCRIPT="/home/zarred/scripts/waybar/create_cpu_icon.sh"
HOSTNAME=$(hostname)

if [[ "$1" == "--switch-mode" ]]; then
    if [[ -x "$ORIG_SCRIPT" ]]; then
        "$ORIG_SCRIPT" --switch-mode
        exit $?
    else
        echo "Error: original script not found" >&2
        exit 1
    fi
fi

get_cpu_usage() {
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    local idle_sum=$((idle + iowait))
    echo "$total $idle_sum"
}

get_temp() {
    local CPU_TEMP_FILE="/sys/class/hwmon/hwmon2/temp1_input"
    if [[ -f "$CPU_TEMP_FILE" ]]; then
        local TEMP_RAW=$(($(cat "$CPU_TEMP_FILE") / 1000))
        # Round to nearest 5
        echo $(( (TEMP_RAW + 2) / 5 * 5 ))
    else
        echo 0
    fi
}

get_profile() {
    local PROFILE="false"
    if [[ "$HOSTNAME" == "web" ]] && command -v powerprofilesctl &> /dev/null; then
        PROFILE=$(powerprofilesctl | grep '\*' | awk '{print $2}' | sed 's/:$//') || true
    elif [[ "$HOSTNAME" == "nano" ]] && [[ -f "/sys/firmware/acpi/platform_profile" ]]; then
        PROFILE=$(cat /sys/firmware/acpi/platform_profile) || true
    fi
    if [[ -z "$PROFILE" ]]; then
        echo "false"
    else
        echo "$PROFILE"
    fi
}

# Monitoring loop
if [[ "$1" == "--monitor" ]]; then
    PREV_STATS=$(get_cpu_usage)
    
    while true; do
        sleep 3
        
        CURR_STATS=$(get_cpu_usage)
        PREV_TOTAL=${PREV_STATS% *}
        PREV_IDLE=${PREV_STATS#* }
        CURR_TOTAL=${CURR_STATS% *}
        CURR_IDLE=${CURR_STATS#* }
        
        DIFF_TOTAL=$((CURR_TOTAL - PREV_TOTAL))
        DIFF_IDLE=$((CURR_IDLE - PREV_IDLE))
        
        if [[ $DIFF_TOTAL -gt 0 ]]; then
            USAGE=$(( 100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL ))
        else
            USAGE=0
        fi
        
        # Round usage to nearest 2 to match old behavior/visuals if desired, or just keep raw
        USAGE=$(( (USAGE + 1) / 2 * 2 ))
        
        TEMP=$(get_temp)
        PROFILE=$(get_profile)
        
        echo "${USAGE},${TEMP},${PROFILE}"
        
        PREV_STATS=$CURR_STATS
    done
else
    # Single shot fallback (measure over 0.5s)
    PREV_STATS=$(get_cpu_usage)
    sleep 0.5
    CURR_STATS=$(get_cpu_usage)
    
    PREV_TOTAL=${PREV_STATS% *}
    PREV_IDLE=${PREV_STATS#* }
    CURR_TOTAL=${CURR_STATS% *}
    CURR_IDLE=${CURR_STATS#* }
    
    DIFF_TOTAL=$((CURR_TOTAL - PREV_TOTAL))
    DIFF_IDLE=$((CURR_IDLE - PREV_IDLE))
    
    if [[ $DIFF_TOTAL -gt 0 ]]; then
        USAGE=$(( 100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL ))
    else
        USAGE=0
    fi
    USAGE=$(( (USAGE + 1) / 2 * 2 ))
    
    TEMP=$(get_temp)
    PROFILE=$(get_profile)
    
    echo "${USAGE},${TEMP},${PROFILE}"
fi
