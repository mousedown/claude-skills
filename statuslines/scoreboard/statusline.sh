#!/bin/bash
# scoreboard-statusline — sports scoreboard / ticker aesthetic
# Everything is a score or stat: model as team, context as hearts, lines as score
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Model: shorten to team-name style (e.g. "SONNET") ──────────────
TEAM=$(echo "$MODEL" \
  | sed 's/^[Cc]laude[- ]*//' \
  | sed 's/[- ][0-9].*//' \
  | tr '[:lower:]' '[:upper:]')
[ -z "$TEAM" ] && TEAM="CLAUDE"

# ── Cost format ────────────────────────────────────────────────────
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

# ── Context hearts: filled ❤ = remaining, empty ♡ = used ──────────
# Hearts represent context remaining, so full bar = lots of space left
REMAINING=$(( 100 - USED ))
FILLED=$(( REMAINING * 10 / 100 ))
[ "$FILLED" -gt 10 ] && FILLED=10
[ "$FILLED" -lt 0 ] && FILLED=0

HEARTS=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$i" -le "$FILLED" ]; then
    HEARTS="${HEARTS}❤"
  else
    HEARTS="${HEARTS}♡"
  fi
done

# Context color based on remaining (few hearts = danger)
if [ "$REMAINING" -le 10 ]; then
  CTX_COLOR="\033[31m"    # red — critical
elif [ "$REMAINING" -le 30 ]; then
  CTX_COLOR="\033[33m"    # yellow — warning
else
  CTX_COLOR="\033[32m"    # green — healthy
fi

# ── Lines score ────────────────────────────────────────────────────
TOTAL_LINES=$(( LINES_ADD + LINES_DEL ))

# ── Git field (stadium) ────────────────────────────────────────────
FIELD_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    FIELD_PART="  \033[1mFIELD:\033[0m ${BRANCH}"
  fi
fi

# ── Assemble scoreboard ────────────────────────────────────────────
BOLD="\033[1m"
RST="\033[0m"

OUT=" ${BOLD}${TEAM}${RST}  ${CTX_COLOR}${HEARTS}${RST}  \033[1mCTX:\033[0m ${USED}%  \033[1mCOST:\033[0m \$${COST_FMT}  \033[1mTIME:\033[0m ${DUR}  \033[1mLINES:\033[0m ${TOTAL_LINES}${FIELD_PART}"

printf "%b" "$OUT"
