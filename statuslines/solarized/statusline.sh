#!/bin/bash
# solarized statusline — Solarized Dark color scheme
# Classic Ethan Schoonover Solarized palette: warm amber/cyan on cool deep teal-black
# Separators: ▸ (right-pointing bullet) — distinct from all other statuslines
# Aesthetic: balanced density, professional warmth, familiar to Solarized users
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

# ── Duration ───────────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Context bar: ● filled / ○ empty (8 segments) ──────────────────
FILLED=$(echo "$USED * 8 / 100" | bc 2>/dev/null || echo 0)
[ "$FILLED" -gt 8 ] && FILLED=8
[ "$FILLED" -lt 0 ] && FILLED=0
EMPTY=$(( 8 - FILLED ))

BAR=""
i=0
while [ $i -lt "$FILLED" ]; do
  BAR="${BAR}●"
  i=$(( i + 1 ))
done
i=0
while [ $i -lt "$EMPTY" ]; do
  BAR="${BAR}○"
  i=$(( i + 1 ))
done

# ── Git branch ─────────────────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$BRANCH" ] && GIT_PART="$BRANCH"
fi

# ── Solarized Dark palette (256-color approximations) ──────────────
# Reference: https://ethanschoonover.com/solarized/
SOL_YELLOW="\033[38;5;136m"   # #b58900 — amber yellow — model name
SOL_ORANGE="\033[38;5;130m"   # #cb4b16 — burnt orange — cost
SOL_RED="\033[38;5;160m"      # #dc322f — red — critical context
SOL_MAGENTA="\033[38;5;125m"  # #d33682 — magenta — warning context
SOL_VIOLET="\033[38;5;61m"    # #6c71c4 — violet — lines changed
SOL_BLUE="\033[38;5;32m"      # #268bd2 — blue — separators
SOL_CYAN="\033[38;5;37m"      # #2aa198 — teal cyan — git branch
SOL_GREEN="\033[38;5;64m"     # #859900 — olive green — duration
SOL_BASE01="\033[38;5;240m"   # #586e75 — secondary text
RST="\033[0m"
DIM="\033[2m"

SEP=" ${SOL_BLUE}▸${RST} "

# ── Context alert color (Solarized semantic progression) ──────────
if [ "$USED" -ge 85 ] 2>/dev/null; then
  CTX_COLOR="$SOL_RED"
elif [ "$USED" -ge 65 ] 2>/dev/null; then
  CTX_COLOR="$SOL_MAGENTA"
else
  CTX_COLOR="$SOL_CYAN"
fi

# ── Lines changed (optional) ───────────────────────────────────────
LINES_PART=""
if [ "$LINES_ADD" -gt 0 ] 2>/dev/null || [ "$LINES_DEL" -gt 0 ] 2>/dev/null; then
  LINES_PART="${SEP}${SOL_GREEN}+${LINES_ADD}${RST} ${SOL_ORANGE}-${LINES_DEL}${RST}"
fi

# ── Assemble ───────────────────────────────────────────────────────
OUT="${SOL_YELLOW}${MODEL}${RST}${SEP}${CTX_COLOR}${BAR} ${USED}%${RST}${SEP}${SOL_ORANGE}\$${COST_FMT}${RST}${SEP}${SOL_GREEN}${DUR}${RST}${LINES_PART}"

if [ -n "$GIT_PART" ]; then
  OUT="${OUT}${SEP}${SOL_CYAN}${GIT_PART}${RST}"
fi

printf "%b" "$OUT"
