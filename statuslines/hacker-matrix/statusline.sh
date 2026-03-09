#!/bin/bash
# Claude Code Statusline — Hacker Matrix Edition
# Classic phosphor-green terminal aesthetic. Monochrome. No frills.
# Requires: jq, bc, git

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────────────
MODEL_RAW=$(echo "$INPUT" | jq -r '.model.display_name // "claude"')
USED=$(echo "$INPUT"     | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT"     | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT"   | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT"   | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$INPUT"         | jq -r '.cwd // ""')

# ── Colors (phosphor green palette) ───────────────────────────────────────
GREEN="\033[92m"   # bright green  — model name
DIM_GREEN="\033[32m" # regular green — structure / separators
YELLOW="\033[93m"  # warn context
RED="\033[91m"     # crit context
RESET="\033[0m"

SEP="${DIM_GREEN} :: ${RESET}"

# ── Model (lowercase, strip "claude-" prefix, strip trailing version digits) ──
MODEL=$(echo "$MODEL_RAW" \
  | sed 's/^[Cc]laude-\{0,1\}//' \
  | sed 's/-[0-9][0-9a-z.-]*$//' \
  | tr '[:upper:]' '[:lower:]')
[ -z "$MODEL" ] && MODEL="$MODEL_RAW"
MODEL_PART="${GREEN}${MODEL}${RESET}"

# ── Context label ──────────────────────────────────────────────────────────
if [ "$USED" -ge 85 ]; then
  CTX_LABEL="${RED}[CRIT:${USED}%]${RESET}"
elif [ "$USED" -ge 65 ]; then
  CTX_LABEL="${YELLOW}[WARN:${USED}%]${RESET}"
else
  CTX_LABEL="${DIM_GREEN}[ctx:${USED}%]${RESET}"
fi

# ── Cost ───────────────────────────────────────────────────────────────────
COST_FMT=$(printf "%.4f" "$COST" 2>/dev/null || echo "0.0000")
COST_PART="${DIM_GREEN}cost[\$${COST_FMT}]${RESET}"

# ── Duration ──────────────────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  DUR_DISPLAY="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR_DISPLAY="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR_DISPLAY="${DURATION_S}s"
fi
DUR_PART="${DIM_GREEN}t[${DUR_DISPLAY}]${RESET}"

# ── Lines (optional field) ─────────────────────────────────────────────────
LINES_PART=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_PART="${DIM_GREEN}+${LINES_ADD}/-${LINES_DEL}${RESET}"
fi

# ── Git branch ─────────────────────────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_PART="${DIM_GREEN}ref[${BRANCH}]${RESET}"
  fi
fi

# ── Assemble ───────────────────────────────────────────────────────────────
OUT="${DIM_GREEN}//${RESET} ${GREEN}claude.${RESET}${MODEL_PART}${SEP}${CTX_LABEL}${SEP}${COST_PART}${SEP}${DUR_PART}"

if [ -n "$LINES_PART" ]; then
  OUT="${OUT}${SEP}${LINES_PART}"
fi

if [ -n "$GIT_PART" ]; then
  OUT="${OUT}${SEP}${GIT_PART}"
fi

printf "%b" "$OUT"
