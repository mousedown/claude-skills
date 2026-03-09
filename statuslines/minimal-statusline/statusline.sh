#!/bin/bash
# minimal-statusline — monochrome with dim separators
# Shows: model │ context% │ $cost │ git-branch
# Color used only for context warnings; everything else is dim
# Requires: jq, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/Claude //')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
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

# ── Git branch ─────────────────────────────────────────────────────
GIT_BRANCH=""
if [ -n "$CWD" ]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# ── Context color (alert only — stays dim until 70%) ───────────────
if [ "$USED" -ge 90 ]; then
  CTX_COLOR="\033[1;31m"   # bold red
elif [ "$USED" -ge 75 ]; then
  CTX_COLOR="\033[33m"     # amber
else
  CTX_COLOR="\033[2m"      # dim (same as everything else)
fi

# ── Build output ───────────────────────────────────────────────────
DIM="\033[2m"
RST="\033[0m"
SEP="${DIM} │ ${RST}"

OUT="${DIM}${MODEL}${RST}${SEP}${CTX_COLOR}${USED}%${RST}${SEP}${DIM}\$${COST_FMT}${RST}${SEP}${DIM}${DUR}${RST}"

if [ -n "$GIT_BRANCH" ]; then
  OUT="${OUT}${SEP}${DIM}${GIT_BRANCH}${RST}"
fi

printf "%b" "$OUT"
