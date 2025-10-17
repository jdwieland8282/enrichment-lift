#!/usr/bin/env bash
set -euo pipefail

# === Config ===
URL='http://enrichment-lift:8080/?pbjs_debug=true&ga=http%3A%2F%2Fenrichment-lift%3A9090%2Fcollect&synthWinRate=1&synthLift=0.3&rk=mgl59gzi#'
BROWSER_APP=${BROWSER_APP:-"Google Chrome"}  # Or "Brave Browser", "Microsoft Edge"
DURATION_MIN=${DURATION_MIN:-30}
MIN_DELAY=${MIN_DELAY:-5}
MAX_DELAY=${MAX_DELAY:-10}

rand_delay() {
  if command -v jot >/dev/null 2>&1; then
    jot -r 1 "$MIN_DELAY" "$MAX_DELAY"
  elif command -v shuf >/dev/null 2>&1; then
    shuf -i "${MIN_DELAY}-${MAX_DELAY}" -n 1
  else
    local range=$((MAX_DELAY - MIN_DELAY + 1))
    echo $(( RANDOM % range + MIN_DELAY ))
  fi
}

# Ensure the page is open once up front.
osascript <<OSA
tell application "$BROWSER_APP"
  if (count of windows) = 0 then make new window
  activate
  tell window 1
    if (count of tabs) = 0 then make new tab
    set URL of active tab to "$URL"
  end tell
end tell
OSA

end_ts=$(( $(date +%s) + DURATION_MIN*60 ))
i=0
echo "Refreshing in $BROWSER_APP every ${MIN_DELAY}-${MAX_DELAY}s for ~${DURATION_MIN}m..."

while (( $(date +%s) < end_ts )); do
  i=$((i+1))
  osascript <<OSA || true
tell application "$BROWSER_APP"
  if (count of windows) = 0 then make new window
  activate
  tell window 1
    try
      -- Reload by re-setting the same URL (works reliably in Chrome/Brave/Edge)
      set URL of active tab to "$URL"
    on error
      -- Fallback: Cmd+R (requires Accessibility permission)
      tell application "System Events" to keystroke "r" using command down
    end try
  end tell
end tell
OSA

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Reload #$i"
  sleep "$(rand_delay)"
done

echo "Done."
