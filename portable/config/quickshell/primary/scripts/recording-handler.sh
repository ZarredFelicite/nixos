#!/usr/bin/env bash

filepath="$1"

if [ ! -f "$filepath" ]; then
    notify-send "Recording" "File not found: $filepath" -u critical
    exit 1
fi

# Show action menu using rofi
action=$(echo -e "Open\nCopy Path\nCopy Video\nShow Info" | rofi -dmenu -p "Recording:")

case "$action" in
    "Open")
        # Open with mpv
        setsid mpv "$filepath" --no-terminal &
        ;;
    "Copy Path")
        wl-copy "$filepath"
        notify-send "Recording" "Path copied to clipboard"
        ;;
    "Copy Video")
        # Copy video file to clipboard (requires wl-copy with file support)
        wl-copy < "$filepath"
        notify-send "Recording" "Video copied to clipboard"
        ;;
    "Show Info")
        # Show file info using mediainfo or ffprobe
        if command -v mediainfo &> /dev/null; then
            info=$(mediainfo "$filepath" | head -20)
        elif command -v ffprobe &> /dev/null; then
            info=$(ffprobe -v error -show_format "$filepath" 2>&1 | head -20)
        else
            info="mediainfo or ffprobe not found"
        fi
        notify-send "Recording Info" "$info"
        ;;
    *)
        # User cancelled
        ;;
esac
