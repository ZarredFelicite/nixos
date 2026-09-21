#!/usr/bin/env zsh

# Paths and intervals can be overridden for testing; defaults match production.
BATTERY_STATE_DIR="${BATTERY_STATE_DIR:-/tmp}"
ICON_BASE_DIR="${ICON_BASE_DIR:-/home/zarred/pictures/icons/waybar}"
RING_GENERATOR="${RING_GENERATOR:-/home/zarred/scripts/waybar/ring_generator.py}"
BLUETOOTH_ADAPTER_PATH="${BLUETOOTH_ADAPTER_PATH:-/org/bluez/hci0}"
BLUETOOTH_OFF_POLL_INTERVAL="${BLUETOOTH_OFF_POLL_INTERVAL:-5}"
LOOP_INTERVAL="${BATTERY_ICON_LOOP_INTERVAL:-1}"

# Define devices and their parts/scales.
typeset -A parts_json scales last_data seen
parts_json[airpods]='["left","right","case"]'
parts_json[zmk]='["left","right","central"]'
scales[airpods]=100
scales[zmk]=100

devices=("airpods" "zmk")

bluetooth_powered() {
  local state

  state=$(busctl --system --no-pager get-property org.bluez \
    "$BLUETOOTH_ADAPTER_PATH" org.bluez.Adapter1 Powered 2>/dev/null) || return 1
  [[ "$state" == *" true" ]]
}

process_device() {
  local device="$1"
  local battery_file="${BATTERY_STATE_DIR}/${device}_battery"
  local data parsed_data part charge charging
  local output_dir icon_scale filename_charge_value output_file part_file
  local charging_suffix
  local -a ring_args

  if [[ ! -f "$battery_file" || ! -r "$battery_file" ]]; then
    seen[$device]=0
    return
  fi

  if ! data=$(< "$battery_file"); then
    seen[$device]=0
    return
  fi

  # Do not invoke jq again until this device's source content changes.
  if [[ "${seen[$device]-0}" == 1 && "${last_data[$device]-}" == "$data" ]]; then
    return
  fi
  last_data[$device]="$data"
  seen[$device]=1

  # Extract all parts in one jq invocation. Invalid/missing charge values are ignored.
  parsed_data=$(printf '%s' "$data" | jq -r --argjson parts "${parts_json[$device]}" '
    . as $root
    | ($root | if type == "object" then (.charge // {}) else {} end) as $charges
    | $parts[] as $part
    | ($charges | if type == "object" then .[$part] else null end) as $charge
    | ($root | if type == "object" then .["charging_" + $part] else null end) as $charging
    | if ($charge | type) == "number"
      then [$part, ($charge | tostring), (($charging == true) | tostring)] | @tsv
      else empty
      end
  ') || return

  output_dir="${ICON_BASE_DIR}/${device}_battery"
  icon_scale=""

  while IFS=$'\t' read -r part charge charging; do
    [[ -n "$part" && -n "$charge" ]] || continue

    # jq has already verified that charge is numeric; use arithmetic only for -1.
    filename_charge_value="$charge"
    if (( charge == -1 )); then
      filename_charge_value=0
    fi

    if [[ "$charging" == true ]]; then
      charging_suffix=1
    else
      charging_suffix=0
    fi

    output_file="${output_dir}/${part}_${filename_charge_value}_${charging_suffix}.png"
    if [[ ! -f "$output_file" ]]; then
      if [[ -z "$icon_scale" ]]; then
        icon_scale=$(printf "%.2f" "$(printf '%s / 100\n' "${scales[$device]}" | bc -l)")
      fi

      ring_args=(
        --percent "$charge"
        --output "$output_file"
        --icon "${ICON_BASE_DIR}/${device}-${part}.png"
        --icon-scale "$icon_scale"
      )
      [[ "$charging" == true ]] && ring_args+=(--charging)
      python "$RING_GENERATOR" "${ring_args[@]}" >/dev/null
    fi

    part_file="${BATTERY_STATE_DIR}/${device}_battery_${part}"
    {
      printf '%s\n' "$output_file"
      printf '%s' "$data"
    } > "$part_file"
  done <<< "$parsed_data"
}

while true; do
  # Avoid touching battery JSON or invoking jq/python/bc while Bluetooth is off.
  if ! bluetooth_powered; then
    sleep "$BLUETOOTH_OFF_POLL_INTERVAL"
    continue
  fi

  for device in "${devices[@]}"; do
    process_device "$device"
  done
  sleep "$LOOP_INTERVAL"
done
