#!/bin/bash
# git-dashboard statusline — git info front and center
# Shows:  branch  ✚staged ✎modified ?untracked ↑ahead ↓behind  │  model  ctx%  $cost
# Falls back to model/context/cost only when not in a git repo
# Requires: jq, bc, git

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/Claude //')
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", int($1+0.5)}')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Format cost ─────────────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")

# ── ANSI colors ─────────────────────────────────────────────────────────────
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
MAGENTA="\033[35m"
GRAY="\033[90m"
WHITE="\033[97m"

# ── Git info ─────────────────────────────────────────────────────────────────
GIT_BRANCH=""
STAGED=0
MODIFIED=0
UNTRACKED=0
AHEAD=0
BEHIND=0
IN_GIT=false

if [ -n "$CWD" ]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$GIT_BRANCH" ]; then
    IN_GIT=true

    # Staged, modified, untracked counts from porcelain output
    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null | awk 'NR==1{print $1+0}')
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null | awk 'NR==1{print $1+0}')
    UNTRACKED=$(echo "$GIT_STATUS" | grep -c "^??" 2>/dev/null | awk 'NR==1{print $1+0}')
    [ -z "$STAGED" ] && STAGED=0
    [ -z "$MODIFIED" ] && MODIFIED=0
    [ -z "$UNTRACKED" ] && UNTRACKED=0

    # Ahead/behind vs upstream
    UPSTREAM=$(git -C "$CWD" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
      AHEAD=$(git -C "$CWD" rev-list --count "${UPSTREAM}..HEAD" 2>/dev/null || echo 0)
      BEHIND=$(git -C "$CWD" rev-list --count "HEAD..${UPSTREAM}" 2>/dev/null || echo 0)
      [ -z "$AHEAD" ] && AHEAD=0
      [ -z "$BEHIND" ] && BEHIND=0
    fi
  fi
fi

# ── Context color ───────────────────────────────────────────────────────────
if [ "$USED" -ge 90 ]; then
  CTX_COLOR="\033[31m"
elif [ "$USED" -ge 70 ]; then
  CTX_COLOR="\033[33m"
else
  CTX_COLOR="\033[90m"
fi

# ── Build output ─────────────────────────────────────────────────────────────
OUT=""

if [ "$IN_GIT" = "true" ]; then
  # Branch — bold, prominent
  OUT="${BOLD}${WHITE} ${GIT_BRANCH}${RST}"

  # Change indicators
  if [ "$STAGED" -gt 0 ]; then
    OUT="${OUT}  ${GREEN}✚${STAGED}${RST}"
  fi
  if [ "$MODIFIED" -gt 0 ]; then
    OUT="${OUT}  ${YELLOW}✎${MODIFIED}${RST}"
  fi
  if [ "$UNTRACKED" -gt 0 ]; then
    OUT="${OUT}  ${GRAY}?${UNTRACKED}${RST}"
  fi

  # Ahead/behind
  if [ "$AHEAD" -gt 0 ]; then
    OUT="${OUT}  ${CYAN}↑${AHEAD}${RST}"
  fi
  if [ "$BEHIND" -gt 0 ]; then
    OUT="${OUT}  ${RED}↓${BEHIND}${RST}"
  fi

  # Divider
  OUT="${OUT}  ${DIM}│${RST}  "
fi

# Secondary info: model (dim), context %, cost
OUT="${OUT}${DIM}${MODEL}${RST}  ${CTX_COLOR}${USED}%${RST}  ${GRAY}\$${COST_FMT}${RST}"

printf "%b" "$OUT"
