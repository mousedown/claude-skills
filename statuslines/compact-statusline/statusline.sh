#!/bin/bash
# compact-statusline — ultra-compact, 3 key fields, no decoration
# Shows: context% · $cost · git-branch
# For developers who find statuslines distracting
# Requires: jq, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Format cost (2 decimals for compactness) ───────────────────────
COST_FMT=$(printf "%.2f" "$COST" 2>/dev/null || echo "0.00")

# ── Context field with alert color ────────────────────────────────
if [ "$USED" -ge 85 ]; then
  CTX="\033[31m${USED}%\033[0m"
elif [ "$USED" -ge 65 ]; then
  CTX="\033[33m${USED}%\033[0m"
else
  CTX="${USED}%"
fi

# ── Git branch ─────────────────────────────────────────────────────
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_PART=" · ${BRANCH}"
  fi
fi

printf "%b" "${CTX} · \$${COST_FMT}${GIT_PART}"
