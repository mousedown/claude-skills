#!/bin/bash
# two-line statusline — two-row layout for information density without width
#
# Line 1:  ◆ model  ▓▓▓▓░░░░░░ 42%  $1.234  12m30s
# Line 2:  ⎇ main  ✚2  ✎1  ↑1   |   +186 -43
#
# Separates "session vitals" from "work state" into two scannable rows.
# Useful when terminal width is limited or you prefer vertical scanning.
#
# Install:
#   cp statusline.sh ~/.claude/statusline.sh
#   chmod +x ~/.claude/statusline.sh
# Add to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
#
# Requirements: jq, bc, git (optional)

INPUT=$(cat)

# ── Parse ──────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/^[Cc]laude[- ]*//')
[ -z "$MODEL" ] && MODEL="Claude"
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
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m$((DURATION_S % 60))s"
elif [ "$DURATION_S" -ge 60 ] 2>/dev/null; then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

# ── Progress bar (10 chars) ────────────────────────────────────────
FILLED=$(echo "$USED * 10 / 100" | bc 2>/dev/null || echo 0)
[ "$FILLED" -gt 10 ] && FILLED=10
[ "$FILLED" -lt 0 ]  && FILLED=0
EMPTY=$(( 10 - FILLED ))

BAR=""
i=0; while [ $i -lt "$FILLED" ]; do BAR="${BAR}█"; i=$(( i + 1 )); done
i=0; while [ $i -lt "$EMPTY"  ]; do BAR="${BAR}▁"; i=$(( i + 1 )); done

# ── ANSI colors ────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
RST="\033[0m"
CYAN="\033[36m"
MAGENTA="\033[35m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
GRAY="\033[90m"
WHITE="\033[97m"

# ── Context color ──────────────────────────────────────────────────
if [ "$USED" -ge 85 ]; then
  CTX_COLOR="$RED"
elif [ "$USED" -ge 65 ]; then
  CTX_COLOR="$YELLOW"
else
  CTX_COLOR="$GREEN"
fi

# ── LINE 1: session vitals — model, context, cost, time ───────────
LINE1="${BOLD}${CYAN}◆ ${MODEL}${RST}  ${CTX_COLOR}${BAR} ${USED}%${RST}  ${MAGENTA}\$${COST_FMT}${RST}  ${DIM}${DUR}${RST}"

# ── LINE 2: work state — git + lines changed ──────────────────────
L2_PARTS=""

# Git info
if [ -n "$CWD" ]; then
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    L2_PARTS="${CYAN}⎇ ${BRANCH}${RST}"

    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null | awk 'NR==1{print $1+0}')
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null | awk 'NR==1{print $1+0}')
    UNTRACKED=$(echo "$GIT_STATUS" | grep -c "^??" 2>/dev/null | awk 'NR==1{print $1+0}')
    [ -z "$STAGED" ]    && STAGED=0
    [ -z "$MODIFIED" ]  && MODIFIED=0
    [ -z "$UNTRACKED" ] && UNTRACKED=0

    # Ahead/behind
    UPSTREAM=$(git -C "$CWD" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
    AHEAD=0; BEHIND=0
    if [ -n "$UPSTREAM" ]; then
      AHEAD=$(git -C "$CWD" rev-list --count "${UPSTREAM}..HEAD" 2>/dev/null || echo 0)
      BEHIND=$(git -C "$CWD" rev-list --count "HEAD..${UPSTREAM}" 2>/dev/null || echo 0)
      [ -z "$AHEAD" ]  && AHEAD=0
      [ -z "$BEHIND" ] && BEHIND=0
    fi

    if [ "$STAGED" -gt 0 ];    then L2_PARTS="${L2_PARTS}  ${GREEN}✚${STAGED}${RST}"; fi
    if [ "$MODIFIED" -gt 0 ];  then L2_PARTS="${L2_PARTS}  ${YELLOW}✎${MODIFIED}${RST}"; fi
    if [ "$UNTRACKED" -gt 0 ]; then L2_PARTS="${L2_PARTS}  ${GRAY}?${UNTRACKED}${RST}"; fi
    if [ "$AHEAD" -gt 0 ];     then L2_PARTS="${L2_PARTS}  ${CYAN}↑${AHEAD}${RST}"; fi
    if [ "$BEHIND" -gt 0 ];    then L2_PARTS="${L2_PARTS}  ${RED}↓${BEHIND}${RST}"; fi
  fi
fi

# Lines changed
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_INFO="${GREEN}+${LINES_ADD}${RST} ${RED}-${LINES_DEL}${RST}"
  if [ -n "$L2_PARTS" ]; then
    L2_PARTS="${L2_PARTS}  ${DIM}│${RST}  ${LINES_INFO}"
  else
    L2_PARTS="$LINES_INFO"
  fi
fi

# ── Output: two lines ──────────────────────────────────────────────
printf "%b\n" "$LINE1"
if [ -n "$L2_PARTS" ]; then
  printf "%b" "$L2_PARTS"
fi
