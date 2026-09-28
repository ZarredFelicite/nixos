#!/usr/bin/env bash

# Get notification count from swaync
notification_count=$(swaync-client -c)

# Generate icon with notification count overlay
if [[ -n "$notification_count" && "$notification_count" -gt 0 ]]; then
    # Pad the count to 3 digits for filename (e.g., 015)
    count_padded=$(printf "%03d" "$notification_count")
    magick composite -compose over "pictures/icons/digits/${count_padded}.png" pictures/icons/notifications.png /tmp/notification_icon.png
else
    # If no notifications, just copy the base notification icon
    cp pictures/icons/notifications.png /tmp/notification_icon.png
fi

# Output file path and formatted information
echo "/tmp/notification_icon.png"
if [[ -n "$notification_count" && "$notification_count" -gt 0 ]]; then
    echo -e "Notifications: $notification_count"
else
    echo "No notifications"
fi