#!/bin/bash
# plain-statusline — zero ANSI colors, pure plain text, pipe-friendly
# Shows: model | context% | $cost | duration | git-branch
# Works in log files, CI output, non-color terminals, or when piped
# Requires: jq, bc, git (optional)

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
GIT_PART=""
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_PART=" | ${BRANCH}"
  fi
fi

OUT="${MODEL} | ${USED}% | \$${COST_FMT} | ${DUR}${GIT_PART}"

printf "%s\n" "$OUT"
