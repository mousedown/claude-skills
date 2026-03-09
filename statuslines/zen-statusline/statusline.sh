#!/bin/bash
# zen-statusline — nature/zen theme, always-on display
# Philosophy: calm, unhurried, soft. Shows model, context as water level,
# mood emoji, cost, duration, and git branch.
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Format cost ────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Format duration ────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  HOURS=$(echo "$DURATION_S / 3600" | bc)
  MINS=$(echo "($DURATION_S % 3600) / 60" | bc)
  DUR_FMT="${HOURS}h${MINS}m"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  MINS=$(echo "$DURATION_S / 60" | bc)
  DUR_FMT="${MINS}m"
else
  DUR_FMT="${DURATION_S}s"
fi

# ── Context bar (10 chars wide) ────────────────────────────────────
BAR_WIDTH=10
FILLED=$(echo "$USED * $BAR_WIDTH / 100" | bc 2>/dev/null || echo 0)
# Clamp to bar width
[ "$FILLED" -gt "$BAR_WIDTH" ] 2>/dev/null && FILLED=$BAR_WIDTH
[ "$FILLED" -lt 0 ] 2>/dev/null && FILLED=0
EMPTY=$(( BAR_WIDTH - FILLED ))

BAR=""
i=0
while [ $i -lt "$FILLED" ]; do
  BAR="${BAR}〰"
  i=$(( i + 1 ))
done
i=0
while [ $i -lt "$EMPTY" ]; do
  BAR="${BAR}·"
  i=$(( i + 1 ))
done

# ── Mood indicator ─────────────────────────────────────────────────
if [ "$USED" -ge 85 ] 2>/dev/null; then
  MOOD="🍂"
elif [ "$USED" -ge 65 ] 2>/dev/null; then
  MOOD="🌤"
else
  MOOD="🌿"
fi

# ── Git branch ─────────────────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_PART="  🌊 ${BRANCH}"
  fi
fi

# ── ANSI colors ────────────────────────────────────────────────────
DIM="\033[2m"
GREEN="\033[32m"
BLUE="\033[34m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ── Context color based on level ───────────────────────────────────
if [ "$USED" -ge 85 ] 2>/dev/null; then
  CTX_COLOR="$RED"
elif [ "$USED" -ge 65 ] 2>/dev/null; then
  CTX_COLOR="$YELLOW"
else
  CTX_COLOR="$CYAN"
fi

# ── Assemble output ────────────────────────────────────────────────
OUT="${MOOD}  ${DIM}${MODEL}${RESET}  ${CTX_COLOR}${BAR}${RESET}  ${USED}%  🌰 \$${COST_FMT}  ⏳ ${DUR_FMT}${GIT_PART}"

printf "%b" "$OUT"
