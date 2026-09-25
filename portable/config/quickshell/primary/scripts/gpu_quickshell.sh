#!/usr/bin/env bash

# GPU monitoring script for NVIDIA discrete GPU
# Outputs: USAGE,MEMORY_USAGE,POWER_USAGE,TEMP
# Requires nvidia-smi

set -e

process_line() {
    local line="$1"
    IFS=',' read -r GPU_UTIL MEM_USED MEM_TOTAL POWER_DRAW POWER_LIMIT TEMP <<< "$line"

    # Clean up whitespace
    GPU_UTIL=$(echo "$GPU_UTIL" | tr -d ' ')
    MEM_USED=$(echo "$MEM_USED" | tr -d ' ')
    MEM_TOTAL=$(echo "$MEM_TOTAL" | tr -d ' ')
    POWER_DRAW=$(echo "$POWER_DRAW" | tr -d ' ')
    POWER_LIMIT=$(echo "$POWER_LIMIT" | tr -d ' ')
    TEMP=$(echo "$TEMP" | tr -d ' ')

    # Convert to integers (remove decimal points)
    MEM_USED=${MEM_USED%.*}
    MEM_TOTAL=${MEM_TOTAL%.*}
    POWER_DRAW=${POWER_DRAW%.*}
    POWER_LIMIT=${POWER_LIMIT%.*}

    # Calculate percentages
    if [[ "$MEM_TOTAL" -gt 0 ]]; then
        MEM_USAGE=$(( (MEM_USED * 100) / MEM_TOTAL ))
    else
        MEM_USAGE=0
    fi

    if [[ "$POWER_LIMIT" -gt 0 ]]; then
        POWER_USAGE=$(( (POWER_DRAW * 100) / POWER_LIMIT ))
    else
        POWER_USAGE=0
    fi

    # Ensure values are within bounds
    GPU_UTIL=$(( GPU_UTIL > 100 ? 100 : GPU_UTIL ))
    MEM_USAGE=$(( MEM_USAGE > 100 ? 100 : MEM_USAGE ))
    POWER_USAGE=$(( POWER_USAGE > 100 ? 100 : POWER_USAGE ))
    
    # Ensure non-negative values
    GPU_UTIL=$(( GPU_UTIL < 0 ? 0 : GPU_UTIL ))
    MEM_USAGE=$(( MEM_USAGE < 0 ? 0 : MEM_USAGE ))
    POWER_USAGE=$(( POWER_USAGE < 0 ? 0 : POWER_USAGE ))
    TEMP=$(( TEMP < 0 ? 0 : TEMP ))

    # Output format: USAGE,MEMORY_USAGE,POWER_USAGE,TEMP,POWER_WATTS
    echo "${GPU_UTIL},${MEM_USAGE},${POWER_USAGE},${TEMP},${POWER_DRAW}"
}

if [[ "$1" == "--monitor" ]]; then
    if ! command -v nvidia-smi &> /dev/null; then
        while true; do
            echo "0,0,0,0,0"
            sleep 3
        done
    else
        # Use stdbuf to unbuffer output if available, otherwise hope nvidia-smi flushes
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,power.draw,power.limit,temperature.gpu --format=csv,noheader,nounits -l 3 | \
        while read -r line; do
            process_line "$line"
        done
    fi
else
    # Check if nvidia-smi is available
    if ! command -v nvidia-smi &> /dev/null; then
        echo "0,0,0,0"
        exit 0
    fi

    # Get GPU stats using nvidia-smi
    GPU_STATS=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,power.draw,power.limit,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0, 0, 1, 0, 1, 0")
    process_line "$GPU_STATS"
fi
