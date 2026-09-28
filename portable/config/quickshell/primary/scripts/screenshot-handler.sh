#!/usr/bin/env bash

filepath="$1"

if [ ! -f "$filepath" ]; then
    notify-send "Screenshot" "File not found: $filepath" -u critical
    exit 1
fi

# Show action menu using rofi
action=$(echo -e "copy\npath\nopen\nedit\nocr" | rofi -dmenu -p "Screenshot Action:")

case "$action" in
    copy)
        wl-copy < "$filepath"
        notify-send "Screenshot" "Image copied to clipboard"
        ;;
    path)
        wl-copy "$filepath"
        notify-send "Screenshot" "Path copied to clipboard: $filepath"
        ;;
    open)
        # Use linkhandler logic for images
        ext="${filepath##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        case "$ext" in
            png|jpg|jpeg|heic|gif|webp|ico)
                setsid mpv "$filepath" --no-terminal &
                ;;
            *)
                setsid xdg-open "$filepath" &
                ;;
        esac
        ;;
    edit)
        if command -v satty &> /dev/null; then
            setsid satty --filename "$filepath" --output-filename "$filepath" &
        else
            notify-send "Screenshot" "satty not found" -u critical
        fi
        ;;
    ocr)
        if command -v tesseract &> /dev/null; then
            tesseract "$filepath" - | wl-copy
            notify-send "Screenshot" "OCR text copied to clipboard"
        else
            notify-send "Screenshot" "tesseract not found" -u critical
        fi
        ;;
    *)
        # User cancelled
        ;;
esac
