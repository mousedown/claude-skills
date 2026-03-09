#!/bin/bash
# time-machine statusline — timestamp-centric, useful for long sessions
# Shows: ◷ wall-clock  model  context-bar%  duration  $/min  lines/min  git-branch
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ───────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/Claude //')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Wall-clock time ─────────────────────────────────────────────────
WALL_TIME=$(date +"%H:%M")

# ── Duration display ────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  H=$((DURATION_S / 3600))
  M=$((DURATION_S % 3600 / 60))
  S=$((DURATION_S % 60))
  DUR_DISPLAY="${H}h${M}m${S}s"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  M=$((DURATION_S / 60))
  S=$((DURATION_S % 60))
  DUR_DISPLAY="${M}m${S}s"
else
  DUR_DISPLAY="${DURATION_S}s"
fi

# ── Cost per minute ─────────────────────────────────────────────────
COST_PER_MIN="—"
DURATION_MIN=$(echo "scale=4; $DURATION_MS / 60000" | bc 2>/dev/null || echo 0)
if [ "$(echo "$DURATION_MIN > 0" | bc 2>/dev/null)" = "1" ]; then
  COST_PER_MIN_RAW=$(echo "scale=4; $COST / $DURATION_MIN" | bc 2>/dev/null || echo "0")
  COST_PER_MIN=$(printf "%.3f" "$COST_PER_MIN_RAW" 2>/dev/null || echo "0.000")
  COST_PER_MIN="\$${COST_PER_MIN}/min"
fi

# ── Lines per minute ────────────────────────────────────────────────
LINES_PER_MIN=""
if [ "$DURATION_S" -gt 0 ] 2>/dev/null && [ "$LINES_ADD" -gt 0 ] 2>/dev/null; then
  LPM=$(echo "scale=0; $LINES_ADD * 60 / $DURATION_S" | bc 2>/dev/null || echo 0)
  if [ "$LPM" -gt 0 ] 2>/dev/null; then
    LINES_PER_MIN="+${LPM} ln/min"
  fi
fi

# ── Context progress bar ────────────────────────────────────────────
FILLED=$(echo "$USED * 10 / 100" | bc 2>/dev/null || echo 0)
BAR=""
for i in $(seq 1 10); do
  if [ "$i" -le "$FILLED" ]; then BAR="${BAR}▓"; else BAR="${BAR}░"; fi
done

# ── Context color ───────────────────────────────────────────────────
if [ "$USED" -ge 90 ]; then
  CTX_COLOR="\033[1;31m"
elif [ "$USED" -ge 70 ]; then
  CTX_COLOR="\033[33m"
else
  CTX_COLOR="\033[32m"
fi

# ── Git branch ──────────────────────────────────────────────────────
GIT_BRANCH=""
if [ -n "$CWD" ]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# ── Colors ──────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
RST="\033[0m"

# ── Build output ────────────────────────────────────────────────────
OUT="${CYAN}◷ ${WALL_TIME}${RST}  ${BOLD}${MODEL}${RST}  ${CTX_COLOR}${BAR} ${USED}%${RST}  ${BOLD}${DUR_DISPLAY}${RST}"

if [ "$COST_PER_MIN" != "—" ]; then
  OUT="${OUT}  ${MAGENTA}${COST_PER_MIN}${RST}"
fi

if [ -n "$LINES_PER_MIN" ]; then
  OUT="${OUT}  ${DIM}${LINES_PER_MIN}${RST}"
fi

if [ -n "$GIT_BRANCH" ]; then
  OUT="${OUT}  ${CYAN}${GIT_BRANCH}${RST}"
fi

printf "%b" "$OUT"
