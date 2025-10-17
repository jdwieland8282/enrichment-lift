#!/usr/bin/env bash
#
# scripts/run_demo.sh
# One-shot launcher for the enrichment-lift demo.
# - Installs deps (npm ci || npm install) if package.json exists
# - Serves the repo root over HTTP on an available port (8080+)
# - Opens the browser to the demo URL
# - Optional: auto-refresh the page on macOS (see REFRESH_OSX)
#
set -euo pipefail

# --- Config (tweak if you like) ---
DEFAULT_PORT="${PORT:-8080}"
OPEN_PATH="${OPEN_PATH:-/}"            # e.g., "/index.html"
QUERY="${QUERY:-?pbjs_debug=true}"     # add your demo params here
AUTO_OPEN="${AUTO_OPEN:-1}"            # 1=open browser, 0=don’t
REFRESH_OSX="${REFRESH_OSX:-0}"        # 1=run refresh_osx.sh after launch (macOS only)
BROWSER_APP="${BROWSER_APP:-Google Chrome}" # used by refresh_osx.sh
# -----------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

# Helper: find a free TCP port starting at DEFAULT_PORT
find_free_port() {
  local p="$1"
  while lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; do
    p=$((p + 1))
    if (( p > 9099 )); then
      echo "No free port found between $1 and 9099" >&2
      exit 1
    fi
  done
  echo "$p"
}

# Helper: open a URL cross-platform
open_url() {
  local url="$1"
  case "$(uname -s)" in
    Darwin) open "$url" ;;
    Linux)  (command -v xdg-open >/dev/null && xdg-open "$url") || echo "Open this URL: $url" ;;
    MINGW*|CYGWIN*|MSYS*) start "" "$url" 2>/dev/null || echo "Open this URL: $url" ;;
    *) echo "Open this URL: $url" ;;
  esac
}

# Ensure Node + npm exist
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "❌ Node.js and npm are required. Install Node 18+ and re-run." >&2
  exit 1
fi

cd "$repo_root"

# Install deps if a package.json is present
if [[ -f package.json ]]; then
  echo "📦 Installing dependencies…"
  if [[ -f package-lock.json ]]; then
    npm ci || npm install
  else
    npm install
  fi
else
  echo "ℹ️ No package.json found. I’ll serve the folder with npx http-server."
fi

# Choose server command
PORT="$(find_free_port "$DEFAULT_PORT")"
URL="http://localhost:${PORT}${OPEN_PATH}${QUERY}"

# Prefer an existing npm script named 'dev'; otherwise use http-server
if npm run -s | grep -qE '^\s*dev\b'; then
  echo "🚀 Starting: npm run dev (PORT=$PORT)"
  # Expose PORT to your dev script if it respects it
  PORT="$PORT" npm run dev &
  server_pid=$!
else
  echo "🚀 Starting: npx http-server (PORT=$PORT)"
  npx --yes http-server -c-1 -p "$PORT" . >/dev/null 2>&1 &
  server_pid=$!
fi

# Cleanup on exit
cleanup() {
  if ps -p "$server_pid" >/dev/null 2>&1; then
    echo ""
    echo "🧹 Stopping server (pid $server_pid)…"
    kill "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Wait a moment for server to bind
sleep 1

# Open browser
if [[ "$AUTO_OPEN" == "1" ]]; then
  echo "🌐 Opening $URL"
  open_url "$URL"
else
  echo "🌐 Server running at: $URL"
fi

# Optional macOS auto-refresh using your refresh_osx.sh
if [[ "$REFRESH_OSX" == "1" && "$(uname -s)" == "Darwin" ]]; then
  if [[ -x "$repo_root/scripts/refresh_osx.sh" ]]; then
    echo "🔁 Auto-refreshing with scripts/refresh_osx.sh in a subshell…"
    ( BROWSER_APP="$BROWSER_APP" URL="$URL" "$repo_root/scripts/refresh_osx.sh" ) &
  elif [[ -x "$repo_root/refresh_osx.sh" ]]; then
    echo "🔁 Auto-refreshing with refresh_osx.sh in a subshell…"
    ( BROWSER_APP="$BROWSER_APP" URL="$URL" "$repo_root/refresh_osx.sh" ) &
  else
    echo "ℹ️ REFRESH_OSX=1 set, but refresh_osx.sh not found. See repo notes."
  fi
fi

echo ""
echo "✅ Demo is live: $URL"
echo "   Press Ctrl+C to stop."
wait "$server_pid"
