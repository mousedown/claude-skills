#!/bin/bash
# retro-terminal statusline — 80s BBS/DOS terminal aesthetic
# Philosophy: bracket notation, block chars, uppercase identifiers.
# Phosphor-green on black. Always on.
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "CLAUDE"')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Uppercase model name ───────────────────────────────────────────
MODEL_UPPER=$(echo "$MODEL" | tr '[:lower:]' '[:upper:]')

# ── Format cost ────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Format duration ────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
DURATION_M=$(echo "$DURATION_S / 60" | bc 2>/dev/null || echo 0)
DURATION_REM=$(echo "$DURATION_S % 60" | bc 2>/dev/null || echo 0)
if [ "$DURATION_M" -ge 60 ] 2>/dev/null; then
  DURATION_H=$(echo "$DURATION_M / 60" | bc)
  DURATION_M=$(echo "$DURATION_M % 60" | bc)
  DUR_FMT="${DURATION_H}h${DURATION_M}m${DURATION_REM}s"
elif [ "$DURATION_M" -gt 0 ] 2>/dev/null; then
  DUR_FMT="${DURATION_M}m${DURATION_REM}s"
else
  DUR_FMT="${DURATION_S}s"
fi

# ── Context block bar (10 chars wide) ─────────────────────────────
BAR_WIDTH=10
FILLED=$(echo "$USED * $BAR_WIDTH / 100" | bc 2>/dev/null || echo 0)
[ "$FILLED" -gt "$BAR_WIDTH" ] 2>/dev/null && FILLED=$BAR_WIDTH
[ "$FILLED" -lt 0 ] 2>/dev/null && FILLED=0
EMPTY=$(( BAR_WIDTH - FILLED ))

BAR=""
i=0
while [ $i -lt "$FILLED" ]; do
  BAR="${BAR}█"
  i=$(( i + 1 ))
done
i=0
while [ $i -lt "$EMPTY" ]; do
  BAR="${BAR}░"
  i=$(( i + 1 ))
done

# ── Git branch ─────────────────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    BRANCH_UPPER=$(echo "$BRANCH" | tr '[:lower:]' '[:upper:]')
    GIT_PART=" [${BRANCH_UPPER}]"
  fi
fi

# ── Lines changed (only if > 0) ────────────────────────────────────
LINES_PART=""
if [ "$LINES_ADDED" -gt 0 ] 2>/dev/null || [ "$LINES_REMOVED" -gt 0 ] 2>/dev/null; then
  LINES_PART=" [+${LINES_ADDED}/-${LINES_REMOVED}]"
fi

# ── ANSI colors ────────────────────────────────────────────────────
DIM="\033[2m"
BRIGHT_GREEN="\033[1;32m"
GREEN="\033[32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# ── Alert level colors ─────────────────────────────────────────────
if [ "$USED" -ge 85 ] 2>/dev/null; then
  BRACKET_COLOR="$RED"
elif [ "$USED" -ge 65 ] 2>/dev/null; then
  BRACKET_COLOR="$YELLOW"
else
  BRACKET_COLOR="$GREEN"
fi

# ── Assemble output ────────────────────────────────────────────────
PREFIX="${DIM}>${RESET} "
MODEL_PART="${BRIGHT_GREEN}[${MODEL_UPPER}]${RESET}"
CTX_PART=" ${BRACKET_COLOR}[CTX:${BAR} ${USED}%]${RESET}"
COST_PART=" ${GREEN}[\$${COST_FMT}]${RESET}"
DUR_PART=" ${GREEN}[${DUR_FMT}]${RESET}"

OUT="${PREFIX}${MODEL_PART}${CTX_PART}${COST_PART}${DUR_PART}${LINES_PART}${GIT_PART}"

printf "%b" "$OUT"
