#!/usr/bin/env bash
# Adapted network polling script aligning with wifi_icon.sh logic.
# Key changes:
#  - 0.1s sampling interval (faster responsiveness) like wifi_icon.sh
#  - Compute signal_percent (0-100) directly (formula: (rssi+100)*100/70 clamped)
#  - Parse ExpectedThroughput (Kbit/s) from iwctl output if present
#  - Provide down_mbps/up_mbps similar to prior script but now from binary units (bits / 2^20 per second) to mirror wifi_icon.sh math
#  - Provide down_score (0-100) and up_score (0-20) analogous to wifi_icon.sh speed_score/upload_score
#  - Preserve prior fields for backward compatibility
# Output: space-separated key=value pairs; spaces replaced by '+' in values.
# Fields (connected): connected=1 interface=<if> ssid=<ssid> rssi=<dBm> signal_percent=<0-100> freq_mhz=<freq>
#   security=<sec> txrate=<raw> rxrate=<raw> expected_kbps=<kbit/s> down_mbps=<float> up_mbps=<float>
#   down_score=<0-100> up_score=<0-20>
# Disconnected: connected=0 interface=<if>

set -euo pipefail

SAMPLE_INTERVAL=0.1

escape() { printf '%s' "$1" | sed 's/ /+/g'; }

# Detect active interface (the one with default route)
IFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -1 || echo "wlan0")

connected=0
rssi=""; freq=""; ssid=""; security=""; txrate=""; rxrate=""; expected_kbps=""

# Check if interface is wireless (starts with wl) or wired
if [[ "$IFACE" =~ ^wl ]]; then
  # Wireless interface - use iwctl
  if wifi_info=$(iwctl station "$IFACE" show 2>/dev/null); then
    if grep -q "Connected network" <<<"$wifi_info"; then
      connected=1
    fi
    rssi=$(grep -oP 'RSSI\s+\K-?\d+' <<<"$wifi_info" | head -1 || true)
    freq=$(grep -oP 'Frequency\s+\K[0-9.]+' <<<"$wifi_info" | head -1 || true)
    ssid=$(grep -oP 'Connected network\s+\K.*' <<<"$wifi_info" | head -1 || true)
    security=$(grep -oP 'Security\s+\K.*' <<<"$wifi_info" | head -1 || true)
    txrate=$(grep -oP 'TxBitrate\s+\K[0-9]+\s+Kbit/s' <<<"$wifi_info" | head -1 || true)
    rxrate=$(grep -oP 'RxBitrate\s+\K[0-9]+\s+Kbit/s' <<<"$wifi_info" | head -1 || true)
    expected_kbps=$(grep -oP 'ExpectedThroughput\s+\K[0-9]+' <<<"$wifi_info" | head -1 || true)
  fi
else
  # Wired interface - check if it's up and has an IP
  if ip link show "$IFACE" 2>/dev/null | grep -q "state UP" && ip addr show "$IFACE" 2>/dev/null | grep -q "inet "; then
    connected=1
  fi
fi

# Signal percent calculation (same as wifi_icon.sh but integer arithmetic)
signal_percent=""
if [[ "$IFACE" =~ ^wl ]]; then
  # Wireless - calculate from RSSI
  if [[ -n ${rssi:-} ]]; then
    # Use bc for safety then clamp
    sp=$(echo "($rssi + 100) * 100 / 70" | bc 2>/dev/null || echo 0)
    # Clamp
    if [[ $sp -lt 0 ]]; then sp=0; elif [[ $sp -gt 100 ]]; then sp=100; fi
    signal_percent=$sp
  fi
else
  # Wired - always 100%
  signal_percent=100
fi

# Throughput sampling (raw bytes)
rx1=0; tx1=0; rx2=0; tx2=0
if [[ -r /sys/class/net/$IFACE/statistics/rx_bytes ]]; then
  rx1=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
  tx1=$(< /sys/class/net/$IFACE/statistics/tx_bytes)
  sleep "$SAMPLE_INTERVAL"
  rx2=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
  tx2=$(< /sys/class/net/$IFACE/statistics/tx_bytes)
