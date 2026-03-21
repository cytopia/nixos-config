#!/bin/bash

# 1. Get coordinates and strip EVERYTHING except the numbers
# This handles "474,10 1x1" -> "474 10"
coords=$(slurp -p | tr ',' ' ' | awk '{print $1, $2}')

if [[ -z "$coords" ]]; then
    exit 1
fi

# Split into clean variables
X_COORD=$(echo "$coords" | awk '{print $1}')
Y_COORD=$(echo "$coords" | awk '{print $2}')

# 2. Query Sway tree with string-to-number conversion
# We use --arg to ensure jq treats the input as a simple string first
PID=$(swaymsg -t get_tree | jq -r \
  --arg x "$X_COORD" \
  --arg y "$Y_COORD" \
  '..
   | select(.pid? != null and .visible == true)
   | select(
       ($x | tonumber) >= .rect.x and
       ($x | tonumber) <= (.rect.x + .rect.width) and
       ($y | tonumber) >= .rect.y and
       ($y | tonumber) <= (.rect.y + .rect.height)
     )
   | .pid' | tail -n 1)

# 3. Final Output
if [[ "$PID" != "null" && -n "$PID" ]]; then
    echo "$PID"
else
    echo "No PID found"
    exit 1
fi
