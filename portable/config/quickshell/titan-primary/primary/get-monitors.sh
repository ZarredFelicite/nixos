#!/usr/bin/env bash

# Script to help identify monitor names for quickshell configuration

echo "=== Available Monitors ==="
echo

if command -v hyprctl >/dev/null 2>&1; then
    echo "Using Hyprland (hyprctl monitors):"
    hyprctl monitors | grep -E "^Monitor" | while read -r line; do
        monitor_name=$(echo "$line" | awk '{print $2}')
        resolution=$(echo "$line" | awk '{print $3}')
        echo "  - $monitor_name ($resolution)"
    done
    echo
elif command -v swaymsg >/dev/null 2>&1; then
    echo "Using Sway (swaymsg -t get_outputs):"
    swaymsg -t get_outputs | jq -r '.[] | "  - \(.name) (\(.current_mode.width)x\(.current_mode.height))"'
    echo
elif command -v xrandr >/dev/null 2>&1; then
    echo "Using X11 (xrandr):"
    xrandr --query | grep " connected" | while read -r line; do
        monitor_name=$(echo "$line" | awk '{print $1}')
        resolution=$(echo "$line" | grep -o '[0-9]\+x[0-9]\+' | head -1)
        echo "  - $monitor_name ($resolution)"
    done
    echo
else
    echo "No supported display server found (Hyprland, Sway, or X11)"
    echo "Please check your display server and install the appropriate tools:"
    echo "  - Hyprland: hyprctl"
    echo "  - Sway: swaymsg + jq"
    echo "  - X11: xrandr"
    exit 1
fi

echo "=== Configuration Instructions ==="
echo
echo "1. Edit config.qml and set your primary monitor:"
echo "   property string primaryMonitor: \"YOUR_MONITOR_NAME\""
echo
echo "2. Example configurations:"
echo "   - Single primary: primaryMonitor: \"DP-1\""
echo "   - Multiple primary: primaryMonitors: [\"DP-1\", \"HDMI-A-1\"]"
echo
echo "3. The primary monitor(s) will show the full bar at the top with all widgets (reserves space)"
echo "4. Secondary monitors will show only workspaces centered at the bottom (no space reserved)"