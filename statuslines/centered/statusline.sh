#!/bin/bash
# centered-statusline — all content centered in the terminal width
#
# Layout:   ·········  ◆ model  ▓▓▓▓░░░░░░ 42%  $1.234  12m30s  ⎇ main  ·········
#
# Measures the visible content width and adds equal padding on both sides
# so the statusline sits in the middle of the screen. Looks great on wide
# terminals and degrades gracefully on narrow ones.
#
# Install:
#   cp statusline.sh ~/.claude/statusline.sh
#   chmod +x ~/.claude/statusline.sh
# Add to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#
# Requirements: jq, bc, tput, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/^[Cc]laude[- ]*//')
[ -z "$MODEL" ] && MODEL="Claude"
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Format cost ────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Duration ───────────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m$((DURATION_S % 60))s"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

# ── Progress bar (10 chars) ────────────────────────────────────────
FILLED=$(echo "$USED * 10 / 100" | bc 2>/dev/null || echo 0)
[ "$FILLED" -gt 10 ] && FILLED=10
[ "$FILLED" -lt 0 ]  && FILLED=0
EMPTY=$(( 10 - FILLED ))

BAR=""
i=0; while [ $i -lt "$FILLED" ]; do BAR="${BAR}▓"; i=$(( i + 1 )); done
i=0; while [ $i -lt "$EMPTY"  ]; do BAR="${BAR}░"; i=$(( i + 1 )); done

# ── Git branch ─────────────────────────────────────────────────────
GIT_PLAIN=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_PLAIN="  ⎇ ${BRANCH}"
  fi
fi

# ── Build plain (no ANSI) version for length measurement ───────────
PLAIN="◆ ${MODEL}  ${BAR} ${USED}%  \$${COST_FMT}  ${DUR}${GIT_PLAIN}"

# Count visible characters (strip ANSI; also strip any residual escapes)
VIS_LEN=$(printf "%s" "$PLAIN" | wc -m 2>/dev/null || printf "%s" "$PLAIN" | wc -c)
# Trim leading whitespace from wc output
VIS_LEN=$(echo "$VIS_LEN" | tr -d ' ')

# ── Terminal width ─────────────────────────────────────────────────
TERM_W=$(tput cols 2>/dev/null || echo 120)

# ── Compute left padding ───────────────────────────────────────────
PAD=$(( (TERM_W - VIS_LEN) / 2 ))
[ "$PAD" -lt 0 ] && PAD=0

# ── Context colors ─────────────────────────────────────────────────
if [ "$USED" -ge 85 ]; then
  CTX_C="\033[31m"
  BAR_C="\033[31m"
elif [ "$USED" -ge 65 ]; then
  CTX_C="\033[33m"
  BAR_C="\033[33m"
else
  CTX_C="\033[32m"
  BAR_C="\033[32m"
fi
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
MAGENTA="\033[35m"

# ── Colored content ────────────────────────────────────────────────
COLORED="${BOLD}◆${RST} ${BOLD}${CYAN}${MODEL}${RST}  ${BAR_C}${BAR}${RST} ${CTX_C}${USED}%${RST}  ${MAGENTA}\$${COST_FMT}${RST}  ${DIM}${DUR}${RST}${GIT_PLAIN:+  ${CYAN}${GIT_PLAIN## }${RST}}"

# Handle GIT_PLAIN with color (re-build if non-empty)
if [ -n "$GIT_PLAIN" ]; then
  GIT_COLORED="  ${CYAN}⎇ ${BRANCH}${RST}"
  COLORED="${BOLD}◆${RST} ${BOLD}${CYAN}${MODEL}${RST}  ${BAR_C}${BAR}${RST} ${CTX_C}${USED}%${RST}  ${MAGENTA}\$${COST_FMT}${RST}  ${DIM}${DUR}${RST}${GIT_COLORED}"
fi

# ── Output centered ────────────────────────────────────────────────
printf "%${PAD}s" ""
printf "%b" "$COLORED"