fi

rx_delta=$(( rx2 - rx1 ))
tx_delta=$(( tx2 - tx1 ))
if (( rx_delta < 0 )); then rx_delta=0; fi
if (( tx_delta < 0 )); then tx_delta=0; fi

# Bits per second using sample interval; use integer math first
# scale bits_per_sec = bytes * 8 / interval. For interval=0.1 => multiply by 80
# We retain general formula for robustness: multiply first then divide.
interval_factor=$(awk -v iv="$SAMPLE_INTERVAL" 'BEGIN{printf "%.0f", 1/iv}') || interval_factor=10
# But for speed avoid awk if SAMPLE_INTERVAL=0.1
if [[ "$SAMPLE_INTERVAL" == "0.1" ]]; then interval_factor=10; fi
# Actually for 0.1s: bits_per_sec = bytes*8*10 = bytes*80
if [[ "$SAMPLE_INTERVAL" == "0.1" ]]; then
  rx_bits_per_sec=$(( rx_delta * 80 ))
  tx_bits_per_sec=$(( tx_delta * 80 ))
else
  # Fallback using bc (slower path)
  rx_bits_per_sec=$(echo "($rx_delta * 8)/$SAMPLE_INTERVAL" | bc 2>/dev/null || echo 0)
  tx_bits_per_sec=$(echo "($tx_delta * 8)/$SAMPLE_INTERVAL" | bc 2>/dev/null || echo 0)
fi

# Convert to Mbit/s using binary 2^20 (like wifi_icon.sh used 1048576 denominator)
# Provide two decimals.
conv=1048576
rx_int=$(( rx_bits_per_sec / conv ))
rx_frac=$(( (rx_bits_per_sec % conv) * 100 / conv ))
tx_int=$(( tx_bits_per_sec / conv ))
tx_frac=$(( (tx_bits_per_sec % conv) * 100 / conv ))

down_mbps=$(printf '%d.%02d' "$rx_int" "$rx_frac")
up_mbps=$(printf '%d.%02d' "$tx_int" "$tx_frac")

# Scores (mirror wifi_icon.sh logic)
# down_score: out of 100 Mbit/s
# up_score: scale to 0-20 (upload often lower)
# Use integer portion + fraction scaled.
# Use bc for safety when decimals appear (though we already have string numbers)
if [[ -n $down_mbps ]]; then
  down_score=$(echo "$down_mbps * 100 / 100" | bc 2>/dev/null || echo 0)
  if [[ $down_score -gt 100 ]]; then down_score=100; fi
else
  down_score=0
fi
if [[ -n $up_mbps ]]; then
  up_score=$(echo "$up_mbps * 20 / 100" | bc 2>/dev/null || echo 0)
  if [[ $up_score -gt 20 ]]; then up_score=20; fi
else
  up_score=0
fi

if [[ ${connected:-0} -eq 1 ]]; then
  printf 'connected=1 interface=%s ' "$IFACE"
  [[ -n ${ssid:-} ]] && printf 'ssid=%s ' "$(escape "$ssid")"
  [[ -n ${rssi:-} ]] && printf 'rssi=%s ' "$rssi"
  [[ -n ${signal_percent:-} ]] && printf 'signal_percent=%s ' "$signal_percent"
  [[ -n ${freq:-} ]] && printf 'freq_mhz=%s ' "$freq"
  [[ -n ${security:-} ]] && printf 'security=%s ' "$(escape "$security")"
  [[ -n ${txrate:-} ]] && printf 'txrate=%s ' "$(escape "$txrate")"
  [[ -n ${rxrate:-} ]] && printf 'rxrate=%s ' "$(escape "$rxrate")"
  [[ -n ${expected_kbps:-} ]] && printf 'expected_kbps=%s ' "$expected_kbps"
  printf 'down_mbps=%s up_mbps=%s down_score=%s up_score=%s\n' "$down_mbps" "$up_mbps" "$down_score" "$up_score"
else
  printf 'connected=0 interface=%s\n' "$IFACE"
fi
