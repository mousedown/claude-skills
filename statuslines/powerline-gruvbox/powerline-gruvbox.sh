#!/bin/zsh
# Powerline Gruvbox — Claude Code statusline
# Warm earth tones with floating diamond/pill-shaped segments
# Aesthetic: retro-warm, cozy, readable — Gruvbox dark palette
#
# Requires: jq, bc, git
# Requires Nerd Fonts for rounded pill separators (  )
#
# Install:
#   cp powerline-gruvbox.sh ~/.claude/statusline.sh
#   chmod +x ~/.claude/statusline.sh
# Add to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }

INPUT=$(cat)

# Rounded pill separators (Nerd Fonts)
PILL_L=$'\ue0b6'  # left rounded cap  ❨
PILL_R=$'\ue0b4'  # right rounded cap ❩

RST=$'\033[0m'
_fg() { printf '\033[38;5;%sm' "$1"; }
_bg() { printf '\033[48;5;%sm' "$1"; }
_bold=$'\033[1m'

# Draw a floating pill: ❨ CONTENT ❩ on terminal bg
# Usage: pill <bg_color> <fg_color> <text>
pill() {
  local bg_c="$1" fg_c="$2" text="$3"
  printf '%s%s%s%s%s%s%s%s%s' \
    "$RST" "$(_fg $bg_c)" "$PILL_L" \
    "$(_bg $bg_c)" "$(_fg $fg_c)" "$_bold" " ${text} " \
    "$RST" "$(_fg $bg_c)" "$PILL_R" "$RST"
}

# ── Gruvbox dark palette (256-color approximations) ────────────────────────────
GB_BG0_H=234   # darkest bg
GB_BG1=237     # dark bg
GB_BG2=239     # medium bg
GB_BG3=241     # lighter bg
GB_FG=223      # light warm white text
GB_RED=167     # muted red
GB_GREEN=142   # muted sage green
GB_YELLOW=214  # warm yellow/gold
GB_BLUE=109    # muted steel blue
GB_PURPLE=132  # muted purple/mauve
GB_AQUA=108    # muted aqua/teal
GB_ORANGE=166  # burnt orange

# ── Parse input ────────────────────────────────────────────────────────────────
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
USED=${USED%%.*}
USED=${USED:-0}

MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
MODEL=${MODEL#Claude }

SESSION_COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

# ── Duration ───────────────────────────────────────────────────────────────────
DURATION_S=$(( DURATION_MS / 1000 ))
if (( DURATION_S >= 3600 )); then
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif (( DURATION_S >= 60 )); then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

COST_FMT=$(printf "%.3f" "${SESSION_COST:-0}")

# ── Git ────────────────────────────────────────────────────────────────────────
GIT_BRANCH="" STAGED=0 MODIFIED=0
if [[ -n "$CWD" ]]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$GIT_BRANCH" ]]; then
    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null || echo 0)
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null || echo 0)
  fi
fi

# ── Context bar (8 blocks) ─────────────────────────────────────────────────────
FILLED=$(( USED * 8 / 100 ))
(( FILLED > 8 )) && FILLED=8
CTX_BAR=""
for i in 1 2 3 4 5 6 7 8; do
  if (( i <= FILLED )); then CTX_BAR="${CTX_BAR}▓"; else CTX_BAR="${CTX_BAR}░"; fi
done

# Context pill color
if (( USED >= 90 )); then
  CTX_BG=$GB_RED; CTX_FG=$GB_FG
elif (( USED >= 70 )); then
  CTX_BG=$GB_ORANGE; CTX_FG=$GB_BG0_H
else
  CTX_BG=$GB_GREEN; CTX_FG=$GB_BG0_H
fi

# ── Assemble pills (space-separated floating segments) ─────────────────────────
OUT=""

# Pill 1: Model (aqua/teal pill)
OUT="${OUT}$(pill $GB_AQUA $GB_BG0_H "◈ ${MODEL}")"

# Pill 2: Git (yellow pill, only when in a repo)
if [[ -n "$GIT_BRANCH" ]]; then
  GIT_TEXT=" ${GIT_BRANCH}"
  (( STAGED > 0 )) && GIT_TEXT="${GIT_TEXT} +${STAGED}"
  (( MODIFIED > 0 )) && GIT_TEXT="${GIT_TEXT} ~${MODIFIED}"
  OUT="${OUT} $(pill $GB_YELLOW $GB_BG0_H "${GIT_TEXT}")"
fi

# Pill 3: Context (color-coded pill)
OUT="${OUT} $(pill $CTX_BG $CTX_FG "${CTX_BAR} ${USED}%%")"

# Pill 4: Cost (purple pill)
OUT="${OUT} $(pill $GB_PURPLE $GB_FG "\$${COST_FMT}")"

# Pill 5: Duration + lines (muted bg2 pill)
DUR_TEXT="${DUR}"
if (( LINES_ADD > 0 || LINES_DEL > 0 )); then
  DUR_TEXT="${DUR_TEXT}  +${LINES_ADD}/-${LINES_DEL}"
fi
OUT="${OUT} $(pill $GB_BG2 $GB_FG "${DUR_TEXT}")"

printf '%s\n' "$OUT"
