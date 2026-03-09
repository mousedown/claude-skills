#!/bin/bash
# emoji-statusline — fun, expressive emoji dashboard
# Shows: 🤖 model  📊 context bar  💵 cost  ⏱ duration  ✏️ lines  🌿 branch
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/Claude //')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Format cost ────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Duration ───────────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

# ── Context bar: 10 segments ───────────────────────────────────────
FILLED=$(( USED * 10 / 100 ))
BAR=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$i" -le "$FILLED" ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
done

# ── Context warning level icon and bar color ───────────────────────
if [ "$USED" -ge 90 ]; then
  CTX_BOOK="📕"
  COLOR_ON="\033[5;31m"   # blinking red
  COLOR_OFF="\033[0m"
elif [ "$USED" -ge 70 ]; then
  CTX_BOOK="📙"
  COLOR_ON="\033[33m"     # yellow
  COLOR_OFF="\033[0m"
else
  CTX_BOOK="📗"
  COLOR_ON="\033[32m"     # green
  COLOR_OFF="\033[0m"
fi

COLORED_BAR="${COLOR_ON}${BAR}${COLOR_OFF}"

# ── Lines changed ──────────────────────────────────────────────────
LINES_PART=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_PART=" ✏️  +${LINES_ADD} -${LINES_DEL}"
fi

# ── Git branch ─────────────────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_PART=" 🌿 ${BRANCH}"
  fi
fi

OUT="🤖 ${MODEL}  ${CTX_BOOK} ${COLORED_BAR} ${USED}%  💵 \$${COST_FMT}  ⏱ ${DUR}${LINES_PART}${GIT_PART}"

printf "%b\n" "$OUT"
