#!/usr/bin/env bash

audio_device="$1"
filename="$2"
logfile="/tmp/region-record-debug.log"

echo "$(date): Script started with audio=$audio_device file=$filename" >> "$logfile"

# Get region from slurp
region=$(slurp 2>&1)
slurp_exit=$?

echo "$(date): Slurp exited with code $slurp_exit, region='$region'" >> "$logfile"

if [ $slurp_exit -ne 0 ] || [ -z "$region" ]; then
    echo "$(date): Region selection cancelled or failed" >> "$logfile"
    notify-send "Recording" "Region selection cancelled"
    exit 1
fi

# Notify that recording is starting
notify-send "Recording" "Starting region recording..."
echo "$(date): Starting wf-recorder with region=$region" >> "$logfile"

# Start wf-recorder with the selected region
wf-recorder --audio-backend=pipewire --audio "$audio_device" -g "$region" -f "$filename" >> "$logfile" 2>&1 &
wf_pid=$!
echo "$(date): wf-recorder started with PID $wf_pid" >> "$logfile"
