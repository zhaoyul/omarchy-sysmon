#!/usr/bin/env bash
# Print eight lines for the kevin.sysmon bar widget:
#   fan RPM, disk free, mem available, disk free %, disk used %, mem total,
#   mem used %, CPU usage %

set -uo pipefail

# CPU: two /proc/stat samples 0.4s apart, excluding guest double-counting.
cpu_sample() {
  awk '/^cpu / {
    total = 0
    for (i = 2; i <= NF && i <= 9; i++) total += $i
    print total, $5
  }' /proc/stat
}

cpu_usage="--"
read -r cpu_total1 cpu_idle1 <<<"$(cpu_sample)"
sleep 0.4
read -r cpu_total2 cpu_idle2 <<<"$(cpu_sample)"
if [[ ${cpu_total1:-} =~ ^[0-9]+$ && ${cpu_idle1:-} =~ ^[0-9]+$ &&
      ${cpu_total2:-} =~ ^[0-9]+$ && ${cpu_idle2:-} =~ ^[0-9]+$ ]] &&
   (( cpu_total2 > cpu_total1 )); then
  cpu_usage=$(awk -v t1="$cpu_total1" -v i1="$cpu_idle1" \
                  -v t2="$cpu_total2" -v i2="$cpu_idle2" \
                  'BEGIN { dt = t2 - t1; printf "%.0f%%", 100 * (dt - (i2 - i1)) / dt }')
fi

# Fan: use the highest reading among all hwmon fan inputs.
fan_rpm=""
for input in /sys/class/hwmon/hwmon*/fan*_input; do
  [[ -r $input ]] || continue
  value=$(<"$input") || continue
  [[ $value =~ ^[0-9]+$ ]] || continue
  if [[ -z $fan_rpm ]] || (( value > fan_rpm )); then
    fan_rpm=$value
  fi
done

# Disk: available space on / and its used/free percentages.
read -r disk_avail_k disk_pct <<<"$(df -Pk / 2>/dev/null | awk 'NR==2 { print $4, $5 }')"
disk_free="--"
disk_free_pct="--"
disk_used_pct="--"
if [[ ${disk_avail_k:-} =~ ^[0-9]+$ ]]; then
  disk_free=$(awk -v k="$disk_avail_k" 'BEGIN { printf "%.1fG", k / 1048576 }')
fi
if [[ ${disk_pct:-} =~ ^[0-9]+%$ ]]; then
  disk_used_pct=$disk_pct
  disk_free_pct=$(awk -v u="${disk_pct%\%}" 'BEGIN { printf "%.0f%%", 100 - u }')
fi

# Memory: used = MemTotal - MemAvailable, as a percentage of MemTotal.
mem_available_k=$(awk '/^MemAvailable:/ { print $2; exit }' /proc/meminfo 2>/dev/null)
mem_total_k=$(awk '/^MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null)
mem_avail="--"
mem_total="--"
mem_used_pct="--"
if [[ ${mem_available_k:-} =~ ^[0-9]+$ ]]; then
  mem_avail=$(awk -v k="$mem_available_k" 'BEGIN { printf "%.1fG", k / 1048576 }')
fi
if [[ ${mem_total_k:-} =~ ^[0-9]+$ ]]; then
  mem_total=$(awk -v k="$mem_total_k" 'BEGIN { printf "%.1fG", k / 1048576 }')
fi
if [[ ${mem_available_k:-} =~ ^[0-9]+$ && ${mem_total_k:-} =~ ^[0-9]+$ ]] && (( mem_total_k > 0 )); then
  mem_used_pct=$(awk -v a="$mem_available_k" -v t="$mem_total_k" 'BEGIN { printf "%.0f%%", 100 * (1 - a / t) }')
fi

printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
  "${fan_rpm:---}" "$disk_free" "$mem_avail" \
  "$disk_free_pct" "$disk_used_pct" "$mem_total" "$mem_used_pct" \
  "$cpu_usage"
