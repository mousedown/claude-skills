#!/bin/zsh
# cost-tracker-statusline — cumulative cost tracking across sessions
# Self-contained single file — no external dependencies beyond jq, bc, git
# Shows: model [ctx bar] X% | $session ($total) | duration | ±lines | branch

INPUT=$(cat)

# ── Parse input ────────────────────────────────────────────────────────────
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' | sed 's/Claude //')
CURRENT_SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
CURRENT_SESSION_COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
EXCEEDS_200K=$(echo "$INPUT" | jq -r '.exceeds_200k_tokens // false')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# ── Session cost tracking ──────────────────────────────────────────────────
STATE_FILE="$HOME/.claude/cost_state.json"

if [ -f "$STATE_FILE" ]; then
  PREV_TOTAL=$(jq -r '.previous_total // 0' "$STATE_FILE")
  LAST_SESSION_ID=$(jq -r '.last_session_id // ""' "$STATE_FILE")
  LAST_SESSION_COST=$(jq -r '.last_session_cost // 0' "$STATE_FILE")
else
  PREV_TOTAL=0
  LAST_SESSION_ID=""
  LAST_SESSION_COST=0
fi

if [ -n "$CURRENT_SESSION_ID" ] && [ "$CURRENT_SESSION_ID" != "$LAST_SESSION_ID" ]; then
  PREV_TOTAL=$(echo "$PREV_TOTAL + $LAST_SESSION_COST" | bc)
  LAST_SESSION_ID="$CURRENT_SESSION_ID"
fi

jq -n \
  --argjson pt "$PREV_TOTAL" \
  --arg sid "$LAST_SESSION_ID" \
  --argjson lsc "$CURRENT_SESSION_COST" \
  '{previous_total: $pt, last_session_id: $sid, last_session_cost: $lsc}' \
  > "$STATE_FILE"

TOTAL_COST=$(echo "$PREV_TOTAL + $CURRENT_SESSION_COST" | bc)
TOTAL_COST_FMT=$(printf "%.3f" "$TOTAL_COST")
SESSION_COST_FMT=$(printf "%.3f" "$CURRENT_SESSION_COST")

# ── Duration ───────────────────────────────────────────────────────────────
DURATION_S=$(echo "$DURATION_MS / 1000" | bc)
if [ "$DURATION_S" -ge 3600 ]; then
  DURATION_DISPLAY="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif [ "$DURATION_S" -ge 60 ]; then
  DURATION_DISPLAY="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DURATION_DISPLAY="${DURATION_S}s"
fi

# ── Git info ───────────────────────────────────────────────────────────────
GIT_BRANCH=""
STAGED=0
MODIFIED=0
if [ -n "$CWD" ]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$GIT_BRANCH" ]; then
    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null || echo 0)
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null || echo 0)
  fi
fi

# ── Progress bar ───────────────────────────────────────────────────────────
FILLED=$(echo "$USED / 10" | bc)
BAR=""
for i in $(seq 1 10); do
  if [ "$i" -le "$FILLED" ]; then BAR="${BAR}▓"; else BAR="${BAR}░"; fi
done

# ── Lines changed ──────────────────────────────────────────────────────────
LINES_INFO=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_INFO=" \033[32m+${LINES_ADD}\033[0m \033[31m-${LINES_DEL}\033[0m"
fi

# ── Git display ────────────────────────────────────────────────────────────
GIT_INFO=""
if [ -n "$GIT_BRANCH" ]; then
  GIT_INFO="\033[36m ${GIT_BRANCH}\033[0m"
  if [ "$STAGED" -gt 0 ]; then GIT_INFO="${GIT_INFO} \033[32m+${STAGED}\033[0m"; fi
  if [ "$MODIFIED" -gt 0 ]; then GIT_INFO="${GIT_INFO} \033[33m~${MODIFIED}\033[0m"; fi
fi

# ── Context warning + color ────────────────────────────────────────────────
RST="\033[0m"
CTX_WARN=""
if [ "$EXCEEDS_200K" = "true" ]; then CTX_WARN=" \033[31;1m⚠ 200k+\033[0m"; fi
if [ "$USED" -ge 90 ]; then CTX_COLOR="\033[31m"
elif [ "$USED" -ge 70 ]; then CTX_COLOR="\033[33m"
else CTX_COLOR="\033[32m"
fi

echo -e "${CTX_COLOR}[${MODEL}] ${BAR} ${USED}%${RST}${CTX_WARN}  \033[35m\$${SESSION_COST_FMT}${RST} \033[90m(\$${TOTAL_COST_FMT} total)${RST}  \033[90m${DURATION_DISPLAY}${RST}${LINES_INFO}  ${GIT_INFO}"
