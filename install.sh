#!/usr/bin/env bash
set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/mousedown/claude-skills/main"
CLAUDE_DIR="$HOME/.claude"

# All available theme directories
THEMES=(
  budget-tracker
  centered
  compact-statusline
  cost-tracker-statusline
  emoji-statusline
  git-dashboard
  gsd-statusline
  hacker-matrix
  lcars
  minimal-statusline
  neon-tokyo
  plain-statusline
  powerline-arrows
  powerline-catppuccin
  powerline-classic
  powerline-gruvbox
  powerline-neon
  powerline-nord
  retro-terminal
  scoreboard
  solarized
  split-view
  time-machine
  tokens-focus
  two-line
  zen-statusline
)

print_themes() {
  echo "Available themes:"
  echo ""
  for t in "${THEMES[@]}"; do
    echo "  $t"
  done
  echo ""
  echo "Usage: $0 <theme-name>"
  echo ""
  echo "Examples:"
  echo "  $0 minimal          # installs minimal-statusline"
  echo "  $0 neon-tokyo        # installs neon-tokyo"
  echo "  $0 powerline-classic # installs powerline-classic"
}

# ── Argument handling ───────────────────────────────────────────────
if [ $# -eq 0 ] || [ "$1" = "--list" ] || [ "$1" = "-l" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  print_themes
  exit 0
fi

INPUT="$1"

# ── Resolve theme name to directory ─────────────────────────────────
resolve_theme() {
  local input="$1"

  # Exact match first
  for t in "${THEMES[@]}"; do
    if [ "$t" = "$input" ]; then
      echo "$t"
      return 0
    fi
  done

  # Try appending -statusline
  for t in "${THEMES[@]}"; do
    if [ "$t" = "${input}-statusline" ]; then
      echo "$t"
      return 0
    fi
  done

  # Prefix / substring match (first match wins)
  for t in "${THEMES[@]}"; do
    if [[ "$t" == *"$input"* ]]; then
      echo "$t"
      return 0
    fi
  done

  return 1
}

THEME_DIR=$(resolve_theme "$INPUT") || {
  echo "Error: theme '$INPUT' not found."
  echo ""
  print_themes
  exit 1
}

echo "Installing theme: $THEME_DIR"

# ── Download setup.json ─────────────────────────────────────────────
SETUP_URL="$REPO_BASE/statuslines/$THEME_DIR/setup.json"
SETUP_TMP=$(mktemp)
trap 'rm -f "$SETUP_TMP"' EXIT

echo "Fetching setup.json ..."
if ! curl -fsSL "$SETUP_URL" -o "$SETUP_TMP"; then
  echo "Error: failed to download setup.json from:"
  echo "  $SETUP_URL"
  exit 1
fi

# ── Parse script filename from the copy command ─────────────────────
# The 1_copy_script value looks like:
#   cp statuslines/<dir>/<script-file> ~/.claude/<dest-file>
COPY_CMD=$(grep '"1_copy_script"' "$SETUP_TMP" | sed 's/.*"1_copy_script"[[:space:]]*:[[:space:]]*"//' | sed 's/".*//')

# Source: everything between "statuslines/<dir>/" and the space before "~"
SCRIPT_FILE=$(echo "$COPY_CMD" | sed 's|.*statuslines/[^/]*/||' | sed 's| .*||')
# Destination filename
DEST_FILE=$(echo "$COPY_CMD" | sed 's|.* ||' | sed "s|~/.claude/||")

if [ -z "$SCRIPT_FILE" ] || [ -z "$DEST_FILE" ]; then
  echo "Error: could not parse script filename from setup.json"
  exit 1
fi

EXT="${DEST_FILE##*.}"
DEST_PATH="$CLAUDE_DIR/$DEST_FILE"

echo "Script file: $SCRIPT_FILE -> $DEST_PATH"

# ── Download the script ─────────────────────────────────────────────
SCRIPT_URL="$REPO_BASE/statuslines/$THEME_DIR/$SCRIPT_FILE"
echo "Downloading script ..."

mkdir -p "$CLAUDE_DIR"

if ! curl -fsSL "$SCRIPT_URL" -o "$DEST_PATH"; then
  echo "Error: failed to download script from:"
  echo "  $SCRIPT_URL"
  exit 1
fi

chmod +x "$DEST_PATH"
echo "Installed script to $DEST_PATH"

# ── Parse the statusLine command from setup.json ────────────────────
# Extract the command value from settings_snippet.statusLine.command
STATUS_CMD=$(grep '"command"' "$SETUP_TMP" | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' | sed 's/".*//')

if [ -z "$STATUS_CMD" ]; then
  # Fallback: build command from extension
  case "$EXT" in
    sh)  STATUS_CMD="$DEST_PATH" ;;
    js)  STATUS_CMD="node $DEST_PATH" ;;
    py)  STATUS_CMD="python3 $DEST_PATH" ;;
    *)   STATUS_CMD="$DEST_PATH" ;;
  esac
  # Replace $HOME with ~
  STATUS_CMD=$(echo "$STATUS_CMD" | sed "s|$HOME|~|g")
fi

echo "Status command: $STATUS_CMD"

# ── Merge into settings.json ────────────────────────────────────────
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

merge_settings() {
  local cmd="$1"
  local settings="$2"

  # Build the new statusLine JSON snippet
  local snippet="{\"statusLine\":{\"type\":\"command\",\"command\":\"$cmd\"}}"

  if command -v jq >/dev/null 2>&1; then
    # jq available — proper merge
    if [ -f "$settings" ] && [ -s "$settings" ]; then
      local tmp
      tmp=$(mktemp)
      jq --arg cmd "$cmd" '.statusLine = {"type": "command", "command": $cmd}' "$settings" > "$tmp"
      mv "$tmp" "$settings"
    else
      echo "$snippet" | jq '.' > "$settings"
    fi
  elif command -v python3 >/dev/null 2>&1; then
    # python3 fallback
    python3 -c "
import json, os, sys
path = '$settings'
cmd = '$cmd'
data = {}
if os.path.isfile(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
data['statusLine'] = {'type': 'command', 'command': cmd}
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  else
    # Last resort: neither jq nor python3 available
    if [ -f "$settings" ] && [ -s "$settings" ]; then
      echo "Warning: neither jq nor python3 found. Cannot safely merge settings."
      echo "Please manually add the following to $settings:"
      echo ""
      echo "  \"statusLine\": {"
      echo "    \"type\": \"command\","
      echo "    \"command\": \"$cmd\""
      echo "  }"
      return 1
    else
      printf '{\n  "statusLine": {\n    "type": "command",\n    "command": "%s"\n  }\n}\n' "$cmd" > "$settings"
    fi
  fi
}

if merge_settings "$STATUS_CMD" "$SETTINGS_FILE"; then
  echo "Updated $SETTINGS_FILE"
else
  echo ""
  echo "Settings file was NOT updated — please update it manually."
fi

echo ""
echo "Done! Theme '$THEME_DIR' is now active."
echo "Restart Claude Code or open a new session to see it."
