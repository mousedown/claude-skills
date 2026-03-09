#!/bin/bash
# lcars statusline — LCARS sci-fi display aesthetic
# Inspired by Star Trek LCARS interface panels:
#   - ▐ UNIT ▌ orange bracket panels for identity
#   - UPPERCASE field labels in muted color
#   - ▪▫ filled/hollow squares for context bar
#   - ALL-CAPS values, │ separators between fields
#   - Alert prefix activates at high context usage
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL_RAW=$(echo "$INPUT" | jq -r '.model.display_name // "CLAUDE"')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Uppercase model (strip "claude-" prefix) ────────────────────────
MODEL=$(echo "$MODEL_RAW" \
  | sed 's/^[Cc]laude[- ]*//' \
  | sed 's/-[0-9][0-9a-z.-]*$//' \
  | tr '[:lower:]' '[:upper:]')
[ -z "$MODEL" ] && MODEL="CLAUDE"

# ── Duration (UPPERCASE units) ─────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  DUR="${DURATION_S%% *}"
  DUR="$((DURATION_S / 3600))H$((DURATION_S % 3600 / 60))M"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR="$((DURATION_S / 60))M$((DURATION_S % 60))S"
else
  DUR="${DURATION_S}S"
fi

COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Git branch (uppercase) ─────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '[:lower:]' '[:upper:]')
  [ -n "$BRANCH" ] && GIT_PART="$BRANCH"
fi

# ── LCARS color palette ────────────────────────────────────────────
# Signature LCARS colors: orange, gold, lavender, cyan, peach, red
LCARS_ORANGE="\033[38;5;208m"   # ░ signature LCARS orange — brackets & identity
LCARS_GOLD="\033[38;5;220m"     # ░ amber gold — cost values
LCARS_LAVENDER="\033[38;5;183m" # ░ soft lavender — time
LCARS_CYAN="\033[38;5;81m"      # ░ LCARS blue-cyan — git, lines added
LCARS_PEACH="\033[38;5;218m"    # ░ peach — lines removed
LCARS_RED="\033[38;5;196m"      # ░ alert red — critical context
LCARS_AMBER="\033[38;5;214m"    # ░ amber — warning context
LCARS_LABEL="\033[38;5;245m"    # ░ muted gray — field labels
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# ── Context bar: ▪ filled / ▫ hollow (8 segments) ─────────────────
FILLED=$(echo "$USED * 8 / 100" | bc 2>/dev/null || echo 0)
[ "$FILLED" -gt 8 ] && FILLED=8
[ "$FILLED" -lt 0 ] && FILLED=0
EMPTY=$(( 8 - FILLED ))

BAR=""
i=0
while [ $i -lt "$FILLED" ]; do
  BAR="${BAR}▪"
  i=$(( i + 1 ))
done
i=0
while [ $i -lt "$EMPTY" ]; do
  BAR="${BAR}▫"
  i=$(( i + 1 ))
done

# ── Context color by level ─────────────────────────────────────────
if [ "$USED" -ge 85 ] 2>/dev/null; then
  CTX_COLOR="$LCARS_RED"
  ALERT=" ${BOLD}${LCARS_RED}◀ ALERT ▶${RST}"
elif [ "$USED" -ge 65 ] 2>/dev/null; then
  CTX_COLOR="$LCARS_AMBER"
  ALERT=""
else
  CTX_COLOR="$LCARS_LAVENDER"
  ALERT=""
fi

# ── Separator ──────────────────────────────────────────────────────
PIPE=" ${DIM}│${RST} "

# ── Assemble in LCARS panel style ─────────────────────────────────
# Identity: ▐ MODEL ▌ — orange bracket panel
UNIT="${LCARS_ORANGE}▐ ${BOLD}${MODEL}${RST}${LCARS_ORANGE} ▌${RST}"

# Context field
CTX="${LCARS_LABEL}CTX${RST} ${CTX_COLOR}${BAR} ${USED}%${RST}"

# Cost field
COST_FIELD="${LCARS_LABEL}COST${RST} ${LCARS_GOLD}\$${COST_FMT}${RST}"

# Time field
TIME_FIELD="${LCARS_LABEL}TIME${RST} ${LCARS_LAVENDER}${DUR}${RST}"

OUT="${UNIT}${PIPE}${CTX}${PIPE}${COST_FIELD}${PIPE}${TIME_FIELD}"

# Lines changed (optional)
if [ "$LINES_ADD" -gt 0 ] 2>/dev/null || [ "$LINES_DEL" -gt 0 ] 2>/dev/null; then
  OUT="${OUT}${PIPE}${LCARS_LABEL}DIFF${RST} ${LCARS_CYAN}+${LINES_ADD}${RST} ${LCARS_PEACH}-${LINES_DEL}${RST}"
fi

# Git field (optional)
if [ -n "$GIT_PART" ]; then
  OUT="${OUT}${PIPE}${LCARS_LABEL}REF${RST} ${LCARS_CYAN}${GIT_PART}${RST}"
fi

# Alert prefix (high context only)
if [ -n "$ALERT" ]; then
  OUT="${ALERT}  ${OUT}"
fi

printf "%b" "$OUT"
