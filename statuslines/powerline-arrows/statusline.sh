#!/bin/bash
# powerline-arrows statusline — Powerline/Starship-inspired with ❯ separators
# Shows: model ❯ context-bar % ❯ $cost ❯ duration ❯ lines ❯ git-branch ●staged ●modified
# Requires: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/Claude //')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Format cost ─────────────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── Duration ────────────────────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc 2>/dev/null || echo 0)
if [ "$DURATION_S" -ge 3600 ] 2>/dev/null; then
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m$((DURATION_S % 60))s"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

# ── Context bar (10 segments: ━ filled, ─ empty) ────────────────────────────
FILLED=$(echo "$USED / 10" | bc 2>/dev/null || echo 0)
BAR=""
for i in $(seq 1 10); do
  if [ "$i" -le "$FILLED" ]; then
    BAR="${BAR}━"
  else
    BAR="${BAR}─"
  fi
done

# ── Context color ───────────────────────────────────────────────────────────
if [ "$USED" -ge 90 ]; then
  CTX_COLOR="\033[31m"       # red
elif [ "$USED" -ge 70 ]; then
  CTX_COLOR="\033[33m"       # yellow/amber
else
  CTX_COLOR="\033[32m"       # green
fi

# ── Git info ────────────────────────────────────────────────────────────────
GIT_BRANCH=""
STAGED=0
MODIFIED=0
if [ -n "$CWD" ]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$GIT_BRANCH" ]; then
    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null | awk 'NR==1{print $1+0}')
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null | awk 'NR==1{print $1+0}')
    [ -z "$STAGED" ] && STAGED=0
    [ -z "$MODIFIED" ] && MODIFIED=0
  fi
fi

# ── ANSI colors ─────────────────────────────────────────────────────────────
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
PURPLE="\033[35m"
GRAY="\033[90m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"

SEP="${DIM}❯${RST}"

# ── Build output ─────────────────────────────────────────────────────────────

# Model — bold cyan
OUT="${BOLD}${CYAN}${MODEL}${RST}"

# Context bar + percentage
OUT="${OUT} ${SEP} ${CTX_COLOR}${BAR}${RST}  ${CTX_COLOR}${USED}%${RST}"

# Cost — purple
OUT="${OUT} ${SEP} ${PURPLE}\$${COST_FMT}${RST}"

# Duration — gray
OUT="${OUT} ${SEP} ${GRAY}${DUR}${RST}"

# Lines added/removed — only if non-zero
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_INFO=""
  if [ "$LINES_ADD" -gt 0 ]; then
    LINES_INFO="${GREEN}+${LINES_ADD}${RST}"
  fi
  if [ "$LINES_DEL" -gt 0 ]; then
    [ -n "$LINES_INFO" ] && LINES_INFO="${LINES_INFO} "
    LINES_INFO="${LINES_INFO}${RED}-${LINES_DEL}${RST}"
  fi
  OUT="${OUT} ${SEP} ${LINES_INFO}"
fi

# Git branch — only if in a repo
if [ -n "$GIT_BRANCH" ]; then
  GIT_INFO="${CYAN} ${GIT_BRANCH}${RST}"
  if [ "$STAGED" -gt 0 ]; then
    GIT_INFO="${GIT_INFO} ${GREEN}●${STAGED}${RST}"
  fi
  if [ "$MODIFIED" -gt 0 ]; then
    GIT_INFO="${GIT_INFO} ${YELLOW}●${MODIFIED}${RST}"
  fi
  OUT="${OUT} ${SEP} ${GIT_INFO}"
fi

printf "%b" "$OUT"
