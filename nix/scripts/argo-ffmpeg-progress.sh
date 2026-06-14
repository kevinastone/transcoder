#!/bin/bash
# argo-ffmpeg-progress — reads ffmpeg's -progress stream from stdin and
# writes Argo-compatible progress as a percentage (percent/100) to a progress file.
#
# Usage:  ffmpeg [...] -progress >(argo-ffmpeg-progress <total_duration> <progress_file>) [...]
#
# Arguments:
#   $1  – total duration in seconds (can be a float string)
#   $2  – path to write progress updates (e.g. Argo's progress file)

TOTAL_DURATION="${1:-0}"
PROGRESS_FILE="$2"

TOTAL_US=$(awk -v dur="$TOTAL_DURATION" 'BEGIN { printf "%.0f\n", dur * 1000000 }' 2>/dev/null)
if [ -z "$TOTAL_US" ]; then
  TOTAL_US=0
fi

while read -r line; do
  if [[ "$line" == out_time_us=* ]]; then
    TIME_US="${line#out_time_us=}"
    if [ -n "$PROGRESS_FILE" ] && [ "$TOTAL_US" -gt 0 ] && [[ "$TIME_US" =~ ^[0-9]+$ ]]; then
      # Calculate progress percentage (0-100)
      PERCENT=$(( TIME_US * 100 / TOTAL_US ))
      # Clamp to 100 just in case time slightly exceeds due to container differences
      if [ "$PERCENT" -gt 100 ]; then
        PERCENT=100
      fi
      echo "$PERCENT/100" > "$PROGRESS_FILE"
    fi
  fi
done
